# App Store Review Fix (2.1.0, 2.3.3, 2.3.8)

## 1) 2.1.0 App Completeness
- Confirmar que `ios/Runner/GoogleService-Info.plist` existe no target `Runner` antes de gerar o `.ipa`.
- Garantir backend ativo no ambiente de review.
- Em `App Review Information`, preencher:
  - `Sign-in required`: Yes
  - Conta de teste valida (email/senha) com dados reais de navegacao no app.
  - Passos exatos para testar compra/restauracao.

## 2) 2.3.3 Accurate Metadata (screenshots)
- Subir screenshots que mostrem telas internas reais do app (Dashboard, Lancamentos, Metas, Insights, Premium).
- Nao usar apenas splash, logo, login ou mockups externos.
- Se houver recursos premium nas capturas, garantir que eles existam no build enviado.

## 3) 2.3.8 Accurate Metadata (4+ e consistencia)
- Garantir que icones e nome do app sejam consistentes entre metadata e binario (`Voolo`).
- Evitar imagens de metadata com conteudo sensivel/violento/enganoso.
- Revisar texto da descricao para nao prometer funcionalidade que nao existe no build atual.

## 4) Texto sugerido para responder ao App Review
Hello App Review Team,

We fixed the issues related to App Completeness and Metadata Accuracy:

1. App Completeness (2.1): we validated the production iOS build with all required runtime services enabled (including Firebase configuration and backend availability). We also provided a valid review account and clear test steps in App Review Information.
2. Metadata Accuracy (2.3.3): screenshots were replaced with real in-app flows showing actual app usage.
3. Metadata Accuracy (2.3.8): metadata and app visuals were aligned and reviewed to ensure they are appropriate for all audiences and consistent with the app name/icons/features.

Additionally, the subscription screen now uses store-fetched pricing (no hardcoded pricing fallback) and includes direct links to Terms of Use and Privacy Policy.

Thank you.
