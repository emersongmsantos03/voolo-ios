import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_strings_extra.dart';

class AppStrings {
  AppStrings._();

  static const supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en'),
    Locale('es'),
  ];

  static const Map<String, Map<String, String>> _values = {
    'pt': {
      'profile': 'Perfil',
      'reports': 'RelatÃ³rios',
      'insights': 'Insights',
      'missions': 'MissÃµes',
      'dark_theme': 'Tema escuro',
      'logout': 'Sair',
      'simulator': 'Simulador',
      'calc_title': 'Simulador de Investimentos',
      'calc_subtitle':
          'Projete o futuro do seu patrimÃ´nio com juros compostos.',
      'monthly_contribution': 'Aporte Mensal (R\$)',
      'annual_rate': 'Taxa Anual (%)',
      'period_years': 'PerÃ­odo (anos)',
      'calc_disclaimer':
          'SimulaÃ§Ã£o baseada em aportes mensais com capitalizaÃ§Ã£o mensal de juros.',
      'final_total': 'Total Final',
      'total_invested': 'Total Investido',
      'profit': 'Rendimento',
      'equity_evolution': 'EvoluÃ§Ã£o do PatrimÃ´nio',
      'total_with_interest': 'Total (com juros)',
      'invested_capital': 'Capital Investido',
      'year_label': 'Ano',
      'premium_calc_title': 'Calculadora de Liberdade',
      'premium_calc_subtitle':
          'Simule sua jornada rumo Ã  independÃªncia financeira com o Plano Premium.',
      'no_entries_found_title':
          'Nenhum lanÃ§amento encontrado para este perÃ­odo.',
      'no_entries_found':
          'Comece a organizar suas finanÃ§as adicionando um novo lanÃ§amento hoje.',
      'day': 'Dia',
      'card': 'CartÃ£o',
      'paid': 'Pago',
      'edit_entry': 'Editar lanÃ§amento',
      'delete_entry': 'Remover lanÃ§amento',
      'language': 'Idioma',
      'dashboard': 'Dashboard',
      'goals': 'Metas',
      'goal': 'Meta',
      'save_goal': 'Salvar Meta',
      'completed_label': 'ConcluÃ­das',
      'credit_cards_title': 'CartÃµes de crÃ©dito',
      'credit_cards_empty': 'Nenhum cartÃ£o cadastrado.',
      'card_add': 'Adicionar cartÃ£o',
      'card_name': 'Nome do cartÃ£o',
      'login': 'Entrar',
      'register': 'Criar conta',
      'email': 'E-mail',
      'password': 'Senha',
      'forgot_password': 'Esqueci minha senha',
      'missions_month': 'MissÃµes do mÃªs',
      'missions_week': 'MissÃµes da semana',
      'missions_day': 'MissÃµes do dia',
      'login_required_missions': 'FaÃ§a login para ver suas missÃµes.',
      'onboarding_title': 'Seu primeiro plano',
      'onboarding_heading': 'Vamos entender seu objetivo financeiro',
      'onboarding_subtitle':
          'Essas respostas personalizam missÃµes e desbloqueios. Seus dados ficam salvos na nuvem.',
      'onboarding_objectives': 'Objetivos',
      'onboarding_missing_fields':
          'Preencha renda, profissÃ£o e pelo menos um objetivo.',
      'session_expired_login': 'SessÃ£o expirada. FaÃ§a login novamente.',
      'save_failed_try_again': 'NÃ£o foi possÃ­vel salvar. Tente novamente.',
      'profession': 'ProfissÃ£o',
      'monthly_income': 'Renda mensal (R\$)',
      'continue': 'Continuar',
      'language_pt': 'PortuguÃªs',
      'language_en': 'InglÃªs',
      'language_es': 'Espanhol',
      'mission_type_daily': 'DIÃRIA',
      'mission_type_weekly': 'SEMANAL',
      'mission_type_monthly': 'MENSAL',
      'missions_premium_title': 'MissÃµes exclusivas para Premium',
      'missions_premium_subtitle':
          'Ganhe XP real e desbloqueie nÃ­veis com desafios validados pelo seu progresso no app.',
      'missions_premium_perk1': 'MissÃµes diÃ¡rias, semanais e mensais',
      'missions_premium_perk2': 'XP dobrado e nÃ­veis exclusivos',
      'missions_premium_perk3': 'Progresso e desbloqueios premium',
      'mission_daily_review_expense': 'Revise 1 gasto',
      'mission_desc_daily_review_expense':
          'Abra um gasto recente e verifique se o valor e a categoria estÃ£o corretos.',
      'mission_daily_tip': 'Veja insights do dia',
      'mission_desc_daily_tip':
          'Abra a aba de Insights ou RelatÃ³rios para ver as dicas do dia.',
      'mission_daily_emotional_spend': 'Classifique um gasto emocional',
      'mission_desc_daily_emotional_spend':
          'Identifique um gasto que foi feito por impulso ou emoÃ§Ã£o e marque-o.',
      'mission_daily_log_expense': 'Registre um gasto hoje',
      'mission_desc_daily_log_expense':
          'Adicione qualquer despesa (fixa ou variÃ¡vel) que vocÃª fez hoje.',
      'mission_daily_balance_repair':
          'Alinhe gastos para fechar o mÃªs no positivo',
      'mission_desc_daily_balance_repair':
          'Revise seus gastos planejados e faÃ§a ajustes para garantir saldo positivo.',
      'mission_daily_variable_reflect':
          'Liste 3 gastos variÃ¡veis para revisar',
      'mission_desc_daily_variable_reflect':
          'Olhe seus gastos variÃ¡veis recentes e veja onde pode economizar.',
      'mission_daily_invest_review':
          'Confira seus investimentos e tome uma aÃ§Ã£o',
      'mission_desc_daily_invest_review':
          'Acesse sua Ã¡rea de investimentos ou calculadora para verificar seu progresso.',
      'mission_weekly_budget': 'Registre gastos em 3 dias da semana',
      'mission_desc_weekly_budget':
          'Mantenha a consistÃªncia registrando gastos em pelo menos 3 dias diferentes desta semana.',
      'mission_weekly_leisure': 'Revise seu lazer da semana',
      'mission_desc_weekly_leisure':
          'Analise quanto vocÃª gastou com lazer e veja se estÃ¡ dentro do planejado.',
      'mission_weekly_no_impulse_7': 'Fique 7 dias sem gasto impulsivo',
      'mission_desc_weekly_no_impulse_7':
          'Evite compras nÃ£o planejadas por uma semana inteira.',
      'mission_weekly_no_impulse_3': 'Fique 3 dias sem gasto impulsivo',
      'mission_desc_weekly_no_impulse_3':
          'Evite compras nÃ£o planejadas por 3 dias consecutivos.',
      'mission_weekly_variable_trim':
          'Defina um limite para gastos variÃ¡veis nesta semana',
      'mission_desc_weekly_variable_trim':
          'EstabeleÃ§a um teto para gastos como alimentaÃ§Ã£o e transporte esta semana.',
      'mission_weekly_invest_review':
          'Revise uma aplicaÃ§Ã£o ou insight da calculadora nesta semana',
      'mission_desc_weekly_invest_review':
          'Dedique um tempo para entender melhor seus investimentos ou simular cenÃ¡rios.',
      'mission_weekly_debt_action':
          'Trace um movimento para reduzir dÃ­vidas pendentes',
      'mission_desc_weekly_debt_action':
          'Planeje um pagamento extra ou renegociaÃ§Ã£o de uma dÃ­vida.',
      'mission_monthly_close_month': 'Feche o mÃªs conscientemente',
      'mission_desc_monthly_close_month':
          'Revise todo o mÃªs que passou, categorize tudo e veja o saldo final.',
      'mission_monthly_compare_two': 'Compare dois meses',
      'mission_desc_monthly_compare_two':
          'Use a ferramenta de comparaÃ§Ã£o para ver sua evoluÃ§Ã£o entre dois meses.',
      'mission_monthly_review_prev': 'Revise o mÃªs anterior',
      'mission_desc_monthly_review_prev':
          'Olhe para o mÃªs passado para entender seus padrÃµes de gastos.',
      'mission_monthly_future_plan': 'Ajuste seu plano futuro',
      'mission_desc_monthly_future_plan':
          'Com base no mÃªs atual, ajuste suas previsÃµes para os prÃ³ximos meses.',
      'mission_monthly_simple_plan': 'Defina um plano simples',
      'mission_desc_monthly_simple_plan':
          'Crie uma meta bÃ¡sica de economia ou limite de gastos para o mÃªs.',
      'mission_monthly_balance_repair':
          'Replaneje este mÃªs para sair no verde',
      'mission_desc_monthly_balance_repair':
          'FaÃ§a cortes necessÃ¡rios agora para terminar o mÃªs com saldo positivo.',
      'mission_monthly_variable_trim':
          'Reduza gastos variÃ¡veis para recuperar margem',
      'mission_desc_monthly_variable_trim':
          'Identifique onde cortar supÃ©rfluos para aumentar sua sobra mensal.',
      'mission_monthly_emergency_build': 'Avance na reserva de emergÃªncia',
      'mission_desc_monthly_emergency_build':
          'Guarde qualquer valor, por menor que seja, na sua reserva de emergÃªncia.',
      'mission_monthly_goal_review': 'Reveja suas metas e ajuste o plano',
      'mission_desc_monthly_goal_review':
          'Verifique o progresso das suas metas e ajuste os prazos ou valores se necessÃ¡rio.',
      'mission_monthly_invest_health':
          'Cheque se seus investimentos acompanham seus objetivos',
      'mission_desc_monthly_invest_health':
          'Garanta que sua carteira de investimentos estÃ¡ alinhada com seus sonhos.',
      'mission_monthly_debt_clear':
          'Esboce um plano para diminuir sua carga de dÃ­vida',
      'mission_desc_monthly_debt_clear':
          'Crie uma estratÃ©gia para pagar suas dÃ­vidas mais rÃ¡pido.',
      'mission_objective_debts_high': 'Renegocie 1 dÃ­vida e registre o plano',
      'mission_objective_debts_low': 'Liste todas as dÃ­vidas e custos mensais',
      'mission_objective_property_high': 'imule entrada e parcelas do imÃ³vel',
      'mission_objective_property_low': 'Defina o valor-alvo do imÃ³vel',
      'mission_objective_trip_high': 'Crie um fundo da viagem com meta mensal',
      'mission_objective_trip_low': 'Defina o custo total da viagem',
      'mission_objective_save_high': 'Automatize um valor para reserva',
      'mission_objective_save_low': 'Defina um valor mÃ­nimo para guardar',
      'mission_objective_security_high':
          'Monte 1 mÃªs de reserva de emergÃªncia',
      'mission_objective_security_low': 'Defina sua meta de reserva',
      'mission_objective_dream_high': 'Quebre seu sonho em 3 marcos',
      'mission_objective_dream_low': 'Defina o prazo do sonho',
      'mission_objective_invest_high': 'Ajuste sua alocaÃ§Ã£o de investimentos',
      'mission_objective_invest_low': 'Defina quanto quer investir no mÃªs',
      'mission_objective_emergency_fund_high':
          'Cheque 2 meses de despesas na reserva',
      'mission_objective_emergency_fund_low':
          'Comece com 1 meta simples de reserva',
      'mission_objective_generic_high':
          'Defina 1 aÃ§Ã£o concreta para o objetivo',
      'mission_objective_generic_low': 'Escreva seu objetivo com prazo',
      'objective_dream': 'Conquistar um sonho',
      'objective_property': 'Adquirir um imÃ³vel',
      'objective_trip': 'Fazer uma viagem',
      'objective_debts': 'Sair de dÃ­vidas',
      'objective_save': 'Guardar dinheiro',
      'objective_security': 'Ter mais seguranÃ§a',
      'objective_emergency_fund': 'Construir reserva de emergÃªncia',
      'objective_invest': 'Investir melhor',
      'login_fill_email_password': 'Preencha e-mail e senha.',
      'error_connect_server': 'Erro ao conectar ao servidor.',
      'reset_need_email':
          'Informe seu e-mail para receber o link de redefiniÃ§Ã£o.',
      'reset_sent': 'Enviamos um link de redefiniÃ§Ã£o para o seu e-mail.',
      'email_not_found': 'E-mail nÃ£o encontrado.',
      'login_invalid_email': 'E-mail invÃ¡lido.',
      'no_connection': 'Sem conexÃ£o com a internet.',
      'reset_error_with_code': 'Erro ao processar a recuperaÃ§Ã£o: {code}.',
      'reset_title': 'Recuperar senha',
      'reset_subtitle':
          'Vamos enviar um link de redefiniÃ§Ã£o para o seu e-mail.',
      'reset_code_subtitle':
          'Digite o cÃ³digo de 5 dÃ­gitos e crie uma nova senha.',
      'reset_send_button': 'Enviar link',
      'reset_send_code_button': 'Enviar cÃ³digo',
      'reset_code_label': 'CÃ³digo de recuperaÃ§Ã£o',
      'reset_code_hint': 'Digite o cÃ³digo de 5 nÃºmeros',
      'reset_verify_button': 'Validar cÃ³digo',
      'reset_new_password': 'Nova senha',
      'reset_new_password_title': 'Nova senha',
      'reset_new_password_subtitle':
          'Defina sua nova senha para acessar a conta.',
      'reset_confirm_password': 'Confirmar nova senha',
      'reset_password_mismatch': 'As senhas nÃ£o conferem.',
      'reset_confirm_button': 'Salvar nova senha',
      'reset_confirmed': 'Senha redefinida com sucesso.',
      'reset_code_sent':
          'Se este e-mail existir, enviamos um cÃ³digo de 5 dÃ­gitos. Ele expira em 5 minutos.',
      'reset_code_invalid': 'CÃ³digo invÃ¡lido. Use 5 nÃºmeros.',
      'reset_code_expires_in': 'CÃ³digo expira em {time}.',
      'reset_code_expired': 'CÃ³digo expirado. Envie um novo cÃ³digo.',
      'reset_resend_button': 'Reenviar link',
      'reset_resend_code_button': 'Reenviar cÃ³digo',
      'reset_resend_button_timer': 'Reenviar em {time}',
      'reset_resend_wait': 'Aguarde 60 segundos para reenviar.',
      'reset_rate_limited': 'Muitas tentativas. Tente novamente mais tarde.',
      'login_google_not_ready':
          'Google ainda nao configurado. No Firebase, configure Android (SHA-1 + google-services.json) e iOS (GoogleService-Info.plist + URL Scheme do REVERSED_CLIENT_ID).',
      'login_apple_not_ready': 'Login com Apple ainda nÃ£o configurado.',
      'login_cancelled': 'Login cancelado.',
      'login_google': 'Entrar com Google',
      'login_apple': 'Entrar com Apple',
      'register_action': 'Cadastrar',
      'register_required_fields': 'Preencha todos os campos obrigatÃ³rios.',
      'register_password_mismatch': 'As senhas nÃ£o conferem.',
      'register_terms_required':
          'VocÃª precisa aceitar os termos para continuar.',
      'register_email_in_use': 'Este e-mail jÃ¡ estÃ¡ em uso.',
      'register_invalid_email': 'E-mail invÃ¡lido.',
      'register_weak_password':
          'Senha muito fraca. Use pelo menos 8 caracteres com maiÃºscula, minÃºscula, nÃºmero e caractere especial.',
      'register_email_not_enabled':
          'Cadastro por e-mail nÃ£o estÃ¡ habilitado no Firebase.',
      'register_error_with_code': 'Erro ao criar conta: {code}.',
      'register_success': 'Conta criada! Agora faÃ§a login.',
      'first_name': 'Nome',
      'profile_property_value': 'Valor aproximado de imÃ³veis',
      'profile_invest_balance': 'Saldo total em investimentos',
      'wealth_info_title': 'PatrimÃ´nio e Investimentos',
      'last_name': 'Sobrenome',
      'birth_date': 'Data de nascimento',
      'gender': 'Sexo',
      'confirm_password': 'Confirmar senha',
      'register_terms_text':
          'Aceito os termos de uso e autorizo o armazenamento online dos meus dados.',
      'gender_not_informed': 'NÃ£o informado',
      'gender_male': 'Masculino',
      'gender_female': 'Feminino',
      'gender_other': 'Outro',
      'login_invalid_credentials': 'E-mail ou senha incorretos.',
      'profile_no_user': 'Nenhum usuÃ¡rio encontrado. FaÃ§a cadastro/login.',
      'profile_required_fields': 'Preencha os campos obrigatÃ³rios.',
      'profile_invalid_income': 'Informe uma renda mensal vÃ¡lida.',
      'profile_photo_upload_error': 'Erro ao enviar a foto.',
      'profile_updated': 'Perfil atualizado.',
      'profile_no_user_body':
          'Nenhum usuÃ¡rio encontrado.\nCrie uma conta e faÃ§a login.',
      'save': 'Salvar',
      'profile_change_photo': 'Alterar foto',
      'select': 'Selecionar',
      'login_blocked':
          'Acesso bloqueado. Entre em contato pelo e-mail: contato@voolo.com',
      'login_failed_try_again': 'Falha ao entrar. Tente novamente.',
      'unknown_route_title': 'Rota nÃ£o encontrada',
      'unknown_route_body':
          'A rota "{route}" nÃ£o existe.\nVerifique AppRoutes e seus Navigator.pushNamed().',
      'premium_cta': 'Seja Premium',
      'premium_badge': 'Premium',
      'premium_dialog_title': 'Seja Premium',
      'premium_dialog_body':
          'Desbloqueie missÃµes, relatÃ³rios inteligentes, calculadora de investimentos e alertas de pagamentos.\n\nEntre em contato para ativar o Premium.',
      'premium_upsell_title': 'Mais controle, mais clareza, mais resultado',
      'premium_welcome_title': 'Premium ativado!',
      'premium_welcome_body':
          'ParabÃ©ns pela escolha do Voolo. Que essa jornada traga mais clareza, controle e tranquilidade.',
      'premium_welcome_tip':
          'Quer um onboarding guiado? Eu te mostro cada funÃ§Ã£o no lugar exato.',
      'premium_welcome_yes': 'Quero onboarding',
      'premium_welcome_no': 'Agora nÃ£o',
      'premium_onboarding_title': 'Bem-vindo ao Premium',
      'premium_onboarding_subtitle':
          'Vamos fazer um caminho pelo app e ver cada funÃ§Ã£o na prÃ¡tica.',
      'premium_onboarding_next': 'PrÃ³ximo',
      'premium_onboarding_finish': 'Finalizar',
      'premium_onboarding_skip': 'Pular',
      'premium_onboarding_open': 'Mostrar no app',
      'premium_onboarding_progress': '{done} de {total} etapas concluÃ­das',
      'premium_insights_title': 'AnÃ¡lises de Elite',
      'premium_insights_subtitle':
          'Desbloqueie insights avanÃ§ados e alertas inteligentes para turbinar sua evoluÃ§Ã£o financeira.',
      'premium_step_reports_title': 'RelatÃ³rios Premium',
      'premium_step_reports_body':
          'Veja um resumo visual do mÃªs e compare sua evoluÃ§Ã£o.',
      'premium_step_reports_tip':
          'Toque em "Mostrar no app" para ver onde fica.',
      'premium_step_goals_title': 'Metas inteligentes',
      'premium_step_goals_body':
          'Metas com progresso claro e desafios semanais.',
      'premium_step_goals_tip': 'Toque em "Mostrar no app" para abrir Metas.',
      'premium_step_invest_title': 'Calculadora de investimentos',
      'premium_step_invest_body':
          'Simule cenÃ¡rios e veja o resultado no longo prazo.',
      'premium_step_invest_tip':
          'Toque em "Mostrar no app" e teste os valores.',
      'premium_step_missions_title': 'MissÃµes premium',
      'premium_step_missions_body':
          'Rotina leve com desafios diÃ¡rios, semanais e mensais.',
      'premium_step_missions_tip':
          'Toque em "Mostrar no app" para ver as missÃµes.',
      'premium_step_insights_title': 'Insights inteligentes',
      'premium_step_insights_body':
          'Alertas e dicas que guiam sua prÃ³xima aÃ§Ã£o.',
      'premium_step_insights_tip':
          'Toque em "Mostrar no app" para abrir Insights.',
      'premium_tour_calculator_title': 'Calculadora de investimentos',
      'premium_tour_calculator_body':
          'Aqui vocÃª simula aportes e taxa para ver o resultado futuro.',
      'premium_tour_calculator_location':
          'Onde fica: botÃ£o Calculadora na tela inicial.',
      'premium_tour_calculator_tip':
          'Teste 5, 10 e 20 anos para comparar cenÃ¡rios.',
      'premium_tour_goals_title': 'Metas inteligentes',
      'premium_tour_goals_body':
          'Suas metas aparecem aqui com progresso e desafios semanais.',
      'premium_tour_goals_location':
          'Onde fica: menu lateral > Metas ou botÃ£o Metas na home.',
      'premium_tour_goals_tip': 'Crie uma meta e marque o que foi concluÃ­do.',
      'premium_tour_missions_title': 'MissÃµes Premium',
      'premium_tour_missions_body':
          'MissÃµes diÃ¡rias, semanais e mensais para manter consistÃªncia.',
      'premium_tour_missions_location': 'Onde fica: menu lateral > MissÃµes.',
      'premium_tour_missions_tip': 'Complete missÃµes e acompanhe seu XP.',
      'premium_tour_reports_title': 'RelatÃ³rios Premium',
      'premium_tour_reports_body':
          'Resumo visual do mÃªs com totais e comparativos.',
      'premium_tour_reports_location': 'Onde fica: menu lateral > RelatÃ³rios.',
      'premium_tour_reports_tip':
          'Troque o mÃªs no topo para comparar perÃ­odos.',
      'premium_tour_insights_title': 'Insights',
      'premium_tour_insights_body':
          'Alertas e sugestÃµes para equilibrar seus gastos.',
      'premium_tour_insights_location': 'Onde fica: menu lateral > Insights.',
      'premium_tour_insights_tip': 'Siga o foco principal e ajuste seu mÃªs.',
      'close': 'Fechar',
      'user_label': 'UsuÃ¡rio',
      'security': 'SeguranÃ§a',
      'settings': 'ConfiguraÃ§Ãµes',
      'login_required_calculator': 'FaÃ§a login para acessar a calculadora.',
      'investment_calculator': 'Calculadora de investimentos',
      'investment_premium_title':
          'Calculadora de investimentos desbloqueada no Premium',
      'investment_premium_subtitle':
          'Simule aportes e veja crescimento real do seu patrimÃ´nio com projeÃ§Ãµes avanÃ§adas.',
      'investment_premium_perk1': 'ProjeÃ§Ãµes de 5, 10 e 20 anos',
      'investment_premium_perk2': 'RelatÃ³rios com insights personalizados',
      'investment_premium_perk3': 'Score de saÃºde financeira',
      'investment_projection_title':
          'ProjeÃ§Ã£o com aporte mensal + juros compostos',
      'investment_monthly_contribution': 'Aporte mensal (R\$)',
      'investment_annual_rate': 'Taxa anual (%)',
      'investment_invalid_inputs':
          'Informe um aporte e uma taxa maiores que zero para ver a projeÃ§Ã£o.',
      'investment_disclaimer':
          'ObservaÃ§Ã£o: esta projeÃ§Ã£o Ã© uma simulaÃ§Ã£o. Resultados reais variam conforme mercado, taxas e impostos.',
      'investment_total_contribution': 'Aporte total',
      'investment_profit': 'Rendimento',
      'investment_final_total': 'Total final',
      'example_500': 'Ex: 500',
      'example_12': 'Ex: 12',
      'years_label': '{years} anos',
      'new_entry': 'Novo lanÃ§amento',
      'type': 'Tipo',
      'name': 'Nome',
      'category': 'Categoria',
      'value_currency': 'Valor (R\$)',
      'due_day_optional': 'Dia de vencimento (opcional)',
      'card_due_day': 'Vencimento da fatura do cartÃ£o',
      'card_select': 'CartÃ£o de crÃ©dito',
      'card_due_day_value': 'Vencimento da fatura: dia {day}',
      'card_required': 'Cadastre um cartÃ£o de crÃ©dito primeiro.',
      'no_due_date': 'Sem vencimento',
      'day_label': 'Dia {n}',
      'credit_card_charge': 'Conta no cartÃ£o de crÃ©dito',
      'card_recurring': 'Compra recorrente no cartÃ£o',
      'card_recurring_short': 'Recorrente',
      'card_paid_badge': 'Fatura paga',
      'card_unknown': 'CartÃ£o desconhecido',
      'bill_paid': 'Conta paga',
      'card_invoice_paid': 'Fatura do cartÃ£o paga',
      'installments_quantity': 'Quantidade de parcelas',
      'credit_card_bills_title': 'Faturas do cartÃ£o',
      'card_due_day_label': 'Vencimento dia {day}',
      'card_insight_title': 'Faturas do cartÃ£o no mÃªs',
      'card_insight_high':
          'As faturas somam {value} ({pct}% da renda). Isso pode apertar seu orÃ§amento.',
      'card_insight_ok':
          'As faturas somam {value} ({pct}% da renda). Dentro do esperado.',
      'expense_tip_fixed':
          'Dica: Se preencher o vencimento, o Jetx avisarÃ¡ 3 dias antes e no dia (quando ativarmos notificaÃ§Ãµes).',
      'expense_tip_variable':
          'Dica: Gastos variÃ¡veis contam apenas no mÃªs atual.',
      'income_variable_tip':
          'Renda variÃ¡vel? Use a mÃ©dia dos Ãºltimos 3 meses para evitar frustraÃ§Ãµes.',
      'credit_card_tip':
          'Compras parceladas comprometem sua renda futura. Use com cuidado.',
      'expense_high_tip':
          'Esse gasto representa {pct}% do seu orÃ§amento mensal. Ideal Ã© atÃ© {ideal}%.',
      'expense_name_required': 'Digite o nome.',
      'expense_value_required': 'Digite um valor vÃ¡lido.',
      'installments_required': 'Informe a quantidade de parcelas.',
      'expense_type_fixed': 'Gasto fixo',
      'expense_type_variable': 'Gasto variÃ¡vel',
      'expense_type_investment': 'Investimento',
      'expense_category_housing': 'Moradia',
      'expense_category_food': 'AlimentaÃ§Ã£o',
      'expense_category_transport': 'Transporte',
      'expense_category_education': 'EducaÃ§Ã£o',
      'expense_category_health': 'SaÃºde',
      'expense_category_leisure': 'Lazer',
      'expense_category_subscriptions': 'Assinaturas',
      'expense_category_investment': 'Investimento',
      'expense_category_other': 'Outros',
      'mission_complete_title': 'Concluir missÃ£o',
      'mission_complete_note_label': 'ComentÃ¡rio de conclusÃ£o (opcional)',
      'mission_complete_note_hint': 'Conte o que vocÃª fez e como fez.',
      'mission_note_title': 'ComentÃ¡rio da missÃ£o',
      'mission_note_view': 'Ver comentÃ¡rio',
      'mission_complete_cta': '+{xp} XP',
      'mission_require_expense_today':
          'Registre pelo menos 1 gasto hoje para concluir.',
      'mission_require_report_today':
          'Abra o relatÃ³rio do mÃªs hoje para concluir.',
      'mission_require_weekly_expenses':
          'Registre gastos em pelo menos 3 dias da semana.',
      'mission_require_previous_month':
          'Tenha pelo menos 1 mÃªs anterior para comparar.',
      'mission_require_goal': 'Crie pelo menos 1 meta pessoal para concluir.',
      'mission_require_default': 'Complete a atividade no app para concluir.',
      'mission_manual_title': 'Concluir manualmente',
      'mission_manual_body':
          'Os requisitos automÃ¡ticos nÃ£o foram detectados. Deseja marcar como concluÃ­da mesmo assim?',
      'confirm': 'Confirmar',
      'cancel': 'Cancelar',
      'back': 'Voltar',
      'finish': 'Finalizar',
      'onboarding_objectives_title':
          'Para comeÃ§ar, quais sÃ£o seus objetivos?',
      'onboarding_objectives_subtitle':
          'Isso nos ajuda a sugerir metas e missÃµes mais alinhadas com vocÃª.',
      'onboarding_objectives_required': 'Escolha pelo menos um objetivo.',
      'onboarding_profession_title': 'Qual Ã© a sua profissÃ£o?',
      'onboarding_profession_subtitle':
          'Queremos entender seu momento profissional para personalizar sua jornada.',
      'onboarding_profession_required': 'Informe sua profissÃ£o.',
      'onboarding_income_title': 'Qual Ã© a sua renda mensal?',
      'onboarding_income_subtitle':
          'Com esse dado, conseguimos montar metas realistas para vocÃª.',
      'summary_fixed': 'Fixos',
      'summary_variable': 'VariÃ¡veis',
      'summary_invest': 'Invest.',
      'summary_free': 'Livre',
      'timeline_more': 'a mais',
      'timeline_less': 'a menos',
      'timeline_variable_change':
          'Este mÃªs vocÃª gastou {pct}% {direction} em variÃ¡veis.',
      'timeline_fixed_change': 'Gastos fixos ficaram {pct}% {direction}.',
      'timeline_invest_streak':
          'VocÃª aumentou seus investimentos por {months} meses seguidos.',
      'timeline_balanced': 'Seu mÃªs estÃ¡ equilibrado. Mantenha o ritmo!',
      'score_title': 'Score financeiro',
      'score_title_month_tips': 'Score financeiro do mÃªs',
      'score_locked_subtitle':
          'Veja sua saÃºde financeira com insights inteligentes.',
      'score_add_income': 'Cadastre sua renda para calcular o score.',
      'score_focus_variable': 'Seu maior foco agora Ã©: gastos variÃ¡veis.',
      'score_focus_fixed': 'Seu maior foco agora Ã©: gastos fixos.',
      'score_focus_invest_low': 'Seu maior foco agora Ã©: investimentos.',
      'score_focus_invest_high':
          'Seu maior foco agora Ã©: equilibrar investimentos.',
      'score_focus_balanced':
          'Boa decisÃ£o: seu orÃ§amento estÃ¡ bem equilibrado.',
      'plan_title': 'Plano do mÃªs',
      'plan_subtitle': 'AÃ§Ãµes rÃ¡pidas para melhorar seu mÃªs.',
      'plan_next_action': 'PrÃ³xima aÃ§Ã£o',
      'plan_action_variable':
          'Reduza gastos variÃ¡veis para atÃ© 30% da renda.',
      'plan_action_fixed':
          'Traga os gastos fixos para no mÃ¡ximo 50% da renda.',
      'plan_action_invest': 'Direcione {value} para investimentos.',
      'plan_action_ok': 'VocÃª estÃ¡ equilibrado. Mantenha o ritmo.',
      'alert_title': 'Alertas inteligentes',
      'alert_add_income': 'Cadastre sua renda para liberar alertas.',
      'alert_fixed_high': 'Gastos fixos acima de 55% da renda.',
      'alert_variable_high': 'Gastos variÃ¡veis acima de 35% da renda.',
      'alert_invest_low': 'Investimentos abaixo do ideal este mÃªs.',
      'alert_negative_balance': 'Seu saldo do mÃªs estÃ¡ negativo.',
      'alert_ok': 'Tudo certo por aqui. Continue consistente.',
      'tips_title': 'Dicas do mÃªs',
      'tip_housing_high':
          'Moradia acima de 35%. Avalie alternativas para reduzir esse custo.',
      'compare_title': 'Comparativo mensal',
      'compare_no_data': 'Sem dados do mÃªs anterior ainda.',
      'insights_title': 'Insights do mÃªs',
      'insights_subtitle': 'Concentre todas as dicas e alertas aqui.',
      'insights_card_subtitle':
          'Veja alertas, plano e comparativos em um sÃ³ lugar.',
      'insights_cta': 'Abrir',
      'habit_title': 'HÃ¡bitos financeiros',
      'habit_streak': 'SequÃªncia {days} dias',
      'habit_log_expense': 'Registrar gastos do dia',
      'habit_log_expense_subtitle': 'Mantenha as despesas em dia.',
      'habit_check_budget': 'Revisar o orÃ§amento',
      'habit_check_budget_subtitle': 'Confirme se vocÃª estÃ¡ no plano.',
      'habit_invest': 'Separar para investir',
      'habit_invest_subtitle': 'Reserve um valor semanal.',
      'month_entries': 'LanÃ§amentos do mÃªs',
      'no_entries_yet': 'Nenhum lanÃ§amento ainda.',
      'month_salary': 'SalÃ¡rio do mÃªs',
      'goals_title': 'Metas',
      'goals_add_new': 'Nova meta',
      'goals_title_label': 'TÃ­tulo da meta',
      'goals_type_label': 'Tipo',
      'goals_type_income': 'Renda / Carreira',
      'goals_type_education': 'EducaÃ§Ã£o',
      'goals_type_personal': 'Pessoal',
      'goals_description_optional': 'DescriÃ§Ã£o (opcional)',
      'goals_title_required': 'Digite um tÃ­tulo para a meta.',
      'goals_income_exists': 'Essa meta jÃ¡ existe como obrigatÃ³ria do ano.',
      'goals_login_required': 'FaÃ§a login para acessar metas.',
      'goals_subtitle':
          'Acompanhe seu progresso, desafios semanais e objetivos estratÃ©gicos.',
      'goals_empty_year': 'Nenhuma meta cadastrada para este ano.',
      'goals_tip_hold_remove':
          'Dica: segure uma meta (nÃ£o obrigatÃ³ria) para remover.',
      'goals_completed_count': '{done} de {total} metas concluÃ­das',
      'goals_already_in_list': 'Essa meta jÃ¡ estÃ¡ na sua lista.',
      'goals_section_year': 'Metas do ano',
      'goals_premium_title': 'Metas avanÃ§adas sÃ£o Premium',
      'goals_premium_perk1': 'Progresso anual em tempo real',
      'goals_premium_perk2': 'Desafios semanais guiados',
      'goals_premium_perk3': 'Metas inteligentes baseadas no seu saldo',
      'goals_no_month_data': 'Sem dados do mÃªs',
      'goals_month_balance': 'Saldo do mÃªs: {value}',
      'save_cloud_error': 'Falha ao salvar na nuvem. Verifique sua conexÃ£o.',
      'goals_progress_section': 'Seu progresso',
      'goals_suggestions_section': 'SugestÃµes para vocÃª',
      'goals_weekly_section': 'Desafios da semana',
      'goals_weekly_empty': 'Sem desafios desta semana. Volte amanhÃ£.',
      'goals_year_progress': 'Progresso anual',
      'mandatory': 'ObrigatÃ³ria',
      'goal_action_complete': 'Concluir',
      'goal_action_add': 'Adicionar',
      'goal_income_title': 'Aumentar renda',
      'goal_income_desc': 'Crie um plano para aumentar seu rendimento no ano.',
      'goal_weekly_finance_content_title':
          'Ver conteÃºdo sobre planejamento financeiro',
      'goal_weekly_finance_content_desc':
          '15 minutos de leitura ou vÃ­deo para reforÃ§ar o bÃ¡sico.',
      'goal_weekly_review_expenses_title': 'Revisar gastos do mÃªs',
      'goal_weekly_review_expenses_desc':
          'Marque gastos variÃ¡veis e escolha 1 ajuste.',
      'goal_weekly_invest_10_title': 'Separar 10% para investir',
      'goal_weekly_invest_10_desc':
          'Direcione uma parte do saldo para investimentos.',
      'goal_weekly_spend_limit_title': 'Criar um teto de gastos semanal',
      'goal_weekly_spend_limit_desc':
          'Defina um limite e acompanhe atÃ© o domingo.',
      'goal_weekly_start_finance_book_title': 'ComeÃ§ar um livro de finanÃ§as',
      'goal_weekly_start_finance_book_desc':
          'Leia 10 pÃ¡ginas e marque como feito.',
      'goal_suggest_income_title': 'Cadastrar renda mensal',
      'goal_suggest_income_desc':
          'Adicione sua renda para desbloquear o planejamento.',
      'goal_suggest_reduce_variable_title': 'Reduzir 10% em variÃ¡veis',
      'goal_suggest_reduce_variable_desc':
          'Ajuste despesas nÃ£o essenciais nas prÃ³ximas semanas.',
      'goal_suggest_invest_title': 'Aumentar investimentos',
      'goal_suggest_invest_desc': 'Meta de aporte mensal consistente.',
      'goal_suggest_emergency_title': 'Montar reserva de emergÃªncia',
      'goal_suggest_emergency_desc': 'Objetivo de 3 a 6 meses de custo fixo.',
      'goal_suggest_education_title': 'Plano de educaÃ§Ã£o financeira',
      'goal_suggest_education_desc': 'Estudar 30 min por semana.',
      'premium_subtitle_short': 'Desbloqueie recursos exclusivos',
      'timeline_title': 'Linha do tempo',
      'timeline_positive_streak': 'SequÃªncia positiva',
      'timeline_positive_streak_desc':
          'Investimentos cresceram por {months} meses seguidos.',
      'timeline_balance_alert': 'Alerta de equilÃ­brio',
      'timeline_balance_alert_desc':
          'VariÃ¡veis superaram fixos. Revise gastos flexÃ­veis.',
      'timeline_control_ok': 'Controle em dia',
      'timeline_control_ok_desc':
          'Fixos estÃ£o controlados em relaÃ§Ã£o aos gastos variÃ¡veis.',
      'timeline_balanced_month': 'MÃªs equilibrado',
      'timeline_balanced_month_desc': 'Nenhuma variaÃ§Ã£o relevante detectada.',
      'add_extra_income': 'Adicionar renda extra',
      'income_label_placeholder': 'Nome da fonte',
      'offline_message': 'VocÃª estÃ¡ offline. Conecte-se a uma rede.',
    },
    'en': {
      'profile': 'Profile',
      'reports': 'Reports',
      'insights': 'Insights',
      'missions': 'Missions',
      'dark_theme': 'Dark theme',
      'logout': 'Sign out',
      'simulator': 'Simulator',
      'calc_title': 'Investment Simulator',
      'calc_subtitle':
          'Project the future of your wealth with compound interest.',
      'monthly_contribution': 'Monthly Contribution',
      'annual_rate': 'Annual Rate (%)',
      'period_years': 'Period (years)',
      'calc_disclaimer':
          'Simulation based on monthly contributions with monthly compounding.',
      'final_total': 'Final Total',
      'total_invested': 'Total Invested',
      'profit': 'Profit',
      'equity_evolution': 'Portfolio Evolution',
      'total_with_interest': 'Total (with interest)',
      'invested_capital': 'Invested Capital',
      'year_label': 'Year',
      'premium_calc_title': 'Freedom Calculator',
      'premium_calc_subtitle':
          'Simulate your journey towards financial independence with the Premium Plan.',
      'no_entries_found_title': 'No entries found',
      'no_entries_found': 'There are no records for this period yet.',
      'day': 'Day',
      'card': 'Card',
      'paid': 'Paid',
      'edit_entry': 'Edit entry',
      'delete_entry': 'Remove entry',
      'language': 'Language',
      'dashboard': 'Dashboard',
      'goals': 'Goals',
      'goal': 'Goal',
      'save_goal': 'Save Goal',
      'completed_label': 'Completed',
      'credit_cards_title': 'Credit cards',
      'credit_cards_empty': 'No cards yet.',
      'card_add': 'Add card',
      'card_name': 'Card name',
      'login': 'Sign in',
      'register': 'Create account',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot password',
      'missions_month': 'Monthly missions',
      'missions_week': 'Weekly missions',
      'missions_day': 'Daily missions',
      'login_required_missions': 'Sign in to see your missions.',
      'onboarding_title': 'Your first plan',
      'onboarding_heading': "Let's understand your financial goal",
      'onboarding_subtitle':
          'These answers personalize missions and unlocks. Your data is saved in the cloud.',
      'onboarding_objectives': 'Goals',
      'onboarding_missing_fields':
          'Fill in income, profession and at least one goal.',
      'session_expired_login': 'Session expired. Sign in again.',
      'save_failed_try_again': 'Unable to save. Try again.',
      'profession': 'Profession',
      'monthly_income': 'Monthly income (R\$)',
      'continue': 'Continue',
      'language_pt': 'Portuguese',
      'language_en': 'English',
      'language_es': 'Spanish',
      'mission_type_daily': 'DAILY',
      'mission_type_weekly': 'WEEKLY',
      'mission_type_monthly': 'MONTHLY',
      'missions_premium_title': 'Premium-only missions',
      'missions_premium_subtitle':
          'Earn real XP and unlock levels with challenges validated by your progress in the app.',
      'missions_premium_perk1': 'Daily, weekly, and monthly missions',
      'missions_premium_perk2': 'Double XP and exclusive levels',
      'missions_premium_perk3': 'Premium progress and unlocks',
      'mission_daily_review_expense': 'Review 1 expense',
      'mission_daily_tip': 'View daily insights',
      'mission_daily_emotional_spend': 'Tag an emotional expense',
      'mission_daily_log_expense': 'Log at least one expense today',
      'mission_daily_balance_repair':
          'Adjust spending to steer the month back to black',
      'mission_daily_variable_reflect': 'List three variable costs to review',
      'mission_daily_invest_review':
          'Open your investments and take a micro-action',
      'mission_weekly_budget': 'Log expenses on 3 days this week',
      'mission_weekly_leisure': 'Review your leisure spending this week',
      'mission_weekly_no_impulse_7': 'Go 7 days without impulsive spending',
      'mission_weekly_no_impulse_3': 'Go 3 days without impulsive spending',
      'mission_weekly_variable_trim':
          'Set a lower limit for variable spending this week',
      'mission_weekly_invest_review':
          'Review an investment or calculator insight this week',
      'mission_weekly_debt_action': 'Sketch a move to tackle outstanding debt',
      'mission_monthly_close_month': 'Close the month consciously',
      'mission_monthly_compare_two': 'Compare two months',
      'mission_monthly_review_prev': 'Review the previous month',
      'mission_monthly_future_plan': 'Adjust your future plan',
      'mission_monthly_simple_plan': 'Set a simple plan',
      'mission_monthly_balance_repair':
          'Re-plan the month to finish in the green',
      'mission_monthly_variable_trim':
          'Cut variable spending to reclaim breathing room',
      'mission_monthly_emergency_build': 'Advance your emergency fund target',
      'mission_monthly_goal_review': 'Review your goals and adjust the plan',
      'mission_monthly_invest_health':
          'Check that investments keep pace with your goals',
      'mission_monthly_debt_clear': 'Outline a plan to lower your debt burden',
      'mission_objective_debts_high': 'Renegotiate 1 debt and record the plan',
      'mission_objective_debts_low': 'List all debts and monthly costs',
      'mission_objective_property_high':
          'Simulate down payment and installments',
      'mission_objective_property_low': 'Set the target value for the home',
      'mission_objective_trip_high': 'Create a trip fund with a monthly target',
      'mission_objective_trip_low': 'Define the total cost of the trip',
      'mission_objective_save_high': 'Automate an amount for savings',
      'mission_objective_save_low': 'Set a minimum amount to save',
      'mission_objective_security_high': 'Build 1 month of emergency reserve',
      'mission_objective_security_low': 'Set your reserve goal',
      'mission_objective_dream_high': 'Break your dream into 3 milestones',
      'mission_objective_dream_low': 'Set the dream deadline',
      'mission_objective_invest_high': 'Adjust your investment allocation',
      'mission_objective_invest_low':
          'Define how much you want to invest this month',
      'mission_objective_emergency_fund_high':
          'Check 2 months of expenses in reserve',
      'mission_objective_emergency_fund_low':
          'Start with a simple reserve goal',
      'mission_objective_generic_high': 'Define 1 concrete action for the goal',
      'mission_objective_generic_low': 'Write your goal with a deadline',
      'objective_dream': 'Achieve a dream',
      'objective_property': 'Buy a home',
      'objective_trip': 'Take a trip',
      'objective_debts': 'Get out of debt',
      'objective_save': 'Save money',
      'objective_security': 'Feel more secure',
      'objective_emergency_fund': 'Build an emergency fund',
      'objective_invest': 'Invest better',
      'login_fill_email_password': 'Enter email and password.',
      'error_connect_server': 'Error connecting to server.',
      'reset_need_email': 'Enter your email to receive the reset link.',
      'reset_sent': 'We sent a reset link to your email.',
      'email_not_found': 'Email not found.',
      'login_invalid_email': 'Invalid email.',
      'no_connection': 'No internet connection.',
      'reset_error_with_code': 'Error processing recovery: {code}.',
      'reset_title': 'Reset password',
      'reset_subtitle': 'We will send a reset link to your email.',
      'reset_code_subtitle': 'Enter the 5-digit code and set a new password.',
      'reset_send_button': 'Send link',
      'reset_send_code_button': 'Send code',
      'reset_code_label': 'Recovery code',
      'reset_code_hint': 'Enter the 5-digit code',
      'reset_verify_button': 'Verify code',
      'reset_new_password': 'New password',
      'reset_new_password_title': 'New password',
      'reset_new_password_subtitle':
          'Set your new password to access your account.',
      'reset_confirm_password': 'Confirm new password',
      'reset_password_mismatch': 'Passwords do not match.',
      'reset_confirm_button': 'Save new password',
      'reset_confirmed': 'Password updated successfully.',
      'reset_code_sent':
          'If this email exists, we sent a 5-digit code. It expires in 5 minutes.',
      'reset_code_invalid': 'Invalid code. Use 5 digits.',
      'reset_code_expires_in': 'Code expires in {time}.',
      'reset_code_expired': 'Code expired. Send a new code.',
      'reset_resend_button': 'Resend link',
      'reset_resend_code_button': 'Resend code',
      'reset_resend_button_timer': 'Resend in {time}',
      'reset_resend_wait': 'Please wait 60 seconds to resend.',
      'reset_rate_limited': 'Too many attempts. Try again later.',
      'login_google_not_ready':
          'Google login is not set up yet. In Firebase, configure Android (SHA-1 + google-services.json) and iOS (GoogleService-Info.plist + REVERSED_CLIENT_ID URL scheme).',
      'login_apple_not_ready': 'Apple login is not set up yet.',
      'login_cancelled': 'Sign-in cancelled.',
      'login_google': 'Sign in with Google',
      'login_apple': 'Sign in with Apple',
      'register_action': 'Sign up',
      'register_required_fields': 'Fill all required fields.',
      'register_password_mismatch': 'Passwords do not match.',
      'register_terms_required': 'You must accept the terms to continue.',
      'register_email_in_use': 'This email is already in use.',
      'register_invalid_email': 'Invalid email.',
      'register_weak_password':
          'Password too weak. Use at least 8 characters with uppercase, lowercase, a number, and a special character.',
      'register_email_not_enabled': 'Email sign-up is not enabled in Firebase.',
      'register_error_with_code': 'Error creating account: {code}.',
      'register_success': 'Account created! Now sign in.',
      'first_name': 'First name',
      'profile_property_value': 'Approximate property value',
      'profile_invest_balance': 'Total investment balance',
      'wealth_info_title': 'Wealth and Investments',
      'last_name': 'Last name',
      'birth_date': 'Birth date',
      'gender': 'Gender',
      'confirm_password': 'Confirm password',
      'register_terms_text':
          'I accept the terms of use and authorize online storage of my data.',
      'gender_not_informed': 'Not informed',
      'gender_male': 'Male',
      'gender_female': 'Female',
      'gender_other': 'Other',
      'login_invalid_credentials': 'Invalid email or password.',
      'profile_no_user': 'No user found. Sign up or sign in.',
      'profile_required_fields': 'Fill the required fields.',
      'profile_invalid_income': 'Enter a valid monthly income.',
      'profile_photo_upload_error': 'Error uploading the photo.',
      'profile_updated': 'Profile updated.',
      'profile_no_user_body': 'No user found.\nCreate an account and sign in.',
      'save': 'Save',
      'profile_change_photo': 'Change photo',
      'select': 'Select',
      'login_blocked': 'Access blocked. Contact us at: contato@voolo.com',
      'login_failed_try_again': 'Sign-in failed. Try again.',
      'unknown_route_title': 'Route not found',
      'unknown_route_body':
          'The route "{route}" does not exist.\nCheck AppRoutes and your Navigator.pushNamed().',
      'premium_cta': 'Go Premium',
      'premium_badge': 'Premium',
      'premium_dialog_title': 'Go Premium',
      'premium_dialog_body':
          'Unlock missions, smart reports, investment calculator, and payment alerts.\n\nContact us to activate Premium.',
      'premium_upsell_title': 'More control, more clarity, more results',
      'premium_welcome_title': 'Premium is on!',
      'premium_welcome_body':
          'Great choice with Voolo. Wishing you clarity, control, and calm in your finances.',
      'premium_welcome_tip':
          'Want a guided tour? I will show each feature in its exact place.',
      'premium_welcome_yes': 'Start onboarding',
      'premium_welcome_no': 'Not now',
      'premium_onboarding_title': 'Welcome to Premium',
      'premium_onboarding_subtitle':
          'Let us walk through the app and see each feature in action.',
      'premium_onboarding_next': 'Next',
      'premium_onboarding_finish': 'Finish',
      'premium_onboarding_skip': 'Skip',
      'premium_onboarding_open': 'Show in app',
      'premium_onboarding_progress': '{done} of {total} steps completed',
      'premium_insights_title': 'Elite Insights',
      'premium_insights_subtitle':
          'Unlock advanced insights and smart alerts to boost your financial evolution.',
      'premium_step_reports_title': 'Premium reports',
      'premium_step_reports_body':
          'See a visual monthly summary and compare trends.',
      'premium_step_reports_tip': 'Tap "Show in app" to see where it lives.',
      'premium_step_goals_title': 'Smart goals',
      'premium_step_goals_body':
          'Goals with clear progress and weekly challenges.',
      'premium_step_goals_tip': 'Tap "Show in app" to open Goals.',
      'premium_step_invest_title': 'Investment calculator',
      'premium_step_invest_body': 'Simulate scenarios and plan long term.',
      'premium_step_invest_tip': 'Tap "Show in app" and try different values.',
      'premium_step_missions_title': 'Premium missions',
      'premium_step_missions_body':
          'Light challenges for daily, weekly, and monthly rhythm.',
      'premium_step_missions_tip': 'Tap "Show in app" to see missions.',
      'premium_step_insights_title': 'Smart insights',
      'premium_step_insights_body':
          'Alerts and tips that guide your next action.',
      'premium_step_insights_tip': 'Tap "Show in app" to open Insights.',
      'premium_tour_calculator_title': 'Investment calculator',
      'premium_tour_calculator_body':
          'Simulate contributions and rates to see future results.',
      'premium_tour_calculator_location':
          'Where it is: Calculator button on the home screen.',
      'premium_tour_calculator_tip': 'Compare 5, 10, and 20-year scenarios.',
      'premium_tour_goals_title': 'Smart goals',
      'premium_tour_goals_body':
          'Your goals appear here with progress and weekly challenges.',
      'premium_tour_goals_location':
          'Where it is: side menu > Goals or Goals button on home.',
      'premium_tour_goals_tip': 'Create a goal and mark progress as you go.',
      'premium_tour_missions_title': 'Premium missions',
      'premium_tour_missions_body':
          'Daily, weekly, and monthly missions to stay consistent.',
      'premium_tour_missions_location': 'Where it is: side menu > Missions.',
      'premium_tour_missions_tip': 'Complete missions and track your XP.',
      'premium_tour_reports_title': 'Premium reports',
      'premium_tour_reports_body':
          'Monthly overview with totals and comparisons.',
      'premium_tour_reports_location': 'Where it is: side menu > Reports.',
      'premium_tour_reports_tip':
          'Switch months at the top to compare periods.',
      'premium_tour_insights_title': 'Insights',
      'premium_tour_insights_body':
          'Alerts and suggestions to balance your spending.',
      'premium_tour_insights_location': 'Where it is: side menu > Insights.',
      'premium_tour_insights_tip':
          'Follow the main focus to improve your month.',
      'close': 'Close',
      'user_label': 'User',
      'security': 'Security',
      'settings': 'Settings',
      'login_required_calculator': 'Sign in to access the calculator.',
      'investment_calculator': 'Investment calculator',
      'investment_premium_title': 'Investment calculator unlocked in Premium',
      'investment_premium_subtitle':
          'Simulate contributions and see real growth with advanced projections.',
      'investment_premium_perk1': 'Projections for 5, 10, and 20 years',
      'investment_premium_perk2': 'Reports with personalized insights',
      'investment_premium_perk3': 'Financial health score',
      'investment_projection_title':
          'Projection with monthly contribution + compound interest',
      'investment_monthly_contribution': 'Monthly contribution (R\$)',
      'investment_annual_rate': 'Annual rate (%)',
      'investment_invalid_inputs':
          'Enter a contribution and a rate greater than zero to see the projection.',
      'investment_disclaimer':
          'Note: this projection is a simulation. Real results vary by market, rates, and taxes.',
      'investment_total_contribution': 'Total contribution',
      'investment_profit': 'Earnings',
      'investment_final_total': 'Final total',
      'example_500': 'Ex: 500',
      'example_12': 'Ex: 12',
      'years_label': '{years} years',
      'new_entry': 'New entry',
      'type': 'Type',
      'name': 'Name',
      'category': 'Category',
      'value_currency': 'Amount (R\$)',
      'due_day_optional': 'Due day (optional)',
      'card_due_day': 'Credit card due date',
      'card_select': 'Credit card',
      'card_due_day_value': 'Statement due day: {day}',
      'card_required': 'Add a credit card first.',
      'no_due_date': 'No due date',
      'day_label': 'Day {n}',
      'credit_card_charge': 'Credit card charge',
      'card_recurring': 'Recurring card purchase',
      'card_recurring_short': 'Recurring',
      'card_paid_badge': 'Statement paid',
      'card_unknown': 'Unknown card',
      'bill_paid': 'Bill paid',
      'card_invoice_paid': 'Card statement paid',
      'installments_quantity': 'Installments quantity',
      'credit_card_bills_title': 'Card statements',
      'card_due_day_label': 'Due day {day}',
      'card_insight_title': 'Card statements this month',
      'card_insight_high':
          'Statements total {value} ({pct}% of income). This may strain your budget.',
      'card_insight_ok':
          'Statements total {value} ({pct}% of income). Within expectations.',
      'expense_tip_fixed':
          'Tip: If you set a due date, Jetx will notify you 3 days before and on the day (when notifications are enabled).',
      'expense_tip_variable':
          'Tip: Variable expenses count only for the current month.',
      'income_variable_tip':
          'Variable income? Use the average of the last 3 months to avoid frustration.',
      'credit_card_tip':
          'Installments affect your future income. Use with care.',
      'expense_high_tip':
          'This expense is {pct}% of your monthly budget. Ideal is up to {ideal}%.',
      'expense_name_required': 'Enter the name.',
      'expense_value_required': 'Enter a valid amount.',
      'installments_required': 'Enter the installments quantity.',
      'expense_type_fixed': 'Fixed expense',
      'expense_type_variable': 'Variable expense',
      'expense_type_investment': 'Investment',
      'expense_category_housing': 'Housing',
      'expense_category_food': 'Food',
      'expense_category_transport': 'Transport',
      'expense_category_education': 'Education',
      'expense_category_health': 'Health',
      'expense_category_leisure': 'Leisure',
      'expense_category_subscriptions': 'Subscriptions',
      'expense_category_investment': 'Investment',
      'expense_category_other': 'Other',
      'mission_complete_title': 'Complete mission',
      'mission_complete_note_label': 'Completion note (optional)',
      'mission_complete_note_hint': 'Describe what you did and how you did it.',
      'mission_note_title': 'Mission note',
      'mission_note_view': 'View note',
      'mission_complete_cta': '+{xp} XP',
      'mission_require_expense_today':
          'Log at least 1 expense today to complete.',
      'mission_require_report_today':
          'Open this monthâ€™s report today to complete.',
      'mission_require_weekly_expenses':
          'Log expenses on at least 3 days this week.',
      'mission_require_previous_month':
          'Have at least one previous month to compare.',
      'mission_require_goal': 'Create at least 1 personal goal to complete.',
      'mission_require_default': 'Complete the activity in the app to finish.',
      'cancel': 'Cancel',
      'back': 'Back',
      'finish': 'Finish',
      'onboarding_objectives_title': 'To start, what are your goals?',
      'onboarding_objectives_subtitle':
          'This helps us suggest goals and missions that fit you better.',
      'onboarding_objectives_required': 'Choose at least one goal.',
      'onboarding_profession_title': 'What is your profession?',
      'onboarding_profession_subtitle':
          'We want to understand your professional moment to personalize your journey.',
      'onboarding_profession_required': 'Enter your profession.',
      'onboarding_income_title': 'What is your monthly income?',
      'onboarding_income_subtitle':
          'With this data, we can build realistic goals for you.',
      'summary_fixed': 'Fixed',
      'summary_variable': 'Variable',
      'summary_invest': 'Invest.',
      'summary_free': 'Free',
      'timeline_more': 'more',
      'timeline_less': 'less',
      'timeline_variable_change':
          'This month you spent {pct}% {direction} on variable expenses.',
      'timeline_fixed_change': 'Fixed expenses were {pct}% {direction}.',
      'timeline_invest_streak':
          'You increased investments for {months} months in a row.',
      'timeline_balanced': 'Your month is balanced. Keep the pace!',
      'score_title': 'Financial score',
      'score_title_month_tips': 'Financial score of the month',
      'score_locked_subtitle': 'See your financial health with smart insights.',
      'score_add_income': 'Add your income to calculate the score.',
      'score_focus_variable': 'Your main focus now: variable expenses.',
      'score_focus_fixed': 'Your main focus now: fixed expenses.',
      'score_focus_invest_low': 'Your main focus now: investments.',
      'score_focus_invest_high': 'Your main focus now: balance investments.',
      'score_focus_balanced': 'Good call: your budget is well balanced.',
      'plan_title': 'Monthly plan',
      'plan_subtitle': 'Quick actions to improve this month.',
      'plan_next_action': 'Next action',
      'plan_action_variable': 'Reduce variable spending to 30% of income.',
      'plan_action_fixed': 'Bring fixed costs down to at most 50% of income.',
      'plan_action_invest': 'Allocate {value} to investments.',
      'plan_action_ok': 'You are balanced. Keep the momentum.',
      'alert_title': 'Smart alerts',
      'alert_add_income': 'Add your income to unlock alerts.',
      'alert_fixed_high': 'Fixed costs are above 55% of income.',
      'alert_variable_high': 'Variable spending is above 35% of income.',
      'alert_invest_low': 'Investments are below target this month.',
      'alert_negative_balance': 'Your monthly balance is negative.',
      'alert_ok': 'All good here. Stay consistent.',
      'tips_title': 'Tips of the month',
      'tip_housing_high':
          'Housing above 35%. Consider options to lower this cost.',
      'compare_title': 'Monthly comparison',
      'compare_no_data': 'No previous month data yet.',
      'insights_title': 'Monthly insights',
      'insights_subtitle': 'Keep all tips and alerts in one place.',
      'insights_card_subtitle': 'Alerts, plan, and comparison in one view.',
      'insights_cta': 'Open',
      'habit_title': 'Money habits',
      'habit_streak': '{days}-day streak',
      'habit_log_expense': 'Log today\'s expenses',
      'habit_log_expense_subtitle': 'Keep your spending updated.',
      'habit_check_budget': 'Review your budget',
      'habit_check_budget_subtitle': 'Make sure you are on plan.',
      'habit_invest': 'Set aside for investing',
      'habit_invest_subtitle': 'Reserve a weekly amount.',
      'month_entries': 'Entries of the month',
      'no_entries_yet': 'No entries yet.',
      'month_salary': 'Monthly salary',
      'goals_title': 'Goals',
      'goals_add_new': 'New goal',
      'goals_title_label': 'Goal title',
      'goals_type_label': 'Type',
      'goals_type_income': 'Income / Career',
      'goals_type_education': 'Education',
      'goals_type_personal': 'Personal',
      'goals_description_optional': 'Description (optional)',
      'goals_title_required': 'Enter a title for the goal.',
      'goals_income_exists': 'This goal already exists for the year.',
      'goals_login_required': 'Sign in to access goals.',
      'goals_subtitle':
          'Track your progress, weekly challenges, and strategic goals.',
      'goals_empty_year': 'No goals registered for this year.',
      'goals_tip_hold_remove':
          'Tip: press and hold a (non-required) goal to remove it.',
      'goals_completed_count': '{done} of {total} goals completed',
      'goals_already_in_list': 'This goal is already in your list.',
      'goals_section_year': 'Goals of the year',
      'goals_premium_title': 'Advanced goals are Premium',
      'goals_premium_perk1': 'Real-time yearly progress',
      'goals_premium_perk2': 'Guided weekly challenges',
      'goals_premium_perk3': 'Smart goals based on your balance',
      'goals_no_month_data': 'No data for the month',
      'goals_month_balance': 'Monthly balance: {value}',
      'save_cloud_error': 'Failed to save in the cloud. Check your connection.',
      'goals_progress_section': 'Your progress',
      'goals_suggestions_section': 'Suggestions for you',
      'goals_weekly_section': 'Weekly challenges',
      'goals_weekly_empty': 'No challenges this week. Come back tomorrow.',
      'goals_year_progress': 'Yearly progress',
      'mandatory': 'Mandatory',
      'goal_action_complete': 'Complete',
      'goal_action_add': 'Add',
      'goal_income_title': 'Increase income',
      'goal_income_desc': 'Create a plan to increase your income this year.',
      'goal_weekly_finance_content_title': 'Watch financial planning content',
      'goal_weekly_finance_content_desc':
          '15 minutes of reading or video to reinforce the basics.',
      'goal_weekly_review_expenses_title': 'Review monthly expenses',
      'goal_weekly_review_expenses_desc':
          'Mark variable expenses and choose 1 adjustment.',
      'goal_weekly_invest_10_title': 'Set aside 10% to invest',
      'goal_weekly_invest_10_desc':
          'Direct part of your balance to investments.',
      'goal_weekly_spend_limit_title': 'Create a weekly spending cap',
      'goal_weekly_spend_limit_desc':
          'Set a limit and track it through Sunday.',
      'goal_weekly_start_finance_book_title': 'Start a finance book',
      'goal_weekly_start_finance_book_desc': 'Read 10 pages and mark as done.',
      'goal_suggest_income_title': 'Add monthly income',
      'goal_suggest_income_desc': 'Add your income to unlock planning.',
      'goal_suggest_reduce_variable_title': 'Reduce variable expenses by 10%',
      'goal_suggest_reduce_variable_desc':
          'Adjust non-essential expenses in the coming weeks.',
      'goal_suggest_invest_title': 'Increase investments',
      'goal_suggest_invest_desc': 'Consistent monthly contribution goal.',
      'goal_suggest_emergency_title': 'Build an emergency fund',
      'goal_suggest_emergency_desc': 'Goal of 3 to 6 months of fixed costs.',
      'goal_suggest_education_title': 'Financial education plan',
      'goal_suggest_education_desc': 'Study 30 min per week.',
      'premium_subtitle_short': 'Unlock exclusive features',
      'timeline_title': 'Timeline',
      'timeline_positive_streak': 'Positive streak',
      'timeline_positive_streak_desc':
          'Investments grew for {months} consecutive months.',
      'timeline_balance_alert': 'Balance alert',
      'timeline_balance_alert_desc':
          'Variables exceeded fixed. Review flexible spending.',
      'timeline_control_ok': 'Control up to date',
      'timeline_control_ok_desc':
          'Fixed are controlled relative to variable spending.',
      'timeline_balanced_month': 'Balanced month',
      'timeline_balanced_month_desc': 'No significant variation detected.',
      'add_extra_income': 'Add extra income',
      'income_label_placeholder': 'Source label',
      'offline_message': 'You are offline. Connect to a network.',
    },
    'es': {
      'profile': 'Perfil',
      'reports': 'Reportes',
      'insights': 'Insights',
      'missions': 'Misiones',
      'dark_theme': 'Tema oscuro',
      'logout': 'Salir',
      'language': 'Idioma',
      'dashboard': 'Tablero',
      'credit_cards_title': 'Tarjetas de crÃ©dito',
      'credit_cards_empty': 'Ninguna tarjeta registrada.',
      'card_add': 'Agregar tarjeta',
      'card_name': 'Nombre de la tarjeta',
      'simulator': 'Simulador',
      'calc_title': 'Simulador de Inversiones',
      'calc_subtitle':
          'Proyecte el futuro de su patrimonio con interÃ©s compuesto.',
      'monthly_contribution': 'Aporte Mensual',
      'annual_rate': 'Tasa Anual (%)',
      'period_years': 'PerÃ­odo (aÃ±os)',
      'calc_disclaimer':
          'SimulaciÃ³n basada en aportes mensuales con capitalizaciÃ³n mensual de intereses.',
      'final_total': 'Total Final',
      'total_invested': 'Total Invertido',
      'profit': 'Rendimiento',
      'equity_evolution': 'EvoluciÃ³n del Patrimonio',
      'total_with_interest': 'Total (con intereses)',
      'invested_capital': 'Capital Invertido',
      'year_label': 'AÃ±o',
      'premium_calc_title': 'Calculadora de Libertad',
      'premium_calc_subtitle':
          'Simula tu camino hacia la independencia financiera con el Plan Premium.',
      'no_entries_found_title': 'No se encontraron lanzamientos',
      'no_entries_found': 'AÃºn no hay registros para este perÃ­odo.',
      'day': 'DÃ­a',
      'card': 'Tarjeta',
      'paid': 'Pagado',
      'edit_entry': 'Editar lanzamiento',
      'delete_entry': 'Eliminar lanzamiento',
      'login': 'Entrar',
      'register': 'Crear cuenta',
      'email': 'Correo',
      'password': 'ContraseÃ±a',
      'forgot_password': 'OlvidÃ© mi contraseÃ±a',
      'missions_month': 'Misiones del mes',
      'missions_week': 'Misiones de la semana',
      'missions_day': 'Misiones del dÃ­a',
      'login_required_missions': 'Inicia sesiÃ³n para ver tus misiones.',
      'onboarding_title': 'Tu primer plan',
      'onboarding_heading': 'Vamos a entender tu objetivo financiero',
      'onboarding_subtitle':
          'Estas respuestas personalizan misiones y desbloqueos. Tus datos se guardan en la nube.',
      'onboarding_objectives': 'Objetivos',
      'onboarding_missing_fields':
          'Completa ingresos, profesiÃ³n y al menos un objetivo.',
      'session_expired_login': 'SesiÃ³n expirada. Inicia sesiÃ³n nuevamente.',
      'save_failed_try_again': 'No fue posible guardar. Intenta de nuevo.',
      'profession': 'ProfesiÃ³n',
      'monthly_income': 'Ingreso mensual (R\$)',
      'continue': 'Continuar',
      'goals': 'Metas',
      'goal': 'Meta',
      'save_goal': 'Guardar Meta',
      'completed_label': 'Completadas',
      'language_pt': 'PortuguÃ©s',
      'language_en': 'InglÃ©s',
      'language_es': 'EspaÃ±ol',
      'mission_type_daily': 'DIARIA',
      'mission_type_weekly': 'SEMANAL',
      'mission_type_monthly': 'MENSUAL',
      'missions_premium_title': 'Misiones exclusivas para Premium',
      'missions_premium_subtitle':
          'Gana XP real y desbloquea niveles con desafÃ­os validados por tu progreso en la app.',
      'missions_premium_perk1': 'Misiones diarias, semanales y mensuales',
      'missions_premium_perk2': 'XP doble y niveles exclusivos',
      'missions_premium_perk3': 'Progreso y desbloqueos premium',
      'mission_daily_review_expense': 'Revisa 1 gasto',
      'mission_daily_tip': 'Ver insights del dÃ­a',
      'mission_daily_emotional_spend': 'Clasifica un gasto emocional',
      'mission_daily_log_expense': 'Registra al menos un gasto hoy',
      'mission_daily_balance_repair':
          'Ajusta gastos para terminar el mes en positivo',
      'mission_daily_variable_reflect':
          'Lista tres gastos variables para revisar',
      'mission_daily_invest_review':
          'Mira tus inversiones y toma una acciÃ³n pequeÃ±a',
      'mission_weekly_budget': 'Registra gastos en 3 dÃ­as de la semana',
      'mission_weekly_leisure': 'Revisa tu ocio de la semana',
      'mission_weekly_no_impulse_7': 'Pasa 7 dÃ­as sin gasto impulsivo',
      'mission_weekly_no_impulse_3': 'Pasa 3 dÃ­as sin gasto impulsivo',
      'mission_weekly_variable_trim':
          'Pon un lÃ­mite mÃ¡s bajo a los gastos variables esta semana',
      'mission_weekly_invest_review':
          'Revisa una inversiÃ³n o dato de la calculadora esta semana',
      'mission_weekly_debt_action':
          'DiseÃ±a un movimiento para pagar deudas pendientes',
      'mission_monthly_close_month': 'Cierra el mes con conciencia',
      'mission_monthly_compare_two': 'Compara dos meses',
      'mission_monthly_review_prev': 'Revisa el mes anterior',
      'mission_monthly_future_plan': 'Ajusta tu plan futuro',
      'mission_monthly_simple_plan': 'Define un plan simple',
      'mission_monthly_balance_repair':
          'Replanifica este mes para cerrar en verde',
      'mission_monthly_variable_trim':
          'Reduce los gastos variables para recuperar margen',
      'mission_monthly_emergency_build': 'Avanza en tu fondo de emergencia',
      'mission_monthly_goal_review': 'Revisa tus metas y ajusta el rumbo',
      'mission_monthly_invest_health':
          'Verifica que tus inversiones sigan tus metas',
      'mission_monthly_debt_clear':
          'Esboza un plan para bajar tu carga de deuda',
      'mission_objective_debts_high': 'Renegocia 1 deuda y registra el plan',
      'mission_objective_debts_low':
          'Lista todas las deudas y costos mensuales',
      'mission_objective_property_high':
          'Simula entrada y cuotas de la vivienda',
      'mission_objective_property_low':
          'Define el valor objetivo de la vivienda',
      'mission_objective_trip_high': 'Crea un fondo de viaje con meta mensual',
      'mission_objective_trip_low': 'Define el costo total del viaje',
      'mission_objective_save_high': 'Automatiza un monto para la reserva',
      'mission_objective_save_low': 'Define un monto mÃ­nimo para ahorrar',
      'mission_objective_security_high': 'Arma 1 mes de reserva de emergencia',
      'mission_objective_security_low': 'Define tu meta de reserva',
      'mission_objective_dream_high': 'Divide tu sueÃ±o en 3 hitos',
      'mission_objective_dream_low': 'Define el plazo del sueÃ±o',
      'mission_objective_invest_high': 'Ajusta tu asignaciÃ³n de inversiones',
      'mission_objective_invest_low':
          'Define cuÃ¡nto quieres invertir en el mes',
      'mission_objective_emergency_fund_high':
          'Verifica 2 meses de gastos en la reserva',
      'mission_objective_emergency_fund_low':
          'Empieza con 1 meta simple de reserva',
      'mission_objective_generic_high':
          'Define 1 acciÃ³n concreta para el objetivo',
      'mission_objective_generic_low': 'Escribe tu objetivo con un plazo',
      'objective_dream': 'Conquistar un sueÃ±o',
      'objective_property': 'Comprar una vivienda',
      'objective_trip': 'Hacer un viaje',
      'objective_debts': 'Salir de deudas',
      'objective_save': 'Ahorrar dinero',
      'objective_security': 'Tener mÃ¡s seguridad',
      'objective_emergency_fund': 'Construir un fondo de emergencia',
      'objective_invest': 'Invertir mejor',
      'login_fill_email_password': 'Completa correo y contraseÃ±a.',
      'error_connect_server': 'Error al conectar con el servidor.',
      'reset_need_email':
          'Ingresa tu correo para recibir el enlace de reinicio.',
      'reset_sent': 'Enviamos un enlace de reinicio a tu correo.',
      'email_not_found': 'Correo no encontrado.',
      'login_invalid_email': 'Correo invÃ¡lido.',
      'no_connection': 'Sin conexiÃ³n a internet.',
      'reset_error_with_code': 'Error al procesar la recuperaciÃ³n: {code}.',
      'reset_title': 'Recuperar contraseÃ±a',
      'reset_subtitle': 'Enviaremos un enlace de reinicio a tu correo.',
      'reset_code_subtitle':
          'Ingresa el cÃ³digo de 5 dÃ­gitos y crea una nueva contraseÃ±a.',
      'reset_send_button': 'Enviar link',
      'reset_send_code_button': 'Enviar cÃ³digo',
      'reset_code_label': 'CÃ³digo de recuperaciÃ³n',
      'reset_code_hint': 'Ingresa el cÃ³digo de 5 nÃºmeros',
      'reset_verify_button': 'Validar cÃ³digo',
      'reset_new_password': 'Nueva contraseÃ±a',
      'reset_new_password_title': 'Nueva contraseÃ±a',
      'reset_new_password_subtitle':
          'Define tu nueva contraseÃ±a para acceder a la cuenta.',
      'reset_confirm_password': 'Confirmar nueva contraseÃ±a',
      'reset_password_mismatch': 'Las contraseÃ±as no coinciden.',
      'reset_confirm_button': 'Guardar nueva contraseÃ±a',
      'reset_confirmed': 'ContraseÃ±a actualizada.',
      'reset_code_sent':
          'Si este correo existe, enviamos un cÃ³digo de 5 dÃ­gitos. Expira en 5 minutos.',
      'reset_code_invalid': 'CÃ³digo invÃ¡lido. Usa 5 nÃºmeros.',
      'reset_code_expires_in': 'El cÃ³digo expira en {time}.',
      'reset_code_expired': 'CÃ³digo expirado. EnvÃ­a un nuevo cÃ³digo.',
      'reset_resend_button': 'Reenviar link',
      'reset_resend_code_button': 'Reenviar cÃ³digo',
      'reset_resend_button_timer': 'Reenviar en {time}',
      'reset_resend_wait': 'Espera 60 segundos para reenviar.',
      'reset_rate_limited': 'Demasiados intentos. Intenta mÃ¡s tarde.',
      'login_google_not_ready':
          'El inicio con Google aun no esta configurado. En Firebase, configura Android (SHA-1 + google-services.json) e iOS (GoogleService-Info.plist + URL Scheme REVERSED_CLIENT_ID).',
      'login_apple_not_ready': 'El inicio con Apple aÃºn no estÃ¡ configurado.',
      'login_cancelled': 'Inicio de sesion cancelado.',
      'login_google': 'Entrar con Google',
      'login_apple': 'Entrar con Apple',
      'register_action': 'Registrarse',
      'register_required_fields': 'Completa todos los campos obligatorios.',
      'register_password_mismatch': 'Las contraseÃ±as no coinciden.',
      'register_terms_required': 'Debes aceptar los tÃ©rminos para continuar.',
      'register_email_in_use': 'Este correo ya estÃ¡ en uso.',
      'register_invalid_email': 'Correo invÃ¡lido.',
      'register_weak_password':
          'ContraseÃ±a muy dÃ©bil. Usa al menos 8 caracteres con mayÃºscula, minÃºscula, nÃºmero y carÃ¡cter especial.',
      'register_email_not_enabled':
          'El registro por correo no estÃ¡ habilitado en Firebase.',
      'register_error_with_code': 'Error al crear la cuenta: {code}.',
      'register_success': 'Cuenta creada! Ahora inicia sesiÃ³n.',
      'first_name': 'Nombre',
      'profile_property_value': 'Valor aproximado de inmuebles',
      'profile_invest_balance': 'Saldo total en inversiones',
      'wealth_info_title': 'Patrimonio e Inversiones',
      'last_name': 'Apellido',
      'birth_date': 'Fecha de nacimiento',
      'gender': 'Sexo',
      'confirm_password': 'Confirmar contraseÃ±a',
      'register_terms_text':
          'Acepto los tÃ©rminos de uso y autorizo el almacenamiento en lÃ­nea de mis datos.',
      'gender_not_informed': 'No informado',
      'gender_male': 'Masculino',
      'gender_female': 'Femenino',
      'gender_other': 'Otro',
      'login_invalid_credentials': 'Correo o contraseÃ±a incorrectos.',
      'profile_no_user':
          'NingÃºn usuario encontrado. RegÃ­strate o inicia sesiÃ³n.',
      'profile_required_fields': 'Completa los campos obligatorios.',
      'profile_invalid_income': 'Ingresa un ingreso mensual vÃ¡lido.',
      'profile_photo_upload_error': 'Error al subir la foto.',
      'profile_updated': 'Perfil actualizado.',
      'profile_no_user_body':
          'NingÃºn usuario encontrado.\nCrea una cuenta e inicia sesiÃ³n.',
      'save': 'Guardar',
      'profile_change_photo': 'Cambiar foto',
      'select': 'Seleccionar',
      'login_blocked': 'Acceso bloqueado. Contacta a: contato@voolo.com',
      'login_failed_try_again': 'No se pudo iniciar sesiÃ³n. Intenta de nuevo.',
      'unknown_route_title': 'Ruta no encontrada',
      'unknown_route_body':
          'La ruta "{route}" no existe.\nRevisa AppRoutes y tus Navigator.pushNamed().',
      'premium_cta': 'Hazte Premium',
      'premium_badge': 'Premium',
      'premium_dialog_title': 'Hazte Premium',
      'premium_dialog_body':
          'Desbloquea misiones, informes inteligentes, calculadora de inversiones y alertas de pagos.\n\nContÃ¡ctanos para activar Premium.',
      'premium_upsell_title': 'MÃ¡s control, mÃ¡s claridad, mÃ¡s resultados',
      'premium_welcome_title': 'Premium activado!',
      'premium_welcome_body':
          'Excelente elecciÃ³n con Voolo. Te deseamos claridad, control y calma financiera.',
      'premium_welcome_tip':
          'Â¿Quieres un recorrido guiado? Te muestro cada funciÃ³n en su lugar.',
      'premium_welcome_yes': 'Quiero onboarding',
      'premium_welcome_no': 'Ahora no',
      'premium_onboarding_title': 'Bienvenido a Premium',
      'premium_onboarding_subtitle':
          'Hagamos un recorrido por la app y veamos cada funciÃ³n en acciÃ³n.',
      'premium_onboarding_next': 'Siguiente',
      'premium_onboarding_finish': 'Finalizar',
      'premium_onboarding_skip': 'Saltar',
      'premium_onboarding_open': 'Mostrar en la app',
      'premium_onboarding_progress': '{done} de {total} pasos completados',
      'premium_insights_title': 'AnÃ¡lisis de Ã‰lite',
      'premium_insights_subtitle':
          'Desbloquea insights avanzados y alertas inteligentes para potenciar tu evoluciÃ³n financiera.',
      'premium_step_reports_title': 'Reportes premium',
      'premium_step_reports_body':
          'Resumen visual del mes y comparativos claros.',
      'premium_step_reports_tip':
          'Toca "Mostrar en la app" para ver dÃ³nde estÃ¡.',
      'premium_step_goals_title': 'Metas inteligentes',
      'premium_step_goals_body':
          'Metas con progreso claro y desafÃ­os semanales.',
      'premium_step_goals_tip': 'Toca "Mostrar en la app" para abrir Metas.',
      'premium_step_invest_title': 'Calculadora de inversiones',
      'premium_step_invest_body':
          'Simula escenarios y planifica a largo plazo.',
      'premium_step_invest_tip': 'Toca "Mostrar en la app" y prueba valores.',
      'premium_step_missions_title': 'Misiones premium',
      'premium_step_missions_body': 'DesafÃ­os diarios, semanales y mensuales.',
      'premium_step_missions_tip':
          'Toca "Mostrar en la app" para ver misiones.',
      'premium_step_insights_title': 'Insights inteligentes',
      'premium_step_insights_body':
          'Alertas y consejos para tu prÃ³xima acciÃ³n.',
      'premium_step_insights_tip':
          'Toca "Mostrar en la app" para abrir Insights.',
      'premium_tour_calculator_title': 'Calculadora de inversiones',
      'premium_tour_calculator_body':
          'Simula aportes y tasa para ver resultados futuros.',
      'premium_tour_calculator_location':
          'DÃ³nde estÃ¡: botÃ³n Calculadora en la pantalla principal.',
      'premium_tour_calculator_tip': 'Compara escenarios de 5, 10 y 20 aÃ±os.',
      'premium_tour_goals_title': 'Metas inteligentes',
      'premium_tour_goals_body':
          'Tus metas aparecen aquÃ­ con progreso y desafÃ­os semanales.',
      'premium_tour_goals_location':
          'DÃ³nde estÃ¡: menÃº lateral > Metas o botÃ³n Metas en home.',
      'premium_tour_goals_tip': 'Crea una meta y marca el avance.',
      'premium_tour_missions_title': 'Misiones premium',
      'premium_tour_missions_body':
          'Misiones diarias, semanales y mensuales para mantener constancia.',
      'premium_tour_missions_location':
          'DÃ³nde estÃ¡: menÃº lateral > Misiones.',
      'premium_tour_missions_tip': 'Completa misiones y sigue tu XP.',
      'premium_tour_reports_title': 'Reportes premium',
      'premium_tour_reports_body':
          'Resumen mensual con totales y comparativos.',
      'premium_tour_reports_location':
          'DÃ³nde estÃ¡: menÃº lateral > Reportes.',
      'premium_tour_reports_tip':
          'Cambia el mes arriba para comparar periodos.',
      'premium_tour_insights_title': 'Insights',
      'premium_tour_insights_body':
          'Alertas y sugerencias para equilibrar tus gastos.',
      'premium_tour_insights_location':
          'DÃ³nde estÃ¡: menÃº lateral > Insights.',
      'premium_tour_insights_tip': 'Sigue el foco principal y mejora tu mes.',
      'close': 'Cerrar',
      'user_label': 'Usuario',
      'security': 'Seguridad',
      'settings': 'Configuraciones',
      'login_required_calculator':
          'Inicia sesiÃ³n para acceder a la calculadora.',
      'investment_calculator': 'Calculadora de inversiones',
      'investment_premium_title':
          'Calculadora de inversiones desbloqueada en Premium',
      'investment_premium_subtitle':
          'Simula aportes y ve el crecimiento real con proyecciones avanzadas.',
      'investment_premium_perk1': 'Proyecciones de 5, 10 y 20 aÃ±os',
      'investment_premium_perk2': 'Informes con insights personalizados',
      'investment_premium_perk3': 'Puntaje de salud financiera',
      'investment_projection_title':
          'ProyecciÃ³n con aporte mensual + interÃ©s compuesto',
      'investment_monthly_contribution': 'Aporte mensual (R\$)',
      'investment_annual_rate': 'Tasa anual (%)',
      'investment_invalid_inputs':
          'Ingresa un aporte y una tasa mayores que cero para ver la proyecciÃ³n.',
      'investment_disclaimer':
          'Nota: esta proyecciÃ³n es una simulaciÃ³n. Los resultados reales varÃ­an segÃºn mercado, tasas e impuestos.',
      'investment_total_contribution': 'Aporte total',
      'investment_profit': 'Rendimiento',
      'investment_final_total': 'Total final',
      'example_500': 'Ej: 500',
      'example_12': 'Ej: 12',
      'years_label': '{years} aÃ±os',
      'new_entry': 'Nuevo lanzamiento',
      'type': 'Tipo',
      'name': 'Nombre',
      'category': 'CategorÃ­a',
      'value_currency': 'Valor (R\$)',
      'due_day_optional': 'DÃ­a de vencimiento (opcional)',
      'card_due_day': 'Vencimiento de la tarjeta',
      'card_select': 'Tarjeta de crÃ©dito',
      'card_due_day_value': 'Vencimiento de la tarjeta: dÃ­a {day}',
      'card_required': 'Registra una tarjeta primero.',
      'no_due_date': 'Sin vencimiento',
      'day_label': 'DÃ­a {n}',
      'credit_card_charge': 'Cargo en tarjeta de crÃ©dito',
      'card_recurring': 'Compra recurrente en la tarjeta',
      'card_recurring_short': 'Recurrente',
      'card_paid_badge': 'Factura pagada',
      'card_unknown': 'Tarjeta desconocida',
      'bill_paid': 'Cuenta pagada',
      'card_invoice_paid': 'Factura de la tarjeta pagada',
      'installments_quantity': 'Cantidad de cuotas',
      'credit_card_bills_title': 'Facturas de la tarjeta',
      'card_due_day_label': 'Vencimiento dÃ­a {day}',
      'card_insight_title': 'Facturas de la tarjeta en el mes',
      'card_insight_high':
          'Las facturas suman {value} ({pct}% del ingreso). Esto puede afectar tu presupuesto.',
      'card_insight_ok':
          'Las facturas suman {value} ({pct}% del ingreso). Dentro de lo esperado.',
      'expense_tip_fixed':
          'Consejo: Si completas el vencimiento, Jetx avisarÃ¡ 3 dÃ­as antes y el dÃ­a (cuando activemos notificaciones).',
      'expense_tip_variable':
          'Consejo: Gastos variables cuentan solo en el mes actual.',
      'income_variable_tip':
          'Â¿Ingreso variable? Usa el promedio de los Ãºltimos 3 meses para evitar frustraciones.',
      'credit_card_tip':
          'Las cuotas comprometen tu ingreso futuro. Ãšsalas con cuidado.',
      'expense_high_tip':
          'Este gasto representa {pct}% de tu presupuesto mensal. Lo ideal es hasta {ideal}%.',
      'expense_name_required': 'Escribe el nombre.',
      'expense_value_required': 'Escribe un valor vÃ¡lido.',
      'installments_required': 'Informa la cantidad de cuotas.',
      'expense_type_fixed': 'Gasto fijo',
      'expense_type_variable': 'Gasto variable',
      'expense_type_investment': 'InversiÃ³n',
      'expense_category_housing': 'Vivienda',
      'expense_category_food': 'AlimentaciÃ³n',
      'expense_category_transport': 'Transporte',
      'expense_category_education': 'EducaciÃ³n',
      'expense_category_health': 'Salud',
      'expense_category_leisure': 'Ocio',
      'expense_category_subscriptions': 'Suscripciones',
      'expense_category_investment': 'Inversion',
      'expense_category_other': 'Otros',
      'mission_complete_title': 'Completar misiÃ³n',
      'mission_complete_note_label': 'Comentario de finalizaciÃ³n (opcional)',
      'mission_complete_note_hint': 'Cuenta quÃ© hiciste y cÃ³mo lo hiciste.',
      'mission_note_title': 'Comentario de la misiÃ³n',
      'mission_note_view': 'Ver comentario',
      'mission_complete_cta': '+{xp} XP',
      'mission_require_expense_today':
          'Registra al menos 1 gasto hoy para completar.',
      'mission_require_report_today':
          'Abre el reporte de este mes hoy para completar.',
      'mission_require_weekly_expenses':
          'Registra gastos en al menos 3 dÃ­as de la semana.',
      'mission_require_previous_month':
          'Ten al menos un mes anterior para comparar.',
      'mission_require_goal': 'Crea al menos 1 meta personal para completar.',
      'mission_require_default':
          'Completa la actividad en la app para finalizar.',
      'cancel': 'Cancelar',
      'back': 'AtrÃ¡s',
      'finish': 'Finalizar',
      'onboarding_objectives_title':
          'Para empezar, Â¿cuÃ¡les son tus objetivos?',
      'onboarding_objectives_subtitle':
          'Esto nos ayuda a sugerir metas y misiones mÃ¡s alineadas contigo.',
      'onboarding_objectives_required': 'Elige al menos un objetivo.',
      'onboarding_profession_title': 'Â¿CuÃ¡l es tu profesiÃ³n?',
      'onboarding_profession_subtitle':
          'Queremos entender tu momento profesional para personalizar tu camino.',
      'onboarding_profession_required': 'Ingresa tu profesiÃ³n.',
      'onboarding_income_title': 'Â¿CuÃ¡l es tu ingreso mensual?',
      'onboarding_income_subtitle':
          'Con este dato, podemos crear metas realistas para ti.',
      'summary_fixed': 'Fijos',
      'summary_variable': 'Variables',
      'summary_invest': 'Inver.',
      'summary_free': 'Libre',
      'timeline_more': 'menos',
      'timeline_less': 'menos',
      'timeline_variable_change':
          'Este mes gastaste {pct}% {direction} en variables.',
      'timeline_fixed_change':
          'Los gastos fijos estuvieron {pct}% {direction}.',
      'timeline_invest_streak':
          'Aumentaste tus inversiones por {months} meses seguidos.',
      'timeline_balanced': 'Tu mes estÃ¡ equilibrado. Â¡Mantente asÃ­!',
      'score_title': 'Puntaje financiero',
      'score_title_month_tips': 'Puntaje financiero del mes',
      'score_locked_subtitle':
          'Ve tu salud financiera con insights inteligentes.',
      'score_add_income': 'Registra tu ingreso para calcular el puntaje.',
      'score_focus_variable': 'Tu foco ahora: gastos variables.',
      'score_focus_fixed': 'Tu foco ahora: gastos fijos.',
      'score_focus_invest_low': 'Tu foco ahora: inversiones.',
      'score_focus_invest_high': 'Tu foco ahora: equilibrar inversiones.',
      'score_focus_balanced':
          'Buena decisiÃ³n: tu presupuesto estÃ¡ equilibrado.',
      'plan_title': 'Plan del mes',
      'plan_subtitle': 'Acciones rÃ¡pidas para mejorar este mes.',
      'plan_next_action': 'PrÃ³xima acciÃ³n',
      'plan_action_variable': 'Reduce gastos variables al 30% del ingreso.',
      'plan_action_fixed':
          'Baja los gastos fijos a un mÃ¡ximo de 50% del ingreso.',
      'plan_action_invest': 'Destina {value} a inversiones.',
      'plan_action_ok': 'EstÃ¡s equilibrado. Mantente asÃ­.',
      'alert_title': 'Alertas inteligentes',
      'alert_add_income': 'Registra tu ingreso para activar alertas.',
      'alert_fixed_high': 'Gastos fijos por encima de 55% del ingreso.',
      'alert_variable_high': 'Gastos variables por encima de 35% del ingreso.',
      'alert_invest_low': 'Inversiones por debajo del ideal este mes.',
      'alert_negative_balance': 'Tu saldo del mes es negativo.',
      'alert_ok': 'Todo bien por aquÃ­. Sigue constante.',
      'tips_title': 'Consejos del mes',
      'tip_housing_high':
          'Vivienda por encima de 35%. Considera opciones para reducir este costo.',
      'compare_title': 'Comparativo mensual',
      'compare_no_data': 'AÃºn no hay datos del mes anterior.',
      'insights_title': 'Insights del mes',
      'insights_subtitle': 'Centraliza consejos y alertas aquÃ­.',
      'insights_card_subtitle': 'Alertas, plan y comparativo en un solo lugar.',
      'insights_cta': 'Abrir',
      'habit_title': 'HÃ¡bitos financieros',
      'habit_streak': 'Racha {days} dÃ­as',
      'habit_log_expense': 'Registrar gastos del dÃ­a',
      'habit_log_expense_subtitle': 'MantÃ©n tus gastos al dÃ­a.',
      'habit_check_budget': 'Revisar el presupuesto',
      'habit_check_budget_subtitle': 'Confirma si estÃ¡s en el plan.',
      'habit_invest': 'Separar para invertir',
      'habit_invest_subtitle': 'Reserva un valor semanal.',
      'month_entries': 'Lanzamientos del mes',
      'no_entries_yet': 'AÃºn no hay lanzamientos.',
      'month_salary': 'Salario del mes',
      'goals_title': 'Metas',
      'goals_add_new': 'Nueva meta',
      'goals_title_label': 'TÃ­tulo de la meta',
      'goals_type_label': 'Tipo',
      'goals_type_income': 'Ingreso / Carrera',
      'goals_type_education': 'EducaciÃ³n',
      'goals_type_personal': 'Personal',
      'goals_description_optional': 'DescripciÃ³n (opcional)',
      'goals_title_required': 'Escribe un tÃ­tulo para la meta.',
      'goals_income_exists': 'Esta meta ya existe como obligatoria del aÃ±o.',
      'goals_login_required': 'Inicia sesiÃ³n para acceder a metas.',
      'goals_subtitle':
          'Sigue tu progreso, desafÃ­os semanales y objetivos estratÃ©gicos.',
      'goals_empty_year': 'Ninguna meta registrada para este aÃ±o.',
      'goals_tip_hold_remove':
          'Consejo: mantÃ©n presionada una meta (no obligatoria) para eliminarla.',
      'goals_completed_count': '{done} de {total} metas completadas',
      'goals_already_in_list': 'Esta meta ya estÃ¡ en tu lista.',
      'goals_section_year': 'Metas del aÃ±o',
      'goals_premium_title': 'Metas avanzadas son Premium',
      'goals_premium_perk1': 'Progreso anual en tiempo real',
      'goals_premium_perk2': 'DesafÃ­os semanales guiados',
      'goals_premium_perk3': 'Metas inteligentes basadas en tu saldo',
      'goals_no_month_data': 'Sin datos del mes',
      'goals_month_balance': 'Saldo del mes: {value}',
      'save_cloud_error': 'Fallo al guardar en la nube. Verifica tu conexiÃ³n.',
      'goals_progress_section': 'Tu progreso',
      'goals_suggestions_section': 'Sugerencias para ti',
      'goals_weekly_section': 'DesafÃ­os de la semana',
      'goals_weekly_empty': 'Sin desafÃ­os esta semana. Vuelve maÃ±ana.',
      'goals_year_progress': 'Progreso anual',
      'mandatory': 'Obligatoria',
      'goal_action_complete': 'Completar',
      'goal_action_add': 'Agregar',
      'goal_income_title': 'Aumentar ingresos',
      'goal_income_desc': 'Crea un plan para aumentar tus ingresos este aÃ±o.',
      'goal_weekly_finance_content_title':
          'Ver contenido sobre planificaciÃ³n financiera',
      'goal_weekly_finance_content_desc':
          '15 minutos de lectura o video para reforzar lo bÃ¡sico.',
      'goal_weekly_review_expenses_title': 'Revisar gastos del mes',
      'goal_weekly_review_expenses_desc':
          'Marca gastos variables y elige 1 ajuste.',
      'goal_weekly_invest_10_title': 'Separar 10% para invertir',
      'goal_weekly_invest_10_desc': 'Dirige una parte del saldo a inversiones.',
      'goal_weekly_spend_limit_title': 'Crear un techo semanal de gastos',
      'goal_weekly_spend_limit_desc':
          'Define un lÃ­mite y acompÃ¡Ã±alo hasta el domingo.',
      'goal_weekly_start_finance_book_title': 'Empezar un libro de finanzas',
      'goal_weekly_start_finance_book_desc':
          'Lee 10 pÃ¡ginas y marca como hecho.',
      'goal_suggest_income_title': 'Registrar ingreso mensual',
      'goal_suggest_income_desc':
          'Agrega tu ingreso para desbloquear la planificaciÃ³n.',
      'goal_suggest_reduce_variable_title': 'Reducir 10% en variables',
      'goal_suggest_reduce_variable_desc':
          'Ajusta gastos no esenciales en las prÃ³ximas semanas.',
      'goal_suggest_invest_title': 'Aumentar inversiones',
      'goal_suggest_invest_desc': 'Meta de aporte mensual consistente.',
      'goal_suggest_emergency_title': 'Armar fondo de emergencia',
      'goal_suggest_emergency_desc': 'Objetivo de 3 a 6 meses de costo fijo.',
      'goal_suggest_education_title': 'Plan de educaciÃ³n financiera',
      'goal_suggest_education_desc': 'Estudiar 30 min por semana.',
      'premium_subtitle_short': 'Desbloquea funciones exclusivas',
      'timeline_title': 'LÃ­nea de tiempo',
      'timeline_positive_streak': 'Racha positiva',
      'timeline_positive_streak_desc':
          'Las inversiones crecieron durante {months} meses consecutivos.',
      'timeline_balance_alert': 'Alerta de equilibrio',
      'timeline_balance_alert_desc':
          'Las variables superaron a las fijas. Revisa los gastos flexibles.',
      'timeline_control_ok': 'Control al dÃ­a',
      'timeline_control_ok_desc':
          'Los fijos estÃ¡n controlados en relaciÃ³n a los gastos variables.',
      'timeline_balanced_month': 'Mes equilibrado',
      'timeline_balanced_month_desc':
          'No se detectÃ³ ninguna variaciÃ³n relevante.',
      'add_extra_income': 'Agregar ingreso extra',
      'income_label_placeholder': 'Nombre de la fuente',
      'offline_message': 'EstÃ¡s desconectado. ConÃ©ctate a una red.',
    }
  };

  static bool _looksMojibake(String value) {
    // Common UTF-8-as-Latin1 artifacts (mojibake) seen in this codebase:
    // "RelatÃƒÂ³rios", "MissÃƒÂµes", "aÃƒÂ§ÃƒÂµes", "Ã¢â€°Â¥", etc.
    return value.contains('Ãƒ') ||
        value.contains('Ã‚') ||
        value.contains('Ã¢') ||
        value.contains('ï¿½');
  }

  static const Map<int, int> _cp1252ToByte = {
    0x20AC: 0x80, // â‚¬
    0x201A: 0x82, // â€š
    0x0192: 0x83, // Æ’
    0x201E: 0x84, // â€ž
    0x2026: 0x85, // â€¦
    0x2020: 0x86, // â€
    0x2021: 0x87, // â€¡
    0x02C6: 0x88, // Ë†
    0x2030: 0x89, // â€°
    0x0160: 0x8A, // Å
    0x2039: 0x8B, // â€¹
    0x0152: 0x8C, // Å’
    0x017D: 0x8E, // Å½
    0x2018: 0x91, // â€˜
    0x2019: 0x92, // â€™
    0x201C: 0x93, // â€œ
    0x201D: 0x94, // â€
    0x2022: 0x95, // â€¢
    0x2013: 0x96, // â€“
    0x2014: 0x97, // â€”
    0x02DC: 0x98, // Ëœ
    0x2122: 0x99, // â„¢
    0x0161: 0x9A, // Å¡
    0x203A: 0x9B, // â€º
    0x0153: 0x9C, // Å“
    0x017E: 0x9E, // Å¾
    0x0178: 0x9F, // Å¸
  };

  static List<int>? _encodeWindows1252(String value) {
    final bytes = <int>[];
    for (final rune in value.runes) {
      if (rune <= 0xFF) {
        bytes.add(rune);
        continue;
      }
      final mapped = _cp1252ToByte[rune];
      if (mapped == null) return null;
      bytes.add(mapped);
    }
    return bytes;
  }

  static String _fixEncodingIfNeeded(String value) {
    if (!_looksMojibake(value)) return value;
    try {
      return utf8.decode(latin1.encode(value));
    } catch (_) {
      try {
        final bytes = _encodeWindows1252(value);
        if (bytes == null) return value;
        return utf8.decode(bytes);
      } catch (_) {
        return value;
      }
    }
  }

  static String t(BuildContext context, String key) {
    final code = Localizations.localeOf(context).languageCode;
    final raw = _values[code]?[key] ?? _values['pt']?[key] ?? key;
    final extra = appStringsExtra[code]?[key] ?? appStringsExtra['pt']?[key];
    return _fixEncodingIfNeeded(raw == key && extra != null ? extra : raw);
  }

  static String tr(BuildContext context, String key, Map<String, String> vars) {
    var value = t(context, key);
    vars.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
  }
}
