# Voolo - Documentacao do App

## 1. Visao geral
O Voolo e um app Flutter para controle financeiro pessoal com foco em:
- acompanhamento de despesas e receitas
- planejamento (metas, orcamentos, dividas)
- analises e relatorios
- trilha gamificada (missoes e progresso)
- recursos Premium com assinatura no Google Play (Android)

Nome tecnico atual do pacote Flutter: `jetx` (`pubspec.yaml`).

## 2. Stack e tecnologias
- Frontend: Flutter (Material 3)
- Estado: `provider`
- Persistencia local: `shared_preferences` + servicos locais
- Backend: Firebase
- Auth: `firebase_auth` (email/senha e Google)
- Banco: `cloud_firestore`
- Arquivos: `firebase_storage`
- Notificacoes locais: `flutter_local_notifications`
- Compra in-app: `in_app_purchase`
- API HTTP para billing: `http`

## 3. Arquitetura (alto nivel)
O app segue uma organizacao por camadas dentro de `lib/`:
- `pages/`: telas e fluxo de UI
- `services/`: acesso a dados locais/remotos e regras de negocio
- `state/`: `ChangeNotifier` para estado compartilhado
- `routes/`: definicao central de rotas
- `core/`: tema, localizacao, utilitarios base
- `widgets/`: componentes reutilizaveis
- `repositories/`: camada de repositorio (ex.: transacoes v2)

Ponto de entrada:
- `lib/main.dart`

Fluxo inicial em `main.dart`:
1. inicializa Firebase
2. inicializa utilitarios de data e base local
3. carrega storage local e sincronizacao curta
4. decide rota inicial (`/login`, `/onboarding` ou `/dashboard`)
5. sobe `MaterialApp` com tema, localizacao e rotas centralizadas

## 4. Modulos funcionais
Telas principais em `lib/pages/`:
- Auth: login, registro, reset de senha
- Dashboard: visao geral financeira
- Expenses: cadastro de despesas
- Transactions: listagem e filtros de transacoes
- Budgets: orcamentos por categoria
- Debts: controle e estrategia de dividas
- Goals: metas financeiras
- Investments: calculadora e plano de investimento
- Reporting: relatorio mensal
- Insights: alertas e recomendacoes
- Missions: progresso gamificado
- Profile: configuracoes e conta
- Premium: assinatura e restauracao de compra

## 5. Rotas do app
Definidas em `lib/routes/app_routes.dart`.

Rotas nomeadas:
- `/login`
- `/register`
- `/forgot-password`
- `/reset-password`
- `/onboarding`
- `/dashboard`
- `/add-expense`
- `/investment-calculator`
- `/calculator`
- `/metas`
- `/monthly-report`
- `/missions`
- `/transactions`
- `/insights`
- `/profile`
- `/budgets`
- `/investment-plan`
- `/debts`
- `/premium`

Rota dinamica suportada:
- `'/reset-password/{token}'` (abre confirmacao com token)

## 6. Localizacao e tema
- Localizacao central em `lib/core/localization/app_strings.dart`
- Idiomas com strings mapeadas no app (pt/en/es)
- Tema em `lib/core/theme/app_theme.dart`
- Estado de tema e idioma via `ThemeState` e `LocaleState`

## 7. Persistencia e dados
Servicos principais em `lib/services/`:
- `local_storage_service.dart`: perfil do usuario, preferencias e sincronizacao
- `local_database_service.dart`: inicializacao e acesso local
- `firestore_service.dart`: operacoes remotas com Firestore
- `financial_insight_service.dart`: logica de insights
- `habits_service.dart`: rotinas/metas de habitos
- `notification_service.dart`: agendamentos e notificacoes
- `storage_service.dart`: upload/download de arquivos
- `billing_service.dart`: sincronizacao de assinatura Premium com backend

Repositorio:
- `lib/repositories/transactions_repository_v2.dart`

## 8. Regras de seguranca (Firestore)
Arquivo:
- `firestore.rules`

Resumo:
- leitura/escrita de documentos de usuario restrita ao proprio dono ou admin
- campos sensiveis de premium/admin protegidos contra auto-elevacao pelo cliente
- validacoes de schema para colecoes v2 (transactions, incomes, debts, budgets, insights)
- colecoes server-only para reset de senha e logs sensiveis

## 9. Premium e billing
Tela:
- `lib/pages/premium/premium_page.dart`

Fluxo atual:
1. app consulta disponibilidade da loja (`InAppPurchase.instance`)
2. consulta dois produtos (`voolo-mensal` e `voolo-anual`)
3. inicia compra e escuta `purchaseStream`
4. ao comprar/restaurar, envia token para backend em:
   - `POST /billing/googleplay/sync-subscription`
5. backend valida assinatura e atualiza status premium

Observacao:
- fluxo implementado para Android (Google Play)

## 10. Backend Firebase (Functions + Firestore)
Arquivos:
- `firebase.json`
- `functions/package.json`
- `firestore.rules`
- `firestore.indexes.json`

Functions:
- source: `functions/`
- runtime Node: `20`
- libs principais: `firebase-admin`, `firebase-functions`, `nodemailer`

## 11. Como rodar localmente
Pre-requisitos:
- Flutter SDK compativel com `sdk >=3.1.0 <4.0.0`
- Android Studio/SDK
- Firebase configurado no projeto

Passos:
1. `flutter pub get`
2. configurar Firebase do app Android (`android/app/google-services.json`)
3. `flutter run`

## 12. Testes e qualidade
Comandos:
- `flutter test`
- `flutter analyze`

Testes existentes em `test/` cobrem:
- rotas
- utilitarios de filtro/formatacao
- cenarios de dividas v2

## 13. Build e release Android
Arquivo de build:
- `android/app/build.gradle.kts`

Dados importantes:
- `applicationId`: `com.voolo.app`
- assina release via `key.properties`

Recomendacao operacional:
- manter `keystore` e `key.properties` fora de versionamento
- usar variaveis/segredos por ambiente para endpoint de billing

## 14. Estrutura de pastas (resumo)
Raiz relevante:
- `lib/` codigo principal Flutter
- `assets/` imagens e seed local
- `android/` projeto nativo Android
- `functions/` Cloud Functions Firebase
- `test/` testes automatizados
- `web/` artefatos/config web

## 15. Proximos passos sugeridos para a documentacao
Para evoluir este documento, recomendo manter:
1. changelog de versao e releases
2. diagrama de fluxo de dados (local -> Firestore -> UI)
3. matriz de permissao por tipo de usuario (user/admin)
4. playbook de incidentes (auth, sync, billing)
