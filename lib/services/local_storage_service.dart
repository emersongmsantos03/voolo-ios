import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/goal.dart';
import '../models/income_source.dart';
import '../models/monthly_dashboard.dart';
import '../models/user_profile.dart';
import '../models/expense.dart';
import '../models/fixed_series.dart';
import '../models/v2/enums.dart';
import '../core/plans/user_plan.dart';
import 'habits_service.dart';
import 'local_database_service.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class LocalStorageService {
  LocalStorageService._();

  /// Web client ID (OAuth 2.0) from Google Cloud / Firebase project.
  /// Used on Android to request an ID token when needed.
  ///
  /// Provide via: `--dart-define=GOOGLE_WEB_CLIENT_ID=...`
  static const String _googleServerClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  static bool _initialized = false;
  static final ValueNotifier<UserProfile?> userNotifier =
      ValueNotifier<UserProfile?>(null);
  static final ValueNotifier<bool> syncNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<int> dashboardNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> goalNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> incomeNotifier = ValueNotifier<int>(0);
  static final List<UserProfile> _accounts = [];
  static String? _currentUserEmail;
  static String? _currentUserId;
  static bool _loggedOut = false;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static StreamSubscription<UserProfile?>? _userSubscription;
  static StreamSubscription<UserProfile?>? _legacyUserSubscription;
  static bool _hasPrimaryProfile = false;
  static StreamSubscription<List<Goal>>? _goalsSubscription;
  static StreamSubscription<List<IncomeSource>>? _incomesSubscription;
  static StreamSubscription<List<MonthlyDashboard>>? _dashboardsSubscription;
  static String? _lastSyncError;
  static String? _lastLoginError;
  static final List<MonthlyDashboard> _dashboards = [];
  static final List<Goal> _goals = [];
  static final List<IncomeSource> _incomes = [];
  static GoogleSignIn? _googleSignIn;

  static GoogleSignIn _googleSignInClient() {
    return _googleSignIn ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId:
          _googleServerClientId.isEmpty ? null : _googleServerClientId,
    );
  }

  static Future<void> init() async {
    if (_initialized) return;
    final authUser = _auth.currentUser;
    if (authUser != null && (authUser.email ?? '').isNotEmpty) {
      _currentUserEmail = authUser.email;
      _currentUserId = authUser.uid;
      _loggedOut = false;
    } else {
      _currentUserEmail = null;
      _currentUserId = null;
      _loggedOut = true;
    }

    // Load local accounts first to show UI quickly
    await _loadAccounts(remote: false);
    userNotifier.value = getUserProfile();

    if (_loggedOut) {
      _stopUserListener();
      _dashboards.clear();
      _goals.clear();
    } else {
      // Start background tasks without awaiting them to unblock main()
      _startBackgroundInitialization();
    }
    _initialized = true;
  }

  static Future<void> _startBackgroundInitialization() async {
    syncNotifier.value = false;
    _listenToCurrentUser();

    // Trigger remote sync with timeouts to avoid hanging indefinitely
    try {
      await _loadAccounts(remote: true).timeout(const Duration(seconds: 5));
      userNotifier.value =
          getUserProfile(); // Refresh UI if account info changed

      if (_currentUserEmail != null && _currentUserEmail!.isNotEmpty) {
        await _ensureUserProfile().timeout(const Duration(seconds: 5));
      }
      await _loadUserData().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Sync background initialization error: $e');
    } finally {
      syncNotifier.value = true;
    }
  }

  static Future<void> waitForSync({int timeoutSeconds = 5}) async {
    if (syncNotifier.value) return;

    final completer = Completer<void>();
    void listener() {
      if (syncNotifier.value) {
        syncNotifier.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      }
    }

    syncNotifier.addListener(listener);

    try {
      await completer.future.timeout(Duration(seconds: timeoutSeconds));
    } catch (_) {
      syncNotifier.removeListener(listener);
      debugPrint(
          'LocalStorageService: waitForSync timed out after $timeoutSeconds s');
    }
  }

  static String? _localUserKey() {
    if (_currentUserEmail != null && _currentUserEmail!.isNotEmpty) {
      return _currentUserEmail;
    }
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      return 'uid:${_currentUserId!}';
    }
    return null;
  }

  static Future<void> _ensureInit() async {
    if (!_initialized) {
      await init();
    }
  }

  static String _essentialGuideKey() {
    final userKey = _localUserKey() ?? 'anonymous';
    return 'dashboard_essential_guide_seen_$userKey';
  }

  static Future<bool> hasSeenDashboardEssentialGuide() async {
    await _ensureInit();
    final value = await LocalDatabaseService.getSetting(_essentialGuideKey());
    return value == '1';
  }

  static Future<void> markDashboardEssentialGuideSeen() async {
    await _ensureInit();
    await LocalDatabaseService.setSetting(_essentialGuideKey(), '1');
  }

  // ================= AUTH / ACCOUNTS =================

  static List<UserProfile> getAccounts() => List.unmodifiable(_accounts);
  static String? get currentUserId => _currentUserId;
  static String? get lastSyncError => _lastSyncError;
  static String? get lastLoginError => _lastLoginError;
  static UserProfile? getUserProfile() {
    if (_loggedOut) return null;
    if (_currentUserEmail == null || _currentUserEmail!.isEmpty) {
      return null;
    }
    try {
      return _accounts.firstWhere(
        (u) => u.email.toLowerCase() == _currentUserEmail!.toLowerCase(),
      );
    } catch (_) {
      return null; // Don't clear credentials here, we might be waiting for sync
    }
  }

  static Future<UserProfile?> login({
    required String email,
    required String password,
  }) async {
    await _ensureInit();
    _lastLoginError = null;
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    try {
      debugPrint('LocalStorageService: Attempting login for $normalizedEmail');
      await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      debugPrint('LocalStorageService: Login successful for $normalizedEmail');
    } on FirebaseAuthException catch (e) {
      debugPrint('LocalStorageService: Login error: ${e.code} - ${e.message}');
      if (e.code == 'user-disabled') {
        _lastLoginError = 'login_blocked';
      } else if (e.code == 'invalid-email') {
        _lastLoginError = 'login_invalid_email';
      } else if (e.code == 'network-request-failed') {
        _lastLoginError = 'no_connection';
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        _lastLoginError = 'login_invalid_credentials';
      } else {
        _lastLoginError = 'login_failed_try_again';
      }
      return null;
    } catch (e) {
      debugPrint('LocalStorageService: Unexpected login error: $e');
      _lastLoginError = 'login_failed_try_again';
      return null;
    }

    final authUser = _auth.currentUser;
    if (authUser == null) return null;
    _currentUserId = authUser.uid;
    _currentUserEmail = authUser.email ?? normalizedEmail;

    final user = await _ensureUserProfile();
    if (user == null) return null;

    await setCurrentUser(email);
    return user;
  }

  static Future<UserProfile?> loginWithGoogle() async {
    await _ensureInit();
    _lastLoginError = null;
    syncNotifier.value = false;
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        await _auth.signInWithPopup(provider);
      } else {
        final googleSignIn = _googleSignInClient();

        // Avoid silently reusing a stale session and make account selection more predictable.
        try {
          await googleSignIn.signOut();
        } catch (_) {}

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          _lastLoginError = 'login_cancelled';
          return null;
        }

        final googleAuth = await googleUser.authentication;
        if (googleAuth.accessToken == null && googleAuth.idToken == null) {
          debugPrint(
            'LocalStorageService: GoogleSignIn returned null tokens. '
            'Set GOOGLE_WEB_CLIENT_ID (Web client ID) and configure Firebase for the active platform (google-services.json / GoogleService-Info.plist).',
          );
          _lastLoginError = 'login_google_not_ready';
          return null;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'LocalStorageService: Google login FirebaseAuthException: ${e.code} - ${e.message}',
      );
      if (e.code == 'network-request-failed') {
        _lastLoginError = 'no_connection';
      } else if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        _lastLoginError = 'login_cancelled';
      } else {
        _lastLoginError = 'login_failed_try_again';
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint(
        'LocalStorageService: Google login PlatformException: ${e.code} - ${e.message}',
      );
      if (e.code == 'network_error') {
        _lastLoginError = 'no_connection';
      } else if (e.code == 'sign_in_canceled' ||
          e.code == 'sign_in_cancelled') {
        _lastLoginError = 'login_cancelled';
      } else {
        // Common Android case: ApiException: 10 (misconfigured SHA-1 / client ID)
        _lastLoginError = 'login_google_not_ready';
      }
      return null;
    } catch (e) {
      debugPrint('LocalStorageService: Unexpected Google login error: $e');
      _lastLoginError = 'login_failed_try_again';
      return null;
    }

    final authUser = _auth.currentUser;
    if (authUser == null) return null;

    _currentUserId = authUser.uid;
    _currentUserEmail = authUser.email ?? '';
    _loggedOut = false;

    var user = await FirestoreService.getUserByUid(_currentUserId!);
    if (user == null) {
      final displayName = authUser.displayName ?? '';
      final parts =
          displayName.trim().split(' ').where((p) => p.isNotEmpty).toList();
      final firstName = parts.isNotEmpty ? parts.first : 'Usuario';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      user = UserProfile(
        firstName: firstName,
        lastName: lastName,
        email: (_currentUserEmail ?? '').trim().toLowerCase(),
        birthDate: DateTime(2000, 1, 1),
        profession: '',
        monthlyIncome: 0,
        gender: 'Nao informado',
        photoPath: authUser.photoURL,
        objectives: const [],
        setupCompleted: false,
        isPremium: false,
        isActive: true,
        totalXp: 0,
      );
      await FirestoreService.upsertUser(user);
    }

    await setCurrentUser(_currentUserEmail ?? '');
    return getUserProfile();
  }

  static Future<void> setCurrentUser(String email) async {
    await _ensureInit();
    _lastLoginError = null;
    final authUser = _auth.currentUser;
    _currentUserEmail = authUser?.email ?? email.trim();
    _currentUserId = authUser?.uid;
    _loggedOut = false;
    try {
      await _startBackgroundInitialization().timeout(
        const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('LocalStorageService: setCurrentUser sync timeout/error: $e');
      syncNotifier.value = true;
    }
    userNotifier.value = getUserProfile();
  }

  static Future<bool> register(UserProfile profile) async {
    return createAccount(profile);
  }

  static Future<bool> createAccount(UserProfile profile) async {
    await _ensureInit();
    _lastLoginError = null;
    profile.isPremium = false;
    final existsRemote = await FirestoreService.userExists(profile.email);
    if (existsRemote == true) return false;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: profile.email.trim(),
        password: profile.password,
      );
      final createdUser = credential.user;
      if (createdUser != null) {
        _currentUserId = createdUser.uid;
        _currentUserEmail = createdUser.email ?? profile.email.trim();
        _loggedOut = false;
      }
    } on FirebaseAuthException {
      rethrow;
    }

    final ok = await FirestoreService.upsertUser(profile);
    _setSyncError(ok);
    _accounts.add(profile);
    await setCurrentUser(profile.email);
    return true;
  }

  static Future<bool> saveUserProfile(UserProfile profile) async {
    await _ensureInit();
    _lastLoginError = null;
    final idx = _accounts.indexWhere(
        (u) => u.email.toLowerCase() == profile.email.toLowerCase());

    final current = getUserProfile();
    // Preserve setupCompleted: true if already set
    bool finalSetupCompleted = profile.setupCompleted;
    if (!finalSetupCompleted) {
      if (current != null && current.setupCompleted) {
        finalSetupCompleted = true;
      } else if (idx >= 0 && _accounts[idx].setupCompleted) {
        finalSetupCompleted = true;
      }
    }
    final finalUser = profile.copyWith(
      setupCompleted: finalSetupCompleted,
      isPremium: current?.isPremium ?? profile.isPremium,
      isActive: current?.isActive ?? profile.isActive,
    );

    if (idx >= 0) {
      _accounts[idx] = finalUser;
    } else {
      _accounts.add(finalUser);
    }
    await _persistAccounts();
    final ok = await FirestoreService.upsertUser(finalUser);
    _setSyncError(ok);
    // Optimized: instead of setCurrentUser (which reloads EVERYTHING), just update the notifier
    userNotifier.value = finalUser;
    return ok;
  }

  static Future<bool> updateUserProfile({
    required UserProfile previous,
    required UserProfile updated,
  }) async {
    await _ensureInit();
    _lastLoginError = null;
    final prevEmail = previous.email.toLowerCase();
    final newEmail = updated.email.toLowerCase();

    if (newEmail != prevEmail) {
      final conflict = await FirestoreService.userExists(updated.email);
      if (conflict == true) return false;
      final authUser = _auth.currentUser;
      if (authUser != null && authUser.email?.toLowerCase() == prevEmail) {
        try {
          await authUser.updateEmail(updated.email);
        } on FirebaseAuthException {
          return false;
        }
      }
      await FirestoreService.renameUserEmail(previous.email, updated.email);
    }

    final idx = _accounts.indexWhere((u) => u.email.toLowerCase() == prevEmail);

    // Preserve setupCompleted if any known version has it as true
    // This prevents stale local cache from overwriting a completed onboarding on the server
    bool finalSetupCompleted = updated.setupCompleted;
    if (!finalSetupCompleted) {
      final current = getUserProfile();
      if (current != null && current.setupCompleted) {
        finalSetupCompleted = true;
      } else if (idx >= 0 && _accounts[idx].setupCompleted) {
        finalSetupCompleted = true;
      }
    }
    final currentProfile = getUserProfile();
    final finalUser = updated.copyWith(
      setupCompleted: finalSetupCompleted,
      isPremium: currentProfile?.isPremium ?? updated.isPremium,
      isActive: currentProfile?.isActive ?? updated.isActive,
    );

    if (idx >= 0) {
      _accounts[idx] = finalUser;
    } else {
      _accounts.add(finalUser);
    }

    final authUser = _auth.currentUser;
    if (authUser != null && updated.password.isNotEmpty) {
      if (updated.password != previous.password) {
        try {
          await authUser.updatePassword(updated.password);
        } on FirebaseAuthException {
          return false;
        }
      }
    }

    await _persistAccounts();
    final ok = await FirestoreService.upsertUser(finalUser);
    _setSyncError(ok);

    if (newEmail != prevEmail) {
      await setCurrentUser(newEmail);
    } else {
      userNotifier.value = finalUser;
    }
    return true;
  }

  static Future<void> logout() async {
    await _ensureInit();
    _lastLoginError = null;
    _currentUserEmail = null;
    _currentUserId = null;
    _loggedOut = true;
    _stopUserListener();
    _dashboards.clear();
    _goals.clear();
    userNotifier.value = null;
    try {
      await _googleSignInClient().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  static Future<bool> updateMonthlyIncome(double income) async {
    final user = getUserProfile();
    if (user == null || _currentUserId == null) return false;

    // Web parity: treat this as updating the primary fixed income baseline.
    user.monthlyIncome = income;
    userNotifier.value = user.copyWith(); // Notify listeners
    final now = DateTime.now();
    final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final primary = _incomes.where((i) => i.isPrimary).toList();
    final IncomeSource nextPrimary = primary.isNotEmpty
        ? primary.first.copyWith(
            amount: income,
            type: 'fixed',
            isActive: true,
            activeFrom: null,
          )
        : IncomeSource(
            id: 'main_income',
            title: 'Renda Principal',
            amount: income,
            type: 'fixed',
            isPrimary: true,
            createdAt: DateTime.now(),
          );

    final nextIncomes = <IncomeSource>[
      for (final i in _incomes)
        if (i.id == nextPrimary.id) nextPrimary else i,
      if (_incomes.every((i) => i.id != nextPrimary.id)) nextPrimary,
    ];

    await FirestoreService.saveIncome(_currentUserId!, nextPrimary);

    final ok = await FirestoreService.updateUserIncomeSync(
      uid: _currentUserId!,
      monthYear: monthYear,
      incomes: nextIncomes,
    );

    _setSyncError(ok);
    return ok;
  }

  static Future<void> markReportViewed() async {
    final user = getUserProfile();
    if (user == null) return;
    user.lastReportViewedAt = DateTime.now();
    await saveUserProfile(user);
  }

  static Future<void> markCalculatorOpened() async {
    final user = getUserProfile();
    if (user == null) return;
    user.lastCalculatorOpenedAt = DateTime.now();
    await saveUserProfile(user);
  }

  static String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  static bool _isIncomeActiveForMonth(IncomeSource income, String monthKey) {
    if (!income.isActive) return false;
    if (income.excludedMonths.contains(monthKey)) return false;
    if (income.activeFrom != null &&
        monthKey.compareTo(income.activeFrom!) < 0) {
      return false;
    }
    if (income.activeUntil != null &&
        monthKey.compareTo(income.activeUntil!) > 0) {
      return false;
    }
    return true;
  }

  static double incomeTotalForMonth(DateTime month) {
    final key = _monthKey(month);
    return _incomes.fold(
      0.0,
      (sum, item) =>
          sum + (_isIncomeActiveForMonth(item, key) ? item.amount : 0.0),
    );
  }

  static double fixedIncomeBaseline() {
    return _incomes.fold(0.0, (sum, item) {
      final type = item.type.isEmpty ? 'fixed' : item.type;
      if (!item.isActive) return sum;
      if (type != 'fixed') return sum;
      return sum + item.amount;
    });
  }

  static void _updateDashboardsIncome() {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    final now = DateTime.now();
    final nowKey = now.year * 12 + now.month;

    var changed = false;
    for (var i = 0; i < _dashboards.length; i++) {
      final d = _dashboards[i];
      final key = d.year * 12 + d.month;
      if (key < nowKey) continue;
      final incomeForMonth = incomeTotalForMonth(DateTime(d.year, d.month, 1));
      if (d.salary == incomeForMonth) continue;

      _dashboards[i] = MonthlyDashboard(
        month: d.month,
        year: d.year,
        salary: incomeForMonth,
        expenses: List.of(d.expenses),
        creditCardPayments: d.creditCardPayments,
        fixedExclusions: d.fixedExclusions,
      );
      changed = true;
    }

    if (changed) {
      dashboardNotifier.value++;
      _persistDashboards(); // fire-and-forget
    }
  }

  static Future<bool> addXp(int amount) async {
    final user = getUserProfile();
    if (user == null || amount == 0) return false;

    user.totalXp += amount;
    userNotifier.value = user;
    final ok = await saveUserProfile(user);
    return ok;
  }

  // ================= INCOME SOURCES =================

  static List<IncomeSource> getIncomes() => List.unmodifiable(_incomes);

  static Future<bool> saveIncome(IncomeSource income) async {
    await _ensureInit();
    if (_currentUserId == null) return false;
    await FirestoreService.saveIncome(_currentUserId!, income);
    return true;
  }

  static Future<bool> deleteIncome(String incomeId) async {
    await _ensureInit();
    if (_currentUserId == null) return false;

    // Protection: Primary income cannot be deleted
    try {
      final income = _incomes.firstWhere((i) => i.id == incomeId);
      if (income.isPrimary) return false;
    } catch (_) {
      // If not found in local list, backend rules will still protect it
    }

    await FirestoreService.deleteIncome(_currentUserId!, incomeId);
    return true;
  }

  static Future<bool> excludeIncomeForMonth(
      String incomeId, DateTime month) async {
    await _ensureInit();
    if (_currentUserId == null) return false;
    final monthKey = _monthKey(month);
    await FirestoreService.excludeIncomeMonth(
        _currentUserId!, incomeId, monthKey);
    return true;
  }

  static Future<bool> setIncomeActiveUntil(
      String incomeId, String monthKey) async {
    await _ensureInit();
    if (_currentUserId == null) return false;
    try {
      final income = _incomes.firstWhere((i) => i.id == incomeId);
      if (income.isPrimary) return false;
    } catch (_) {
      // If not found locally, let backend rules handle it
    }
    await FirestoreService.setIncomeActiveUntil(
        _currentUserId!, incomeId, monthKey);
    return true;
  }

  // ================= GOALS =================

  static List<Goal> getGoals() => List.unmodifiable(_goals);

  static Future<bool> saveGoals(List<Goal> goals) async {
    await _ensureInit();
    _lastLoginError = null;
    final isNewGoal = goals.length > _goals.length;
    _goals
      ..clear()
      ..addAll(goals);

    if (isNewGoal) {
      await addXp(50);
    }

    return _persistGoals();
  }

  // ================= DASHBOARD =================

  static Future<bool> saveDashboard(MonthlyDashboard dashboard) async {
    _lastLoginError = null;

    // Despesas vivem na subcoleÃ§Ã£o /transactions. NÃ£o salvar embutidas no dashboard.
    final dashboardToSave = MonthlyDashboard(
      month: dashboard.month,
      year: dashboard.year,
      salary: dashboard.salary,
      expenses: const [], // Sempre vazio no documento de sumÃ¡rio
      creditCardPayments: dashboard.creditCardPayments,
      fixedExclusions: dashboard.fixedExclusions,
    );

    _dashboards.removeWhere(
        (d) => d.month == dashboard.month && d.year == dashboard.year);
    _dashboards.add(dashboardToSave);
    dashboardNotifier.value++;
    final windowChanged = _ensureDashboardWindow();
    final plan = UserPlan.fromProfile(getUserProfile());
    final uid = _currentUserId;
    var ok = true;
    if (plan.hasCloudBackup) {
      if (uid != null && uid.isNotEmpty) {
        final saved =
            await FirestoreService.upsertDashboard(uid, dashboardToSave);
        if (!saved) ok = false;
      }
      if (_currentUserEmail != null && _currentUserEmail!.isNotEmpty) {
        await FirestoreService.upsertLegacyDashboard(
            _currentUserEmail!, dashboardToSave);
      }
    }
    final localKey = _localUserKey();
    if (localKey != null) {
      await LocalDatabaseService.replaceDashboards(localKey, _dashboards);
    }

    /* 
    // Reward XP for new expenses (simple heuristic)
    // Disabled to prevent infinite loop with Dashboard load
    if (dashboard.expenses.isNotEmpty) {
      await addXp(10);
    }
    */

    if (windowChanged) {
      final persisted = await _persistDashboards();
      if (!persisted) ok = false;
    }
    _setSyncError(ok);
    return ok;
  }

  static MonthlyDashboard? getDashboard(int month, int year) {
    try {
      return _dashboards.firstWhere((d) => d.month == month && d.year == year);
    } catch (_) {
      return null;
    }
  }

  static final Set<String> _dueDateBackfillDone = <String>{};
  static final Set<String> _seriesIdBackfillDone = <String>{};

  static List<String> _candidateSeriesIdsForFixedExpense(Expense expense) {
    final out = <String>{};
    final raw = (expense.seriesId ?? '').trim();
    if (raw.isNotEmpty) out.add(raw);

    final debtId = (expense.debtId ?? '').trim();
    if (debtId.isNotEmpty) out.add(FirestoreService.debtSeriesIdFor(debtId));

    final computed = FirestoreService.fixedSeriesIdForExpense(expense);
    if (computed != null && computed.trim().isNotEmpty) {
      out.add(computed.trim());
    }

    // Legacy fallback: some historical fixed series used the tx id as the series id.
    if (expense.id.trim().isNotEmpty) out.add(expense.id.trim());

    return out.toList();
  }

  static Stream<List<Expense>> watchTransactions(int month, int year) {
    if (_currentUserId == null || _currentUserId!.isEmpty)
      return Stream.value([]);
    final monthYear = '$year-${month.toString().padLeft(2, '0')}';

    final key = '${_currentUserId!}|$monthYear';
    if (!_dueDateBackfillDone.contains(key)) {
      _dueDateBackfillDone.add(key);
      FirestoreService.backfillDueDatesForMonth(_currentUserId!, monthYear)
          .catchError((_) {});
    }
    if (!_seriesIdBackfillDone.contains(key)) {
      _seriesIdBackfillDone.add(key);
      FirestoreService.backfillSeriesIdsForMonth(_currentUserId!, monthYear)
          .catchError((_) {});
    }

    return FirestoreService.watchTransactions(_currentUserId!, monthYear);
  }

  static Future<bool> saveExpense(Expense expense) async {
    await _ensureInit();
    final uid = _currentUserId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      debugPrint(
          'LocalStorageService: Cannot save expense because uid is missing.');
      return false;
    }
    try {
      final isInstallment = (expense.installments ?? 0) > 1;
      if (expense.isFixed && !isInstallment) {
        final seriesId = _candidateSeriesIdsForFixedExpense(expense).first;
        final normalized = expense.copyWith(seriesId: seriesId);
        await FirestoreService.saveTransaction(uid, normalized);
        await FirestoreService.saveFixedSeries(
          uid,
          FixedSeries(
            seriesId: seriesId,
            name: normalized.name,
            amount: normalized.amount,
            category: normalized.category,
            dueDay: normalized.dueDay,
            isCreditCard: normalized.isCreditCard,
            creditCardId:
                normalized.isCreditCard ? normalized.creditCardId : null,
            isActive: true,
            endMonthYear: null,
          ),
        );
      } else {
        await FirestoreService.saveTransaction(uid, expense);
      }

      // Bidirectional sync: if this transaction represents a debt installment,
      // reflect the paid flag back into the debt doc (best-effort).
      final resolvedDebtId =
          (expense.debtId != null && expense.debtId!.isNotEmpty)
              ? expense.debtId
              : ((expense.seriesId ?? '').startsWith('debt_')
                  ? (expense.seriesId ?? '').substring('debt_'.length)
                  : null);
      if (resolvedDebtId != null && resolvedDebtId.isNotEmpty) {
        final monthYear =
            '${expense.date.year.toString().padLeft(4, '0')}-${expense.date.month.toString().padLeft(2, '0')}';
        FirestoreService.syncDebtPaidFromTransaction(
          uid,
          debtId: resolvedDebtId,
          monthYear: monthYear,
          isPaid: expense.isPaid,
        ).catchError((_) {});
      }

      if (expense.isFixed && !expense.isCreditCard && expense.dueDay != null) {
        NotificationService.scheduleExpenseReminder(expense).catchError((_) {});
      }
      return true;
    } catch (e) {
      debugPrint('LocalStorageService: Error saving expense: $e');
      return false;
    }
  }

  static Future<bool> deleteExpense(String expenseId) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return false;
    try {
      await FirestoreService.deleteTransaction(_currentUserId!, expenseId);
      NotificationService.cancelExpenseReminder(expenseId).catchError((_) {});
      return true;
    } catch (e) {
      debugPrint('LocalStorageService: Error deleting expense: $e');
      return false;
    }
  }

  static Future<bool> deleteFixedExpenseOnlyThisMonth({
    required Expense expense,
    required DateTime month,
  }) async {
    await _ensureInit();
    final uid = _currentUserId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;

    final candidates = _candidateSeriesIdsForFixedExpense(expense);
    if (candidates.isEmpty) return false;
    final primarySeriesId = candidates.first;
    final monthKey = _monthKey(month);

    try {
      // Ensure the tx carries the seriesId to allow future cleanup.
      if ((expense.seriesId == null || expense.seriesId!.isEmpty) &&
          primarySeriesId.isNotEmpty) {
        await FirestoreService.saveTransaction(
            uid, expense.copyWith(seriesId: primarySeriesId));
      }

      for (final sid in candidates) {
        await FirestoreService.deleteFixedOccurrencesForMonth(
                uid, sid, monthKey)
            .catchError((_) {});
        await FirestoreService.addFixedExclusion(uid, monthKey, sid)
            .catchError((_) {});
      }

      // Always remove the selected document as well (older docs may not have
      // a consistent seriesId/date schema, making series queries miss them).
      try {
        await FirestoreService.deleteTransaction(uid, expense.id);
      } catch (_) {
        // ignore
      }

      // Update local dashboard cache to avoid "recreate" races.
      final d = getDashboard(month.month, month.year);
      if (d != null) {
        final nextExclusions = <String>[...d.fixedExclusions];
        var changed = false;
        for (final sid in candidates) {
          if (sid.isEmpty) continue;
          if (nextExclusions.contains(sid)) continue;
          nextExclusions.add(sid);
          changed = true;
        }
        if (!changed) return true;
        final next = d.copyWith(fixedExclusions: nextExclusions);
        _dashboards.removeWhere((x) => x.month == d.month && x.year == d.year);
        _dashboards.add(next);
        dashboardNotifier.value++;
        _persistDashboards();
      }

      return true;
    } catch (e) {
      debugPrint(
          'LocalStorageService: deleteFixedExpenseOnlyThisMonth error: $e');
      return false;
    }
  }

  static Future<bool> deleteFixedExpenseFromThisMonthForward({
    required Expense expense,
    required DateTime fromMonth,
  }) async {
    await _ensureInit();
    final uid = _currentUserId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;

    final candidates = _candidateSeriesIdsForFixedExpense(expense);
    if (candidates.isEmpty) return false;
    final primarySeriesId = candidates.first;

    final monthStart = DateTime(fromMonth.year, fromMonth.month, 1);
    final prevMonth = DateTime(fromMonth.year, fromMonth.month - 1, 1);
    final endMonthYear = _monthKey(prevMonth);

    try {
      // Ensure the tx carries a stable seriesId so future deletes are reliable.
      if ((expense.seriesId == null || expense.seriesId!.isEmpty) &&
          primarySeriesId.isNotEmpty) {
        await FirestoreService.saveTransaction(
            uid, expense.copyWith(seriesId: primarySeriesId));
      }

      for (final sid in candidates) {
        await FirestoreService.endFixedSeries(uid, sid, endMonthYear)
            .catchError((_) {});
        await FirestoreService.deleteFixedSeriesFromDate(uid, sid, monthStart)
            .catchError((_) {});
      }

      // Also delete the selected document (in case its seriesId didn't match
      // any candidate or its date fields are legacy).
      try {
        await FirestoreService.deleteTransaction(uid, expense.id);
      } catch (_) {
        // ignore
      }
      return true;
    } catch (e) {
      debugPrint(
          'LocalStorageService: deleteFixedExpenseFromThisMonthForward error: $e');
      return false;
    }
  }

  static Future<void> ensureFixedExpensesForMonth({
    required int month,
    required int year,
    required List<Expense> monthTransactions,
  }) async {
    await _ensureInit();
    final uid = _currentUserId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final monthYear =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final dash = getDashboard(month, year);
    final excluded = dash?.fixedExclusions ?? const <String>[];

    // Existing fixed txs for this month (ignore credit-card installments).
    final existingSeries = <String>{};
    final duplicatesBySeries = <String, List<String>>{};
    for (final tx in monthTransactions) {
      if (!tx.isFixed) continue;
      if ((tx.installments ?? 0) > 1) continue;

      final computed = (tx.seriesId == null || tx.seriesId!.trim().isEmpty)
          ? FirestoreService.fixedSeriesIdForExpense(tx)
          : null;
      final sid = (tx.seriesId == null || tx.seriesId!.trim().isEmpty)
          ? (computed ?? tx.id)
          : tx.seriesId!.trim();
      if (sid.startsWith('inst_')) continue;
      existingSeries.add(sid);
      (duplicatesBySeries[sid] ??= <String>[]).add(tx.id);

      // Best-effort: persist missing seriesId to make deletes/exclusions reliable.
      if (computed != null &&
          computed.isNotEmpty &&
          (tx.seriesId == null || tx.seriesId!.trim().isEmpty)) {
        FirestoreService.saveTransaction(uid, tx.copyWith(seriesId: computed))
            .catchError((_) {});
      }
    }

    // Cleanup: for a fixed series there should be at most 1 occurrence per month.
    for (final entry in duplicatesBySeries.entries) {
      final sid = entry.key;
      final ids = entry.value;
      if (ids.length <= 1) continue;

      final preferredId = sid.startsWith('debt_') ? '${sid}_$monthYear' : null;
      final keepId = (preferredId != null && ids.contains(preferredId))
          ? preferredId
          : ids.first;

      for (final extraId in ids.where((x) => x != keepId)) {
        try {
          await deleteExpense(extraId);
        } catch (_) {
          // ignore: best-effort cleanup
        }
      }
    }

    List<FixedSeries> seriesList = const [];
    try {
      seriesList = await FirestoreService.getFixedSeries(uid);
    } catch (e) {
      debugPrint(
          'LocalStorageService: ensureFixedExpensesForMonth getFixedSeries error: $e');
      return;
    }

    final seriesMap = <String, FixedSeries>{
      for (final s in seriesList) s.seriesId: s,
    };

    // Backfill missing series docs from current month txs (skip installments).
    for (final tx in monthTransactions) {
      if (!tx.isFixed) continue;
      if ((tx.installments ?? 0) > 1) continue;
      final sid =
          (tx.seriesId == null || tx.seriesId!.isEmpty) ? tx.id : tx.seriesId!;
      if (sid.startsWith('inst_')) continue;
      if (seriesMap.containsKey(sid)) continue;
      try {
        await FirestoreService.saveFixedSeries(
          uid,
          FixedSeries(
            seriesId: sid,
            name: tx.name,
            amount: tx.amount,
            category: tx.category,
            dueDay: tx.dueDay,
            isCreditCard: tx.isCreditCard,
            creditCardId: tx.isCreditCard ? tx.creditCardId : null,
            isActive: true,
          ),
        );
      } catch (_) {
        // ignore: best-effort backfill
      }
    }

    for (final series in seriesList) {
      final sid = series.seriesId;
      if (sid.isEmpty) continue;
      if (sid.startsWith('inst_')) continue;
      if (excluded.contains(sid)) continue;
      if (!series.isActive) continue;
      if (series.endMonthYear != null &&
          monthYear.compareTo(series.endMonthYear!) > 0) {
        continue;
      }
      if (existingSeries.contains(sid)) continue;
      if (series.name.trim().isEmpty ||
          !series.amount.isFinite ||
          series.amount <= 0) continue;

      final daysInMonth = DateTime(year, month + 1, 0).day;
      final day = (series.dueDay ?? 1).clamp(1, daysInMonth);
      final date = DateTime(year, month, day);

      final isDebtSeries = sid.startsWith('debt_');
      final txId = isDebtSeries
          ? '${sid}_$monthYear'
          : DateTime.now().microsecondsSinceEpoch.toString();
      final debtId = isDebtSeries ? sid.substring('debt_'.length) : null;

      final tx = Expense(
        id: txId,
        seriesId: sid,
        debtId: debtId,
        name: series.name,
        amount: series.amount,
        type: ExpenseType.fixed,
        category: series.category,
        date: date,
        txType: isDebtSeries ? TxType.debtPayment : null,
        dueDay: series.dueDay,
        isPaid: false,
        isCreditCard: series.isCreditCard,
        creditCardId: series.isCreditCard ? series.creditCardId : null,
        isCardRecurring: series.isCreditCard,
      );

      await saveExpense(tx);
    }
  }

  static List<MonthlyDashboard> getAllDashboards() =>
      List.unmodifiable(_dashboards);

  static bool _ensureDashboardWindow() {
    if (_currentUserId == null || _currentUserId!.isEmpty) return false;
    final user = getUserProfile();
    if (user == null) return false;

    final now = DateTime.now();
    final startKey = now.year * 12 + now.month;
    final endKey = startKey + 11;

    final Map<int, MonthlyDashboard> existing = {};
    for (final d in _dashboards) {
      final key = d.year * 12 + d.month;
      existing[key] = d;
    }

    var changed = false;
    final List<MonthlyDashboard> next = [];

    for (final entry in existing.entries) {
      final d = entry.value;
      final key = entry.key;
      final hasExpenses = d.expenses.isNotEmpty;
      final withinWindow = key >= startKey && key <= endKey;
      if (hasExpenses || withinWindow) {
        next.add(d);
      } else {
        changed = true;
      }
    }

    for (var i = 0; i <= 11; i++) {
      final key = startKey + i;
      if (!existing.containsKey(key)) {
        final year = (key - 1) ~/ 12;
        final month = ((key - 1) % 12) + 1;
        next.add(
          MonthlyDashboard(
            month: month,
            year: year,
            salary: incomeTotalForMonth(DateTime(year, month, 1)),
            expenses: const [],
            creditCardPayments: const {},
          ),
        );
        changed = true;
      }
    }

    if (changed) {
      _dashboards
        ..clear()
        ..addAll(next);
    }
    return changed;
  }

  // ================= INTERNAL =================

  static Future<void> _loadAccounts({bool remote = true}) async {
    if (!remote) {
      _accounts.clear();
      final localUsers = await LocalDatabaseService.getUsers();
      if (localUsers.isNotEmpty) {
        _accounts.addAll(localUsers);
      }
      return;
    }

    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    // 2. Tenta carregar do Firestore (fonte da verdade)
    try {
      final user = await FirestoreService.getUserByUid(_currentUserId!)
          .timeout(const Duration(seconds: 5));
      if (user != null) {
        if (!user.isActive) {
          await _handleInactiveUser(user);
          return;
        }

        final idx = _accounts.indexWhere(
            (u) => u.email.toLowerCase() == user.email.toLowerCase());
        if (idx >= 0) {
          _accounts[idx] = user;
        } else {
          _accounts.add(user);
        }

        await LocalDatabaseService.upsertUser(user);
      }
    } catch (e) {
      debugPrint('Error loading remote accounts: $e');
    }
  }

  static Future<UserProfile?> _ensureUserProfile() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return null;
    final normalizedEmail = (_currentUserEmail ?? '').trim().toLowerCase();

    final local =
        _accounts.where((u) => u.email.toLowerCase() == normalizedEmail);
    if (local.isNotEmpty) return local.first;

    final user = await FirestoreService.getUserByUid(_currentUserId!);
    final legacyUser =
        await FirestoreService.getUserByLegacyEmailDoc(normalizedEmail);
    if (user != null) {
      if (!user.isActive) {
        await _handleInactiveUser(user);
        return null;
      }
      _listenToCurrentUser();
      if (legacyUser != null && _isProfileMoreComplete(legacyUser, user)) {
        await FirestoreService.upsertUser(legacyUser);
        _accounts.add(legacyUser);
        return legacyUser;
      }
      _accounts.add(user);
      return user;
    }

    if (legacyUser != null) {
      if (!legacyUser.isActive) {
        await _handleInactiveUser(legacyUser);
        return null;
      }
      _listenToCurrentUser();
      await FirestoreService.upsertUser(legacyUser);
      final legacyDashboards =
          await FirestoreService.getLegacyDashboards(normalizedEmail);
      if (legacyDashboards.isNotEmpty) {
        await FirestoreService.replaceDashboards(
            _currentUserId!, legacyDashboards);
      }
      final legacyGoals =
          await FirestoreService.getLegacyGoals(normalizedEmail);
      if (legacyGoals.isNotEmpty) {
        await FirestoreService.replaceGoals(_currentUserId!, legacyGoals);
      }
      _accounts.add(legacyUser);
      return legacyUser;
    }

    final fallback = UserProfile(
      firstName: 'Usuario',
      lastName: '',
      email: normalizedEmail,
      birthDate: DateTime(2000, 1, 1),
      profession: '',
      monthlyIncome: 0,
      gender: 'Nao informado',
      photoPath: null,
      objectives: const [],
      setupCompleted: false,
      isPremium: false,
      isActive: true,
      totalXp: 0,
    );
    _accounts.add(fallback);

    final existsRemote = await FirestoreService.userExists(normalizedEmail);
    if (existsRemote == false) {
      await FirestoreService.upsertUser(fallback);
    }
    return fallback;
  }

  static Future<void> _handleInactiveUser(UserProfile user) async {
    _lastLoginError = 'login_blocked';
    _currentUserEmail = null;
    _currentUserId = null;
    _loggedOut = true;
    _stopUserListener();
    _dashboards.clear();
    _goals.clear();
    userNotifier.value = null;
    try {
      await _auth.signOut();
    } on FirebaseAuthException {
      // ignore
    }
  }

  static void _listenToCurrentUser() {
    _stopUserListener();
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    // Keep daily habits synced across devices (Dashboard <-> Insights and Web <-> Flutter).
    HabitsService.startSync(uid: _currentUserId!);
    _userSubscription = FirestoreService.watchUserByUid(_currentUserId!).listen(
      (profile) async {
        if (profile == null) return;
        _hasPrimaryProfile = true;
        if (!profile.isActive) {
          await _handleInactiveUser(profile);
          return;
        }
        final idx = _accounts.indexWhere(
          (u) => u.email.toLowerCase() == profile.email.toLowerCase(),
        );
        if (idx >= 0) {
          _accounts[idx] = profile;
        } else {
          _accounts.add(profile);
        }
        await LocalDatabaseService.upsertUser(profile);
        userNotifier.value = profile;
      },
    );

    _goalsSubscription = FirestoreService.watchGoals(_currentUserId!).listen(
      (goals) async {
        if (goals.isEmpty && _goals.isEmpty) return;
        _goals.clear();
        _goals.addAll(goals);
        goalNotifier.value++;
      },
    );

    _incomesSubscription =
        FirestoreService.watchIncomes(_currentUserId!).listen(
      (incomes) async {
        _incomes.clear();
        _incomes.addAll(incomes);
        incomeNotifier.value++;

        // --- Migration & Protection Logic ---
        final hasPrimary = incomes.any((i) => i.isPrimary);
        final user = userNotifier.value;

        if (!hasPrimary) {
          if (incomes.isEmpty && user != null && user.monthlyIncome > 0) {
            debugPrint(
                'LocalStorageService: Migrating legacy monthlyIncome to incomes collection (Primary)');
            await saveIncome(IncomeSource(
              id: 'main_income',
              title: 'Renda Principal',
              amount: user.monthlyIncome,
              type: 'fixed',
              isPrimary: true,
              createdAt: DateTime.now(),
            ));
            return;
          } else if (incomes.isNotEmpty) {
            debugPrint('LocalStorageService: Fixing missing primary income');
            await saveIncome(incomes.first.copyWith(isPrimary: true));
            return;
          } else if (incomes.isEmpty &&
              (user == null || user.monthlyIncome == 0)) {
            debugPrint('LocalStorageService: Creating default primary income');
            await saveIncome(IncomeSource(
              id: 'main_income',
              title: 'Renda Principal',
              amount: 0.0,
              type: 'fixed',
              isPrimary: true,
              createdAt: DateTime.now(),
            ));
            return;
          }
        }
        // --------------------------------------

        final now = DateTime.now();
        final monthYear = _monthKey(now);
        final baseline = fixedIncomeBaseline();
        final monthTotal = incomeTotalForMonth(now);

        final currentProfile = userNotifier.value;
        final currentDash = getDashboard(now.month, now.year);
        final needsSync = _currentUserId != null &&
            (currentProfile == null ||
                currentProfile.monthlyIncome != baseline ||
                currentDash == null ||
                currentDash.salary != monthTotal);

        // Sync baseline back to profile for other parts of the app (web uses monthlyIncome as fixed baseline)
        if (currentProfile != null &&
            currentProfile.monthlyIncome != baseline) {
          userNotifier.value = currentProfile.copyWith(monthlyIncome: baseline);
        }

        _updateDashboardsIncome();

        if (needsSync) {
          final ok = await FirestoreService.updateUserIncomeSync(
            uid: _currentUserId!,
            monthYear: monthYear,
            incomes: List.of(_incomes),
          );
          _setSyncError(ok);
        }
      },
    );

    _dashboardsSubscription =
        FirestoreService.watchDashboards(_currentUserId!).listen(
      (dashboards) async {
        debugPrint(
            'LocalStorageService: Received ${dashboards.length} dashboards from Firestore for UID: $_currentUserId');
        if (dashboards.isEmpty && _dashboards.isEmpty) return;

        // Merge strategy: Update existing, add new ones from remote
        final Map<int, MonthlyDashboard> merged = {};
        for (final d in _dashboards) {
          merged[d.year * 12 + d.month] = d;
        }
        for (final d in dashboards) {
          merged[d.year * 12 + d.month] =
              d; // Remote overwrites local for same month
        }

        final newList = merged.values.toList();
        newList.sort((a, b) {
          final aKey = a.year * 12 + a.month;
          final bKey = b.year * 12 + b.month;
          return aKey.compareTo(bKey);
        });

        _dashboards.clear();
        _dashboards.addAll(newList);

        // Re-ensure window to avoid losing placeholders if remote only has few months
        _ensureDashboardWindow();

        dashboardNotifier.value++;

        final localKey = _localUserKey();
        if (localKey != null) {
          LocalDatabaseService.replaceDashboards(localKey, _dashboards);
        }
      },
      onError: (e) =>
          debugPrint('LocalStorageService: Dashboards sync error: $e'),
    );

    final email = (_currentUserEmail ?? '').trim();
    if (email.isEmpty) return;
    _legacyUserSubscription =
        FirestoreService.watchUserByLegacyEmailDoc(email).listen(
      (legacyProfile) async {
        if (legacyProfile == null) return;
        final current = getUserProfile();
        // If we already have a primary UID profile, only sync premium/active flags.
        if (_hasPrimaryProfile && current == null) return;
        if (!legacyProfile.isActive) {
          await _handleInactiveUser(legacyProfile);
          return;
        }
        if (!_hasPrimaryProfile && current == null) {
          _accounts.add(legacyProfile);
          userNotifier.value = legacyProfile;
          return;
        }
        if (current == null) return;
        final shouldUpdate = current.isPremium != legacyProfile.isPremium ||
            current.isActive != legacyProfile.isActive;
        if (!shouldUpdate) return;
        current.isPremium = legacyProfile.isPremium;
        current.isActive = legacyProfile.isActive;
        final idx = _accounts.indexWhere(
          (u) => u.email.toLowerCase() == current.email.toLowerCase(),
        );
        if (idx >= 0) {
          _accounts[idx] = current;
        } else {
          _accounts.add(current);
        }
        userNotifier.value = current;
        await FirestoreService.upsertUser(current);
      },
    );
  }

  static void _stopUserListener() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _hasPrimaryProfile = false;
    _goalsSubscription?.cancel();
    _goalsSubscription = null;
    _incomesSubscription?.cancel();
    _incomesSubscription = null;
    _dashboardsSubscription?.cancel();
    _dashboardsSubscription = null;
    _legacyUserSubscription?.cancel();
    _legacyUserSubscription = null;
    HabitsService.stopSync();
  }

  static bool _isProfileMoreComplete(
      UserProfile candidate, UserProfile current) {
    // XP is now the primary priority for sync alignment
    if (candidate.totalXp > current.totalXp) return true;

    if (current.monthlyIncome == 0 && candidate.monthlyIncome > 0) return true;
    if (current.objectives.isEmpty && candidate.objectives.isNotEmpty)
      return true;
    if (!current.setupCompleted && candidate.setupCompleted) return true;
    if (current.profession.isEmpty && candidate.profession.isNotEmpty)
      return true;
    if (current.firstName.isEmpty && candidate.firstName.isNotEmpty)
      return true;
    if (current.lastName.isEmpty && candidate.lastName.isNotEmpty) return true;
    if ((current.photoPath ?? '').isEmpty &&
        (candidate.photoPath ?? '').isNotEmpty) {
      return true;
    }
    return false;
  }

  static Future<void> _persistAccounts() async {
    var ok = true;
    for (final user in _accounts) {
      // Salva no banco local
      await LocalDatabaseService.upsertUser(user);

      // Tenta salvar no Firestore
      final saved = await FirestoreService.upsertUser(user);
      if (!saved) ok = false;
    }
    _setSyncError(ok);
  }

  static Future<void> _loadUserData() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    debugPrint(
        'LocalStorageService: Starting _loadUserData for UID: $_currentUserId');

    // 1. Fetch from Local Database
    List<MonthlyDashboard> localDashboards = [];
    final localKey = _localUserKey();
    if (localKey != null) {
      localDashboards = await LocalDatabaseService.getDashboards(localKey);
    }

    // 2. Fetch from Remote Firestore (One-time fetch to supplement stream)
    final remoteDashboards =
        await FirestoreService.getDashboards(_currentUserId!);

    // 3. Merge everything into the static list carefully
    final Map<int, MonthlyDashboard> merged = {};

    // Priority 1: Current static list (might have data from stream already)
    for (final d in _dashboards) {
      merged[d.year * 12 + d.month] = d;
    }

    // Priority 2: Local data (only if month not already present or is more complete?)
    // For simplicity, we trust remote more.
    for (final d in localDashboards) {
      merged[d.year * 12 + d.month] = d;
    }

    // Priority 3: Remote data (Highest priority for initial load)
    for (final d in remoteDashboards) {
      merged[d.year * 12 + d.month] = d;
    }

    // Update the static list
    _dashboards.clear();
    _dashboards.addAll(merged.values);

    // 4. Handle legacy sync if needed
    if (_dashboards.isEmpty &&
        _currentUserEmail != null &&
        _currentUserEmail!.isNotEmpty) {
      final legacy =
          await FirestoreService.getLegacyDashboards(_currentUserEmail!);
      if (legacy.isNotEmpty) {
        _dashboards.addAll(legacy);
        await FirestoreService.replaceDashboards(_currentUserId!, legacy);
      }
    }

    // 5. Cleanup & Notify
    if (_goals.isEmpty) {
      final goals = await FirestoreService.getGoals(_currentUserId!);
      _goals.addAll(goals);
    }

    _ensureDashboardWindow();

    // Persist the merged state locally
    if (localKey != null) {
      await LocalDatabaseService.replaceDashboards(localKey, _dashboards);
    }

    dashboardNotifier.value++;
    debugPrint(
        'LocalStorageService: _loadUserData completed. Total dashboards: ${_dashboards.length}');

    // 6. Migration: Move monthlyIncome to incomes collection if empty
    final user = getUserProfile();
    if (user != null && user.monthlyIncome > 0 && _incomes.isEmpty) {
      debugPrint(
          'LocalStorageService: Migrating legacy monthlyIncome to incomes collection');
      await saveIncome(IncomeSource(
        id: 'main_income',
        title: 'Renda Principal',
        amount: user.monthlyIncome,
        type: 'fixed',
        createdAt: DateTime.now(),
      ));
    }
  }

  static Future<bool> _persistDashboards() async {
    final localKey = _localUserKey();
    if (localKey != null) {
      await LocalDatabaseService.replaceDashboards(localKey, _dashboards);
    }

    final plan = UserPlan.fromProfile(getUserProfile());
    if (!plan.hasCloudBackup) return true;

    if (_currentUserId == null || _currentUserId!.isEmpty) return false;
    final ok =
        await FirestoreService.replaceDashboards(_currentUserId!, _dashboards);
    _setSyncError(ok);
    return ok;
  }

  static Future<bool> _persistGoals() async {
    final plan = UserPlan.fromProfile(getUserProfile());
    if (!plan.hasCloudBackup) return true;

    if (_currentUserId == null || _currentUserId!.isEmpty) return false;
    final ok = await FirestoreService.replaceGoals(_currentUserId!, _goals);
    _setSyncError(ok);
    return ok;
  }

  static void _setSyncError(bool ok) {
    if (ok) {
      _lastSyncError = null;
    } else {
      _lastSyncError =
          'Tivemos um problema ao sincronizar agora, mas nÃ£o se preocupe: seus dados continuam salvos no seu celular.';
    }
  }
}
