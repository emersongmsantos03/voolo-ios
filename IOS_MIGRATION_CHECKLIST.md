# iOS release checklist (Voolo)

Este projeto foi adaptado para iOS no Flutter, mas antes de subir na App Store voce precisa validar estes pontos no macOS (Xcode):

1. Firebase (obrigatorio)
- Adicione o app iOS no Firebase com o mesmo Bundle ID do Xcode (`com.voolo.jetx`).
- Baixe `GoogleService-Info.plist` e coloque em `ios/Runner/GoogleService-Info.plist`.
- No Xcode, confirme que o arquivo foi incluído no target `Runner`.

2. Google Sign-In (se usar login Google no iOS)
- Em `GoogleService-Info.plist`, copie `REVERSED_CLIENT_ID`.
- Adicione em `ios/Runner/Info.plist` como `CFBundleURLTypes` -> `CFBundleURLSchemes`.
- No Firebase Authentication, habilite Google provider.

3. In-App Purchase (App Store)
- Crie os produtos no App Store Connect com os IDs usados no app:
  - `voolo`
  - `voolo_y`
- No Codemagic, passe os mesmos IDs no build iOS com:
  - `--dart-define=VOOLO_IOS_MONTHLY_SUBSCRIPTION_ID=voolo`
  - `--dart-define=VOOLO_IOS_YEARLY_SUBSCRIPTION_ID=voolo_y`
- Garanta que o backend tenha o endpoint iOS:
  - `POST /billing/appstore/sync-subscription`
- O app agora envia `receiptData`, `subscriptionId` e `transactionId`.

4. Backend iOS (Firebase Functions)
- Entre na pasta `functions` e rode `npm install`.
- Configure os segredos do App Store Connect no Firebase Functions:
  - `apple.key_id`
  - `apple.issuer_id`
  - `apple.bundle_id`
  - `apple.private_key_b64`
  - `apple.environment` (`SANDBOX` para testes/review, `PRODUCTION` quando for publicar)
- O arquivo `.p8` da chave vai no backend, nao no app iOS. Use os nomes equivalentes:
  - `APPLE_KEY_ID=BDWV8JZ952`
  - `APPLE_ISSUER_ID=83971460-f0c1-42bb-8c02-8fbd6c17c5ba`
  - `APPLE_BUNDLE_ID=com.voolo.jetx`
  - `APPLE_PRIVATE_KEY_B64=<base64-do-arquivo-p8>`
  - `APPLE_ENVIRONMENT=SANDBOX`
- Exemplo de configuracao via Firebase CLI:
  - `firebase functions:config:set apple.key_id="..." apple.issuer_id="..." apple.bundle_id="com.voolo.jetx" apple.private_key_b64="..." apple.environment="SANDBOX"`
- Depois publique apenas o backend:
  - `firebase deploy --only functions:billingApiUs`

5. Conta e privacidade (App Review)
- O app deve permitir exclusao de conta dentro do proprio fluxo autenticado.
- Revise `ios/Runner/PrivacyInfo.xcprivacy` antes de cada envio.
- Em `App Store Connect`, preencha os privacy labels de acordo com o que o Firebase/Auth/Firestore realmente coletam.

6. Notificacoes locais
- O app ja pede permissao no iOS.
- Valide no dispositivo real (simulador nao entrega todos os cenarios de notificacao).

6. Build iOS
- No macOS, execute na raiz do projeto:
  - `flutter clean`
  - `flutter pub get`
  - `cd ios && pod install && cd ..`
  - `flutter build ios --release`

7. Validacao final de QA
- Login email/senha
- Login Google no iOS
- Troca de foto de perfil (camera e galeria)
- Face ID/Touch ID (bloqueio)
- Restaurar compras e compra de assinatura
- Notificacoes locais agendadas
- Exclusao de conta dentro do app
