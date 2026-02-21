const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

admin.initializeApp();

const REGION = 'southamerica-east1';
const CODE_TTL_MS = 5 * 60 * 1000;
const TOKEN_TTL_MS = 10 * 60 * 1000;
const LINK_TTL_MS = 30 * 60 * 1000;
const RESET_COLLECTION = 'password_resets';
const RESET_LINK_COLLECTION = 'password_reset_links';
const RESET_LINK_REQUESTS_COLLECTION = 'password_reset_link_requests';
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;
const RATE_LIMIT_MAX = 5;
const RESEND_COOLDOWN_MS = 60 * 1000;

let transporter;

const getConfig = () => functions.config();

const getEmailFrom = () => {
  const fromEnv = String(process.env.EMAIL_FROM || '').trim();
  if (fromEnv) return fromEnv;
  const config = getConfig();
  const fromConfig = String(config?.smtp?.from || '').trim();
  return fromConfig;
};

const getSmtpConfig = () => {
  const host = String(process.env.SMTP_HOST || 'smtp.umbler.com').trim();
  const port = Number(process.env.SMTP_PORT || 0) || 587;
  const user =
    String(process.env.SMTP_USER || '').trim() ||
    String(getConfig()?.smtp?.user || '').trim();
  const pass =
    String(process.env.SMTP_PASS || '').trim() ||
    String(getConfig()?.smtp?.pass || '').trim();
  const secureRaw = String(process.env.SMTP_SECURE || '').trim().toLowerCase();
  const secure = secureRaw === 'true' || secureRaw === '1' || port === 465;

  if (!host || !user || !pass) return null;
  return {
    host,
    port: port || (secure ? 465 : 587),
    secure,
    auth: { user, pass },
  };
};

const getTransporter = () => {
  if (transporter) return transporter;
  const config = getSmtpConfig();
  if (!config) {
    throw new Error('smtp-not-configured');
  }
  transporter = nodemailer.createTransport(config);
  return transporter;
};

const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

const isValidEmail = (email) =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

const requireSecret = () => {
  const secret = getConfig()?.otp?.secret;
  if (!secret) {
    throw new Error('otp-secret-not-configured');
  }
  return secret;
};

const hashValue = (value, secret) =>
  crypto.createHmac('sha256', secret).update(value).digest('hex');

const randomCode = () =>
  Math.floor(10000 + Math.random() * 90000).toString();

const randomToken = () => crypto.randomBytes(24).toString('hex');

const applyCors = (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return false;
  }
  return true;
};

const sendError = (res, status, code) =>
  res.status(status).json({ error: { message: code } });

const requireAuth = async (req) => {
  const header = String(req.headers.authorization || '');
  const match = header.match(/^Bearer (.+)$/i);
  if (!match) {
    const error = new Error('unauthenticated');
    error.code = 'unauthenticated';
    throw error;
  }
  try {
    return await admin.auth().verifyIdToken(match[1]);
  } catch (_) {
    const error = new Error('unauthenticated');
    error.code = 'unauthenticated';
    throw error;
  }
};

const monthKeyFrom = (d) => {
  if (!d) return null;
  if (typeof d === 'string' && /^\d{4}-\d{2}$/.test(d)) return d;
  const date = d.toDate ? d.toDate() : d instanceof Date ? d : null;
  if (!date) return null;
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
};

const addMonths = (monthKey, delta) => {
  const m = String(monthKey || '').match(/^(\d{4})-(\d{2})$/);
  if (!m) return null;
  const year = parseInt(m[1], 10);
  const month = parseInt(m[2], 10);
  const date = new Date(year, month - 1 + delta, 1);
  const y = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  return `${y}-${mm}`;
};

const CATEGORY_KEYS = [
  'MORADIA',
  'ALIMENTACAO',
  'TRANSPORTE',
  'EDUCACAO',
  'SAUDE',
  'LAZER',
  'ASSINATURAS',
  'OUTROS',
];

const ESSENTIAL_CATEGORIES = new Set([
  'MORADIA',
  'ALIMENTACAO',
  'TRANSPORTE',
  'EDUCACAO',
  'SAUDE',
  'ASSINATURAS',
]);

const normalizeTxStatus = (tx) => {
  const raw = String(tx?.status || '').trim();
  if (raw) return raw.toUpperCase();
  return tx?.isPaid === true ? 'PAID' : 'PENDING';
};

const normalizeTxType = (tx) => {
  const rawUpper = String(tx?.type || '').trim().toUpperCase();
  if (rawUpper === 'EXPENSE' || rawUpper === 'INVESTMENT' || rawUpper === 'DEBT_PAYMENT') return rawUpper;

  const legacyLower = String(tx?.type || '').trim().toLowerCase();
  if (legacyLower === 'investment') return 'INVESTMENT';
  if (legacyLower === 'fixed' || legacyLower === 'variable') return 'EXPENSE';

  if (tx?.isInvestment === true) return 'INVESTMENT';
  if (String(tx?.category || '').trim().toLowerCase() === 'investment') return 'INVESTMENT';

  return rawUpper || null;
};

const normalizeTxIsVariable = (tx, txType) => {
  if (typeof tx?.isVariable === 'boolean') return tx.isVariable;
  const legacyLower = String(tx?.type || '').trim().toLowerCase();
  if (legacyLower === 'variable') return true;
  if (legacyLower === 'fixed') return false;
  if (txType === 'INVESTMENT') return false;
  return false;
};

const normalizeTxReferenceMonth = (tx) =>
  monthKeyFrom(tx?.referenceMonth) || monthKeyFrom(tx?.dueDate) || monthKeyFrom(tx?.date);

const normalizeTxCategoryKey = (tx) => {
  const key = String(tx?.categoryKey || '').trim();
  return key || null;
};

const isTxPaidExpense = (tx) => {
  if (!tx) return false;
  if (Number(tx.schemaVersion || 0) !== 2) return false;

  const type = normalizeTxType(tx);
  if (type !== 'EXPENSE') return false;

  const status = normalizeTxStatus(tx);
  if (status !== 'PAID') return false;

  const amount = Number(tx.amount || 0);
  if (!Number.isFinite(amount) || amount <= 0) return false;
  const month = normalizeTxReferenceMonth(tx);
  if (!month) return false;
  const categoryKey = normalizeTxCategoryKey(tx);
  if (!categoryKey) return false;
  return true;
};

const budgetDocId = (referenceMonth, categoryKey) =>
  `${referenceMonth}_${String(categoryKey || '').trim()}`;

const getUserTokens = async (uid) => {
  const snap = await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('fcmTokens')
    .get();
  return snap.docs.map((d) => d.id).filter(Boolean);
};

const sendBudgetNotification = async (uid, payload) => {
  const tokens = await getUserTokens(uid);
  if (!tokens.length) return { sent: 0 };

  const message = {
    tokens,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: {
      kind: 'budget_alert',
      referenceMonth: payload.referenceMonth || '',
      categoryKey: payload.categoryKey || '',
      level: payload.level || '',
    },
  };

  const result = await admin.messaging().sendEachForMulticast(message);

  // Cleanup invalid tokens
  const invalid = [];
  result.responses.forEach((r, i) => {
    if (r.success) return;
    const code = r.error?.code || '';
    if (
      code.includes('messaging/invalid-registration-token') ||
      code.includes('messaging/registration-token-not-registered')
    ) {
      invalid.push(tokens[i]);
    }
  });
  if (invalid.length) {
    const batch = admin.firestore().batch();
    invalid.forEach((t) => {
      batch.delete(
        admin
          .firestore()
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(t)
      );
    });
    await batch.commit();
  }

  return { sent: result.successCount };
};

const getResetDoc = (email) =>
  admin.firestore().collection(RESET_COLLECTION).doc(email);

const getResetLinkDoc = (tokenId) =>
  admin.firestore().collection(RESET_LINK_COLLECTION).doc(tokenId);

const getResetLinkRequestDoc = (emailHash) =>
  admin.firestore().collection(RESET_LINK_REQUESTS_COLLECTION).doc(emailHash);

const getResetLinkBaseUrl = () => {
  const base =
    String(process.env.PUBLIC_BASE_URL || '').trim() ||
    String(getConfig()?.public?.base_url || '').trim() ||
    'https://voolo-ad416.web.app';
  return String(base || '').replace(/\/+$/, '');
};

const sendEmail = async ({ to, subject, html, text }) => {
  const from = getEmailFrom();
  if (!from) {
    throw new Error('smtp-from-not-configured');
  }
  await getTransporter().sendMail({
    from,
    to,
    subject,
    html,
    text,
  });
};

const sendResetEmail = async ({ email, code }) => {
  const safeEmail = normalizeEmail(email);
  const subject = 'Voolo | Codigo para redefinir sua senha';
  const text = `Seu codigo de recuperacao: ${code}

Ele expira em 5 minutos.
Se voce nao solicitou isso, ignore este e-mail.
`;
  const html = `
    <div style="font-family:Arial,Helvetica,sans-serif;line-height:1.6;color:#111;background:#f6f7fb;padding:24px">
      <table width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:0 auto;background:#ffffff;border-radius:14px;overflow:hidden;border:1px solid #eef0f4">
        <tr>
          <td style="padding:20px 24px;background:#0f172a;color:#ffffff">
            <div style="font-size:18px;font-weight:700">Voolo</div>
            <div style="font-size:12px;opacity:0.8">Recuperacao de senha</div>
          </td>
        </tr>
        <tr>
          <td style="padding:24px">
            <h2 style="margin:0 0 12px 0;font-size:20px">Use o codigo abaixo</h2>
            <p style="margin:0 0 16px 0;color:#4b5563">Este codigo expira em <b>5 minutos</b>.</p>
            <div style="font-size:28px;letter-spacing:6px;font-weight:700;padding:14px 16px;border-radius:12px;background:#f3f4f6;display:inline-block">
              ${code}
            </div>
            <p style="margin:16px 0 0 0;color:#6b7280">Se voce nao solicitou este codigo, ignore este e-mail.</p>
          </td>
        </tr>
        <tr>
          <td style="padding:16px 24px;background:#f9fafb;color:#9ca3af;font-size:12px">
            Este e-mail foi enviado para ${safeEmail}.
          </td>
        </tr>
      </table>
    </div>
  `;

  await sendEmail({ to: safeEmail, subject, html, text });
};

const sendResetLinkEmail = async ({ email, link }) => {
  const safeEmail = normalizeEmail(email);
  const subject = 'Voolo | Redefina sua senha';
  const text = `Use este link para redefinir sua senha:
${link}

Este link expira em 30 minutos e pode ser usado apenas uma vez.
Se voce nao solicitou, ignore esta mensagem.
`;
  const html = `
    <div style="font-family:Arial,Helvetica,sans-serif;line-height:1.6;color:#111;background:#f6f7fb;padding:24px">
      <table width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:0 auto;background:#ffffff;border-radius:14px;overflow:hidden;border:1px solid #eef0f4">
        <tr>
          <td style="padding:20px 24px;background:#0f172a;color:#ffffff">
            <div style="font-size:18px;font-weight:700">Voolo</div>
            <div style="font-size:12px;opacity:0.8">Recuperacao de senha</div>
          </td>
        </tr>
        <tr>
          <td style="padding:24px">
            <h2 style="margin:0 0 12px 0;font-size:20px">Redefinir senha</h2>
            <p style="margin:0 0 16px 0;color:#4b5563">Clique no botao abaixo para criar uma nova senha. Este link expira em <b>30 minutos</b> e so pode ser usado uma vez.</p>
            <a href="${link}" style="display:inline-block;background:#111827;color:#fff;text-decoration:none;padding:12px 18px;border-radius:10px;font-weight:600">Redefinir senha</a>
            <p style="margin:16px 0 0 0;color:#6b7280">Se voce nao solicitou este link, ignore este e-mail.</p>
            <p style="margin:16px 0 0 0;color:#9ca3af;font-size:12px">Se o botao nao funcionar, copie e cole este link no navegador:<br/>${link}</p>
          </td>
        </tr>
        <tr>
          <td style="padding:16px 24px;background:#f9fafb;color:#9ca3af;font-size:12px">
            Este e-mail foi enviado para ${safeEmail}.
          </td>
        </tr>
      </table>
    </div>
  `;

  await sendEmail({ to: safeEmail, subject, html, text });
};

const isStrongPasswordServer = (password) => {
  const value = String(password || '');
  if (value.length < 8) return false;
  if (!/[A-Z]/.test(value)) return false;
  if (!/[a-z]/.test(value)) return false;
  if (!/[0-9]/.test(value)) return false;
  if (!/[^A-Za-z0-9]/.test(value)) return false;
  return true;
};

exports.sendPasswordResetCode = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    if (!applyCors(req, res)) return;
    if (req.method !== 'POST') {
      return sendError(res, 405, 'method-not-allowed');
    }
    try {
      const email = normalizeEmail(req.body?.data?.email);
      if (!email || !isValidEmail(email)) {
        return sendError(res, 400, 'invalid-argument');
      }

      try {
        await admin.auth().getUserByEmail(email);
      } catch (error) {
        if (error?.code === 'auth/user-not-found') {
          return sendError(res, 404, 'not-found');
        }
        return sendError(res, 500, 'auth-unavailable');
      }

      const secret = requireSecret();
      const code = randomCode();
      const codeHash = hashValue(code, secret);
      const expiresAt = Date.now() + CODE_TTL_MS;

      const docRef = getResetDoc(email);
      const existingSnap = await docRef.get();
      const now = Date.now();
      if (existingSnap.exists) {
        const data = existingSnap.data() || {};
        const lastSentAt = data.lastSentAt?.toMillis?.() || 0;
        if (lastSentAt && now - lastSentAt < RESEND_COOLDOWN_MS) {
          return sendError(res, 429, 'too-soon');
        }
        const windowStart = data.windowStart?.toMillis?.() || 0;
        const sendCount = data.sendCount || 0;
        if (windowStart && now - windowStart < RATE_LIMIT_WINDOW_MS) {
          if (sendCount >= RATE_LIMIT_MAX) {
            return sendError(res, 429, 'rate-limited');
          }
        }
      }

      const nextWindowStart =
        existingSnap.exists &&
        (existingSnap.data()?.windowStart?.toMillis?.() || 0) &&
        now - (existingSnap.data()?.windowStart?.toMillis?.() || 0) <
          RATE_LIMIT_WINDOW_MS
          ? existingSnap.data().windowStart
          : admin.firestore.Timestamp.fromMillis(now);
      const nextSendCount =
        existingSnap.exists &&
        (existingSnap.data()?.windowStart?.toMillis?.() || 0) &&
        now - (existingSnap.data()?.windowStart?.toMillis?.() || 0) <
          RATE_LIMIT_WINDOW_MS
          ? (existingSnap.data()?.sendCount || 0) + 1
          : 1;

      await docRef.set({
        email,
        codeHash,
        codeExpiresAt: admin.firestore.Timestamp.fromMillis(expiresAt),
        tokenHash: null,
        tokenExpiresAt: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        verifiedAt: null,
        lastSentAt: admin.firestore.Timestamp.fromMillis(now),
        windowStart: nextWindowStart,
        sendCount: nextSendCount,
      });

      await sendResetEmail({ email, code });

      return res.json({ result: { ok: true } });
    } catch (error) {
      const message = error?.message || '';
      if (message === 'smtp-not-configured' || message === 'smtp-from-not-configured') {
        return sendError(res, 500, 'smtp-not-configured');
      }
      if (message === 'otp-secret-not-configured') {
        return sendError(res, 500, 'otp-secret-not-configured');
      }
      return sendError(res, 500, 'unknown');
    }
  });

exports.verifyPasswordResetCode = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    if (!applyCors(req, res)) return;
    if (req.method !== 'POST') {
      return sendError(res, 405, 'method-not-allowed');
    }
    try {
      const email = normalizeEmail(req.body?.data?.email);
      const code = String(req.body?.data?.code || '').trim();
      if (!email || !isValidEmail(email) || !/^\d{5}$/.test(code)) {
        return sendError(res, 400, 'invalid-argument');
      }

      const docSnap = await getResetDoc(email).get();
      if (!docSnap.exists) {
        return sendError(res, 404, 'not-found');
      }

      const data = docSnap.data() || {};
      const expiresAt = data.codeExpiresAt?.toMillis?.() || 0;
      if (!expiresAt || Date.now() > expiresAt) {
        return sendError(res, 400, 'code-expired');
      }

      const secret = requireSecret();
      const codeHash = hashValue(code, secret);
      if (codeHash !== data.codeHash) {
        return sendError(res, 400, 'invalid-code');
      }

      const token = randomToken();
      const tokenHash = hashValue(token, secret);
      const tokenExpiresAt = Date.now() + TOKEN_TTL_MS;

      await getResetDoc(email).set(
        {
          tokenHash,
          tokenExpiresAt: admin.firestore.Timestamp.fromMillis(tokenExpiresAt),
          verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return res.json({ result: { token } });
    } catch (error) {
      const message = error?.message || '';
      if (message === 'otp-secret-not-configured') {
        return sendError(res, 500, 'otp-secret-not-configured');
      }
      return sendError(res, 500, 'unknown');
    }
  });

exports.confirmPasswordResetCode = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    if (!applyCors(req, res)) return;
    if (req.method !== 'POST') {
      return sendError(res, 405, 'method-not-allowed');
    }
    try {
      const email = normalizeEmail(req.body?.data?.email);
      const token = String(req.body?.data?.token || '').trim();
      const newPassword = String(req.body?.data?.newPassword || '');
      if (!email || !isValidEmail(email) || token.length === 0) {
        return sendError(res, 400, 'invalid-argument');
      }
      if (!isStrongPasswordServer(newPassword)) {
        return sendError(res, 400, 'weak-password');
      }

      const docSnap = await getResetDoc(email).get();
      if (!docSnap.exists) {
        return sendError(res, 404, 'not-found');
      }

      const data = docSnap.data() || {};
      const secret = requireSecret();
      const tokenHash = hashValue(token, secret);
      const storedHash = data.tokenHash || '';
      const tokenExpiresAt = data.tokenExpiresAt?.toMillis?.() || 0;
      if (!storedHash || tokenHash !== storedHash) {
        return sendError(res, 400, 'invalid-token');
      }
      if (!tokenExpiresAt || Date.now() > tokenExpiresAt) {
        return sendError(res, 400, 'token-expired');
      }

      const user = await admin.auth().getUserByEmail(email);
      await admin.auth().updateUser(user.uid, { password: newPassword });

      await getResetDoc(email).delete();

      return res.json({ result: { ok: true } });
    } catch (error) {
      const message = error?.message || '';
      if (message === 'otp-secret-not-configured') {
        return sendError(res, 500, 'otp-secret-not-configured');
      }
      if (message === 'auth/user-not-found') {
        return sendError(res, 404, 'not-found');
      }
      return sendError(res, 500, 'unknown');
    }
  });

exports.requestPasswordResetLink = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    if (!applyCors(req, res)) return;
    if (req.method !== 'POST') {
      return sendError(res, 405, 'method-not-allowed');
    }
    try {
      const email = normalizeEmail(req.body?.data?.email);
      if (!email || !isValidEmail(email)) {
        return sendError(res, 400, 'invalid-argument');
      }

      const secret = requireSecret();
      const emailHash = hashValue(email, secret);

      const now = Date.now();
      const requestRef = getResetLinkRequestDoc(emailHash);
      const existingSnap = await requestRef.get();
      if (existingSnap.exists) {
        const data = existingSnap.data() || {};
        const lastSentAt = data.lastSentAt?.toMillis?.() || 0;
        if (lastSentAt && now - lastSentAt < RESEND_COOLDOWN_MS) {
          return sendError(res, 429, 'too-soon');
        }
        const windowStart = data.windowStart?.toMillis?.() || 0;
        const sendCount = data.sendCount || 0;
        if (windowStart && now - windowStart < RATE_LIMIT_WINDOW_MS) {
          if (sendCount >= RATE_LIMIT_MAX) {
            return sendError(res, 429, 'rate-limited');
          }
        }
      }

      let uid = null;
      try {
        const user = await admin.auth().getUserByEmail(email);
        uid = user?.uid || null;
      } catch (error) {
        if (error?.code !== 'auth/user-not-found') {
          return sendError(res, 500, 'auth-unavailable');
        }
      }

      const token = randomToken();
      const tokenId = hashValue(token, secret);
      const expiresAt = now + LINK_TTL_MS;

      const existing = existingSnap.exists ? existingSnap.data() : null;
      const previousTokenId = String(existing?.latestTokenId || '').trim();
      if (previousTokenId) {
        await getResetLinkDoc(previousTokenId).delete().catch(() => {});
      }

      await getResetLinkDoc(tokenId).set({
        email,
        emailHash,
        uid,
        expiresAt: admin.firestore.Timestamp.fromMillis(expiresAt),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        usedAt: null,
      });

      const nextWindowStart =
        existingSnap.exists &&
        (existingSnap.data()?.windowStart?.toMillis?.() || 0) &&
        now - (existingSnap.data()?.windowStart?.toMillis?.() || 0) <
          RATE_LIMIT_WINDOW_MS
          ? existingSnap.data().windowStart
          : admin.firestore.Timestamp.fromMillis(now);
      const nextSendCount =
        existingSnap.exists &&
        (existingSnap.data()?.windowStart?.toMillis?.() || 0) &&
        now - (existingSnap.data()?.windowStart?.toMillis?.() || 0) <
          RATE_LIMIT_WINDOW_MS
          ? (existingSnap.data()?.sendCount || 0) + 1
          : 1;

      await requestRef.set({
        email,
        latestTokenId: tokenId,
        lastSentAt: admin.firestore.Timestamp.fromMillis(now),
        windowStart: nextWindowStart,
        sendCount: nextSendCount,
      }, { merge: true });

      if (uid) {
        const link = `${getResetLinkBaseUrl()}/auth/reset?token=${encodeURIComponent(token)}`;
        await sendResetLinkEmail({ email, link });
      }

      return res.json({ result: { ok: true } });
    } catch (error) {
      const message = error?.message || '';
      if (message === 'smtp-not-configured' || message === 'smtp-from-not-configured') {
        return sendError(res, 500, 'smtp-not-configured');
      }
      if (message === 'otp-secret-not-configured') {
        return sendError(res, 500, 'otp-secret-not-configured');
      }
      return sendError(res, 500, 'unknown');
    }
  });

exports.verifyPasswordResetLink = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    if (!applyCors(req, res)) return;
    if (req.method !== 'POST') {
      return sendError(res, 405, 'method-not-allowed');
    }
    try {
      const token = String(req.body?.data?.token || '').trim();
      if (!token) {
        return sendError(res, 400, 'invalid-argument');
      }
      const secret = requireSecret();
      const tokenId = hashValue(token, secret);

      const docSnap = await getResetLinkDoc(tokenId).get();
      if (!docSnap.exists) {
        return sendError(res, 404, 'not-found');
      }

      const data = docSnap.data() || {};
      const expiresAt = data.expiresAt?.toMillis?.() || 0;
      const usedAt = data.usedAt || null;
      if (usedAt || !expiresAt || Date.now() > expiresAt) {
        await getResetLinkDoc(tokenId).delete().catch(() => {});
        return sendError(res, 400, 'token-expired');
      }

      return res.json({ result: { ok: true } });
    } catch (error) {
      const message = error?.message || '';
      if (message === 'otp-secret-not-configured') {
        return sendError(res, 500, 'otp-secret-not-configured');
      }
      return sendError(res, 500, 'unknown');
    }
  });

exports.confirmPasswordResetLink = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    if (!applyCors(req, res)) return;
    if (req.method !== 'POST') {
      return sendError(res, 405, 'method-not-allowed');
    }
    try {
      const token = String(req.body?.data?.token || '').trim();
      const newPassword = String(req.body?.data?.newPassword || '');
      if (!token) {
        return sendError(res, 400, 'invalid-argument');
      }
      if (!isStrongPasswordServer(newPassword)) {
        return sendError(res, 400, 'weak-password');
      }

      const secret = requireSecret();
      const tokenId = hashValue(token, secret);

      const docSnap = await getResetLinkDoc(tokenId).get();
      if (!docSnap.exists) {
        return sendError(res, 404, 'not-found');
      }

      const data = docSnap.data() || {};
      const expiresAt = data.expiresAt?.toMillis?.() || 0;
      const usedAt = data.usedAt || null;
      if (usedAt || !expiresAt || Date.now() > expiresAt) {
        await getResetLinkDoc(tokenId).delete().catch(() => {});
        return sendError(res, 400, 'token-expired');
      }

      let uid = String(data.uid || '').trim();
      if (!uid) {
        const email = normalizeEmail(data.email || '');
        if (email) {
          const user = await admin.auth().getUserByEmail(email);
          uid = user?.uid || '';
        }
      }
      if (!uid) {
        return sendError(res, 404, 'not-found');
      }

      await admin.auth().updateUser(uid, { password: newPassword });
      await getResetLinkDoc(tokenId).delete();

      return res.json({ result: { ok: true } });
    } catch (error) {
      const message = error?.message || '';
      if (message === 'otp-secret-not-configured') {
        return sendError(res, 500, 'otp-secret-not-configured');
      }
      if (message === 'auth/user-not-found') {
        return sendError(res, 404, 'not-found');
      }
      return sendError(res, 500, 'unknown');
    }
  });

// ====== BUDGETS: Real-time spent + notifications ======

exports.onTransactionWrite = functions
  .region(REGION)
  .firestore.document('users/{uid}/transactions/{txId}')
  .onWrite(async (change, context) => {
    const uid = context.params.uid;
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;

    const beforeCounts = isTxPaidExpense(before);
    const afterCounts = isTxPaidExpense(after);

    if (!beforeCounts && !afterCounts) return null;

    const beforeMonth = beforeCounts ? normalizeTxReferenceMonth(before) : null;
    const afterMonth = afterCounts ? normalizeTxReferenceMonth(after) : null;
    const beforeCategory = beforeCounts ? normalizeTxCategoryKey(before) : null;
    const afterCategory = afterCounts ? normalizeTxCategoryKey(after) : null;

    const beforeAmount = beforeCounts ? Number(before.amount || 0) : 0;
    const afterAmount = afterCounts ? Number(after.amount || 0) : 0;

    const db = admin.firestore();

    // Updates can move month/category; apply two increments if needed
    const updates = [];
    if (beforeCounts) {
      updates.push({
        month: beforeMonth,
        categoryKey: beforeCategory,
        delta: -beforeAmount,
      });
    }
    if (afterCounts) {
      updates.push({
        month: afterMonth,
        categoryKey: afterCategory,
        delta: afterAmount,
      });
    }

    const touched = new Set();

    await db.runTransaction(async (tx) => {
      for (const u of updates) {
        if (!u.month || !u.categoryKey || !Number.isFinite(u.delta) || u.delta === 0) {
          continue;
        }
        const id = budgetDocId(u.month, u.categoryKey);
        const ref = db.collection('users').doc(uid).collection('budgets').doc(id);
        const snap = await tx.get(ref);
        const data = snap.exists ? snap.data() : {};
        const currentSpent = Number(data.spentAmount || 0);
        const nextSpent = Math.max(0, currentSpent + u.delta);

        const base = {
          schemaVersion: 2,
          referenceMonth: u.month,
          categoryKey: u.categoryKey,
          essential: ESSENTIAL_CATEGORIES.has(u.categoryKey),
          spentAmount: nextSpent,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (!snap.exists) {
          base.limitAmount = 0;
          base.suggestedAmount = null;
          base.notified80 = false;
          base.notified100 = false;
          base.createdAt = admin.firestore.FieldValue.serverTimestamp();
          base.createdBy = uid;
          base.sourceApp = 'admin';
        }

        tx.set(ref, base, { merge: true });
        touched.add(id);
      }
    });

    // Post-transaction: send notifications for the "after" category/month only
    if (!afterCounts) return null;
    const budgetId = budgetDocId(afterMonth, afterCategory);
    if (!touched.has(budgetId)) return null;

    const ref = db.collection('users').doc(uid).collection('budgets').doc(budgetId);
    const snap = await ref.get();
    if (!snap.exists) return null;

    const data = snap.data() || {};
    const limit = Number(data.limitAmount || 0);
    const spent = Number(data.spentAmount || 0);
    if (!Number.isFinite(limit) || limit <= 0) return null;

    const notified80 = data.notified80 === true;
    const notified100 = data.notified100 === true;

    const updatesNotify = {};
    const notifications = [];

    if (!notified80 && spent >= 0.8 * limit) {
      updatesNotify.notified80 = true;
      notifications.push({
        level: '80',
        title: 'Atenção no orçamento',
        body: `Você atingiu 80% do orçamento de ${afterCategory}.`,
      });
    }
    if (!notified100 && spent >= limit) {
      updatesNotify.notified100 = true;
      notifications.push({
        level: '100',
        title: 'Orçamento estourado',
        body: `Você atingiu 100% do orçamento de ${afterCategory}.`,
      });
    }

    if (Object.keys(updatesNotify).length) {
      await ref.set(
        { ...updatesNotify, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    for (const n of notifications) {
      await sendBudgetNotification(uid, {
        title: n.title,
        body: n.body,
        referenceMonth: afterMonth,
        categoryKey: afterCategory,
        level: n.level,
      });
    }

    return null;
  });

exports.suggestBudgets = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    if (!applyCors(req, res)) return;
    if (req.method !== 'POST') {
      return sendError(res, 405, 'method-not-allowed');
    }
    try {
      const auth = await requireAuth(req);
      const uid = auth.uid;

      const monthYear = String(req.body?.data?.monthYear || '').trim();
      const savingsPctRaw = req.body?.data?.savingsPct;
      const savingsPct = Math.min(
        0.8,
        Math.max(0, Number.isFinite(Number(savingsPctRaw)) ? Number(savingsPctRaw) : 0.1)
      );

      if (!/^\d{4}-\d{2}$/.test(monthYear)) {
        return sendError(res, 400, 'invalid-argument');
      }

      const db = admin.firestore();

      // Income for the month (sum of active incomes)
      const incomesSnap = await db.collection('users').doc(uid).collection('incomes').get();
      const incomes = incomesSnap.docs.map((d) => d.data());
      const incomeTotal = incomes.reduce((acc, inc) => {
        const active = inc.isActive !== false;
        if (!active) return acc;
        const excluded = Array.isArray(inc.excludedMonths) && inc.excludedMonths.includes(monthYear);
        if (excluded) return acc;
        const activeFrom = inc.activeFrom;
        const activeUntil = inc.activeUntil;
        if (activeFrom && /^\d{4}-\d{2}$/.test(activeFrom) && monthYear < activeFrom) return acc;
        if (activeUntil && /^\d{4}-\d{2}$/.test(activeUntil) && monthYear > activeUntil) return acc;
        const amount = Number(inc.amount || 0);
        return Number.isFinite(amount) ? acc + amount : acc;
      }, 0);

      // Expenses and investments for the month (paid only)
      const txSnap = await db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('schemaVersion', '==', 2)
        .where('referenceMonth', '==', monthYear)
        .get();
      const txs = txSnap.docs.map((d) => d.data());
      const paidTxs = txs.filter((t) => normalizeTxStatus(t) === 'PAID');
      const fixedTotal = paidTxs
        .filter((t) => normalizeTxType(t) === 'EXPENSE' && normalizeTxIsVariable(t, normalizeTxType(t)) === false)
        .reduce((a, t) => a + Number(t.amount || 0), 0);
      const investmentsTotal = paidTxs
        .filter((t) => normalizeTxType(t) === 'INVESTMENT')
        .reduce((a, t) => a + Number(t.amount || 0), 0);

      const savingsTarget = Math.max(0, incomeTotal * savingsPct);
      const availableBudget = Math.max(0, incomeTotal - fixedTotal - investmentsTotal - savingsTarget);

      // Historical weights: last 3 months variable expenses by category (paid only)
      const histMonths = [addMonths(monthYear, -1), addMonths(monthYear, -2), addMonths(monthYear, -3)].filter(Boolean);
      const histSnap = histMonths.length
        ? await db
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .where('schemaVersion', '==', 2)
            .where('referenceMonth', 'in', histMonths)
            .get()
        : { docs: [] };
      const hist = histSnap.docs.map((d) => d.data());

      const perCat = {};
      CATEGORY_KEYS.forEach((c) => (perCat[c] = 0));
      hist
        .filter((t) => normalizeTxStatus(t) === 'PAID')
        .filter((t) => normalizeTxType(t) === 'EXPENSE' && normalizeTxIsVariable(t, normalizeTxType(t)) === true)
        .forEach((t) => {
          const key = normalizeTxCategoryKey(t);
          const amt = Number(t.amount || 0);
          if (!key) return;
          if (!(key in perCat)) return;
          if (!Number.isFinite(amt) || amt <= 0) return;
          perCat[key] += amt;
        });

      // Average over months; build weights (essential gets small boost)
      const weights = {};
      let sumW = 0;
      CATEGORY_KEYS.forEach((c) => {
        const avg = perCat[c] / Math.max(1, histMonths.length);
        const w = (avg > 0 ? avg : 1) * (ESSENTIAL_CATEGORIES.has(c) ? 1.15 : 1);
        weights[c] = w;
        sumW += w;
      });

      const suggestions = {};
      CATEGORY_KEYS.forEach((c) => {
        const raw = (availableBudget * (weights[c] / sumW)) || 0;
        const rounded = Math.round(raw * 100) / 100;
        suggestions[c] = rounded;
      });

      // Recompute month spent totals (paid expenses) to keep budgets consistent across apps.
      const spentPerCat = {};
      CATEGORY_KEYS.forEach((c) => (spentPerCat[c] = 0));
      paidTxs
        .filter((t) => normalizeTxType(t) === 'EXPENSE')
        .forEach((t) => {
          const key = normalizeTxCategoryKey(t);
          const amt = Number(t.amount || 0);
          if (!key) return;
          if (!(key in spentPerCat)) return;
          if (!Number.isFinite(amt) || amt <= 0) return;
          spentPerCat[key] += amt;
        });

      // Persist suggestedAmount (and initialize docs if missing)
      const batch = db.batch();
      CATEGORY_KEYS.forEach((c) => {
        const id = budgetDocId(monthYear, c);
        const ref = db.collection('users').doc(uid).collection('budgets').doc(id);
        batch.set(
          ref,
          {
            schemaVersion: 2,
            referenceMonth: monthYear,
            categoryKey: c,
            essential: ESSENTIAL_CATEGORIES.has(c),
            suggestedAmount: suggestions[c],
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            // Do not overwrite user limits; only initialize numeric fields if missing.
            limitAmount: admin.firestore.FieldValue.increment(0),
            spentAmount: Math.max(0, Math.round(Number(spentPerCat[c] || 0) * 100) / 100),
          },
          { merge: true }
        );
      });
      await batch.commit();

      return res.json({
        result: {
          monthYear,
          incomeTotal,
          fixedTotal,
          investmentsTotal,
          savingsPct,
          savingsTarget,
          availableBudget,
          suggestions,
        },
      });
    } catch (error) {
      const code = error?.code || error?.message || 'unknown';
      if (code === 'unauthenticated') {
        return sendError(res, 401, 'unauthenticated');
      }
      return sendError(res, 500, 'unknown');
    }
  });

// ====== DEBTS: compute premium payoff plan (server-side) ======

exports.computeDebtPlan = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    if (!applyCors(req, res)) return;
    if (req.method !== 'POST') {
      return sendError(res, 405, 'method-not-allowed');
    }
    try {
      const auth = await requireAuth(req);
      const uid = auth.uid;

      const methodRaw = String(req.body?.data?.method || 'avalanche').toLowerCase();
      const method = methodRaw === 'snowball' ? 'snowball' : 'avalanche';
      const monthYear = String(req.body?.data?.monthYear || '').trim() || monthKeyFrom(new Date());
      if (!/^\d{4}-\d{2}$/.test(monthYear)) {
        return sendError(res, 400, 'invalid-argument');
      }

      const db = admin.firestore();
      const round2 = (n) => Math.round((Number(n) || 0) * 100) / 100;
      const safeMoney = (n) => round2(Math.max(0, Number(n) || 0));
      const parseMonthKey = (mk) => {
        const m = String(mk || '').match(/^(\d{4})-(\d{2})$/);
        if (!m) return null;
        const y = parseInt(m[1], 10);
        const mm = parseInt(m[2], 10);
        if (!Number.isFinite(y) || !Number.isFinite(mm) || mm < 1 || mm > 12) return null;
        return { y, m: mm };
      };
      const compareMonthKey = (a, b) => {
        const pa = parseMonthKey(a);
        const pb = parseMonthKey(b);
        if (!pa || !pb) return 0;
        if (pa.y !== pb.y) return pa.y - pb.y;
        return pa.m - pb.m;
      };
      const monthlyRateFraction = (ratePct) => {
        if (ratePct == null) return 0;
        const n = Number(ratePct);
        if (!Number.isFinite(n) || n <= 0) return 0;
        return n / 100;
      };
      const inferMinPayment = (debt) => {
        const bal = safeMoney(debt.totalAmount);
        if (debt.minPayment != null && Number.isFinite(debt.minPayment) && debt.minPayment > 0) {
          return { value: safeMoney(debt.minPayment), assumed: false, rule: 'provided' };
        }
        const kind = String(debt.kind || '').toLowerCase();
        const pct =
          kind === 'financing'
            ? 0.015
            : kind === 'loan'
              ? 0.03
              : kind === 'card'
                ? 0.02
                : 0.02;
        const floor = kind === 'financing' ? 150 : 80;
        const guess = safeMoney(Math.min(bal, Math.max(floor, bal * pct)));
        return { value: guess, assumed: true, rule: `heuristic:${kind || 'other'}` };
      };

      // Income (same heuristic as budgets)
      const incomesSnap = await db.collection('users').doc(uid).collection('incomes').get();
      const incomes = incomesSnap.docs.map((d) => d.data());
      const incomeTotal = incomes.reduce((acc, inc) => {
        const active = inc.isActive !== false;
        if (!active) return acc;
        const excluded = Array.isArray(inc.excludedMonths) && inc.excludedMonths.includes(monthYear);
        if (excluded) return acc;
        const activeFrom = inc.activeFrom;
        const activeUntil = inc.activeUntil;
        if (activeFrom && /^\d{4}-\d{2}$/.test(activeFrom) && monthYear < activeFrom) return acc;
        if (activeUntil && /^\d{4}-\d{2}$/.test(activeUntil) && monthYear > activeUntil) return acc;
        const amount = Number(inc.amount || 0);
        return Number.isFinite(amount) ? acc + amount : acc;
      }, 0);

      // Essential expenses (paid)
      const essentialKeys = Array.from(ESSENTIAL_CATEGORIES);
      const essentialSnap = await db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('schemaVersion', '==', 2)
        .where('referenceMonth', '==', monthYear)
        .where('status', '==', 'PAID')
        .where('type', '==', 'EXPENSE')
        .where('categoryKey', 'in', essentialKeys)
        .get();
      const essentialTotal = essentialSnap.docs.reduce((a, d) => a + Number(d.data().amount || 0), 0);

      const surplus = Math.max(0, incomeTotal - essentialTotal);

      // Defaults: keep conservative to avoid dangerous plans.
      const incomePct = 0.25;
      const surplusPct = 0.7;
      const maxByIncome = incomeTotal * incomePct;
      const maxBySurplus = surplus * surplusPct;
      const recommendedMaxInstallment = Math.max(0, Math.min(maxByIncome, maxBySurplus));

      const debtsSnap = await db
        .collection('users')
        .doc(uid)
        .collection('debts')
        .where('schemaVersion', '==', 2)
        .where('status', 'in', ['ACTIVE', 'NEGOTIATING'])
        .get();

      const debts = debtsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

      const normalized = debts
        .map((d) => {
          const total = Number(d.totalAmount || 0);
          const rate = d.interestRate == null ? null : Number(d.interestRate);
          const minPayment = d.minPayment == null ? null : Number(d.minPayment);
          return {
            id: d.id,
            creditorName: String(d.creditorName || d.creditor || '').trim() || 'Dívida',
            totalAmount: Number.isFinite(total) ? total : 0,
            interestRate: Number.isFinite(rate) ? rate : null,
            minPayment: Number.isFinite(minPayment) ? minPayment : null,
            lateSince: d.lateSince || null,
            isLate: d.isLate === true || d.status === 'LATE',
            status: d.status,
            kind: d.kind || d.type || 'unknown',
          };
        })
        .filter((d) => d.totalAmount > 0)
        .map((d) => {
          const inferred = inferMinPayment(d);
          const hasRate = d.interestRate != null && Number.isFinite(d.interestRate);
          return {
            ...d,
            totalAmount: safeMoney(d.totalAmount),
            interestRate: hasRate ? round2(d.interestRate) : null,
            monthlyRateFraction: monthlyRateFraction(d.interestRate),
            minPaymentUsed: inferred.value,
            minPaymentAssumed: inferred.assumed,
            minPaymentRule: inferred.rule,
          };
        });

      const sorted = normalized.sort((a, b) => {
        if (Boolean(a.isLate) !== Boolean(b.isLate)) return a.isLate ? -1 : 1;

        if (method === 'snowball') {
          if (a.totalAmount !== b.totalAmount) return a.totalAmount - b.totalAmount;
          const ar = a.interestRate ?? -1;
          const br = b.interestRate ?? -1;
          return br - ar;
        }
        const ar = a.interestRate ?? -1;
        const br = b.interestRate ?? -1;
        if (ar !== br) return br - ar;
        return b.totalAmount - a.totalAmount;
      });

      const explanation =
        method === 'snowball'
          ? 'Snowball: começa pelas menores dívidas para gerar motivação e “ganhos rápidos”.'
          : 'Avalanche: começa pelas maiores taxas de juros para reduzir o custo total.';

      const instructions =
        method === 'snowball'
          ? [
              '1) Pague o mínimo de todas as dívidas.',
              '2) Coloque todo o valor extra na menor dívida.',
              '3) Ao quitar uma, some (role) o valor dela para a próxima.',
            ].join('\n')
          : [
              '1) Pague o mínimo de todas as dívidas.',
              '2) Coloque todo o valor extra na dívida com maior juros.',
              '3) Ao quitar uma, some (role) o valor dela para a próxima.',
            ].join('\n');

      const warnings = [];
      if (incomeTotal <= 0) warnings.push('Sem renda cadastrada: a recomendação de parcela pode ficar conservadora.');
      if (surplus <= 0) warnings.push('Seu orçamento essencial está consumindo toda a renda deste mês; priorize renegociação antes de aumentar parcelas.');
      if (sorted.some((d) => d.minPaymentAssumed)) {
        warnings.push('Algumas dívidas não têm “pagamento mínimo”; usei uma estimativa. Ajuste o mínimo real para maior precisão.');
      }
      if (sorted.some((d) => d.interestRate == null)) {
        warnings.push('Algumas dívidas estão sem juros informados; a simulação considera juros 0% a.m. nelas.');
      }

      const minimumPaymentsTotal = safeMoney(sorted.reduce((a, d) => a + safeMoney(d.minPaymentUsed || 0), 0));
      const monthlyBudgetUsed = safeMoney(Math.max(recommendedMaxInstallment, minimumPaymentsTotal));
      if (minimumPaymentsTotal > recommendedMaxInstallment && recommendedMaxInstallment > 0) {
        warnings.push('Seu total de mínimos é maior que a parcela máxima recomendada; considere renegociar prazos/juros.');
      }
      const extraBudget = safeMoney(Math.max(0, monthlyBudgetUsed - minimumPaymentsTotal));

      const MAX_MONTHS = 240;
      const PREVIEW_MONTHS = 24;
      const state = sorted.map((d) => ({
        id: d.id,
        creditorName: d.creditorName,
        kind: d.kind,
        startingBalance: safeMoney(d.totalAmount),
        balance: safeMoney(d.totalAmount),
        monthlyRateFraction: d.monthlyRateFraction || 0,
        interestRate: d.interestRate,
        minPaymentUsed: safeMoney(d.minPaymentUsed || 0),
      }));

      const totalsByDebt = new Map();
      state.forEach((d) => totalsByDebt.set(d.id, { totalPaid: 0, totalInterest: 0 }));
      const payoffByDebt = new Map();

      const schedulePreview = [];
      let monthsSimulated = 0;
      let simMonth = monthYear;
      let lastRemainingTotal = safeMoney(state.reduce((a, d) => a + d.balance, 0));
      let nonProgressStreak = 0;

      const nextFocusIdx = () => state.findIndex((d) => d.balance > 0);

      while (monthsSimulated < MAX_MONTHS) {
        const remainingTotalStart = safeMoney(state.reduce((a, d) => a + d.balance, 0));
        if (remainingTotalStart <= 0) break;

        const interestByDebt = new Map();
        for (const d of state) {
          const interest = safeMoney(d.balance * (d.monthlyRateFraction || 0));
          d.balance = safeMoney(d.balance + interest);
          interestByDebt.set(d.id, interest);
          const totals = totalsByDebt.get(d.id);
          totals.totalInterest = safeMoney(totals.totalInterest + interest);
        }

        let budgetLeft = monthlyBudgetUsed;
        const allocations = [];
        for (const d of state) {
          if (d.balance <= 0) continue;
          const pay = safeMoney(Math.min(d.balance, d.minPaymentUsed || 0, budgetLeft));
          if (pay <= 0) continue;
          d.balance = safeMoney(d.balance - pay);
          budgetLeft = safeMoney(budgetLeft - pay);
          const totals = totalsByDebt.get(d.id);
          totals.totalPaid = safeMoney(totals.totalPaid + pay);
          allocations.push({ debtId: d.id, payment: pay, kind: 'min' });
        }

        while (budgetLeft > 0) {
          const idx = nextFocusIdx();
          if (idx < 0) break;
          const focus = state[idx];
          const pay = safeMoney(Math.min(focus.balance, budgetLeft));
          if (pay <= 0) break;
          focus.balance = safeMoney(focus.balance - pay);
          budgetLeft = safeMoney(budgetLeft - pay);
          const totals = totalsByDebt.get(focus.id);
          totals.totalPaid = safeMoney(totals.totalPaid + pay);
          allocations.push({ debtId: focus.id, payment: pay, kind: 'extra' });
        }

        for (const d of state) {
          if (d.balance <= 0 && !payoffByDebt.has(d.id)) payoffByDebt.set(d.id, simMonth);
        }

        const remainingTotalEnd = safeMoney(state.reduce((a, d) => a + d.balance, 0));
        const focusDebtId = (() => {
          const idx = nextFocusIdx();
          return idx >= 0 ? state[idx].id : null;
        })();

        if (remainingTotalEnd >= lastRemainingTotal - 0.01) nonProgressStreak += 1;
        else nonProgressStreak = 0;
        lastRemainingTotal = remainingTotalEnd;
        if (nonProgressStreak >= 3) {
          warnings.push('A simulação não está reduzindo o saldo (juros podem estar maiores que os pagamentos). Renegocie ou aumente o valor mensal.');
          break;
        }

        if (schedulePreview.length < PREVIEW_MONTHS) {
          schedulePreview.push({
            monthYear: simMonth,
            focusDebtId,
            paid: safeMoney(allocations.reduce((a, x) => a + safeMoney(x.payment || 0), 0)),
            interest: safeMoney(Array.from(interestByDebt.values()).reduce((a, v) => a + safeMoney(v), 0)),
            remainingTotal: remainingTotalEnd,
            balances: state.map((d) => ({ debtId: d.id, endingBalance: safeMoney(d.balance) })),
            allocations,
          });
        }

        monthsSimulated += 1;
        simMonth = addMonths(simMonth, 1);
      }

      const estimatedDebtFreeMonthYear =
        state.every((d) => d.balance <= 0) && monthsSimulated > 0
          ? addMonths(monthYear, monthsSimulated - 1)
          : state.every((d) => d.balance <= 0)
            ? monthYear
            : null;

      const payoffSummary = state.map((d) => {
        const payoffMonthYear = payoffByDebt.get(d.id) || null;
        const totals = totalsByDebt.get(d.id) || { totalPaid: 0, totalInterest: 0 };
        const monthsToPayoff = payoffMonthYear ? Math.max(0, compareMonthKey(payoffMonthYear, monthYear)) + 1 : null;
        return {
          debtId: d.id,
          creditorName: d.creditorName,
          kind: d.kind,
          startingBalance: safeMoney(d.startingBalance),
          interestRate: d.interestRate,
          minPaymentUsed: safeMoney(d.minPaymentUsed),
          payoffMonthYear,
          monthsToPayoff,
          totalPaid: safeMoney(totals.totalPaid),
          totalInterest: safeMoney(totals.totalInterest),
        };
      });

      const plan = {
        schemaVersion: 2,
        method,
        monthYear,
        incomeTotal,
        essentialTotal,
        surplus,
        incomePct,
        surplusPct,
        recommendedMaxInstallment,
        explanation,
        instructions,
        warnings,
        minimumPaymentsTotal,
        monthlyBudgetUsed,
        extraBudget,
        estimatedDebtFreeMonthYear,
        monthsSimulated,
        focusDebtId: sorted[0]?.id || null,
        debts: sorted.map((d, idx) => ({
          id: d.id,
          creditorName: d.creditorName,
          totalAmount: safeMoney(d.totalAmount),
          interestRate: d.interestRate,
          minPayment: d.minPayment,
          minPaymentUsed: safeMoney(d.minPaymentUsed),
          minPaymentAssumed: Boolean(d.minPaymentAssumed),
          isLate: Boolean(d.isLate),
          lateSince: d.lateSince || null,
          status: d.status,
          kind: d.kind,
          order: idx + 1,
          recommendedFocus: idx === 0,
        })),
        payoffSummary,
        schedulePreview,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: uid,
        sourceApp: 'admin',
      };

      const planId = `${monthYear}_${method}`;
      await db.collection('users').doc(uid).collection('debtPlans').doc(planId).set(plan, { merge: true });

      return res.json({ result: plan });
    } catch (error) {
      const code = error?.code || error?.message || 'unknown';
      if (code === 'unauthenticated') {
        return sendError(res, 401, 'unauthenticated');
      }
      return sendError(res, 500, 'unknown');
    }
  });

// ====== INVESTMENTS: risk profile + allocation (no product recommendations) ======

exports.computeInvestmentProfile = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    if (!applyCors(req, res)) return;
    if (req.method !== 'POST') {
      return sendError(res, 405, 'method-not-allowed');
    }
    try {
      const auth = await requireAuth(req);
      const uid = auth.uid;

      const answers = Array.isArray(req.body?.data?.answers) ? req.body.data.answers : [];
      if (!Array.isArray(answers) || answers.length < 6 || answers.length > 8) {
        return sendError(res, 400, 'invalid-argument');
      }
      const normalized = answers.map((x) => {
        const n = Number(x);
        if (!Number.isFinite(n)) return 0;
        return Math.max(0, Math.min(2, Math.round(n)));
      });
      const score = normalized.reduce((a, b) => a + b, 0);

      let risk = 'conservative';
      if (score >= 10) risk = 'aggressive';
      else if (score >= 6) risk = 'moderate';

      const allocation =
        risk === 'conservative'
          ? { fixedLiquid: 0.8, fixedLong: 0.2, equity: 0.0, highRisk: 0.0 }
          : risk === 'moderate'
            ? { fixedLiquid: 0.6, fixedLong: 0.0, equity: 0.3, highRisk: 0.1 }
            : { fixedLiquid: 0.4, fixedLong: 0.0, equity: 0.4, highRisk: 0.2 };

      const db = admin.firestore();
      await db
        .collection('users')
        .doc(uid)
        .collection('investmentProfile')
        .doc('current')
        .set(
          {
            schemaVersion: 1,
            answers: normalized,
            score,
            risk,
            allocation,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: uid,
            sourceApp: 'admin',
          },
          { merge: true }
        );

      return res.json({
        result: {
          risk,
          score,
          allocation,
        },
      });
    } catch (error) {
      const code = error?.code || error?.message || 'unknown';
      if (code === 'unauthenticated') {
        return sendError(res, 401, 'unauthenticated');
      }
      return sendError(res, 500, 'unknown');
    }
  });
