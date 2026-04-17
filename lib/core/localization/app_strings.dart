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
      'reports': 'Relatórios',
      'insights': 'Insights',
      'missions': 'Missões',
      'dark_theme': 'Tema escuro',
      'logout': 'Sair',
      'simulator': 'Simulador',
      'calc_title': 'Simulador de Investimentos',
      'calc_subtitle':
          'Projete o futuro do seu patrimônio com juros compostos.',
      'monthly_contribution': 'Aporte Mensal (R\$)',
      'annual_rate': 'Taxa Anual (%)',
      'period_years': 'Período (anos)',
      'calc_disclaimer':
          'Simulação baseada em aportes mensais com capitalização mensal de juros.',
      'final_total': 'Total Final',
      'total_invested': 'Total Investido',
      'profit': 'Rendimento',
      'equity_evolution': 'Evolução do Patrimônio',
      'total_with_interest': 'Total (com juros)',
      'invested_capital': 'Capital Investido',
      'year_label': 'Ano',
      'premium_calc_title': 'Calculadora de Liberdade',
      'premium_calc_subtitle':
          'Simule sua jornada rumo à independência financeira com o Plano Premium.',
      'no_entries_found_title':
          'Nenhum lançamento encontrado para este período.',
      'no_entries_found':
          'Comece a organizar suas finanças adicionando um novo lançamento hoje.',
      'day': 'Dia',
      'card': 'Cartão',
      'paid': 'Pago',
      'edit_entry': 'Editar lançamento',
      'delete_entry': 'Remover lançamento',
      'language': 'Idioma',
      'dashboard': 'Dashboard',
      'goals': 'Metas',
      'goal': 'Meta',
      'save_goal': 'Salvar Meta',
      'completed_label': 'Concluídas',
      'credit_cards_title': 'Cartões de crédito',
      'credit_cards_empty': 'Nenhum cartão cadastrado.',
      'card_add': 'Adicionar cartão',
      'card_name': 'Nome do cartão',
      'login': 'Entrar',
      'register': 'Criar conta',
      'email': 'E-mail',
      'password': 'Senha',
      'forgot_password': 'Esqueci minha senha',
      'missions_month': 'Missões do mês',
      'missions_week': 'Missões da semana',
      'missions_day': 'Missões do dia',
      'login_required_missions': 'Faça login para ver suas missões.',
      'onboarding_title': 'Seu primeiro plano',
      'onboarding_heading': 'Vamos entender seu objetivo financeiro',
      'onboarding_subtitle':
          'Essas respostas personalizam missões e desbloqueios. Seus dados ficam salvos na nuvem.',
      'onboarding_objectives': 'Objetivos',
      'onboarding_missing_fields':
          'Preencha renda, profissão e pelo menos um objetivo.',
      'session_expired_login': 'Sessão expirada. Faça login novamente.',
      'save_failed_try_again': 'Não foi possível salvar. Tente novamente.',
      'profession': 'Profissão',
      'onboarding_primary_income_label': 'Entrada principal',
      'onboarding_income_fallback_label': 'Renda {n}',
      'monthly_income': 'Entradas mensais (R\$)',
      'continue': 'Continuar',
      'language_pt': 'Português',
      'language_en': 'Inglês',
      'language_es': 'Espanhol',
      'mission_type_daily': 'DIÁRIA',
      'mission_type_weekly': 'SEMANAL',
      'mission_type_monthly': 'MENSAL',
      'missions_premium_title': 'Missões exclusivas para Premium',
      'missions_premium_subtitle':
          'Ganhe XP real e desbloqueie níveis com desafios validados pelo seu progresso no app.',
      'missions_premium_perk1': 'Missões diárias, semanais e mensais',
      'missions_premium_perk2': 'XP dobrado e níveis exclusivos',
      'missions_premium_perk3': 'Progresso e desbloqueios premium',
      'mission_daily_review_expense': 'Revise 1 gasto',
      'mission_desc_daily_review_expense':
          'Abra um gasto recente e verifique se o valor e a categoria estão corretos.',
      'mission_daily_tip': 'Veja insights do dia',
      'mission_desc_daily_tip':
          'Abra a aba de Insights ou Relatórios para ver as dicas do dia.',
      'mission_daily_emotional_spend': 'Classifique um gasto emocional',
      'mission_desc_daily_emotional_spend':
          'Identifique um gasto que foi feito por impulso ou emoção e marque-o.',
      'mission_daily_log_expense': 'Registre um gasto hoje',
      'mission_desc_daily_log_expense':
          'Adicione qualquer despesa (fixa ou variável) que você fez hoje.',
      'mission_daily_balance_repair':
          'Alinhe gastos para fechar o mês no positivo',
      'mission_desc_daily_balance_repair':
          'Revise seus gastos planejados e faça ajustes para garantir saldo positivo.',
      'mission_daily_variable_reflect': 'Liste 3 gastos variáveis para revisar',
      'mission_desc_daily_variable_reflect':
          'Olhe seus gastos variáveis recentes e veja onde pode economizar.',
      'mission_daily_invest_review':
          'Confira seus investimentos e tome uma ação',
      'mission_desc_daily_invest_review':
          'Acesse sua área de investimentos ou calculadora para verificar seu progresso.',
      'mission_weekly_budget': 'Registre gastos em 3 dias da semana',
      'mission_desc_weekly_budget':
          'Mantenha a consistência registrando gastos em pelo menos 3 dias diferentes desta semana.',
      'mission_weekly_leisure': 'Revise seu lazer da semana',
      'mission_desc_weekly_leisure':
          'Analise quanto você gastou com lazer e veja se está dentro do planejado.',
      'mission_weekly_no_impulse_7': 'Fique 7 dias sem gasto impulsivo',
      'mission_desc_weekly_no_impulse_7':
          'Evite compras não planejadas por uma semana inteira.',
      'mission_weekly_no_impulse_3': 'Fique 3 dias sem gasto impulsivo',
      'mission_desc_weekly_no_impulse_3':
          'Evite compras não planejadas por 3 dias consecutivos.',
      'mission_weekly_variable_trim':
          'Defina um limite para gastos variáveis nesta semana',
      'mission_desc_weekly_variable_trim':
          'Estabeleça um teto para gastos como alimentação e transporte esta semana.',
      'mission_weekly_invest_review':
          'Revise uma aplicação ou insight da calculadora nesta semana',
      'mission_desc_weekly_invest_review':
          'Dedique um tempo para entender melhor seus investimentos ou simular cenários.',
      'mission_weekly_debt_action':
          'Trace um movimento para reduzir dívidas pendentes',
      'mission_desc_weekly_debt_action':
          'Planeje um pagamento extra ou renegociação de uma dívida.',
      'mission_monthly_close_month': 'Feche o mês conscientemente',
      'mission_desc_monthly_close_month':
          'Revise todo o mês que passou, categorize tudo e veja o saldo final.',
      'mission_monthly_compare_two': 'Compare dois meses',
      'mission_desc_monthly_compare_two':
          'Use a ferramenta de comparação para ver sua evolução entre dois meses.',
      'mission_monthly_review_prev': 'Revise o mês anterior',
      'mission_desc_monthly_review_prev':
          'Olhe para o mês passado para entender seus padrões de gastos.',
      'mission_monthly_future_plan': 'Ajuste seu plano futuro',
      'mission_desc_monthly_future_plan':
          'Com base no mês atual, ajuste suas previsões para os próximos meses.',
      'mission_monthly_simple_plan': 'Defina um plano simples',
      'mission_desc_monthly_simple_plan':
          'Crie uma meta básica de economia ou limite de gastos para o mês.',
      'mission_monthly_balance_repair': 'Replaneje este mês para sair no verde',
      'mission_desc_monthly_balance_repair':
          'Faça cortes necessários agora para terminar o mês com saldo positivo.',
      'mission_monthly_variable_trim':
          'Reduza gastos variáveis para recuperar margem',
      'mission_desc_monthly_variable_trim':
          'Identifique onde cortar supérfluos para aumentar sua sobra mensal.',
      'mission_monthly_emergency_build': 'Avance na reserva de emergência',
      'mission_desc_monthly_emergency_build':
          'Guarde qualquer valor, por menor que seja, na sua reserva de emergência.',
      'mission_monthly_goal_review': 'Reveja suas metas e ajuste o plano',
      'mission_desc_monthly_goal_review':
          'Verifique o progresso das suas metas e ajuste os prazos ou valores se necessário.',
      'mission_monthly_invest_health':
          'Cheque se seus investimentos acompanham seus objetivos',
      'mission_desc_monthly_invest_health':
          'Garanta que sua carteira de investimentos está alinhada com seus sonhos.',
      'mission_monthly_debt_clear':
          'Esboce um plano para diminuir sua carga de dívida',
      'mission_desc_monthly_debt_clear':
          'Crie uma estratégia para pagar suas dívidas mais rápido.',
      'mission_objective_debts_high': 'Renegocie 1 dívida e registre o plano',
      'mission_objective_debts_low': 'Liste todas as dívidas e custos mensais',
      'mission_objective_property_high': 'imule entrada e parcelas do imóvel',
      'mission_objective_property_low': 'Defina o valor-alvo do imóvel',
      'mission_objective_trip_high': 'Crie um fundo da viagem com meta mensal',
      'mission_objective_trip_low': 'Defina o custo total da viagem',
      'mission_objective_save_high': 'Automatize um valor para reserva',
      'mission_objective_save_low': 'Defina um valor mínimo para guardar',
      'mission_objective_security_high': 'Monte 1 mês de reserva de emergência',
      'mission_objective_security_low': 'Defina sua meta de reserva',
      'mission_objective_dream_high': 'Quebre seu sonho em 3 marcos',
      'mission_objective_dream_low': 'Defina o prazo do sonho',
      'mission_objective_invest_high': 'Ajuste sua alocação de investimentos',
      'mission_objective_invest_low': 'Defina quanto quer investir no mês',
      'mission_objective_emergency_fund_high':
          'Cheque 2 meses de despesas na reserva',
      'mission_objective_emergency_fund_low':
          'Comece com 1 meta simples de reserva',
      'mission_objective_generic_high':
          'Defina 1 ação concreta para o objetivo',
      'mission_objective_generic_low': 'Escreva seu objetivo com prazo',
      'objective_dream': 'Conquistar um sonho',
      'objective_property': 'Adquirir um imóvel',
      'objective_trip': 'Fazer uma viagem',
      'objective_debts': 'Sair de dívidas',
      'objective_save': 'Guardar dinheiro',
      'objective_security': 'Ter mais segurança',
      'objective_emergency_fund': 'Construir reserva de emergência',
      'objective_invest': 'Investir melhor',
      'login_fill_email_password': 'Preencha e-mail e senha.',
      'error_connect_server': 'Erro ao conectar ao servidor.',
      'reset_need_email':
          'Informe seu e-mail para receber o link de redefinição.',
      'reset_sent': 'Enviamos um link de redefinição para o seu e-mail.',
      'email_not_found': 'E-mail não encontrado.',
      'login_invalid_email': 'E-mail inválido.',
      'no_connection': 'Sem conexão com a internet.',
      'reset_error_with_code': 'Erro ao processar a recuperação: {code}.',
      'reset_title': 'Recuperar senha',
      'reset_subtitle':
          'Vamos enviar um link de redefinição para o seu e-mail.',
      'reset_code_subtitle':
          'Digite o código de 5 dígitos e crie uma nova senha.',
      'reset_send_button': 'Enviar link',
      'reset_send_code_button': 'Enviar código',
      'reset_code_label': 'Código de recuperação',
      'reset_code_hint': 'Digite o código de 5 números',
      'reset_verify_button': 'Validar código',
      'reset_new_password': 'Nova senha',
      'reset_new_password_title': 'Nova senha',
      'reset_new_password_subtitle':
          'Defina sua nova senha para acessar a conta.',
      'reset_confirm_password': 'Confirmar nova senha',
      'reset_password_mismatch': 'As senhas não conferem.',
      'reset_confirm_button': 'Salvar nova senha',
      'reset_confirmed': 'Senha redefinida com sucesso.',
      'reset_code_sent':
          'Se este e-mail existir, enviamos um código de 5 dígitos. Ele expira em 5 minutos.',
      'reset_code_invalid': 'Código inválido. Use 5 números.',
      'reset_code_expires_in': 'Código expira em {time}.',
      'reset_code_expired': 'Código expirado. Envie um novo código.',
      'reset_resend_button': 'Reenviar link',
      'reset_resend_code_button': 'Reenviar código',
      'reset_resend_button_timer': 'Reenviar em {time}',
      'reset_resend_wait': 'Aguarde 60 segundos para reenviar.',
      'reset_rate_limited': 'Muitas tentativas. Tente novamente mais tarde.',
      'login_google_not_ready':
          'Google ainda nao configurado. No Firebase, adicione o SHA-1 do Android e baixe novamente android/app/google-services.json.',
      'login_apple_not_ready': 'Login com Apple ainda não configurado.',
      'login_cancelled': 'Login cancelado.',
      'login_google': 'Entrar com Google',
      'login_apple': 'Entrar com Apple',
      'register_action': 'Cadastrar',
      'register_required_fields': 'Preencha todos os campos obrigatórios.',
      'register_password_mismatch': 'As senhas não conferem.',
      'register_terms_required':
          'Você precisa aceitar os termos para continuar.',
      'register_email_in_use': 'Este e-mail já está em uso.',
      'register_invalid_email': 'E-mail inválido.',
      'register_weak_password':
          'Senha muito fraca. Use pelo menos 8 caracteres com maiúscula, minúscula, número e caractere especial.',
      'register_email_not_enabled':
          'Cadastro por e-mail não está habilitado no Firebase.',
      'register_error_with_code': 'Erro ao criar conta: {code}.',
      'register_success': 'Conta criada! Agora faça login.',
      'first_name': 'Nome',
      'profile_property_value': 'Valor aproximado de imóveis',
      'profile_invest_balance': 'Saldo total em investimentos',
      'wealth_info_title': 'Patrimônio e Investimentos',
      'last_name': 'Sobrenome',
      'birth_date': 'Data de nascimento',
      'gender': 'Sexo',
      'confirm_password': 'Confirmar senha',
      'register_terms_text':
          'Aceito os termos de uso e autorizo o armazenamento online dos meus dados.',
      'gender_not_informed': 'Não informado',
      'gender_male': 'Masculino',
      'gender_female': 'Feminino',
      'gender_other': 'Outro',
      'login_invalid_credentials': 'E-mail ou senha incorretos.',
      'profile_no_user': 'Nenhum usuário encontrado. Faça cadastro/login.',
      'profile_required_fields': 'Preencha os campos obrigatórios.',
      'profile_invalid_income': 'Informe uma renda mensal válida.',
      'profile_photo_upload_error': 'Erro ao enviar a foto.',
      'profile_updated': 'Perfil atualizado.',
      'profile_no_user_body':
          'Nenhum usuário encontrado.\nCrie uma conta e faça login.',
      'save': 'Salvar',
      'profile_change_photo': 'Alterar foto',
      'profile_personal_data_title': 'Dados pessoais',
      'profile_personal_data_subtitle':
          'Mantenha seus dados principais atualizados para o app organizar melhor sua jornada.',
      'profile_income_title': 'Renda',
      'profile_income_subtitle':
          'Sua renda é a base para limites, previsões e recomendações do mês.',
      'profile_primary_income_label': 'Entrada principal',
      'profile_income_delete_title': 'Apagar renda fixa',
      'profile_income_delete_body':
          'Deseja remover apenas este mês ou apagar para todos os meses seguintes?',
      'profile_income_delete_scope_month': 'Somente este mês',
      'profile_income_delete_scope_future': 'Meses seguintes',
      'select': 'Selecionar',
      'login_blocked':
          'Acesso bloqueado. Entre em contato pelo e-mail: contato@voolo.com',
      'login_failed_try_again': 'Falha ao entrar. Tente novamente.',
      'unknown_route_title': 'Rota não encontrada',
      'unknown_route_body':
          'A rota "{route}" não existe.\nVerifique AppRoutes e seus Navigator.pushNamed().',
      'premium_cta': 'Seja Premium',
      'premium_badge': 'Premium',
      'premium_dialog_title': 'Seja Premium',
      'premium_cancel_anytime': 'Cancele quando quiser.',
      'premium_dialog_choose_plan': 'Escolha seu plano premium:',
      'premium_checkout_secure_title': 'Pagamento seguro',
      'premium_checkout_secure_body':
          'A assinatura abre no navegador e fica vinculada à sua conta. Não há compra dentro do app.',
      'premium_checkout_monthly_title': 'Plano mensal',
      'premium_checkout_monthly_subtitle':
          '7 dias de teste. Cancele quando quiser.',
      'premium_checkout_yearly_title': 'Plano anual',
      'premium_checkout_yearly_subtitle':
          '7 dias de teste. Melhor custo-benefício para manter o Premium.',
      'premium_checkout_includes_title': 'O que você libera',
      'premium_checkout_feature_1':
          'Relatórios inteligentes e detalhes premium.',
      'premium_checkout_feature_2': 'Metas, missões e insights avançados.',
      'premium_checkout_feature_3':
          'Acesso contínuo enquanto a assinatura estiver ativa.',
      'premium_checkout_cta': 'Continuar',
      'premium_checkout_footer':
          'Depois de concluir a assinatura, volte ao app. O status premium será atualizado pelo servidor.',
      'premium_checkout_login_required': 'Entre na conta para continuar.',
      'premium_checkout_open_error':
          'Não foi possível abrir a assinatura agora.',
      'premium_checkout_opened_snack':
          'Checkout aberto. Conclua a assinatura no navegador.',
      'profile_premium_section_title': 'Assinatura Premium',
      'profile_premium_section_subtitle':
          'Sua assinatura está ativa. Gerencie ou cancele pelo portal seguro.',
      'profile_premium_section_body':
          'Quando você cancelar, o acesso continua até o fim do período pago.',
      'profile_premium_cancel_cta': 'Cancelar assinatura',
      'profile_paddle_portal_error':
          'Não foi possível abrir o portal de assinaturas agora.',
      'profile_paddle_login_required':
          'Entre na conta para gerenciar a assinatura.',
      'profile_subscription_login_required':
          'Entre na conta para cancelar a assinatura.',
      'profile_subscription_cancelled':
          'Assinatura cancelada. O acesso continua até o fim do periodo pago.',
      'profile_subscription_action_error':
          'Não foi possível concluir a solicitação agora.',
      'premium_plan_monthly_title': 'Plano mensal - R\$ 29,90/mês',
      'premium_plan_monthly_subtitle':
          'Renovação automática. Cancele quando quiser.',
      'premium_plan_yearly_title': 'Plano anual - R\$ 299,90/ano',
      'premium_plan_yearly_subtitle':
          'Pagamento anual com acesso premium durante todos os meses do período.',
      'premium_dialog_body':
          'Desbloqueie missões, relatórios inteligentes, calculadora de investimentos e alertas de pagamentos.\n\nEntre em contato para ativar o Premium.',
      'premium_upsell_title': 'Mais controle, mais clareza, mais resultado',
      'premium_welcome_title': 'Premium ativado!',
      'premium_welcome_body':
          'Parabéns pela escolha do Voolo. Que essa jornada traga mais clareza, controle e tranquilidade.',
      'premium_welcome_tip':
          'Quer um onboarding guiado? Eu te mostro cada função no lugar exato.',
      'premium_welcome_yes': 'Quero onboarding',
      'premium_welcome_no': 'Agora não',
      'premium_onboarding_title': 'Bem-vindo ao Premium',
      'premium_onboarding_subtitle':
          'Vamos fazer um caminho pelo app e ver cada função na prática.',
      'premium_onboarding_next': 'Próximo',
      'premium_onboarding_finish': 'Finalizar',
      'premium_onboarding_skip': 'Pular',
      'premium_onboarding_open': 'Mostrar no app',
      'premium_onboarding_progress': '{done} de {total} etapas concluídas',
      'premium_insights_title': 'Análises de Elite',
      'premium_insights_subtitle':
          'Desbloqueie insights avançados e alertas inteligentes para turbinar sua evolução financeira.',
      'premium_step_reports_title': 'Relatórios Premium',
      'premium_step_reports_body':
          'Veja um resumo visual do mês e compare sua evolução.',
      'premium_step_reports_tip':
          'Toque em "Mostrar no app" para ver onde fica.',
      'premium_step_goals_title': 'Metas inteligentes',
      'premium_step_goals_body':
          'Metas com progresso claro e desafios semanais.',
      'premium_step_goals_tip': 'Toque em "Mostrar no app" para abrir Metas.',
      'premium_step_invest_title': 'Calculadora de investimentos',
      'premium_step_invest_body':
          'Simule cenários e veja o resultado no longo prazo.',
      'premium_step_invest_tip':
          'Toque em "Mostrar no app" e teste os valores.',
      'premium_step_missions_title': 'Missões premium',
      'premium_step_missions_body':
          'Rotina leve com desafios diários, semanais e mensais.',
      'premium_step_missions_tip':
          'Toque em "Mostrar no app" para ver as missões.',
      'premium_step_insights_title': 'Insights inteligentes',
      'premium_step_insights_body':
          'Alertas e dicas que guiam sua próxima ação.',
      'premium_step_insights_tip':
          'Toque em "Mostrar no app" para abrir Insights.',
      'premium_tour_calculator_title': 'Calculadora de investimentos',
      'premium_tour_calculator_body':
          'Aqui você simula aportes e taxa para ver o resultado futuro.',
      'premium_tour_calculator_location':
          'Onde fica: botão Calculadora na tela inicial.',
      'premium_tour_calculator_tip':
          'Teste 5, 10 e 20 anos para comparar cenários.',
      'premium_tour_goals_title': 'Metas inteligentes',
      'premium_tour_goals_body':
          'Suas metas aparecem aqui com progresso e desafios semanais.',
      'premium_tour_goals_location':
          'Onde fica: menu lateral > Metas ou botão Metas na home.',
      'premium_tour_goals_tip': 'Crie uma meta e marque o que foi concluído.',
      'premium_tour_missions_title': 'Missões Premium',
      'premium_tour_missions_body':
          'Missões diárias, semanais e mensais para manter consistência.',
      'premium_tour_missions_location': 'Onde fica: menu lateral > Missões.',
      'premium_tour_missions_tip': 'Complete missões e acompanhe seu XP.',
      'premium_tour_reports_title': 'Relatórios Premium',
      'premium_tour_reports_body':
          'Resumo visual do mês com totais e comparativos.',
      'premium_tour_reports_location': 'Onde fica: menu lateral > Relatórios.',
      'premium_tour_reports_tip':
          'Troque o mês no topo para comparar períodos.',
      'premium_tour_insights_title': 'Insights',
      'premium_tour_insights_body':
          'Alertas e sugestões para equilibrar seus gastos.',
      'premium_tour_insights_location': 'Onde fica: menu lateral > Insights.',
      'premium_tour_insights_tip': 'Siga o foco principal e ajuste seu mês.',
      'close': 'Fechar',
      'ok': 'OK',
      'previous_month': 'Mês anterior',
      'next_month': 'Próximo mês',
      'user_label': 'Usuário',
      'security': 'Segurança',
      'settings': 'Configurações',
      'login_required_calculator': 'Faça login para acessar a calculadora.',
      'investment_calculator': 'Calculadora de investimentos',
      'investment_premium_title':
          'Calculadora de investimentos desbloqueada no Premium',
      'investment_premium_subtitle':
          'Simule aportes e veja crescimento real do seu patrimônio com projeções avançadas.',
      'investment_premium_perk1': 'Projeções de 5, 10 e 20 anos',
      'investment_premium_perk2': 'Relatórios com insights personalizados',
      'investment_premium_perk3': 'Score de saúde financeira',
      'investment_projection_title':
          'Projeção com aporte mensal + juros compostos',
      'investment_monthly_contribution': 'Aporte mensal (R\$)',
      'investment_annual_rate': 'Taxa anual (%)',
      'investment_invalid_inputs':
          'Informe um aporte e uma taxa maiores que zero para ver a projeção.',
      'investment_disclaimer':
          'Observação: esta projeção é uma simulação. Resultados reais variam conforme mercado, taxas e impostos.',
      'investment_total_contribution': 'Aporte total',
      'investment_profit': 'Rendimento',
      'investment_final_total': 'Total final',
      'investment_reserve_emergency_title':
          'Reserva de emergência (prioridade)',
      'investment_reserve_emergency_subtitle':
          'Simples e líquido até completar a reserva.',
      'investment_fixed_liquid_label': 'Renda fixa com liquidez (Selic/CDB)',
      'investment_fixed_long_label': 'Renda fixa longa',
      'investment_variable_diversified_label': 'Variável diversificada',
      'investment_reserve_emergency_months_label':
          'Reserva de emergência (meses)',
      'investment_allocation_title': 'Alocação sugerida (classes de ativos):',
      'investment_high_risk_label': 'Maior risco',
      'investment_risk_aggressive': 'Agressivo',
      'investment_risk_moderate': 'Moderado',
      'investment_risk_conservative': 'Conservador',
      'investment_allocate_now': 'Alocar agora',
      'investment_allocation_chosen': 'Alocação escolhida',
      'investment_allocation_not_defined': 'Alocação ainda não definida.',
      'investment_allocation_unlock_hint':
          'Complete para desbloquear suas sugestões de alocação.',
      'investment_allocation_define_value': 'Defina um valor para alocar.',
      'investment_profile_updated': 'Perfil atualizado.',
      'investment_profile_local_applied':
          'N?o foi poss?vel calcular online; usei um c?lculo local simples.',
      'investment_profile_local_saved': 'Perfil aplicado localmente.',
      'investment_plan_title': 'Seu plano de investimentos',
      'investment_plan_edit_button': 'Editar plano',
      'investment_plan_quick_summary': 'Resumo r?pido do seu m?s',
      'investment_plan_target_label': 'Aporte alvo',
      'investment_plan_profile_label': 'Perfil',
      'investment_plan_reserve_label': 'Reserva',
      'investment_plan_goals_title': 'Metas',
      'investment_plan_save_button': 'Salvar',
      'investment_plan_saving_button': 'Salvando...',
      'investment_plan_setup_help':
          'Defina metas simples (reserva e aporte). Voc? pode ajustar depois.',
      'investment_plan_target_input_label': 'Aporte mensal alvo (R\$)',
      'investment_plan_suggestions_title': 'Sugest?es para este m?s',
      'investment_plan_simulate_label': 'Simular valor (opcional)',
      'investment_plan_simulate_hint': 'Se vazio, usamos o aporte mensal alvo.',
      'investment_plan_suggestions_empty':
          'Defina um valor (aporte) para ver sugest?es.',
      'investment_plan_save_choice': 'Salvar esta escolha',
      'investment_plan_choice_saved': 'Perfil salvo',
      'investment_step_simple_title': 'Primeiro passo (simples)',
      'investment_step_simple_subtitle':
          'Equilíbrio entre segurança e crescimento.',
      'investment_step_simple_note':
          'Se quiser deixar ainda mais simples: reduza "alto risco" para 0% e aumente o ETF.',
      'investment_step_aggressive_title': 'Agressivo (diversificado)',
      'investment_step_aggressive_subtitle':
          'Mais volatilidade, sempre com base segura.',
      'investment_step_aggressive_note':
          'Se oscilar te incomodar, aumente a parte "liquidez" e reduza o ETF.',
      'investment_step_moderate_title': 'Moderado (simples)',
      'investment_step_moderate_subtitle': 'Para começar sem estresse.',
      'investment_step_moderate_note':
          'Se oscilar te incomodar, aumente a parte "liquidez" e reduza o ETF.',
      'investment_step_moderate_ipca_title': 'Moderado com IPCA',
      'investment_step_moderate_ipca_subtitle':
          'Mais proteção de longo prazo, mantendo simplicidade.',
      'investment_reserve_emergency_note_1':
          'Objetivo: 3–6 meses de custos essenciais em liquidez diária.',
      'investment_reserve_emergency_note_2':
          'Depois da reserva pronta, volte aqui e escolha uma alocação de longo prazo.',
      'investment_step_conservative_title': 'Começo conservador',
      'investment_step_conservative_subtitle':
          'Para sair do zero sem estresse.',
      'investment_step_conservative_note':
          'Depois que a reserva estiver pronta, você pode adicionar um pouco de IPCA+ ou ETF.',
      'investment_step_conservative_long_title': 'Conservador + longo prazo',
      'investment_step_conservative_long_subtitle':
          'Um toque de longo prazo, mantendo segurança.',
      'investment_step_conservative_long_note':
          'Aumente a parte de liquidez se preferir mais segurança.',
      'example_500': 'Ex: 500',
      'example_12': 'Ex: 12',
      'years_label': '{years} anos',
      'new_entry': 'Novo lançamento',
      'type': 'Tipo',
      'name': 'Nome',
      'category': 'Categoria',
      'value_currency': 'Valor (R\$)',
      'due_day_optional': 'Dia de vencimento (opcional)',
      'card_due_day': 'Vencimento da fatura do cartão',
      'card_select': 'Cartão de crédito',
      'card_due_day_value': 'Vencimento da fatura: dia {day}',
      'card_required': 'Cadastre um cartão de crédito primeiro.',
      'no_due_date': 'Sem vencimento',
      'day_label': 'Dia {n}',
      'credit_card_charge': 'Conta no cartão de crédito',
      'card_recurring': 'Compra recorrente no cartão',
      'card_recurring_short': 'Recorrente',
      'card_paid_badge': 'Fatura paga',
      'card_unknown': 'Cartão desconhecido',
      'bill_paid': 'Conta paga',
      'card_invoice_paid': 'Fatura do cartão paga',
      'installments_quantity': 'Quantidade de parcelas',
      'credit_card_bills_title': 'Faturas do cartão',
      'card_due_day_label': 'Vencimento dia {day}',
      'card_insight_title': 'Faturas do cartão no mês',
      'card_insight_high':
          'As faturas somam {value} ({pct}% da renda). Isso pode apertar seu orçamento.',
      'card_insight_ok':
          'As faturas somam {value} ({pct}% da renda). Dentro do esperado.',
      'expense_tip_fixed':
          'Dica: Se preencher o vencimento, o Jetx avisará 3 dias antes e no dia (quando ativarmos notificações).',
      'expense_tip_variable':
          'Dica: Gastos variáveis contam apenas no mês atual.',
      'income_variable_tip':
          'Renda variável? Use a média dos últimos 3 meses para evitar frustrações.',
      'credit_card_tip':
          'Compras parceladas comprometem sua renda futura. Use com cuidado.',
      'expense_high_tip':
          'Esse gasto representa {pct}% do seu orçamento mensal. Ideal é até {ideal}%.',
      'expense_low_tip':
          'Com esse lançamento, essa área fica em {pct}% do seu orçamento mensal. O ideal é pelo menos {ideal}%.',
      'expense_name_required': 'Digite o nome.',
      'expense_value_required': 'Digite um valor válido.',
      'installments_required': 'Informe a quantidade de parcelas.',
      'expense_type_fixed': 'Gasto fixo',
      'expense_type_variable': 'Gasto variável',
      'expense_type_investment': 'Investimento',
      'expense_type_fixed_short': 'Fixo',
      'expense_type_variable_short': 'Variavel',
      'expense_type_investment_short': 'Investimento',
      'expense_category_housing': 'Moradia',
      'expense_category_food': 'Alimentação',
      'expense_category_transport': 'Transporte',
      'expense_category_education': 'Educação',
      'expense_category_health': 'Saúde',
      'expense_category_leisure': 'Lazer',
      'expense_category_subscriptions': 'Assinaturas',
      'expense_category_investment': 'Investimento',
      'expense_category_debts': 'Dividas',
      'expense_category_other': 'Outros',
      'payment_method_debit': 'Debito',
      'payment_method_credit': 'Credito',
      'payment_method_investment': 'Investimento',
      'payment_impact_balance_now': 'Sai do saldo agora',
      'payment_impact_invoice': 'Entra na fatura',
      'payment_impact_invoice_installment':
          'Entra na fatura ({current}/{total})',
      'expense_due_statement_day': 'Fatura dia {day}',
      'mission_complete_title': 'Concluir missão',
      'mission_complete_note_label': 'Comentário de conclusão (opcional)',
      'mission_complete_note_hint': 'Conte o que você fez e como fez.',
      'mission_note_title': 'Comentário da missão',
      'mission_note_view': 'Ver comentário',
      'mission_complete_cta': '+{xp} XP',
      'mission_require_expense_today':
          'Registre pelo menos 1 gasto hoje para concluir.',
      'mission_require_report_today':
          'Abra o relatório do mês hoje para concluir.',
      'mission_require_weekly_expenses':
          'Registre gastos em pelo menos 3 dias da semana.',
      'mission_require_previous_month':
          'Tenha pelo menos 1 mês anterior para comparar.',
      'mission_require_goal': 'Crie pelo menos 1 meta pessoal para concluir.',
      'mission_require_default': 'Complete a atividade no app para concluir.',
      'mission_manual_title': 'Concluir manualmente',
      'mission_manual_body':
          'Os requisitos automáticos não foram detectados. Deseja marcar como concluída mesmo assim?',
      'confirm': 'Confirmar',
      'cancel': 'Cancelar',
      'back': 'Voltar',
      'finish': 'Finalizar',
      'onboarding_objectives_title': 'Para começar, quais são seus objetivos?',
      'onboarding_objectives_subtitle':
          'Isso nos ajuda a sugerir metas e missões mais alinhadas com você.',
      'onboarding_objectives_required': 'Escolha pelo menos um objetivo.',
      'onboarding_profession_title': 'Qual é a sua profissão?',
      'onboarding_profession_subtitle':
          'Queremos entender seu momento profissional para personalizar sua jornada.',
      'onboarding_profession_required': 'Informe sua profissão.',
      'onboarding_income_title': 'Qual é a sua entrada mensal?',
      'onboarding_income_subtitle':
          'Com esse dado, conseguimos montar metas realistas para você.',
      'summary_fixed': 'Fixos',
      'summary_variable': 'Variáveis',
      'summary_invest': 'Invest.',
      'summary_free': 'Livre',
      'timeline_more': 'a mais',
      'timeline_less': 'a menos',
      'timeline_variable_change':
          'Este mês você gastou {pct}% {direction} em variáveis.',
      'timeline_fixed_change': 'Gastos fixos ficaram {pct}% {direction}.',
      'timeline_invest_streak':
          'Você aumentou seus investimentos por {months} meses seguidos.',
      'timeline_balanced': 'Seu mês está equilibrado. Mantenha o ritmo!',
      'score_title': 'Score financeiro',
      'score_title_month_tips': 'Score financeiro do mês',
      'score_locked_subtitle':
          'Veja sua saúde financeira com insights inteligentes.',
      'score_add_income': 'Cadastre sua renda para calcular o score.',
      'score_focus_variable': 'Seu maior foco agora é: gastos variáveis.',
      'score_focus_fixed': 'Seu maior foco agora é: gastos fixos.',
      'score_focus_invest_low': 'Seu maior foco agora é: investimentos.',
      'score_focus_invest_high':
          'Seu maior foco agora é: equilibrar investimentos.',
      'score_focus_balanced':
          'Boa decisão: seu orçamento está bem equilibrado.',
      'plan_title': 'Plano do mês',
      'plan_subtitle': 'Ações rápidas para melhorar seu mês.',
      'plan_next_action': 'Próxima ação',
      'plan_action_variable': 'Reduza gastos variáveis para até 25% da renda.',
      'plan_action_fixed': 'Traga os gastos fixos para no máximo 50% da renda.',
      'plan_action_invest': 'Direcione {value} para investimentos.',
      'plan_action_ok': 'Você está equilibrado. Mantenha o ritmo.',
      'alert_title': 'Alertas inteligentes',
      'alert_add_income': 'Cadastre sua renda para liberar alertas.',
      'alert_fixed_high': 'Gastos fixos acima de 60% da renda.',
      'alert_variable_high': 'Gastos variáveis acima de 35% da renda.',
      'alert_leisure_high': 'Lazer acima de 25% da renda.',
      'alert_invest_low': 'Investimentos abaixo de 10% da renda.',
      'alert_negative_balance': 'Seu saldo do mês está negativo.',
      'alert_ok': 'Tudo certo por aqui. Continue consistente.',
      'tips_title': 'Dicas do mês',
      'monthly_report_title': 'Relatório mensal',
      'monthly_report_empty': 'Nenhum dado encontrado para este mês.',
      'monthly_report_month_spending': 'Gastos do mês',
      'monthly_report_total_spent': 'Total de gastos',
      'monthly_report_total_invested': 'Total investido',
      'monthly_report_total_invested_info':
          'Este valor soma apenas o que foi investido ao longo dos meses. Os rendimentos não aparecem aqui.',
      'monthly_report_balance': 'Saldo do mês',
      'monthly_report_entries_filters': 'Lançamentos (filtros)',
      'monthly_report_adjust_balance': 'Ajustar saldo do mês',
      'monthly_report_timeline': 'Linha do tempo',
      'monthly_report_card_credit': 'Cartão de crédito',
      'monthly_report_no_card': 'Sem cartão cadastrado',
      'monthly_report_card_due_day': 'Vencimento do cartão: dia {day}',
      'monthly_report_due_day_optional': 'Dia de vencimento (opcional)',
      'monthly_report_loading': 'Carregando...',
      'monthly_report_login_required': 'Faça login para acessar relatórios.',
      'monthly_report_premium_title': 'Relatórios inteligentes são Premium',
      'monthly_report_premium_subtitle':
          'Veja linha do tempo, evolução mensal e insights detalhados.',
      'monthly_report_premium_perk1': 'Linha do tempo do seu dinheiro',
      'monthly_report_premium_perk2': 'Score da saúde financeira',
      'monthly_report_premium_perk3': 'Insights personalizados do mês',
      'tip_housing_high':
          'Moradia acima de 35%. Avalie alternativas para reduzir esse custo.',
      'compare_title': 'Comparativo mensal',
      'compare_no_data': 'Sem dados do mês anterior ainda.',
      'insights_title': 'Insights do mês',
      'insights_subtitle': 'Concentre todas as dicas e alertas aqui.',
      'insights_card_subtitle':
          'Veja alertas, plano e comparativos em um só lugar.',
      'insights_cta': 'Abrir',
      'habit_title': 'Hábitos financeiros',
      'habit_streak': 'Sequência {days} dias',
      'habit_log_expense': 'Registrar gastos do dia',
      'habit_log_expense_subtitle': 'Mantenha as despesas em dia.',
      'habit_check_budget': 'Revisar o orçamento',
      'habit_check_budget_subtitle': 'Confirme se você está no plano.',
      'habit_invest': 'Separar para investir',
      'habit_invest_subtitle': 'Reserve um valor semanal.',
      'month_entries': 'Lançamentos do mês',
      'no_entries_yet': 'Nenhum lançamento ainda.',
      'month_salary': 'Entradas do mês',
      'view_all_entries': 'Ver todos os lançamentos',
      'income_modal_new_title': 'Nova entrada',
      'income_modal_edit_title': 'Editar entrada',
      'income_modal_fixed': 'Fixa',
      'income_modal_variable': 'Variável',
      'income_modal_fixed_info_title': 'Entrada Fixa',
      'income_modal_variable_info_title': 'Entrada Variável',
      'income_modal_fixed_info_body':
          'Esta entrada vale apenas para o mês atual, como uma entrada previsível.',
      'income_modal_variable_info_body':
          'Esta entrada vale apenas para o mês atual e não se repete sozinha.',
      'income_modal_title_hint': 'Ex: Salário, Freelance',
      'income_modal_amount_label': 'Valor da entrada',
      'income_modal_amount_hint': '0,00',
      'income_modal_primary_title': 'Entrada principal',
      'income_modal_error_fill': 'Preencha o nome e o valor corretamente.',
      'income_modal_error_save': 'Erro ao salvar entrada.',
      'income_category_salary': 'Salário',
      'income_category_service': 'Prestação de serviço',
      'income_category_yield': 'Rendimento',
      'income_category_bonus': 'Bônus',
      'income_category_other': 'Outra entrada',
      'profile_delete_account_title': 'Excluir conta',
      'profile_delete_account_subtitle': 'Ação permanente e irreversível.',
      'profile_delete_account_body':
          'Isso remove seus dados locais e remotos e encerra seu acesso ao app.',
      'profile_delete_account_password_label': 'Digite sua senha',
      'profile_delete_account_confirm': 'Excluir conta',
      'profile_delete_account_requires_password':
          'Esta conta não usa senha para entrar. Use o método de login original.',
      'profile_delete_account_invalid_password':
          'Senha inválida. Tente novamente.',
      'profile_delete_account_failed':
          'Não foi possível excluir a conta agora.',
      'goals_title': 'Metas',
      'goals_add_new': 'Nova meta',
      'goals_title_label': 'Título da meta',
      'goals_type_label': 'Tipo',
      'goals_type_income': 'Renda / Carreira',
      'goals_type_education': 'Educação',
      'goals_type_personal': 'Pessoal',
      'goals_description_optional': 'Descrição (opcional)',
      'goals_title_required': 'Digite um título para a meta.',
      'goals_income_exists': 'Essa meta já existe como obrigatória do ano.',
      'goals_login_required': 'Faça login para acessar metas.',
      'goals_subtitle':
          'Acompanhe seu progresso, desafios semanais e objetivos estratégicos.',
      'goals_empty_year': 'Nenhuma meta cadastrada para este ano.',
      'goals_tip_hold_remove':
          'Dica: segure uma meta (não obrigatória) para remover.',
      'goals_completed_count': '{done} de {total} metas concluídas',
      'goals_already_in_list': 'Essa meta já está na sua lista.',
      'goals_section_year': 'Metas do ano',
      'goals_premium_title': 'Metas avançadas são Premium',
      'goals_premium_perk1': 'Progresso anual em tempo real',
      'goals_premium_perk2': 'Desafios semanais guiados',
      'goals_premium_perk3': 'Metas inteligentes baseadas no seu saldo',
      'goals_no_month_data': 'Sem dados do mês',
      'goals_month_balance': 'Saldo do mês: {value}',
      'save_cloud_error': 'Falha ao salvar na nuvem. Verifique sua conexão.',
      'goals_progress_section': 'Seu progresso',
      'goals_suggestions_section': 'Sugestões para você',
      'goals_weekly_section': 'Desafios da semana',
      'goals_weekly_empty': 'Sem desafios desta semana. Volte amanhã.',
      'goals_year_progress': 'Progresso anual',
      'mandatory': 'Obrigatória',
      'goal_action_complete': 'Concluir',
      'goal_action_add': 'Adicionar',
      'goal_income_title': 'Aumentar renda',
      'goal_income_desc': 'Crie um plano para aumentar seu rendimento no ano.',
      'goal_weekly_finance_content_title':
          'Ver conteúdo sobre planejamento financeiro',
      'goal_weekly_finance_content_desc':
          '15 minutos de leitura ou vídeo para reforçar o básico.',
      'goal_weekly_review_expenses_title': 'Revisar gastos do mês',
      'goal_weekly_review_expenses_desc':
          'Marque gastos variáveis e escolha 1 ajuste.',
      'goal_weekly_invest_10_title': 'Separar 10% para investir',
      'goal_weekly_invest_10_desc':
          'Direcione uma parte do saldo para investimentos.',
      'goal_weekly_spend_limit_title': 'Criar um teto de gastos semanal',
      'goal_weekly_spend_limit_desc':
          'Defina um limite e acompanhe até o domingo.',
      'goal_weekly_start_finance_book_title': 'Começar um livro de finanças',
      'goal_weekly_start_finance_book_desc':
          'Leia 10 páginas e marque como feito.',
      'goal_suggest_income_title': 'Cadastrar renda mensal',
      'goal_suggest_income_desc':
          'Adicione sua renda para desbloquear o planejamento.',
      'goal_suggest_reduce_variable_title': 'Reduzir 10% em variáveis',
      'goal_suggest_reduce_variable_desc':
          'Ajuste despesas não essenciais nas próximas semanas.',
      'goal_suggest_invest_title': 'Aumentar investimentos',
      'goal_suggest_invest_desc': 'Meta de aporte mensal consistente.',
      'goal_suggest_emergency_title': 'Montar reserva de emergência',
      'goal_suggest_emergency_desc': 'Objetivo de 3 a 6 meses de custo fixo.',
      'goal_suggest_education_title': 'Plano de educação financeira',
      'goal_suggest_education_desc': 'Estudar 30 min por semana.',
      'premium_subtitle_short': 'Desbloqueie recursos exclusivos',
      'timeline_title': 'Linha do tempo',
      'timeline_positive_streak': 'Sequência positiva',
      'timeline_positive_streak_desc':
          'Investimentos cresceram por {months} meses seguidos.',
      'timeline_balance_alert': 'Alerta de equilíbrio',
      'timeline_balance_alert_desc':
          'Variáveis superaram fixos. Revise gastos flexíveis.',
      'timeline_control_ok': 'Controle em dia',
      'timeline_control_ok_desc':
          'Fixos estão controlados em relação aos gastos variáveis.',
      'timeline_balanced_month': 'Mês equilibrado',
      'timeline_balanced_month_desc': 'Nenhuma variação relevante detectada.',
      'add_extra_income': 'Adicionar entrada',
      'income_label_placeholder': 'Nome da entrada',
      'offline_message': 'Você está offline. Conecte-se a uma rede.',
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
      'onboarding_primary_income_label': 'Primary entry',
      'onboarding_income_fallback_label': 'Income {n}',
      'monthly_income': 'Monthly entries (R\$)',
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
          'Google login is not set up yet. In Firebase, add the Android SHA-1 and re-download android/app/google-services.json.',
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
      'profile_personal_data_title': 'Personal data',
      'profile_personal_data_subtitle':
          'Keep your main data updated so the app can better organize your journey.',
      'profile_income_title': 'Income',
      'profile_income_subtitle':
          'Your income is the base for limits, projections, and monthly recommendations.',
      'profile_primary_income_label': 'Primary entry',
      'profile_income_delete_title': 'Delete fixed income',
      'profile_income_delete_body':
          'Do you want to remove only this month or delete it for all following months?',
      'profile_income_delete_scope_month': 'Only this month',
      'profile_income_delete_scope_future': 'Following months',
      'select': 'Select',
      'login_blocked': 'Access blocked. Contact us at: contato@voolo.com',
      'login_failed_try_again': 'Sign-in failed. Try again.',
      'unknown_route_title': 'Route not found',
      'unknown_route_body':
          'The route "{route}" does not exist.\nCheck AppRoutes and your Navigator.pushNamed().',
      'premium_cta': 'Go Premium',
      'premium_badge': 'Premium',
      'premium_dialog_title': 'Go Premium',
      'premium_cancel_anytime': 'Cancel anytime.',
      'premium_dialog_choose_plan': 'Choose your premium plan:',
      'premium_checkout_secure_title': 'Secure payment',
      'premium_checkout_secure_body':
          'The subscription opens in the browser and stays linked to your account. There is no in-app purchase.',
      'premium_checkout_monthly_title': 'Monthly plan',
      'premium_checkout_monthly_subtitle': '7-day trial. Cancel anytime.',
      'premium_checkout_yearly_title': 'Yearly plan',
      'premium_checkout_yearly_subtitle':
          '7-day trial. Best value for keeping Premium.',
      'premium_checkout_includes_title': 'What you unlock',
      'premium_checkout_feature_1': 'Smart reports and premium details.',
      'premium_checkout_feature_2': 'Goals, missions, and advanced insights.',
      'premium_checkout_feature_3':
          'Continuous access while the subscription is active.',
      'premium_checkout_cta': 'Continue',
      'premium_checkout_footer':
          'After finishing the subscription, come back to the app. Premium status will be refreshed by the server.',
      'premium_checkout_login_required': 'Sign in to continue.',
      'premium_checkout_open_error':
          'Could not open the subscription right now.',
      'premium_checkout_opened_snack':
          'Checkout opened. Complete the subscription in the browser.',
      'profile_premium_section_title': 'Premium subscription',
      'profile_premium_section_subtitle':
          'Your subscription is active. Manage or cancel it through the secure portal.',
      'profile_premium_section_body':
          'When you cancel, access continues until the end of the paid period.',
      'profile_premium_cancel_cta': 'Cancel subscription',
      'profile_paddle_portal_error':
          'Could not open the subscriptions portal right now.',
      'profile_paddle_login_required': 'Sign in to manage the subscription.',
      'profile_subscription_login_required':
          'Sign in to cancel the subscription.',
      'profile_subscription_cancelled':
          'Subscription cancelled. Access continues until the end of the paid period.',
      'profile_subscription_action_error':
          'Could not complete the request right now.',
      'premium_plan_monthly_title': 'Monthly plan - R\$ 29.90/month',
      'premium_plan_monthly_subtitle': 'Automatic renewal. Cancel anytime.',
      'premium_plan_yearly_title': 'Yearly plan - R\$ 299.90/year',
      'premium_plan_yearly_subtitle':
          'Annual payment with premium access for every month of the period.',
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
      'ok': 'OK',
      'previous_month': 'Previous month',
      'next_month': 'Next month',
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
      'investment_reserve_emergency_title': 'Emergency reserve (priority)',
      'investment_reserve_emergency_subtitle':
          'Simple and liquid until the reserve is complete.',
      'investment_fixed_liquid_label': 'Liquid fixed income (Treasury/CDB)',
      'investment_fixed_long_label': 'Long-term fixed income',
      'investment_variable_diversified_label': 'Diversified variable',
      'investment_reserve_emergency_months_label': 'Emergency reserve (months)',
      'investment_allocation_title': 'Suggested allocation (asset classes):',
      'investment_high_risk_label': 'Higher risk',
      'investment_risk_aggressive': 'Aggressive',
      'investment_risk_moderate': 'Moderate',
      'investment_risk_conservative': 'Conservative',
      'investment_allocate_now': 'Allocate now',
      'investment_allocation_chosen': 'Chosen allocation',
      'investment_allocation_not_defined': 'Allocation not yet defined.',
      'investment_allocation_unlock_hint':
          'Complete it to unlock your allocation suggestions.',
      'investment_allocation_define_value': 'Set an amount to allocate.',
      'investment_profile_updated': 'Profile updated.',
      'investment_profile_local_applied':
          'Could not calculate online; used a simple local calculation.',
      'investment_profile_local_saved': 'Profile applied locally.',
      'investment_plan_title': 'Your investment plan',
      'investment_plan_edit_button': 'Edit plan',
      'investment_plan_quick_summary': 'Quick summary of your month',
      'investment_plan_target_label': 'Target contribution',
      'investment_plan_profile_label': 'Profile',
      'investment_plan_reserve_label': 'Reserve',
      'investment_plan_goals_title': 'Goals',
      'investment_plan_save_button': 'Save',
      'investment_plan_saving_button': 'Saving...',
      'investment_plan_setup_help':
          'Set simple goals (reserve and contribution). You can adjust them later.',
      'investment_plan_target_input_label': 'Target monthly contribution (R\$)',
      'investment_plan_suggestions_title': 'Suggestions for this month',
      'investment_plan_simulate_label': 'Simulate amount (optional)',
      'investment_plan_simulate_hint':
          'If empty, we use the target monthly contribution.',
      'investment_plan_suggestions_empty':
          'Set an amount (contribution) to see suggestions.',
      'investment_plan_save_choice': 'Save this choice',
      'investment_plan_choice_saved': 'Profile saved',
      'investment_step_simple_title': 'First step (simple)',
      'investment_step_simple_subtitle': 'Balance between safety and growth.',
      'investment_step_simple_note':
          'If you want to keep it even simpler: reduce "high risk" to 0% and increase the ETF.',
      'investment_step_aggressive_title': 'Aggressive (diversified)',
      'investment_step_aggressive_subtitle':
          'More volatility, always with a safe base.',
      'investment_step_aggressive_note':
          'If volatility bothers you, increase the "liquidity" part and reduce the ETF.',
      'investment_step_moderate_title': 'Moderate (simple)',
      'investment_step_moderate_subtitle': 'To get started without stress.',
      'investment_step_moderate_note':
          'If volatility bothers you, increase the "liquidity" part and reduce the ETF.',
      'investment_step_moderate_ipca_title':
          'Moderate with inflation protection',
      'investment_step_moderate_ipca_subtitle':
          'More long-term protection while staying simple.',
      'investment_reserve_emergency_note_1':
          'Goal: 3-6 months of essential costs in daily liquidity.',
      'investment_reserve_emergency_note_2':
          'After the reserve is ready, come back and choose a long-term allocation.',
      'investment_step_conservative_title': 'Conservative start',
      'investment_step_conservative_subtitle':
          'To get off zero without stress.',
      'investment_step_conservative_note':
          'Once the reserve is ready, you can add a bit of inflation-protected or ETF exposure.',
      'investment_step_conservative_long_title': 'Conservative + long term',
      'investment_step_conservative_long_subtitle':
          'A touch of long-term growth while keeping safety.',
      'investment_step_conservative_long_note':
          'Increase the liquidity portion if you want more safety.',
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
      'expense_low_tip':
          'With this entry, this area reaches {pct}% of your monthly budget. The ideal is at least {ideal}%.',
      'expense_name_required': 'Enter the name.',
      'expense_value_required': 'Enter a valid amount.',
      'installments_required': 'Enter the installments quantity.',
      'expense_type_fixed': 'Fixed expense',
      'expense_type_variable': 'Variable expense',
      'expense_type_investment': 'Investment',
      'expense_type_fixed_short': 'Fixed',
      'expense_type_variable_short': 'Variable',
      'expense_type_investment_short': 'Investment',
      'expense_category_housing': 'Housing',
      'expense_category_food': 'Food',
      'expense_category_transport': 'Transport',
      'expense_category_education': 'Education',
      'expense_category_health': 'Health',
      'expense_category_leisure': 'Leisure',
      'expense_category_subscriptions': 'Subscriptions',
      'expense_category_investment': 'Investment',
      'expense_category_debts': 'Debts',
      'expense_category_other': 'Other',
      'payment_method_debit': 'Debit',
      'payment_method_credit': 'Credit',
      'payment_method_investment': 'Investment',
      'payment_impact_balance_now': 'Leaves balance now',
      'payment_impact_invoice': 'Goes to statement',
      'payment_impact_invoice_installment':
          'Goes to statement ({current}/{total})',
      'expense_due_statement_day': 'Statement day {day}',
      'mission_complete_title': 'Complete mission',
      'mission_complete_note_label': 'Completion note (optional)',
      'mission_complete_note_hint': 'Describe what you did and how you did it.',
      'mission_note_title': 'Mission note',
      'mission_note_view': 'View note',
      'mission_complete_cta': '+{xp} XP',
      'mission_require_expense_today':
          'Log at least 1 expense today to complete.',
      'mission_require_report_today':
          'Open this month’s report today to complete.',
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
      'onboarding_income_title': 'What is your monthly entry?',
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
      'plan_action_variable': 'Reduce variable spending to 25% of income.',
      'plan_action_fixed': 'Bring fixed costs down to at most 50% of income.',
      'plan_action_invest': 'Allocate {value} to investments.',
      'plan_action_ok': 'You are balanced. Keep the momentum.',
      'alert_title': 'Smart alerts',
      'alert_add_income': 'Add your income to unlock alerts.',
      'alert_fixed_high': 'Fixed costs are above 60% of income.',
      'alert_variable_high': 'Variable spending is above 35% of income.',
      'alert_leisure_high': 'Leisure spending is above 25% of income.',
      'alert_invest_low': 'Investments are below 10% of income.',
      'alert_negative_balance': 'Your monthly balance is negative.',
      'alert_ok': 'All good here. Stay consistent.',
      'tips_title': 'Tips of the month',
      'monthly_report_title': 'Monthly report',
      'monthly_report_empty': 'No data found for this month.',
      'monthly_report_month_spending': 'Month spending',
      'monthly_report_total_spent': 'Total spending',
      'monthly_report_total_invested': 'Total invested',
      'monthly_report_total_invested_info':
          'This value includes only what was invested over the months. Earnings do not appear here.',
      'monthly_report_balance': 'Month balance',
      'monthly_report_entries_filters': 'Entries (filters)',
      'monthly_report_adjust_balance': 'Adjust month balance',
      'monthly_report_timeline': 'Timeline',
      'monthly_report_card_credit': 'Credit card',
      'monthly_report_no_card': 'No card registered',
      'monthly_report_card_due_day': 'Card due day: {day}',
      'monthly_report_due_day_optional': 'Due day (optional)',
      'monthly_report_loading': 'Loading...',
      'monthly_report_login_required': 'Log in to access reports.',
      'monthly_report_premium_title': 'Smart reports are Premium',
      'monthly_report_premium_subtitle':
          'See timeline, monthly evolution, and detailed insights.',
      'monthly_report_premium_perk1': 'Timeline of your money',
      'monthly_report_premium_perk2': 'Financial health score',
      'monthly_report_premium_perk3': 'Personalized monthly insights',
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
      'month_salary': 'Monthly entries',
      'view_all_entries': 'View all entries',
      'income_modal_new_title': 'New entry',
      'income_modal_edit_title': 'Edit entry',
      'income_modal_fixed': 'Fixed',
      'income_modal_variable': 'Variable',
      'income_modal_fixed_info_title': 'Fixed entry',
      'income_modal_variable_info_title': 'Variable entry',
      'income_modal_fixed_info_body':
          'This entry applies only to the current month as a predictable entry.',
      'income_modal_variable_info_body':
          'This entry applies only to the current month and does not repeat by itself.',
      'income_modal_title_hint': 'Ex: Salary, Freelance',
      'income_modal_amount_label': 'Entry amount',
      'income_modal_amount_hint': '0.00',
      'income_modal_primary_title': 'Primary entry',
      'income_modal_error_fill': 'Fill the name and amount correctly.',
      'income_modal_error_save': 'Error saving entry.',
      'income_category_salary': 'Salary',
      'income_category_service': 'Service income',
      'income_category_yield': 'Yield',
      'income_category_bonus': 'Bonus',
      'income_category_other': 'Other entry',
      'profile_delete_account_title': 'Delete account',
      'profile_delete_account_subtitle': 'Permanent and irreversible action.',
      'profile_delete_account_body':
          'This removes your local and remote data and ends access to the app.',
      'profile_delete_account_password_label': 'Enter your password',
      'profile_delete_account_confirm': 'Delete account',
      'profile_delete_account_requires_password':
          'This account does not use a password to sign in. Use the original login method.',
      'profile_delete_account_invalid_password':
          'Invalid password. Please try again.',
      'profile_delete_account_failed':
          'We could not delete the account right now.',
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
      'add_extra_income': 'Add entry',
      'income_label_placeholder': 'Entry name',
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
      'credit_cards_title': 'Tarjetas de crédito',
      'credit_cards_empty': 'Ninguna tarjeta registrada.',
      'card_add': 'Agregar tarjeta',
      'card_name': 'Nombre de la tarjeta',
      'simulator': 'Simulador',
      'calc_title': 'Simulador de Inversiones',
      'calc_subtitle':
          'Proyecte el futuro de su patrimonio con interés compuesto.',
      'monthly_contribution': 'Aporte Mensual',
      'annual_rate': 'Tasa Anual (%)',
      'period_years': 'Período (años)',
      'calc_disclaimer':
          'Simulación basada en aportes mensuales con capitalización mensual de intereses.',
      'final_total': 'Total Final',
      'total_invested': 'Total Invertido',
      'profit': 'Rendimiento',
      'equity_evolution': 'Evolución del Patrimonio',
      'total_with_interest': 'Total (con intereses)',
      'invested_capital': 'Capital Invertido',
      'year_label': 'Año',
      'premium_calc_title': 'Calculadora de Libertad',
      'premium_calc_subtitle':
          'Simula tu camino hacia la independencia financiera con el Plan Premium.',
      'no_entries_found_title': 'No se encontraron lanzamientos',
      'no_entries_found': 'Aún no hay registros para este período.',
      'day': 'Día',
      'card': 'Tarjeta',
      'paid': 'Pagado',
      'edit_entry': 'Editar lanzamiento',
      'delete_entry': 'Eliminar lanzamiento',
      'login': 'Entrar',
      'register': 'Crear cuenta',
      'email': 'Correo',
      'password': 'Contraseña',
      'forgot_password': 'Olvidé mi contraseña',
      'missions_month': 'Misiones del mes',
      'missions_week': 'Misiones de la semana',
      'missions_day': 'Misiones del día',
      'login_required_missions': 'Inicia sesión para ver tus misiones.',
      'onboarding_title': 'Tu primer plan',
      'onboarding_heading': 'Vamos a entender tu objetivo financiero',
      'onboarding_subtitle':
          'Estas respuestas personalizan misiones y desbloqueos. Tus datos se guardan en la nube.',
      'onboarding_objectives': 'Objetivos',
      'onboarding_missing_fields':
          'Completa ingresos, profesión y al menos un objetivo.',
      'session_expired_login': 'Sesión expirada. Inicia sesión nuevamente.',
      'save_failed_try_again': 'No fue posible guardar. Intenta de nuevo.',
      'profession': 'Profesión',
      'onboarding_primary_income_label': 'Entrada principal',
      'onboarding_income_fallback_label': 'Ingreso {n}',
      'monthly_income': 'Entradas mensuales (R\$)',
      'continue': 'Continuar',
      'goals': 'Metas',
      'goal': 'Meta',
      'save_goal': 'Guardar Meta',
      'completed_label': 'Completadas',
      'language_pt': 'Portugués',
      'language_en': 'Inglés',
      'language_es': 'Español',
      'mission_type_daily': 'DIARIA',
      'mission_type_weekly': 'SEMANAL',
      'mission_type_monthly': 'MENSUAL',
      'missions_premium_title': 'Misiones exclusivas para Premium',
      'missions_premium_subtitle':
          'Gana XP real y desbloquea niveles con desafíos validados por tu progreso en la app.',
      'missions_premium_perk1': 'Misiones diarias, semanales y mensuales',
      'missions_premium_perk2': 'XP doble y niveles exclusivos',
      'missions_premium_perk3': 'Progreso y desbloqueos premium',
      'mission_daily_review_expense': 'Revisa 1 gasto',
      'mission_daily_tip': 'Ver insights del día',
      'mission_daily_emotional_spend': 'Clasifica un gasto emocional',
      'mission_daily_log_expense': 'Registra al menos un gasto hoy',
      'mission_daily_balance_repair':
          'Ajusta gastos para terminar el mes en positivo',
      'mission_daily_variable_reflect':
          'Lista tres gastos variables para revisar',
      'mission_daily_invest_review':
          'Mira tus inversiones y toma una acción pequeña',
      'mission_weekly_budget': 'Registra gastos en 3 días de la semana',
      'mission_weekly_leisure': 'Revisa tu ocio de la semana',
      'mission_weekly_no_impulse_7': 'Pasa 7 días sin gasto impulsivo',
      'mission_weekly_no_impulse_3': 'Pasa 3 días sin gasto impulsivo',
      'mission_weekly_variable_trim':
          'Pon un límite más bajo a los gastos variables esta semana',
      'mission_weekly_invest_review':
          'Revisa una inversión o dato de la calculadora esta semana',
      'mission_weekly_debt_action':
          'Diseña un movimiento para pagar deudas pendientes',
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
      'mission_objective_save_low': 'Define un monto mínimo para ahorrar',
      'mission_objective_security_high': 'Arma 1 mes de reserva de emergencia',
      'mission_objective_security_low': 'Define tu meta de reserva',
      'mission_objective_dream_high': 'Divide tu sueño en 3 hitos',
      'mission_objective_dream_low': 'Define el plazo del sueño',
      'mission_objective_invest_high': 'Ajusta tu asignación de inversiones',
      'mission_objective_invest_low':
          'Define cuánto quieres invertir en el mes',
      'mission_objective_emergency_fund_high':
          'Verifica 2 meses de gastos en la reserva',
      'mission_objective_emergency_fund_low':
          'Empieza con 1 meta simple de reserva',
      'mission_objective_generic_high':
          'Define 1 acción concreta para el objetivo',
      'mission_objective_generic_low': 'Escribe tu objetivo con un plazo',
      'objective_dream': 'Conquistar un sueño',
      'objective_property': 'Comprar una vivienda',
      'objective_trip': 'Hacer un viaje',
      'objective_debts': 'Salir de deudas',
      'objective_save': 'Ahorrar dinero',
      'objective_security': 'Tener más seguridad',
      'objective_emergency_fund': 'Construir un fondo de emergencia',
      'objective_invest': 'Invertir mejor',
      'login_fill_email_password': 'Completa correo y contraseña.',
      'error_connect_server': 'Error al conectar con el servidor.',
      'reset_need_email':
          'Ingresa tu correo para recibir el enlace de reinicio.',
      'reset_sent': 'Enviamos un enlace de reinicio a tu correo.',
      'email_not_found': 'Correo no encontrado.',
      'login_invalid_email': 'Correo inválido.',
      'no_connection': 'Sin conexión a internet.',
      'reset_error_with_code': 'Error al procesar la recuperación: {code}.',
      'reset_title': 'Recuperar contraseña',
      'reset_subtitle': 'Enviaremos un enlace de reinicio a tu correo.',
      'reset_code_subtitle':
          'Ingresa el código de 5 dígitos y crea una nueva contraseña.',
      'reset_send_button': 'Enviar link',
      'reset_send_code_button': 'Enviar código',
      'reset_code_label': 'Código de recuperación',
      'reset_code_hint': 'Ingresa el código de 5 números',
      'reset_verify_button': 'Validar código',
      'reset_new_password': 'Nueva contraseña',
      'reset_new_password_title': 'Nueva contraseña',
      'reset_new_password_subtitle':
          'Define tu nueva contraseña para acceder a la cuenta.',
      'reset_confirm_password': 'Confirmar nueva contraseña',
      'reset_password_mismatch': 'Las contraseñas no coinciden.',
      'reset_confirm_button': 'Guardar nueva contraseña',
      'reset_confirmed': 'Contraseña actualizada.',
      'reset_code_sent':
          'Si este correo existe, enviamos un código de 5 dígitos. Expira en 5 minutos.',
      'reset_code_invalid': 'Código inválido. Usa 5 números.',
      'reset_code_expires_in': 'El código expira en {time}.',
      'reset_code_expired': 'Código expirado. Envía un nuevo código.',
      'reset_resend_button': 'Reenviar link',
      'reset_resend_code_button': 'Reenviar código',
      'reset_resend_button_timer': 'Reenviar en {time}',
      'reset_resend_wait': 'Espera 60 segundos para reenviar.',
      'reset_rate_limited': 'Demasiados intentos. Intenta más tarde.',
      'login_google_not_ready':
          'El inicio con Google aun no esta configurado. En Firebase, agrega el SHA-1 de Android y vuelve a descargar android/app/google-services.json.',
      'login_apple_not_ready': 'El inicio con Apple aún no está configurado.',
      'login_cancelled': 'Inicio de sesion cancelado.',
      'login_google': 'Entrar con Google',
      'login_apple': 'Entrar con Apple',
      'register_action': 'Registrarse',
      'register_required_fields': 'Completa todos los campos obligatorios.',
      'register_password_mismatch': 'Las contraseñas no coinciden.',
      'register_terms_required': 'Debes aceptar los términos para continuar.',
      'register_email_in_use': 'Este correo ya está en uso.',
      'register_invalid_email': 'Correo inválido.',
      'register_weak_password':
          'Contraseña muy débil. Usa al menos 8 caracteres con mayúscula, minúscula, número y carácter especial.',
      'register_email_not_enabled':
          'El registro por correo no está habilitado en Firebase.',
      'register_error_with_code': 'Error al crear la cuenta: {code}.',
      'register_success': 'Cuenta creada! Ahora inicia sesión.',
      'first_name': 'Nombre',
      'profile_property_value': 'Valor aproximado de inmuebles',
      'profile_invest_balance': 'Saldo total en inversiones',
      'wealth_info_title': 'Patrimonio e Inversiones',
      'last_name': 'Apellido',
      'birth_date': 'Fecha de nacimiento',
      'gender': 'Sexo',
      'confirm_password': 'Confirmar contraseña',
      'register_terms_text':
          'Acepto los términos de uso y autorizo el almacenamiento en línea de mis datos.',
      'gender_not_informed': 'No informado',
      'gender_male': 'Masculino',
      'gender_female': 'Femenino',
      'gender_other': 'Otro',
      'login_invalid_credentials': 'Correo o contraseña incorrectos.',
      'profile_no_user':
          'Ningún usuario encontrado. Regístrate o inicia sesión.',
      'profile_required_fields': 'Completa los campos obligatorios.',
      'profile_invalid_income': 'Ingresa un ingreso mensual válido.',
      'profile_photo_upload_error': 'Error al subir la foto.',
      'profile_updated': 'Perfil actualizado.',
      'profile_no_user_body':
          'Ningún usuario encontrado.\nCrea una cuenta e inicia sesión.',
      'save': 'Guardar',
      'profile_change_photo': 'Cambiar foto',
      'profile_personal_data_title': 'Datos personales',
      'profile_personal_data_subtitle':
          'Mantén tus datos principales actualizados para que la app organice mejor tu camino.',
      'profile_income_title': 'Ingreso',
      'profile_income_subtitle':
          'Tu ingreso es la base de límites, proyecciones y recomendaciones del mes.',
      'profile_primary_income_label': 'Entrada principal',
      'profile_income_delete_title': 'Eliminar ingreso fijo',
      'profile_income_delete_body':
          '¿Quieres quitar solo este mes o eliminarlo para todos los meses siguientes?',
      'profile_income_delete_scope_month': 'Solo este mes',
      'profile_income_delete_scope_future': 'Meses siguientes',
      'select': 'Seleccionar',
      'login_blocked': 'Acceso bloqueado. Contacta a: contato@voolo.com',
      'login_failed_try_again': 'No se pudo iniciar sesión. Intenta de nuevo.',
      'unknown_route_title': 'Ruta no encontrada',
      'unknown_route_body':
          'La ruta "{route}" no existe.\nRevisa AppRoutes y tus Navigator.pushNamed().',
      'premium_cta': 'Hazte Premium',
      'premium_badge': 'Premium',
      'premium_dialog_title': 'Hazte Premium',
      'premium_cancel_anytime': 'Cancela cuando quieras.',
      'premium_dialog_choose_plan': 'Elige tu plan premium:',
      'premium_checkout_secure_title': 'Pago seguro',
      'premium_checkout_secure_body':
          'La suscripción se abre en el navegador y queda vinculada a tu cuenta. No hay compra dentro de la app.',
      'premium_checkout_monthly_title': 'Plan mensual',
      'premium_checkout_monthly_subtitle':
          '7 días de prueba. Cancela cuando quieras.',
      'premium_checkout_yearly_title': 'Plan anual',
      'premium_checkout_yearly_subtitle':
          '7 días de prueba. Mejor costo-beneficio para mantener Premium.',
      'premium_checkout_includes_title': 'Qué desbloqueas',
      'premium_checkout_feature_1': 'Informes inteligentes y detalles premium.',
      'premium_checkout_feature_2': 'Metas, misiones e insights avanzados.',
      'premium_checkout_feature_3':
          'Acceso continuo mientras la suscripción esté activa.',
      'premium_checkout_cta': 'Continuar',
      'premium_checkout_footer':
          'Después de completar la suscripción, vuelve a la app. El estado premium se actualizará desde el servidor.',
      'premium_checkout_login_required': 'Inicia sesión para continuar.',
      'premium_checkout_open_error': 'No se pudo abrir la suscripción ahora.',
      'premium_checkout_opened_snack':
          'Checkout abierto. Completa la suscripción en el navegador.',
      'profile_premium_section_title': 'Suscripción Premium',
      'profile_premium_section_subtitle':
          'Tu suscripción está activa. Adminístrala o cancélala desde el portal seguro.',
      'profile_premium_section_body':
          'Cuando canceles, el acceso continúa hasta el final del periodo pagado.',
      'profile_premium_cancel_cta': 'Cancelar suscripción',
      'profile_paddle_portal_error':
          'No se pudo abrir el portal de suscripciones ahora.',
      'profile_paddle_login_required':
          'Inicia sesión para gestionar la suscripción.',
      'profile_subscription_login_required':
          'Inicia sesión para cancelar la suscripción.',
      'profile_subscription_cancelled':
          'Suscripción cancelada. El acceso continúa hasta el final del periodo pagado.',
      'profile_subscription_action_error':
          'No se pudo completar la solicitud ahora.',
      'premium_plan_monthly_title': 'Plan mensual - R\$ 29,90/mes',
      'premium_plan_monthly_subtitle':
          'Renovación automática. Cancela cuando quieras.',
      'premium_plan_yearly_title': 'Plan anual - R\$ 299,90/año',
      'premium_plan_yearly_subtitle':
          'Pago anual con acceso premium durante todos los meses del período.',
      'premium_dialog_body':
          'Desbloquea misiones, informes inteligentes, calculadora de inversiones y alertas de pagos.\n\nContáctanos para activar Premium.',
      'premium_upsell_title': 'Más control, más claridad, más resultados',
      'premium_welcome_title': 'Premium activado!',
      'premium_welcome_body':
          'Excelente elección con Voolo. Te deseamos claridad, control y calma financiera.',
      'premium_welcome_tip':
          '¿Quieres un recorrido guiado? Te muestro cada función en su lugar.',
      'premium_welcome_yes': 'Quiero onboarding',
      'premium_welcome_no': 'Ahora no',
      'premium_onboarding_title': 'Bienvenido a Premium',
      'premium_onboarding_subtitle':
          'Hagamos un recorrido por la app y veamos cada función en acción.',
      'premium_onboarding_next': 'Siguiente',
      'premium_onboarding_finish': 'Finalizar',
      'premium_onboarding_skip': 'Saltar',
      'premium_onboarding_open': 'Mostrar en la app',
      'premium_onboarding_progress': '{done} de {total} pasos completados',
      'premium_insights_title': 'Análisis de Élite',
      'premium_insights_subtitle':
          'Desbloquea insights avanzados y alertas inteligentes para potenciar tu evolución financiera.',
      'premium_step_reports_title': 'Reportes premium',
      'premium_step_reports_body':
          'Resumen visual del mes y comparativos claros.',
      'premium_step_reports_tip':
          'Toca "Mostrar en la app" para ver dónde está.',
      'premium_step_goals_title': 'Metas inteligentes',
      'premium_step_goals_body':
          'Metas con progreso claro y desafíos semanales.',
      'premium_step_goals_tip': 'Toca "Mostrar en la app" para abrir Metas.',
      'premium_step_invest_title': 'Calculadora de inversiones',
      'premium_step_invest_body':
          'Simula escenarios y planifica a largo plazo.',
      'premium_step_invest_tip': 'Toca "Mostrar en la app" y prueba valores.',
      'premium_step_missions_title': 'Misiones premium',
      'premium_step_missions_body': 'Desafíos diarios, semanales y mensuales.',
      'premium_step_missions_tip':
          'Toca "Mostrar en la app" para ver misiones.',
      'premium_step_insights_title': 'Insights inteligentes',
      'premium_step_insights_body':
          'Alertas y consejos para tu próxima acción.',
      'premium_step_insights_tip':
          'Toca "Mostrar en la app" para abrir Insights.',
      'premium_tour_calculator_title': 'Calculadora de inversiones',
      'premium_tour_calculator_body':
          'Simula aportes y tasa para ver resultados futuros.',
      'premium_tour_calculator_location':
          'Dónde está: botón Calculadora en la pantalla principal.',
      'premium_tour_calculator_tip': 'Compara escenarios de 5, 10 y 20 años.',
      'premium_tour_goals_title': 'Metas inteligentes',
      'premium_tour_goals_body':
          'Tus metas aparecen aquí con progreso y desafíos semanales.',
      'premium_tour_goals_location':
          'Dónde está: menú lateral > Metas o botón Metas en home.',
      'premium_tour_goals_tip': 'Crea una meta y marca el avance.',
      'premium_tour_missions_title': 'Misiones premium',
      'premium_tour_missions_body':
          'Misiones diarias, semanales y mensuales para mantener constancia.',
      'premium_tour_missions_location': 'Dónde está: menú lateral > Misiones.',
      'premium_tour_missions_tip': 'Completa misiones y sigue tu XP.',
      'premium_tour_reports_title': 'Reportes premium',
      'premium_tour_reports_body':
          'Resumen mensual con totales y comparativos.',
      'premium_tour_reports_location': 'Dónde está: menú lateral > Reportes.',
      'premium_tour_reports_tip':
          'Cambia el mes arriba para comparar periodos.',
      'premium_tour_insights_title': 'Insights',
      'premium_tour_insights_body':
          'Alertas y sugerencias para equilibrar tus gastos.',
      'premium_tour_insights_location': 'Dónde está: menú lateral > Insights.',
      'premium_tour_insights_tip': 'Sigue el foco principal y mejora tu mes.',
      'close': 'Cerrar',
      'ok': 'OK',
      'previous_month': 'Mes anterior',
      'next_month': 'Próximo mes',
      'user_label': 'Usuario',
      'security': 'Seguridad',
      'settings': 'Configuraciones',
      'login_required_calculator':
          'Inicia sesión para acceder a la calculadora.',
      'investment_calculator': 'Calculadora de inversiones',
      'investment_premium_title':
          'Calculadora de inversiones desbloqueada en Premium',
      'investment_premium_subtitle':
          'Simula aportes y ve el crecimiento real con proyecciones avanzadas.',
      'investment_premium_perk1': 'Proyecciones de 5, 10 y 20 años',
      'investment_premium_perk2': 'Informes con insights personalizados',
      'investment_premium_perk3': 'Puntaje de salud financiera',
      'investment_projection_title':
          'Proyección con aporte mensual + interés compuesto',
      'investment_monthly_contribution': 'Aporte mensual (R\$)',
      'investment_annual_rate': 'Tasa anual (%)',
      'investment_invalid_inputs':
          'Ingresa un aporte y una tasa mayores que cero para ver la proyección.',
      'investment_disclaimer':
          'Nota: esta proyección es una simulación. Los resultados reales varían según mercado, tasas e impuestos.',
      'investment_total_contribution': 'Aporte total',
      'investment_profit': 'Rendimiento',
      'investment_final_total': 'Total final',
      'investment_reserve_emergency_title': 'Reserva de emergencia (prioridad)',
      'investment_reserve_emergency_subtitle':
          'Simple y líquida hasta completar la reserva.',
      'investment_fixed_liquid_label': 'Renta fija con liquidez (Selic/CDB)',
      'investment_fixed_long_label': 'Renta fija a largo plazo',
      'investment_variable_diversified_label': 'Variable diversificada',
      'investment_reserve_emergency_months_label':
          'Reserva de emergencia (meses)',
      'investment_allocation_title': 'Asignación sugerida (clases de activos):',
      'investment_high_risk_label': 'Mayor riesgo',
      'investment_risk_aggressive': 'Agresivo',
      'investment_risk_moderate': 'Moderado',
      'investment_risk_conservative': 'Conservador',
      'investment_allocate_now': 'Asignar ahora',
      'investment_allocation_chosen': 'Asignación elegida',
      'investment_allocation_not_defined':
          'La asignación aún no está definida.',
      'investment_allocation_unlock_hint':
          'Complétalo para desbloquear tus sugerencias de asignación.',
      'investment_allocation_define_value': 'Define un valor para asignar.',
      'investment_profile_updated': 'Perfil actualizado.',
      'investment_profile_local_applied':
          'No fue posible calcular en l?nea; us? un c?lculo local simple.',
      'investment_profile_local_saved': 'Perfil aplicado localmente.',
      'investment_plan_title': 'Tu plan de inversiones',
      'investment_plan_edit_button': 'Editar plan',
      'investment_plan_quick_summary': 'Resumen r?pido de tu mes',
      'investment_plan_target_label': 'Aporte objetivo',
      'investment_plan_profile_label': 'Perfil',
      'investment_plan_reserve_label': 'Reserva',
      'investment_plan_goals_title': 'Metas',
      'investment_plan_save_button': 'Guardar',
      'investment_plan_saving_button': 'Guardando...',
      'investment_plan_setup_help':
          'Define metas simples (reserva y aporte). Puedes ajustarlas despu?s.',
      'investment_plan_target_input_label': 'Aporte mensual objetivo (R\$)',
      'investment_plan_suggestions_title': 'Sugerencias para este mes',
      'investment_plan_simulate_label': 'Simular valor (opcional)',
      'investment_plan_simulate_hint':
          'Si est? vac?o, usamos el aporte mensual objetivo.',
      'investment_plan_suggestions_empty':
          'Define un valor (aporte) para ver sugerencias.',
      'investment_plan_save_choice': 'Guardar esta elecci?n',
      'investment_plan_choice_saved': 'Perfil guardado',
      'investment_step_simple_title': 'Primer paso (simple)',
      'investment_step_simple_subtitle':
          'Equilibrio entre seguridad y crecimiento.',
      'investment_step_simple_note':
          'Si quieres dejarlo aún más simple: reduce "alto riesgo" a 0% y aumenta el ETF.',
      'investment_step_aggressive_title': 'Agresivo (diversificado)',
      'investment_step_aggressive_subtitle':
          'Más volatilidad, siempre con una base segura.',
      'investment_step_aggressive_note':
          'Si la volatilidad te molesta, aumenta la parte de "liquidez" y reduce el ETF.',
      'investment_step_moderate_title': 'Moderado (simple)',
      'investment_step_moderate_subtitle': 'Para empezar sin estrés.',
      'investment_step_moderate_note':
          'Si la volatilidad te molesta, aumenta la parte de "liquidez" y reduce el ETF.',
      'investment_step_moderate_ipca_title': 'Moderado con IPCA',
      'investment_step_moderate_ipca_subtitle':
          'Más protección de largo plazo, manteniendo la simplicidad.',
      'investment_reserve_emergency_note_1':
          'Objetivo: 3-6 meses de costos esenciales en liquidez diaria.',
      'investment_reserve_emergency_note_2':
          'Después de completar la reserva, vuelve aquí y elige una asignación de largo plazo.',
      'investment_step_conservative_title': 'Inicio conservador',
      'investment_step_conservative_subtitle': 'Para salir de cero sin estrés.',
      'investment_step_conservative_note':
          'Cuando la reserva esté lista, puedes agregar un poco de IPCA+ o ETF.',
      'investment_step_conservative_long_title': 'Conservador + largo plazo',
      'investment_step_conservative_long_subtitle':
          'Un toque de largo plazo, manteniendo seguridad.',
      'investment_step_conservative_long_note':
          'Aumenta la parte de liquidez si prefieres más seguridad.',
      'example_500': 'Ej: 500',
      'example_12': 'Ej: 12',
      'years_label': '{years} años',
      'new_entry': 'Nuevo lanzamiento',
      'type': 'Tipo',
      'name': 'Nombre',
      'category': 'Categoría',
      'value_currency': 'Valor (R\$)',
      'due_day_optional': 'Día de vencimiento (opcional)',
      'card_due_day': 'Vencimiento de la tarjeta',
      'card_select': 'Tarjeta de crédito',
      'card_due_day_value': 'Vencimiento de la tarjeta: día {day}',
      'card_required': 'Registra una tarjeta primero.',
      'no_due_date': 'Sin vencimiento',
      'day_label': 'Día {n}',
      'credit_card_charge': 'Cargo en tarjeta de crédito',
      'card_recurring': 'Compra recurrente en la tarjeta',
      'card_recurring_short': 'Recurrente',
      'card_paid_badge': 'Factura pagada',
      'card_unknown': 'Tarjeta desconocida',
      'bill_paid': 'Cuenta pagada',
      'card_invoice_paid': 'Factura de la tarjeta pagada',
      'installments_quantity': 'Cantidad de cuotas',
      'credit_card_bills_title': 'Facturas de la tarjeta',
      'card_due_day_label': 'Vencimiento día {day}',
      'card_insight_title': 'Facturas de la tarjeta en el mes',
      'card_insight_high':
          'Las facturas suman {value} ({pct}% del ingreso). Esto puede afectar tu presupuesto.',
      'card_insight_ok':
          'Las facturas suman {value} ({pct}% del ingreso). Dentro de lo esperado.',
      'expense_tip_fixed':
          'Consejo: Si completas el vencimiento, Jetx avisará 3 días antes y el día (cuando activemos notificaciones).',
      'expense_tip_variable':
          'Consejo: Gastos variables cuentan solo en el mes actual.',
      'income_variable_tip':
          '¿Ingreso variable? Usa el promedio de los últimos 3 meses para evitar frustraciones.',
      'credit_card_tip':
          'Las cuotas comprometen tu ingreso futuro. Úsalas con cuidado.',
      'expense_high_tip':
          'Este gasto representa {pct}% de tu presupuesto mensual. Lo ideal es hasta {ideal}%.',
      'expense_low_tip':
          'Con este registro, esta área queda en {pct}% de tu presupuesto mensual. Lo ideal es al menos {ideal}%.',
      'expense_name_required': 'Escribe el nombre.',
      'expense_value_required': 'Escribe un valor válido.',
      'installments_required': 'Informa la cantidad de cuotas.',
      'expense_type_fixed': 'Gasto fijo',
      'expense_type_variable': 'Gasto variable',
      'expense_type_fixed_short': 'Fijo',
      'expense_type_variable_short': 'Variable',
      'expense_type_investment_short': 'Inversion',
      'expense_type_investment': 'Inversión',
      'expense_category_housing': 'Vivienda',
      'expense_category_food': 'Alimentación',
      'expense_category_transport': 'Transporte',
      'expense_category_education': 'Educación',
      'expense_category_health': 'Salud',
      'expense_category_leisure': 'Ocio',
      'expense_category_subscriptions': 'Suscripciones',
      'expense_category_investment': 'Inversion',
      'expense_category_debts': 'Deudas',
      'expense_category_other': 'Otros',
      'payment_method_debit': 'Debito',
      'payment_method_credit': 'Credito',
      'payment_method_investment': 'Inversion',
      'payment_impact_balance_now': 'Sale del saldo ahora',
      'payment_impact_invoice': 'Va a la factura',
      'payment_impact_invoice_installment':
          'Va a la factura ({current}/{total})',
      'expense_due_statement_day': 'Factura dia {day}',
      'mission_complete_title': 'Completar misión',
      'mission_complete_note_label': 'Comentario de finalización (opcional)',
      'mission_complete_note_hint': 'Cuenta qué hiciste y cómo lo hiciste.',
      'mission_note_title': 'Comentario de la misión',
      'mission_note_view': 'Ver comentario',
      'mission_complete_cta': '+{xp} XP',
      'mission_require_expense_today':
          'Registra al menos 1 gasto hoy para completar.',
      'mission_require_report_today':
          'Abre el reporte de este mes hoy para completar.',
      'mission_require_weekly_expenses':
          'Registra gastos en al menos 3 días de la semana.',
      'mission_require_previous_month':
          'Ten al menos un mes anterior para comparar.',
      'mission_require_goal': 'Crea al menos 1 meta personal para completar.',
      'mission_require_default':
          'Completa la actividad en la app para finalizar.',
      'cancel': 'Cancelar',
      'back': 'Atrás',
      'finish': 'Finalizar',
      'onboarding_objectives_title': 'Para empezar, ¿cuáles son tus objetivos?',
      'onboarding_objectives_subtitle':
          'Esto nos ayuda a sugerir metas y misiones más alineadas contigo.',
      'onboarding_objectives_required': 'Elige al menos un objetivo.',
      'onboarding_profession_title': '¿Cuál es tu profesión?',
      'onboarding_profession_subtitle':
          'Queremos entender tu momento profesional para personalizar tu camino.',
      'onboarding_profession_required': 'Ingresa tu profesión.',
      'onboarding_income_title': '¿Cuál es tu entrada mensual?',
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
      'timeline_balanced': 'Tu mes está equilibrado. ¡Mantente así!',
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
          'Buena decisión: tu presupuesto está equilibrado.',
      'plan_title': 'Plan del mes',
      'plan_subtitle': 'Acciones rápidas para mejorar este mes.',
      'plan_next_action': 'Próxima acción',
      'plan_action_variable': 'Reduce gastos variables al 25% del ingreso.',
      'plan_action_fixed':
          'Baja los gastos fijos a un máximo de 50% del ingreso.',
      'plan_action_invest': 'Destina {value} a inversiones.',
      'plan_action_ok': 'Estás equilibrado. Mantente así.',
      'alert_title': 'Alertas inteligentes',
      'alert_add_income': 'Registra tu ingreso para activar alertas.',
      'alert_fixed_high': 'Gastos fijos por encima de 60% del ingreso.',
      'alert_variable_high': 'Gastos variables por encima de 35% del ingreso.',
      'alert_leisure_high': 'Ocio por encima de 25% del ingreso.',
      'alert_invest_low': 'Inversiones por debajo de 10% del ingreso.',
      'alert_negative_balance': 'Tu saldo del mes es negativo.',
      'alert_ok': 'Todo bien por aquí. Sigue constante.',
      'tips_title': 'Consejos del mes',
      'monthly_report_title': 'Reporte mensual',
      'monthly_report_empty': 'No se encontraron datos para este mes.',
      'monthly_report_month_spending': 'Gasto del mes',
      'monthly_report_total_spent': 'Gasto total',
      'monthly_report_total_invested': 'Total invertido',
      'monthly_report_total_invested_info':
          'Este valor suma solo lo invertido a lo largo de los meses. Los rendimientos no aparecen aquí.',
      'monthly_report_balance': 'Saldo del mes',
      'monthly_report_entries_filters': 'Lanzamientos (filtros)',
      'monthly_report_adjust_balance': 'Ajustar saldo del mes',
      'monthly_report_timeline': 'Línea de tiempo',
      'monthly_report_card_credit': 'Tarjeta de crédito',
      'monthly_report_no_card': 'Ninguna tarjeta registrada',
      'monthly_report_card_due_day': 'Vencimiento de la tarjeta: día {day}',
      'monthly_report_due_day_optional': 'Día de vencimiento (opcional)',
      'monthly_report_loading': 'Cargando...',
      'monthly_report_login_required': 'Inicia sesión para acceder a reportes.',
      'monthly_report_premium_title': 'Los reportes inteligentes son Premium',
      'monthly_report_premium_subtitle':
          'Ve la línea de tiempo, la evolución mensual y los insights detallados.',
      'monthly_report_premium_perk1': 'Línea de tiempo de tu dinero',
      'monthly_report_premium_perk2': 'Puntaje de salud financiera',
      'monthly_report_premium_perk3': 'Insights mensuales personalizados',
      'tip_housing_high':
          'Vivienda por encima de 35%. Considera opciones para reducir este costo.',
      'compare_title': 'Comparativo mensual',
      'compare_no_data': 'Aún no hay datos del mes anterior.',
      'insights_title': 'Insights del mes',
      'insights_subtitle': 'Centraliza consejos y alertas aquí.',
      'insights_card_subtitle': 'Alertas, plan y comparativo en un solo lugar.',
      'insights_cta': 'Abrir',
      'habit_title': 'Hábitos financieros',
      'habit_streak': 'Racha {days} días',
      'habit_log_expense': 'Registrar gastos del día',
      'habit_log_expense_subtitle': 'Mantén tus gastos al día.',
      'habit_check_budget': 'Revisar el presupuesto',
      'habit_check_budget_subtitle': 'Confirma si estás en el plan.',
      'habit_invest': 'Separar para invertir',
      'habit_invest_subtitle': 'Reserva un valor semanal.',
      'month_entries': 'Lanzamientos del mes',
      'no_entries_yet': 'Aún no hay lanzamientos.',
      'month_salary': 'Entradas del mes',
      'view_all_entries': 'Ver todos los lanzamientos',
      'income_modal_new_title': 'Nueva entrada',
      'income_modal_edit_title': 'Editar entrada',
      'income_modal_fixed': 'Fijo',
      'income_modal_variable': 'Variable',
      'income_modal_fixed_info_title': 'Entrada fija',
      'income_modal_variable_info_title': 'Entrada variable',
      'income_modal_fixed_info_body':
          'Esta entrada se aplica solo al mes actual como una entrada previsible.',
      'income_modal_variable_info_body':
          'Esta entrada se aplica solo al mes actual y no se repite sola.',
      'income_modal_title_hint': 'Ej: Salario, Freelance',
      'income_modal_amount_label': 'Monto de la entrada',
      'income_modal_amount_hint': '0,00',
      'income_modal_primary_title': 'Entrada principal',
      'income_modal_error_fill': 'Completa correctamente el nombre y el valor.',
      'income_modal_error_save': 'Error al guardar la entrada.',
      'income_category_salary': 'Salario',
      'income_category_service': 'Prestación de servicio',
      'income_category_yield': 'Rendimiento',
      'income_category_bonus': 'Bono',
      'income_category_other': 'Otra entrada',
      'profile_delete_account_title': 'Eliminar cuenta',
      'profile_delete_account_subtitle': 'Acción permanente e irreversible.',
      'profile_delete_account_body':
          'Esto elimina tus datos locales y remotos y cierra el acceso a la app.',
      'profile_delete_account_password_label': 'Ingresa tu contraseña',
      'profile_delete_account_confirm': 'Eliminar cuenta',
      'profile_delete_account_requires_password':
          'Esta cuenta no usa contraseña para iniciar sesión. Usa el método de acceso original.',
      'profile_delete_account_invalid_password':
          'Contraseña inválida. Inténtalo de nuevo.',
      'profile_delete_account_failed':
          'No fue posible eliminar la cuenta ahora.',
      'goals_title': 'Metas',
      'goals_add_new': 'Nueva meta',
      'goals_title_label': 'Título de la meta',
      'goals_type_label': 'Tipo',
      'goals_type_income': 'Ingreso / Carrera',
      'goals_type_education': 'Educación',
      'goals_type_personal': 'Personal',
      'goals_description_optional': 'Descripción (opcional)',
      'goals_title_required': 'Escribe un título para la meta.',
      'goals_income_exists': 'Esta meta ya existe como obligatoria del año.',
      'goals_login_required': 'Inicia sesión para acceder a metas.',
      'goals_subtitle':
          'Sigue tu progreso, desafíos semanales y objetivos estratégicos.',
      'goals_empty_year': 'Ninguna meta registrada para este año.',
      'goals_tip_hold_remove':
          'Consejo: mantén presionada una meta (no obligatoria) para eliminarla.',
      'goals_completed_count': '{done} de {total} metas completadas',
      'goals_already_in_list': 'Esta meta ya está en tu lista.',
      'goals_section_year': 'Metas del año',
      'goals_premium_title': 'Metas avanzadas son Premium',
      'goals_premium_perk1': 'Progreso anual en tiempo real',
      'goals_premium_perk2': 'Desafíos semanales guiados',
      'goals_premium_perk3': 'Metas inteligentes basadas en tu saldo',
      'goals_no_month_data': 'Sin datos del mes',
      'goals_month_balance': 'Saldo del mes: {value}',
      'save_cloud_error': 'Fallo al guardar en la nube. Verifica tu conexión.',
      'goals_progress_section': 'Tu progreso',
      'goals_suggestions_section': 'Sugerencias para ti',
      'goals_weekly_section': 'Desafíos de la semana',
      'goals_weekly_empty': 'Sin desafíos esta semana. Vuelve mañana.',
      'goals_year_progress': 'Progreso anual',
      'mandatory': 'Obligatoria',
      'goal_action_complete': 'Completar',
      'goal_action_add': 'Agregar',
      'goal_income_title': 'Aumentar ingresos',
      'goal_income_desc': 'Crea un plan para aumentar tus ingresos este año.',
      'goal_weekly_finance_content_title':
          'Ver contenido sobre planificación financiera',
      'goal_weekly_finance_content_desc':
          '15 minutos de lectura o video para reforzar lo básico.',
      'goal_weekly_review_expenses_title': 'Revisar gastos del mes',
      'goal_weekly_review_expenses_desc':
          'Marca gastos variables y elige 1 ajuste.',
      'goal_weekly_invest_10_title': 'Separar 10% para invertir',
      'goal_weekly_invest_10_desc': 'Dirige una parte del saldo a inversiones.',
      'goal_weekly_spend_limit_title': 'Crear un techo semanal de gastos',
      'goal_weekly_spend_limit_desc':
          'Define un límite y acompáñalo hasta el domingo.',
      'goal_weekly_start_finance_book_title': 'Empezar un libro de finanzas',
      'goal_weekly_start_finance_book_desc':
          'Lee 10 páginas y marca como hecho.',
      'goal_suggest_income_title': 'Registrar ingreso mensual',
      'goal_suggest_income_desc':
          'Agrega tu ingreso para desbloquear la planificación.',
      'goal_suggest_reduce_variable_title': 'Reducir 10% en variables',
      'goal_suggest_reduce_variable_desc':
          'Ajusta gastos no esenciales en las próximas semanas.',
      'goal_suggest_invest_title': 'Aumentar inversiones',
      'goal_suggest_invest_desc': 'Meta de aporte mensual consistente.',
      'goal_suggest_emergency_title': 'Armar fondo de emergencia',
      'goal_suggest_emergency_desc': 'Objetivo de 3 a 6 meses de costo fijo.',
      'goal_suggest_education_title': 'Plan de educación financiera',
      'goal_suggest_education_desc': 'Estudiar 30 min por semana.',
      'premium_subtitle_short': 'Desbloquea funciones exclusivas',
      'timeline_title': 'Línea de tiempo',
      'timeline_positive_streak': 'Racha positiva',
      'timeline_positive_streak_desc':
          'Las inversiones crecieron durante {months} meses consecutivos.',
      'timeline_balance_alert': 'Alerta de equilibrio',
      'timeline_balance_alert_desc':
          'Las variables superaron a las fijas. Revisa los gastos flexibles.',
      'timeline_control_ok': 'Control al día',
      'timeline_control_ok_desc':
          'Los fijos están controlados en relación a los gastos variables.',
      'timeline_balanced_month': 'Mes equilibrado',
      'timeline_balanced_month_desc':
          'No se detectó ninguna variación relevante.',
      'add_extra_income': 'Agregar entrada',
      'income_label_placeholder': 'Nombre de la entrada',
      'offline_message': 'Estás desconectado. Conéctate a una red.',
    }
  };

  static bool _looksMojibake(String value) {
    // Common UTF-8-as-Latin1 artifacts (mojibake) seen in this codebase:
    // "RelatÃ³rios", "MissÃµes", "aÃ§Ãµes", "â‰¥", etc.
    return value.contains('Ã') ||
        value.contains('Â') ||
        value.contains('â') ||
        value.contains('�');
  }

  static const Map<int, int> _cp1252ToByte = {
    0x20AC: 0x80, // €
    0x201A: 0x82, // ‚
    0x0192: 0x83, // ƒ
    0x201E: 0x84, // „
    0x2026: 0x85, // …
    0x2020: 0x86, // †
    0x2021: 0x87, // ‡
    0x02C6: 0x88, // ˆ
    0x2030: 0x89, // ‰
    0x0160: 0x8A, // Š
    0x2039: 0x8B, // ‹
    0x0152: 0x8C, // Œ
    0x017D: 0x8E, // Ž
    0x2018: 0x91, // ‘
    0x2019: 0x92, // ’
    0x201C: 0x93, // “
    0x201D: 0x94, // ”
    0x2022: 0x95, // •
    0x2013: 0x96, // –
    0x2014: 0x97, // —
    0x02DC: 0x98, // ˜
    0x2122: 0x99, // ™
    0x0161: 0x9A, // š
    0x203A: 0x9B, // ›
    0x0153: 0x9C, // œ
    0x017E: 0x9E, // ž
    0x0178: 0x9F, // Ÿ
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
    return byCode(code, key);
  }

  static String tr(BuildContext context, String key, Map<String, String> vars) {
    var value = t(context, key);
    vars.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
  }

  static String byCode(String code, String key) {
    final raw = _values[code]?[key] ?? _values['pt']?[key] ?? key;
    final extra = appStringsExtra[code]?[key] ?? appStringsExtra['pt']?[key];
    return _fixEncodingIfNeeded(raw == key && extra != null ? extra : raw);
  }

  static String trByCode(
    String code,
    String key,
    Map<String, String> vars,
  ) {
    var value = byCode(code, key);
    vars.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
  }
}
