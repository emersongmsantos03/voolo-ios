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
  - `voolo_monthly`
  - `voolo_yearly`
- Garanta que o backend tenha o endpoint iOS:
  - `POST /billing/appstore/sync-subscription`
- O app agora envia `receiptData`, `subscriptionId` e `transactionId`.

4. Conta e privacidade (App Review)
- O app deve permitir exclusao de conta dentro do proprio fluxo autenticado.
- Revise `ios/Runner/PrivacyInfo.xcprivacy` antes de cada envio.
- Em `App Store Connect`, preencha os privacy labels de acordo com o que o Firebase/Auth/Firestore realmente coletam.

5. Notificacoes locais
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
