# App Store Review Fix (2.1.0, 2.3.3, 2.3.8)

## 1) 2.1.0 App Completeness
- Confirmar que `Util/GoogleService-Info.plist` existe e está incluído no target `Runner` antes de gerar o `.ipa`.
- Garantir backend ativo no ambiente de review.
- Em `App Review Information`, preencher:
  - `Sign-in required`: Yes
  - Conta de teste valida (email/senha) com dados reais de navegacao no app.
  - Passos exatos para testar compra/restauracao.

## 2) 2.3.3 Accurate Metadata (screenshots)
- Subir screenshots que mostrem telas internas reais do app, como Dashboard, adicionar lancamento, Perfil, Calculadora e Premium.
- Nao usar apenas splash, logo, login ou mockups externos.
- Garantir que a maioria das imagens mostre o app em uso, com graficos, cards, formularios e navegação real.
- Gerar e enviar os conjuntos de 6.7-inch iPhone e 13-inch iPad.
- Se houver recursos premium nas capturas, garantir que eles existam no build enviado.

## 3) 2.3.8 Accurate Metadata (4+ e consistencia)
- Garantir que icones e nome do app sejam consistentes entre metadata e binario (`Voolo`).
- Evitar imagens de metadata com conteudo sensivel/violento/enganoso.
- Revisar texto da descricao para nao prometer funcionalidade que nao existe no build atual.

## 4) Conta e privacidade
- Como o app permite criar conta, manter a opcao de exclusao dentro do proprio app autenticado.
- Validar `ios/Runner/PrivacyInfo.xcprivacy` e os privacy labels no App Store Connect antes do envio.
- Confirmar que os links de `Termos de Uso` e `Politica de Privacidade` abrem em HTTPS.

## 5) Texto sugerido para responder ao App Review
Hello App Review Team,

We fixed the issues related to App Completeness and Metadata Accuracy:

1. App Completeness (2.1): we validated the production iOS build with all required runtime services enabled (including Firebase configuration and backend availability). We also provided a valid review account and clear test steps in App Review Information.
2. Metadata Accuracy (2.3.3): screenshots were replaced with real in-app flows showing actual app usage.
3. Metadata Accuracy (2.3.8): metadata and app visuals were aligned and reviewed to ensure they are appropriate for all audiences and consistent with the app name/icons/features.
4. Account & Privacy: the app includes in-app account deletion for authenticated users, privacy links in the subscription flow, and an updated iOS privacy manifest.

Additionally, the subscription screen now shows the subscription name, duration, store-fetched price where available, and direct links to Terms of Use and Privacy Policy.

Thank you.

## 6) App Store Connect metadata to fill manually
- `Privacy Policy` URL: `https://voolo.app/privacy`
- `Terms of Use (EULA)`: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
- Make sure both links are also visible inside the iOS subscription paywall.

## 7) App Description snippet
If you want to mention the subscription terms directly in the App Description, use:

`Voolo Premium is an auto-renewable subscription. Subscription options: Voolo Monthly (1 month) and Voolo Yearly (1 year). Payment is charged to your Apple ID, and the subscription renews automatically unless canceled at least 24 hours before the end of the current period. Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ Privacy Policy: https://voolo.app/privacy`
