const Map<String, Map<String, String>> appStringsExtra = {
  'pt': {
    'budgets': 'Orçamentos',
    'investments_plan': 'Investimentos (Plano)',
    'debts_exit': 'Sair das Dívidas',
    'missions_tagline': 'Desafios que valem dinheiro no bolso.',
    'xp_total': 'XP Total',
    'level_label': 'Nível {level}',
    'level_progress_next': '{pct}% para o próximo nível',
    'financial_level_1': 'Iniciante',
    'financial_level_2': 'Organizado',
    'financial_level_3': 'Planejador',
    'financial_level_4': 'Investidor',
    'missions_xp_to_next_level': 'Faltam {xp} XP para Nível {level}',
    'missions_auto_info': 'Missão automática: concluída por ações no app.',
    'missions_complete_failed': 'Não foi possível concluir agora.',
    'missions_note_hint': 'Escreva aqui...',
    'missions_note_min': 'Mínimo: {min} caracteres',
    'mission_status_completed': 'Concluída',
    'mission_status_automatic': 'Automática',
    'mission_status_automatic_completed': 'Concluída automaticamente',
    'mission_action_collect': 'Coletar',
    'mission_action_write': 'Escrever',
    'mission_ready_collect': 'Pronta para coletar',
    'mission_write_to_complete': 'Escreva para concluir',
    'mission_in_progress': 'Em progresso',
    'mission_done': 'Feito',
    'mission_pending': 'Pendente',
    'ratio_variable': 'Variáveis',
    'ratio_fixed': 'Fixos',
    'ratio_invest': 'Invest.',
    'ratio_buffer': 'Sobra',
    'ratio_distribution_title': 'Distribuição do mês',
    'ratio_distribution_subtitle':
        'Fixo, variável, investimento e sobra em uma leitura rápida.',
    'ratio_tip_fixed': 'Aqui entram as despesas mais recorrentes do seu mes.',
    'ratio_tip_variable':
        'Aqui entra o que oscila conforme seu consumo no mes.',
    'ratio_tip_invest': 'Tente investir pelo menos 15-20% de sua renda mensal.',
    'ratio_tip_buffer':
        'Este e o valor que ainda esta livre no fim do seu mes.',
    'dashboard_base_income': 'Lançamentos do mês',
    'edit_short': 'Editar',
    'financial_position_available': 'Restante do mes',
    'financial_position_with_invoice':
        'Considerando a fatura atual, ficam {value} livres no mes.',
    'financial_position_invoice_note':
        'Ja considera a fatura em aberto deste mes.',
    'financial_position_without_invoice':
        'Sem pressao relevante de cartao neste mes.',
    'financial_position_paid_out': 'Saídas do mês',
    'financial_position_current_invoice': 'Fatura atual',
    'financial_position_invested': 'Investido',
    'financial_position_total_account': 'Saldo total da conta',
    'bills_home_title': 'Faturas em aberto',
    'bills_home_subtitle':
        'Acompanhe o que esta pendente no cartao e marque quando pagar.',
    'bills_compact_title': 'Cartões e faturas',
    'bills_compact_subtitle':
        'Veja, adicione e acompanhe suas faturas sem sair da home.',
    'bills_add_card': 'Adicionar cartao',
    'bills_empty_title': 'Nenhum cartão cadastrado',
    'bills_empty_subtitle': 'Adicione um cartão para acompanhar a fatura aqui.',
    'bills_selected_due': 'Vence dia {day}',
    'bills_selected_clear': 'Sem fatura aberta neste ciclo.',
    'bills_selected_open': 'Em aberto',
    'bills_pay_popup_title': 'Pagar fatura',
    'bills_pay_popup_body': 'Marcar a fatura de {card} como paga por {value}?',
    'bills_installments': 'Parcelas neste mes: {value}',
    'bills_pay_cta': 'Pagar',
    'bills_paid_badge': 'Paga',
    'bills_reopen_cta': 'Reabrir',
    'bills_help_title': 'Cartões e faturas',
    'bills_help_body':
        'O app nao paga a fatura por voce. Aqui voce acompanha o valor do ciclo e pode apenas marcar se a fatura esta aberta ou ja foi paga fora do app.',
    'financial_position_committed_help_title': 'Comprometido',
    'financial_position_committed_help_body':
        'Mostra tudo que ja comprometeu sua renda no mes, incluindo debito, credito e investimentos.',
    'financial_position_current_invoice_help_title': 'Fatura atual',
    'financial_position_current_invoice_help_body':
        'Soma tudo o que foi lancado no cartao neste mes, considerando todos os cartoes.',
    'financial_position_invested_help_title': 'Investido',
    'financial_position_invested_help_body':
        'Mostra apenas o valor aportado neste mes. Rendimentos nao entram aqui.',
    'drawer_shortcuts': 'Atalhos',
    'drawer_preferences': 'Preferencias',
    'drawer_premium_active': 'Conta premium ativa',
    'drawer_essential_plan': 'Plano essencial do Voolo',
    'ratio_housing': 'Moradia',
    'essential_balance_title': 'Saldo do mês',
    'essential_balance_entries': 'Entradas: {value}',
    'essential_balance_exits': 'Saídas: {value}',
    'essential_balance_free': 'Saldo livre: {value}',
    'essential_guide_title': 'Trilha essencial',
    'essential_guide_subtitle_free':
        'No plano gratuito, siga estes 3 passos para comecar.',
    'essential_guide_subtitle_premium':
        'Comece por estes passos para organizar seu mes.',
    'essential_guide_progress': '{done} de {total} passos concluidos',
    'essential_guide_how': 'Como fazer',
    'essential_guide_do_now': 'Fazer agora',
    'essential_guide_skip': 'Pular',
    'essential_guide_finish': 'Concluir trilha',
    'essential_guide_later': 'Fazer depois',
    'essential_guide_never_again': 'Nao ver novamente',
    'essential_guide_action_expense_title': 'Registrar gasto',
    'essential_guide_action_expense_subtitle':
        'Adicione um gasto simples do dia.',
    'essential_guide_action_expense_help':
        'Toque em +, escolha gasto fixo ou variavel, preencha nome e valor, e salve. Exemplo: Mercado R\$ 85.',
    'essential_guide_action_card_title': 'Adicionar cartao de credito',
    'essential_guide_action_card_subtitle':
        'Cadastre o cartao para organizar faturas.',
    'essential_guide_action_card_help':
        'Abra Cartoes, toque em adicionar, informe nome e dia de vencimento da fatura. Se nao usar cartao, pode pular.',
    'essential_guide_action_balance_title': 'Ver saldo do mes',
    'essential_guide_action_balance_subtitle':
        'Veja o que entrou, saiu e sobrou.',
    'essential_guide_action_balance_help':
        'Toque em Ver saldo para abrir um resumo de entradas, saidas e saldo livre do mes.',
    'essential_guide_action_goal_title': 'Criar meta',
    'essential_guide_action_goal_subtitle':
        'Defina uma meta simples para manter foco.',
    'essential_guide_action_goal_help':
        'Abra Metas, escolha um objetivo e salve uma meta curta com valor e prazo.',
    'progress_levels_title': 'Progresso e niveis',
    'progress_levels_locked_subtitle':
        'Acompanhe XP, niveis e desbloqueios no Premium.',
    'compare_locked_subtitle':
        'Compare com o mes anterior para equilibrar melhor seus gastos.',
    'dashboard_empty_title': 'Comece sua jornada',
    'dashboard_empty_message':
        'Ainda nao temos dados suficientes. Registre seu primeiro gasto para iniciar a analise.',
    'dashboard_empty_cta': 'Adicionar primeiro gasto',
    'dashboard_premium_health_title':
        'Descubra onde seu mes aperta antes de faltar dinheiro',
    'dashboard_premium_health_subtitle':
        'No Premium, sua saude financeira e a distribuicao do mes mostram rapido o que esta pesado e onde ajustar para sobrar mais.',
    'score_health_label': 'Saude financeira',
    'score_tip_add_income':
        'Cadastre sua renda para calcular sua saude financeira.',
    'score_tip_overspending':
        'Seus gastos passaram sua renda ({pct} acima). Corte variaveis primeiro e renegocie fixos.',
    'score_tip_balanced':
        'Bom equilibrio. Mantenha consistencia e revise seu orcamento mensalmente.',
    'score_tip_budget_tight':
        'Seu orcamento esta apertado. Tente deixar pelo menos {pct} de sobra no mes.',
    'score_tip_housing_high':
        'Moradia esta alta. Busque ficar em ate {pct} da renda (aluguel/financiamento/condominio).',
    'score_tip_variable_high':
        'Gastos variaveis estao altos. Defina um teto de ate {pct} da renda para este mes.',
    'score_tip_fixed_high':
        'Gastos fixos estao altos. Tente reduzir para ate {pct} da renda com cortes e renegociacoes.',
    'score_tip_invest_zero':
        'Voce esta equilibrado, mas investir da mais robustez (meta: {pct} da renda).',
    'score_tip_invest_low':
        'Aumente seus investimentos para cerca de {pct} da renda para fortalecer seu score.',
    'score_tip_debt_penalty':
        'Dividas em aberto reduzem seu score em 20% ate serem quitadas.',
    'profile_edit_short': 'Editar perfil',
    'transactions': 'Lancamentos',
    'planning': 'Planejamento',
    'goals_load_error': 'Erro ao carregar metas.',
    'goals_quick_tip':
        'Comece com uma meta simples e clara. Exemplo: Guardar R\$ 200 por mes.',
    'budget_edit_title': 'Orcamento - {category}',
    'budget_limit_label': 'Limite (R\$)',
    'budget_essential_title': 'Categoria essencial',
    'budget_essential_subtitle': 'Ajuda nas sugestoes e no plano de dividas.',
    'budget_suggestions_updated': 'Sugestoes atualizadas.',
    'budget_suggestions_failed': 'Nao foi possivel gerar sugestoes.',
    'budgets_smart_title': 'Orcamentos inteligentes',
    'budgets_smart_subtitle':
        'Defina limites por categoria e receba alertas em tempo real.',
    'budgets_smart_perk_1': 'Sugestao automatica com base no seu historico',
    'budgets_smart_perk_2': 'Alertas de 80% e 100% (sem duplicar no mes)',
    'budgets_smart_perk_3': 'Integracao com relatorios e missoes',
    'investment_plan_title': 'Planejamento de investimentos',
    'investment_plan_subtitle':
        'Perfil de risco + sugestao de alocacao (sem indicar produtos).',
    'investment_plan_perk_1': 'Questionario curto (6 perguntas)',
    'investment_plan_perk_2': 'Alocacao por classes de ativos',
    'investment_plan_perk_3':
        'Missoes integradas (reserva, 1o investimento, consistencia)',
    'debts_plan_title': 'Plano anti-dividas',
    'debts_plan_subtitle':
        'Priorize e quite dividas com um caminho claro e seguro.',
    'debts_plan_perk_1': 'Prioridade inteligente (Avalanche ou Snowball)',
    'debts_plan_perk_2': 'Parcela maxima recomendada baseada no seu orcamento',
    'debts_plan_perk_3': 'Etapas conectadas a missoes e relatorios',
    'weekly_plan_title': 'Plano da semana',
    'weekly_plan_subtitle':
        'Seu proximo melhor passo para manter o mes sob controle.',
    'weekly_plan_actions_label': 'Acoes',
    'weekly_plan_streak_label': 'Streak',
    'weekly_plan_insights_label': 'Insights',
    'weekly_plan_follow_cta': 'Seguir passo da semana',
    'weekly_plan_add_income_title': 'Adicionar entrada do mês',
    'weekly_plan_add_income_desc':
        'Sem entradas ativas o plano perde precisão.',
    'weekly_plan_negative_balance_title': 'Voltar para saldo positivo',
    'weekly_plan_negative_balance_desc':
        'Seu mes esta no vermelho. Priorize corte de variaveis e renegociacao de fixos.',
    'weekly_plan_trim_variable_title': 'Reduzir gastos variaveis',
    'weekly_plan_trim_variable_desc':
        'Variaveis em {pct}% da renda. Defina teto semanal.',
    'weekly_plan_increase_invest_title': 'Aumentar aporte de investimento',
    'weekly_plan_increase_invest_desc':
        'Seu aporte esta abaixo de 10% da renda. Simule um valor inicial sustentavel.',
    'weekly_plan_create_goal_title': 'Criar uma meta principal',
    'weekly_plan_create_goal_desc':
        'Uma meta clara direciona decisoes da semana e aumenta consistencia.',
    'weekly_plan_checkin_consistency_title': 'Subir consistencia do check-in',
    'weekly_plan_checkin_consistency_desc':
        'Voce fez {days}/7 check-ins. Meta da semana: pelo menos 5 dias.',
    'weekly_plan_maintain_routine_title': 'Manter rotina e revisar categorias',
    'weekly_plan_maintain_routine_desc':
        'Seu plano esta saudavel. Revise categorias 1x na semana para prevenir desvios.',
    'dashboard_premium_plan_title':
        'Receba o proximo passo certo para melhorar seu mes',
    'dashboard_premium_plan_subtitle':
        'Desbloqueie o plano da semana e insights que apontam prioridades, riscos e oportunidades para voce agir na hora certa.',
    'insight_high_commitment_message':
        'Voce ja comprometeu mais de 80% da sua renda neste mes. Atencao aos proximos gastos.',
    'insight_credit_red_message':
        'Seu saldo ainda parece positivo, mas a fatura atual deixaria o mes no vermelho. Revise o credito antes da proxima compra.',
    'insight_credit_over_debit_message':
        'Neste mes, o credito passou o debito. Vale acompanhar antes que a fatura cresca mais rapido que sua sobra.',
    'insight_installments_weight_message':
        'Mais da metade da sua fatura atual vem de parcelas. Veja quanto ja esta comprometido antes de assumir novas compras.',
    'insight_category_concentration_message':
        'Uma unica categoria ja concentra boa parte do seu mes. Revise onde esse peso esta ficando maior.',
    'insight_spending_speed_message':
        'Seu ritmo de gasto esta mais rapido que o ritmo do mes. Vale segurar variaveis nos proximos dias.',
    'insight_food_high_message':
        'Seus gastos com alimentacao estao acima da media (25% da renda). Que tal cozinhar mais em casa?',
    'insight_emergency_goal_message':
        'Ainda nao identificamos uma meta de reserva de emergencia. Esse e o primeiro passo para sua seguranca.',
    'insight_invest_free_cash_message':
        'Ainda existe saldo livre neste mes. Que tal direcionar uma parte para investimento em vez de deixar parado?',
    'insight_empty_dashboard_message':
        'Seu dashboard esta vazio. Registre seu primeiro gasto para comecarmos a analise.',
    'insight_action_review_spend': 'Revisar gastos',
    'insight_action_view_bill': 'Ver fatura',
    'insight_action_view_entries': 'Ver lancamentos',
    'insight_action_review_installments': 'Revisar parcelas',
    'insight_action_review_category': 'Revisar categoria',
    'insight_action_hold_spending': 'Segurar gastos',
    'insight_action_see_expenses': 'Ver gastos',
    'insight_action_create_reserve': 'Criar reserva',
    'insight_action_simulate_now': 'Simular agora',
    'insight_action_add_expense': 'Adicionar gasto',
    'notif_channel_reminders_name': 'Lembretes do Voolo',
    'notif_channel_reminders_desc': 'Avisos de vencimento e revisao de gastos.',
    'notif_channel_engagement_name': 'Check-ins do Voolo',
    'notif_channel_engagement_desc': 'Lembretes gentis para manter o controle.',
    'notif_due_today_title': 'Vence hoje',
    'notif_due_today_body': '{name} vence hoje. Confira o pagamento.',
    'notif_due_soon_title': 'Vencimento chegando',
    'notif_due_soon_body':
        '{name} vence em 3 dias. Antecipe para evitar juros.',
    'notif_card_due_today_title': 'Fatura vence hoje',
    'notif_card_due_today_body':
        'A fatura do cartao {name} vence hoje. Confira o pagamento.',
    'notif_card_due_soon_title': 'Fatura chegando',
    'notif_card_due_soon_body':
        'A fatura do cartao {name} vence em 3 dias. Evite juros.',
    'notif_weekly_review_title': 'Fechamento da semana',
    'notif_weekly_review_body':
        'Confira seu resumo e ajuste o que for necessario.',
    'notif_monthly_entries_title': 'Hora de atualizar suas entradas',
    'notif_monthly_entries_body':
        'Você provavelmente já recebeu suas entradas deste mês. Deseja adicioná-las no Volo para manter sua saúde financeira atualizada?',
    'goals_title_hint': 'Ex: Quitar cartao em 6 meses',
    'goals_title_required':
        'Digite um titulo claro para a meta. Exemplo: Guardar R\$ 200 por mes.',
    'goals_premium_subtitle':
        'Defina objetivos, receba sugestoes personalizadas e alcance seus sonhos com o Voolo Pro.',
    'onboarding_step_progress': 'Passo {step} de {total}',
    'onboarding_objective_required_hint':
        'Escolha um objetivo para continuar. Exemplo: Guardar dinheiro.',
    'onboarding_profession_required_hint':
        'Digite sua profissao. Exemplo: Assistente administrativo.',
    'onboarding_income_required_hint':
        'Digite sua renda mensal. Exemplo: 2500,00.',
    'onboarding_success_next':
        'Perfeito. Agora vamos para o painel com seus proximos passos.',
    'onboarding_profession_label': 'Profissao',
    'onboarding_profession_hint': 'Ex: Assistente administrativo',
    'onboarding_extra_income_label': 'Entrada extra',
    'onboarding_income_source_hint': 'Ex: Salário, prestação de serviço',
    'onboarding_add_extra_income': 'Adicionar entrada',
    'investment_step_safety_note':
        'Antes de aumentar o risco, priorize montar uma reserva de emergência.',
    'investment_step_aggressive_ipca_label':
        'Tesouro IPCA+ curto/médio / renda fixa mais longa',
    'investment_step_aggressive_equity_label':
        'ETF de ações amplo (Brasil e/ou global)',
    'investment_step_moderate_ipca_label': 'Tesouro IPCA+ curto/médio',
    'investment_step_moderate_equity_label':
        'ETF de ações amplo (Brasil e/ou global)',
    'investment_step_conservative_ipca_label': 'Tesouro IPCA+ curto/médio',
    'investment_plan_reserve_range_error':
        'Defina uma meta de reserva entre 1 e 24 meses.',
    'investment_plan_monthly_amount_error': 'Defina um aporte mensal válido.',
    'investment_plan_saved': 'Plano salvo.',
    'investment_plan_choice_saved_snack': 'Escolha salva.',
    'investment_plan_setup_help':
        'Defina metas simples (reserva e aporte). Você pode ajustar depois.',
    'investment_plan_reserve_months_hint': 'Ex.: 3, 4, 6',
    'investment_plan_profile_summary': 'Perfil: {risk} • Valor usado: {amount}',
    'investment_plan_suggestions_title': 'Sugestões para este mês',
    'investment_plan_suggestions_empty':
        'Defina um valor (aporte) para ver sugestões.',
    'investment_profile_saved_hint':
        'Se quiser, você pode refazer o questionário.',
    'investment_profile_mission_title': 'Missão: definir seu perfil',
    'investment_profile_calculating': 'Calculando…',
    'investment_profile_calculate_button': 'Calcular perfil',
    'investment_plan_quick_summary_label': 'Resumo rápido do seu mês',
    'investment_plan_progress_label': 'Progresso',
    'investment_profile_local_fallback':
        'Não foi possível calcular online; usei um cálculo local simples.',
    'investment_question_1':
        'Por quanto tempo você pretende deixar o dinheiro investido?',
    'investment_question_1_option_1': 'Até 1 ano',
    'investment_question_1_option_2': '1 a 3 anos',
    'investment_question_1_option_3': '3+ anos',
    'investment_question_2': 'Como você reage a oscilações no curto prazo?',
    'investment_question_2_option_1': 'Me incomoda',
    'investment_question_2_option_2': 'Depende',
    'investment_question_2_option_3': 'Tranquilo',
    'investment_question_3': 'Qual sua experiência com investimentos?',
    'investment_question_3_option_1': 'Nenhuma',
    'investment_question_3_option_2': 'Alguma',
    'investment_question_3_option_3': 'Boa',
    'investment_question_4': 'Você tem reserva de emergência?',
    'investment_question_4_option_1': 'Não',
    'investment_question_4_option_2': 'Parcial',
    'investment_question_4_option_3': 'Sim',
    'investment_question_5': 'Qual sua prioridade hoje?',
    'investment_question_5_option_1': 'Segurança',
    'investment_question_5_option_2': 'Equilíbrio',
    'investment_question_5_option_3': 'Crescimento',
    'investment_question_6': 'Se um investimento cair 10%, você...',
    'investment_question_6_option_1': 'Vende',
    'investment_question_6_option_2': 'Espera',
    'investment_question_6_option_3': 'Aporta mais',
  },
  'en': {
    'budgets': 'Budgets',
    'investments_plan': 'Investments (Plan)',
    'debts_exit': 'Get out of debt',
    'missions_tagline': 'Challenges that put money back in your pocket.',
    'xp_total': 'Total XP',
    'level_label': 'Level {level}',
    'level_progress_next': '{pct}% to the next level',
    'financial_level_1': 'Beginner',
    'financial_level_2': 'Organized',
    'financial_level_3': 'Planner',
    'financial_level_4': 'Investor',
    'missions_xp_to_next_level': '{xp} XP to Level {level}',
    'missions_auto_info':
        'Automatic mission: completed through in-app actions.',
    'missions_complete_failed': 'Could not complete right now.',
    'missions_note_hint': 'Write here...',
    'missions_note_min': 'Minimum: {min} characters',
    'mission_status_completed': 'Completed',
    'mission_status_automatic': 'Automatic',
    'mission_status_automatic_completed': 'Completed automatically',
    'mission_action_collect': 'Collect',
    'mission_action_write': 'Write',
    'mission_ready_collect': 'Ready to collect',
    'mission_write_to_complete': 'Write to complete',
    'mission_in_progress': 'In progress',
    'mission_done': 'Done',
    'mission_pending': 'Pending',
    'ratio_variable': 'Variable',
    'ratio_fixed': 'Fixed',
    'ratio_invest': 'Invest.',
    'ratio_buffer': 'Buffer',
    'ratio_distribution_title': 'Month distribution',
    'ratio_distribution_subtitle':
        'Fixed, variable, investment, and leftover in one quick view.',
    'ratio_tip_fixed': 'These are your most recurring monthly expenses.',
    'ratio_tip_variable':
        'This is the part that changes according to your spending during the month.',
    'ratio_tip_invest': 'Try to invest at least 15-20% of your monthly income.',
    'ratio_tip_buffer':
        'This is the amount still free at the end of your month.',
    'dashboard_base_income': 'Monthly entries',
    'edit_short': 'Edit',
    'financial_position_available': 'Left for the month',
    'financial_position_with_invoice':
        'Considering the current bill, {value} remains free this month.',
    'financial_position_invoice_note':
        'This already includes the open bill for this month.',
    'financial_position_without_invoice':
        'No meaningful card pressure this month.',
    'financial_position_paid_out': 'Monthly exits',
    'financial_position_current_invoice': 'Current bill',
    'financial_position_invested': 'Invested',
    'financial_position_total_account': 'Total account balance',
    'bills_home_title': 'Open bills',
    'bills_home_subtitle':
        'Track what is still pending on your card and mark it when paid.',
    'bills_compact_title': 'Cards and bills',
    'bills_compact_subtitle':
        'View, add, and track your bills without leaving the home screen.',
    'bills_add_card': 'Add card',
    'bills_empty_title': 'No cards added',
    'bills_empty_subtitle': 'Add a credit card to track its bill here.',
    'bills_selected_due': 'Due on day {day}',
    'bills_selected_clear': 'No open bill in this cycle.',
    'bills_selected_open': 'Open',
    'bills_pay_popup_title': 'Pay bill',
    'bills_pay_popup_body': 'Mark the {card} bill as paid for {value}?',
    'bills_installments': 'Installments this month: {value}',
    'bills_pay_cta': 'Pay',
    'bills_paid_badge': 'Paid',
    'bills_reopen_cta': 'Reopen',
    'bills_help_title': 'Cards and bills',
    'bills_help_body':
        'The app does not pay the bill for you. Here you track the bill amount for the cycle and only mark whether it is still open or already paid outside the app.',
    'financial_position_committed_help_title': 'Committed',
    'financial_position_committed_help_body':
        'Shows everything that already committed your income this month, including debit, credit, and investments.',
    'financial_position_current_invoice_help_title': 'Current bill',
    'financial_position_current_invoice_help_body':
        'Adds up everything launched on credit cards this month, across all cards.',
    'financial_position_invested_help_title': 'Invested',
    'financial_position_invested_help_body':
        'Shows only the amount contributed this month. Returns are not included here.',
    'drawer_shortcuts': 'Shortcuts',
    'drawer_preferences': 'Preferences',
    'drawer_premium_active': 'Premium account active',
    'drawer_essential_plan': 'Voolo essential plan',
    'ratio_housing': 'Housing',
    'essential_balance_title': 'Monthly balance',
    'essential_balance_entries': 'Income: {value}',
    'essential_balance_exits': 'Expenses: {value}',
    'essential_balance_free': 'Free balance: {value}',
    'essential_guide_title': 'Essential path',
    'essential_guide_subtitle_free':
        'On the free plan, follow these 3 steps to get started.',
    'essential_guide_subtitle_premium':
        'Start with these steps to organize your month.',
    'essential_guide_progress': '{done} of {total} steps completed',
    'essential_guide_how': 'How to do it',
    'essential_guide_do_now': 'Do now',
    'essential_guide_skip': 'Skip',
    'essential_guide_finish': 'Finish guide',
    'essential_guide_later': 'Do later',
    'essential_guide_never_again': 'Do not show again',
    'essential_guide_action_expense_title': 'Add an expense',
    'essential_guide_action_expense_subtitle':
        'Log one simple expense from today.',
    'essential_guide_action_expense_help':
        'Tap +, choose fixed or variable expense, fill name and amount, then save. Example: Groceries \$20.',
    'essential_guide_action_card_title': 'Add a credit card',
    'essential_guide_action_card_subtitle':
        'Register your card to track bills.',
    'essential_guide_action_card_help':
        'Open Cards, tap add, enter card name and bill due day. If you do not use a card, skip this step.',
    'essential_guide_action_balance_title': 'Check monthly balance',
    'essential_guide_action_balance_subtitle':
        'See what came in, what went out, and what is left.',
    'essential_guide_action_balance_help':
        'Tap Check balance to open a summary with income, expenses, and free balance for the month.',
    'essential_guide_action_goal_title': 'Create a goal',
    'essential_guide_action_goal_subtitle': 'Set a simple goal to keep focus.',
    'essential_guide_action_goal_help':
        'Open Goals, pick an objective, and save a short goal with amount and deadline.',
    'progress_levels_title': 'Progress and levels',
    'progress_levels_locked_subtitle':
        'Track XP, levels, and unlocks in Premium.',
    'compare_locked_subtitle':
        'Compare with last month to balance spending better.',
    'dashboard_empty_title': 'Start your journey',
    'dashboard_empty_message':
        'There is not enough data yet. Add your first expense to start analysis.',
    'dashboard_empty_cta': 'Add first expense',
    'dashboard_premium_health_title':
        'See where your month gets tight before money runs short',
    'dashboard_premium_health_subtitle':
        'In Premium, your financial health and month distribution show what is heavy and where to adjust so more money stays free.',
    'score_health_label': 'Financial health',
    'score_tip_add_income':
        'Add your income to calculate your financial health.',
    'score_tip_overspending':
        'Your spending exceeded your income ({pct} over). Cut variable expenses first and renegotiate fixed costs.',
    'score_tip_balanced':
        'Good balance. Keep consistency and review your budget monthly.',
    'score_tip_budget_tight':
        'Your budget is tight. Try to keep at least {pct} as monthly buffer.',
    'score_tip_housing_high':
        'Housing is high. Try to keep it up to {pct} of your income (rent/mortgage/condo).',
    'score_tip_variable_high':
        'Variable expenses are high. Set a cap up to {pct} of income this month.',
    'score_tip_fixed_high':
        'Fixed costs are high. Try reducing to up to {pct} of income through cuts and renegotiation.',
    'score_tip_invest_zero':
        'You are balanced, but investing adds more resilience (target: {pct} of income).',
    'score_tip_invest_low':
        'Increase your investments to around {pct} of income to strengthen your score.',
    'score_tip_debt_penalty':
        'Open debts reduce your score by 20% until paid off.',
    'profile_edit_short': 'Edit profile',
    'transactions': 'Entries',
    'planning': 'Planning',
    'goals_load_error': 'Error loading goals.',
    'goals_quick_tip':
        'Start with one simple and clear goal. Example: Save R\$ 200 per month.',
    'budget_edit_title': 'Budget - {category}',
    'budget_limit_label': 'Limit (R\$)',
    'budget_essential_title': 'Essential category',
    'budget_essential_subtitle': 'Helps suggestions and debt planning.',
    'budget_suggestions_updated': 'Suggestions updated.',
    'budget_suggestions_failed': 'Could not generate suggestions.',
    'budgets_smart_title': 'Smart budgets',
    'budgets_smart_subtitle':
        'Set category limits and receive real-time alerts.',
    'budgets_smart_perk_1': 'Automatic suggestion based on your history',
    'budgets_smart_perk_2':
        '80% and 100% alerts (without duplicates in the month)',
    'budgets_smart_perk_3': 'Integration with reports and missions',
    'investment_plan_title': 'Investment planning',
    'investment_plan_subtitle':
        'Risk profile + allocation suggestion (without product recommendation).',
    'investment_plan_perk_1': 'Short questionnaire (6 questions)',
    'investment_plan_perk_2': 'Allocation by asset classes',
    'investment_plan_perk_3':
        'Integrated missions (reserve, first investment, consistency)',
    'debts_plan_title': 'Debt-free plan',
    'debts_plan_subtitle':
        'Prioritize and pay off debts with a clear, safe path.',
    'debts_plan_perk_1': 'Smart priority (Avalanche or Snowball)',
    'debts_plan_perk_2': 'Recommended max installment based on your budget',
    'debts_plan_perk_3': 'Steps connected to missions and reports',
    'weekly_plan_title': 'Weekly plan',
    'weekly_plan_subtitle':
        'Your next best step to keep the month under control.',
    'weekly_plan_actions_label': 'Actions',
    'weekly_plan_streak_label': 'Streak',
    'weekly_plan_insights_label': 'Insights',
    'weekly_plan_follow_cta': 'Follow weekly step',
    'weekly_plan_add_income_title': 'Add monthly entries',
    'weekly_plan_add_income_desc':
        'Without active entries, the plan loses accuracy.',
    'weekly_plan_negative_balance_title': 'Return to positive balance',
    'weekly_plan_negative_balance_desc':
        'Your month is in the red. Prioritize cutting variable spending and renegotiating fixed costs.',
    'weekly_plan_trim_variable_title': 'Reduce variable spending',
    'weekly_plan_trim_variable_desc':
        'Variable spending is at {pct}% of income. Set a weekly cap.',
    'weekly_plan_increase_invest_title': 'Increase investment contribution',
    'weekly_plan_increase_invest_desc':
        'Your contribution is below 10% of income. Simulate a sustainable starting amount.',
    'weekly_plan_create_goal_title': 'Create a main goal',
    'weekly_plan_create_goal_desc':
        'A clear goal guides weekly decisions and improves consistency.',
    'weekly_plan_checkin_consistency_title': 'Improve check-in consistency',
    'weekly_plan_checkin_consistency_desc':
        'You completed {days}/7 check-ins. Weekly target: at least 5 days.',
    'weekly_plan_maintain_routine_title':
        'Keep the routine and review categories',
    'weekly_plan_maintain_routine_desc':
        'Your plan is healthy. Review categories once a week to prevent drift.',
    'dashboard_premium_plan_title':
        'Get the right next step to improve your month',
    'dashboard_premium_plan_subtitle':
        'Unlock the weekly plan and insights that point to priorities, risks, and opportunities so you can act at the right time.',
    'insight_high_commitment_message':
        'You have already committed more than 80% of your income this month. Be careful with upcoming spending.',
    'insight_credit_red_message':
        'Your balance still looks positive, but the current bill would push the month into the red. Review credit before the next purchase.',
    'insight_credit_over_debit_message':
        'This month, credit has surpassed debit. It is worth watching before the bill grows faster than your leftover money.',
    'insight_installments_weight_message':
        'More than half of your current bill comes from installments. Check how much is already committed before taking on new purchases.',
    'insight_category_concentration_message':
        'A single category already concentrates a large part of your month. Review where this weight is growing.',
    'insight_spending_speed_message':
        'Your spending pace is faster than the pace of the month. It is worth slowing variable expenses over the next few days.',
    'insight_food_high_message':
        'Your food spending is above average (25% of income). How about cooking more at home?',
    'insight_emergency_goal_message':
        'We still have not identified an emergency fund goal. That is the first step toward your financial safety.',
    'insight_invest_free_cash_message':
        'There is still free cash this month. How about directing part of it to investing instead of leaving it idle?',
    'insight_empty_dashboard_message':
        'Your dashboard is empty. Add your first expense so we can start the analysis.',
    'insight_action_review_spend': 'Review spending',
    'insight_action_view_bill': 'View bill',
    'insight_action_view_entries': 'View entries',
    'insight_action_review_installments': 'Review installments',
    'insight_action_review_category': 'Review category',
    'insight_action_hold_spending': 'Hold spending',
    'insight_action_see_expenses': 'See expenses',
    'insight_action_create_reserve': 'Create reserve',
    'insight_action_simulate_now': 'Simulate now',
    'insight_action_add_expense': 'Add expense',
    'notif_channel_reminders_name': 'Voolo reminders',
    'notif_channel_reminders_desc':
        'Due date alerts and spending review reminders.',
    'notif_channel_engagement_name': 'Voolo check-ins',
    'notif_channel_engagement_desc': 'Gentle reminders to stay in control.',
    'notif_due_today_title': 'Due today',
    'notif_due_today_body': '{name} is due today. Check the payment.',
    'notif_due_soon_title': 'Due date coming up',
    'notif_due_soon_body':
        '{name} is due in 3 days. Plan ahead to avoid interest.',
    'notif_card_due_today_title': 'Card bill due today',
    'notif_card_due_today_body':
        'Your {name} card bill is due today. Check the payment.',
    'notif_card_due_soon_title': 'Card bill coming up',
    'notif_card_due_soon_body':
        'Your {name} card bill is due in 3 days. Avoid interest.',
    'notif_weekly_review_title': 'Weekly review',
    'notif_weekly_review_body': 'Check your summary and adjust what is needed.',
    'notif_monthly_entries_title': 'Time to update your entries',
    'notif_monthly_entries_body':
        'You have probably already received your income or other entries this month. Would you like to add them in Volo to keep your financial health up to date?',
    'goals_title_hint': 'Ex: Pay off card in 6 months',
    'goals_title_required':
        'Enter a clear goal title. Example: Save R\$ 200 per month.',
    'goals_premium_subtitle':
        'Set goals, get personalized suggestions, and achieve your dreams with Voolo Pro.',
    'onboarding_step_progress': 'Step {step} of {total}',
    'onboarding_objective_required_hint':
        'Choose one objective to continue. Example: Save money.',
    'onboarding_profession_required_hint':
        'Enter your profession. Example: Administrative assistant.',
    'onboarding_income_required_hint':
        'Enter your monthly income. Example: 2500.00.',
    'onboarding_success_next':
        'Great. Now let us go to your dashboard with your next steps.',
    'onboarding_profession_label': 'Profession',
    'onboarding_profession_hint': 'Ex: Administrative assistant',
    'onboarding_extra_income_label': 'Extra entry',
    'onboarding_income_source_hint': 'Ex: Salary, service income',
    'onboarding_add_extra_income': 'Add entry',
    'investment_step_safety_note':
        'Before increasing risk, prioritize building an emergency reserve.',
    'investment_step_aggressive_ipca_label':
        'Inflation-linked bonds / longer fixed income',
    'investment_step_aggressive_equity_label':
        'Broad equity ETF (Brazil and/or global)',
    'investment_step_moderate_ipca_label':
        'Inflation-linked bonds / shorter-term fixed income',
    'investment_step_moderate_equity_label':
        'Broad equity ETF (Brazil and/or global)',
    'investment_step_conservative_ipca_label':
        'Inflation-linked bonds / shorter-term fixed income',
    'investment_plan_reserve_range_error':
        'Set an emergency reserve goal between 1 and 24 months.',
    'investment_plan_monthly_amount_error': 'Set a valid monthly contribution.',
    'investment_plan_saved': 'Plan saved.',
    'investment_plan_choice_saved_snack': 'Choice saved.',
    'investment_plan_setup_help':
        'Set simple goals (reserve and contribution). You can adjust them later.',
    'investment_plan_reserve_months_hint': 'Ex: 3, 4, 6',
    'investment_plan_profile_summary':
        'Profile: {risk} • Amount used: {amount}',
    'investment_plan_suggestions_title': 'Suggestions for this month',
    'investment_plan_suggestions_empty':
        'Set an amount (contribution) to see suggestions.',
    'investment_profile_saved_hint':
        'If you want, you can retake the questionnaire.',
    'investment_profile_mission_title': 'Mission: define your profile',
    'investment_profile_calculating': 'Calculating…',
    'investment_profile_calculate_button': 'Calculate profile',
    'investment_plan_quick_summary_label': 'Quick summary of your month',
    'investment_plan_progress_label': 'Progress',
    'investment_profile_local_fallback':
        'Could not calculate online; used a simple local calculation.',
    'investment_question_1': 'How long do you plan to keep the money invested?',
    'investment_question_1_option_1': 'Up to 1 year',
    'investment_question_1_option_2': '1 to 3 years',
    'investment_question_1_option_3': '3+ years',
    'investment_question_2': 'How do you react to short-term swings?',
    'investment_question_2_option_1': 'It bothers me',
    'investment_question_2_option_2': 'It depends',
    'investment_question_2_option_3': "I'm fine",
    'investment_question_3': 'How much investing experience do you have?',
    'investment_question_3_option_1': 'None',
    'investment_question_3_option_2': 'Some',
    'investment_question_3_option_3': 'Good',
    'investment_question_4': 'Do you have an emergency fund?',
    'investment_question_4_option_1': 'No',
    'investment_question_4_option_2': 'Partial',
    'investment_question_4_option_3': 'Yes',
    'investment_question_5': 'What is your priority today?',
    'investment_question_5_option_1': 'Safety',
    'investment_question_5_option_2': 'Balance',
    'investment_question_5_option_3': 'Growth',
    'investment_question_6': 'If an investment drops 10%, you...',
    'investment_question_6_option_1': 'Sell',
    'investment_question_6_option_2': 'Wait',
    'investment_question_6_option_3': 'Add more',
  },
  'es': {
    'budgets': 'Presupuestos',
    'investments_plan': 'Inversiones (Plan)',
    'debts_exit': 'Salir de deudas',
    'missions_tagline': 'Desafíos que ponen dinero de vuelta en tu bolsillo.',
    'xp_total': 'XP total',
    'level_label': 'Nivel {level}',
    'level_progress_next': '{pct}% para el próximo nivel',
    'financial_level_1': 'Principiante',
    'financial_level_2': 'Organizado',
    'financial_level_3': 'Planificador',
    'financial_level_4': 'Inversionista',
    'missions_xp_to_next_level': 'Faltan {xp} XP para Nivel {level}',
    'missions_auto_info':
        'Misión automática: se completa con acciones en la app.',
    'missions_complete_failed': 'No se pudo completar en este momento.',
    'missions_note_hint': 'Escribe aquí...',
    'missions_note_min': 'Mínimo: {min} caracteres',
    'mission_status_completed': 'Completada',
    'mission_status_automatic': 'Automática',
    'mission_status_automatic_completed': 'Completada automáticamente',
    'mission_action_collect': 'Reclamar',
    'mission_action_write': 'Escribir',
    'mission_ready_collect': 'Lista para reclamar',
    'mission_write_to_complete': 'Escribe para completar',
    'mission_in_progress': 'En progreso',
    'mission_done': 'Hecho',
    'mission_pending': 'Pendiente',
    'ratio_variable': 'Variables',
    'ratio_fixed': 'Fijos',
    'ratio_invest': 'Inv.',
    'ratio_buffer': 'Sobra',
    'ratio_distribution_title': 'Distribucion del mes',
    'ratio_distribution_subtitle':
        'Fijo, variable, inversion y sobra en una lectura rapida.',
    'ratio_tip_fixed': 'Aqui entran los gastos mas recurrentes de tu mes.',
    'ratio_tip_variable':
        'Aqui entra lo que cambia segun tu consumo durante el mes.',
    'ratio_tip_invest':
        'Intenta invertir al menos 15-20% de tu ingreso mensual.',
    'ratio_tip_buffer':
        'Este es el valor que todavia queda libre al final del mes.',
    'dashboard_base_income': 'Entradas del mes',
    'edit_short': 'Editar',
    'financial_position_available': 'Restante del mes',
    'financial_position_with_invoice':
        'Considerando la factura actual, quedan {value} libres este mes.',
    'financial_position_invoice_note':
        'Esto ya considera la factura abierta de este mes.',
    'financial_position_without_invoice':
        'Sin presion relevante de tarjeta este mes.',
    'financial_position_paid_out': 'Salidas del mes',
    'financial_position_current_invoice': 'Factura actual',
    'financial_position_invested': 'Invertido',
    'financial_position_total_account': 'Saldo total de la cuenta',
    'bills_home_title': 'Facturas abiertas',
    'bills_home_subtitle':
        'Sigue lo pendiente en la tarjeta y marcalo cuando pagues.',
    'bills_compact_title': 'Tarjetas y facturas',
    'bills_compact_subtitle':
        'Ve, agrega y acompana tus facturas sin salir del inicio.',
    'bills_add_card': 'Agregar tarjeta',
    'bills_empty_title': 'Ninguna tarjeta registrada',
    'bills_empty_subtitle': 'Agrega una tarjeta para seguir su factura aqui.',
    'bills_selected_due': 'Vence el dia {day}',
    'bills_selected_clear': 'No hay factura abierta en este ciclo.',
    'bills_selected_open': 'Abierta',
    'bills_pay_popup_title': 'Pagar factura',
    'bills_pay_popup_body':
        'Marcar la factura de {card} como pagada por {value}?',
    'bills_installments': 'Cuotas este mes: {value}',
    'bills_pay_cta': 'Pagar',
    'bills_paid_badge': 'Pagada',
    'bills_reopen_cta': 'Reabrir',
    'bills_help_title': 'Tarjetas y facturas',
    'bills_help_body':
        'La app no paga la factura por ti. Aqui acompanias el valor del ciclo y solo marcas si la factura sigue abierta o si ya fue pagada fuera de la app.',
    'financial_position_committed_help_title': 'Comprometido',
    'financial_position_committed_help_body':
        'Muestra todo lo que ya comprometio tu ingreso del mes, incluyendo debito, credito e inversiones.',
    'financial_position_current_invoice_help_title': 'Factura actual',
    'financial_position_current_invoice_help_body':
        'Suma todo lo lanzado en tarjeta este mes, considerando todas las tarjetas.',
    'financial_position_invested_help_title': 'Invertido',
    'financial_position_invested_help_body':
        'Muestra solo lo aportado en este mes. Los rendimientos no entran aqui.',
    'drawer_shortcuts': 'Atajos',
    'drawer_preferences': 'Preferencias',
    'drawer_premium_active': 'Cuenta premium activa',
    'drawer_essential_plan': 'Plan esencial de Voolo',
    'ratio_housing': 'Vivienda',
    'essential_balance_title': 'Saldo del mes',
    'essential_balance_entries': 'Entradas: {value}',
    'essential_balance_exits': 'Salidas: {value}',
    'essential_balance_free': 'Saldo libre: {value}',
    'essential_guide_title': 'Ruta esencial',
    'essential_guide_subtitle_free':
        'En el plan gratis, sigue estos 3 pasos para empezar.',
    'essential_guide_subtitle_premium':
        'Empieza con estos pasos para organizar tu mes.',
    'essential_guide_progress': '{done} de {total} pasos completados',
    'essential_guide_how': 'Como hacerlo',
    'essential_guide_do_now': 'Hacer ahora',
    'essential_guide_skip': 'Saltar',
    'essential_guide_finish': 'Finalizar guia',
    'essential_guide_later': 'Hacer despues',
    'essential_guide_never_again': 'No mostrar de nuevo',
    'essential_guide_action_expense_title': 'Registrar gasto',
    'essential_guide_action_expense_subtitle':
        'Registra un gasto simple de hoy.',
    'essential_guide_action_expense_help':
        'Toca +, elige gasto fijo o variable, completa nombre y valor, y guarda. Ejemplo: Mercado \$20.',
    'essential_guide_action_card_title': 'Agregar tarjeta de credito',
    'essential_guide_action_card_subtitle':
        'Registra tu tarjeta para organizar facturas.',
    'essential_guide_action_card_help':
        'Abre Tarjetas, toca agregar, informa nombre y dia de vencimiento. Si no usas tarjeta, puedes saltar.',
    'essential_guide_action_balance_title': 'Ver saldo del mes',
    'essential_guide_action_balance_subtitle':
        'Mira lo que entro, salio y sobro.',
    'essential_guide_action_balance_help':
        'Toca Ver saldo para abrir un resumen de entradas, salidas y saldo libre del mes.',
    'essential_guide_action_goal_title': 'Crear meta',
    'essential_guide_action_goal_subtitle':
        'Define una meta simple para mantener foco.',
    'essential_guide_action_goal_help':
        'Abre Metas, elige un objetivo y guarda una meta corta con valor y plazo.',
    'progress_levels_title': 'Progreso y niveles',
    'progress_levels_locked_subtitle':
        'Sigue XP, niveles y desbloqueos en Premium.',
    'compare_locked_subtitle':
        'Compara con el mes anterior para equilibrar mejor tus gastos.',
    'dashboard_empty_title': 'Empieza tu camino',
    'dashboard_empty_message':
        'Aun no hay datos suficientes. Registra tu primer gasto para iniciar el analisis.',
    'dashboard_empty_cta': 'Agregar primer gasto',
    'dashboard_premium_health_title':
        'Mira donde tu mes se aprieta antes de quedarte sin margen',
    'dashboard_premium_health_subtitle':
        'En Premium, tu salud financiera y la distribucion del mes muestran rapido que esta pesado y donde ajustar para que sobre mas.',
    'score_health_label': 'Salud financiera',
    'score_tip_add_income':
        'Registra tu ingreso para calcular tu salud financiera.',
    'score_tip_overspending':
        'Tus gastos superaron tu ingreso ({pct} por encima). Recorta variables primero y renegocia fijos.',
    'score_tip_balanced':
        'Buen equilibrio. Manten consistencia y revisa tu presupuesto cada mes.',
    'score_tip_budget_tight':
        'Tu presupuesto esta ajustado. Intenta dejar al menos {pct} de margen en el mes.',
    'score_tip_housing_high':
        'La vivienda esta alta. Busca mantenerla hasta {pct} del ingreso (alquiler/hipoteca/condominio).',
    'score_tip_variable_high':
        'Los gastos variables estan altos. Define un tope de hasta {pct} del ingreso este mes.',
    'score_tip_fixed_high':
        'Los gastos fijos estan altos. Intenta reducirlos hasta {pct} del ingreso con recortes y renegociaciones.',
    'score_tip_invest_zero':
        'Estas equilibrado, pero invertir da mas robustez (meta: {pct} del ingreso).',
    'score_tip_invest_low':
        'Aumenta tus inversiones a cerca de {pct} del ingreso para fortalecer tu puntaje.',
    'score_tip_debt_penalty':
        'Las deudas abiertas reducen tu puntaje en 20% hasta que sean pagadas.',
    'profile_edit_short': 'Editar perfil',
    'transactions': 'Movimientos',
    'planning': 'Planificacion',
    'goals_load_error': 'Error al cargar metas.',
    'goals_quick_tip':
        'Empieza con una meta simple y clara. Ejemplo: Ahorrar R\$ 200 por mes.',
    'budget_edit_title': 'Presupuesto - {category}',
    'budget_limit_label': 'Limite (R\$)',
    'budget_essential_title': 'Categoria esencial',
    'budget_essential_subtitle': 'Ayuda en sugerencias y en el plan de deudas.',
    'budget_suggestions_updated': 'Sugerencias actualizadas.',
    'budget_suggestions_failed': 'No fue posible generar sugerencias.',
    'budgets_smart_title': 'Presupuestos inteligentes',
    'budgets_smart_subtitle':
        'Define limites por categoria y recibe alertas en tiempo real.',
    'budgets_smart_perk_1': 'Sugerencia automatica basada en tu historial',
    'budgets_smart_perk_2': 'Alertas de 80% y 100% (sin duplicar en el mes)',
    'budgets_smart_perk_3': 'Integracion con reportes y misiones',
    'investment_plan_title': 'Planificacion de inversiones',
    'investment_plan_subtitle':
        'Perfil de riesgo + sugerencia de asignacion (sin recomendar productos).',
    'investment_plan_perk_1': 'Cuestionario corto (6 preguntas)',
    'investment_plan_perk_2': 'Asignacion por clases de activos',
    'investment_plan_perk_3':
        'Misiones integradas (reserva, primera inversion, consistencia)',
    'debts_plan_title': 'Plan anti-deudas',
    'debts_plan_subtitle':
        'Prioriza y liquida deudas con un camino claro y seguro.',
    'debts_plan_perk_1': 'Prioridad inteligente (Avalanche o Snowball)',
    'debts_plan_perk_2': 'Cuota maxima recomendada basada en tu presupuesto',
    'debts_plan_perk_3': 'Etapas conectadas a misiones y reportes',
    'weekly_plan_title': 'Plan de la semana',
    'weekly_plan_subtitle':
        'Tu siguiente mejor paso para mantener el mes bajo control.',
    'weekly_plan_actions_label': 'Acciones',
    'weekly_plan_streak_label': 'Racha',
    'weekly_plan_insights_label': 'Insights',
    'weekly_plan_follow_cta': 'Seguir paso semanal',
    'weekly_plan_add_income_title': 'Agregar entradas del mes',
    'weekly_plan_add_income_desc':
        'Sin entradas activas, el plan pierde precisión.',
    'weekly_plan_negative_balance_title': 'Volver al saldo positivo',
    'weekly_plan_negative_balance_desc':
        'Tu mes esta en rojo. Prioriza recortar variables y renegociar fijos.',
    'weekly_plan_trim_variable_title': 'Reducir gastos variables',
    'weekly_plan_trim_variable_desc':
        'Los variables estan en {pct}% del ingreso. Define un limite semanal.',
    'weekly_plan_increase_invest_title': 'Aumentar aporte de inversion',
    'weekly_plan_increase_invest_desc':
        'Tu aporte esta por debajo del 10% del ingreso. Simula un valor inicial sostenible.',
    'weekly_plan_create_goal_title': 'Crear una meta principal',
    'weekly_plan_create_goal_desc':
        'Una meta clara orienta las decisiones de la semana y aumenta la consistencia.',
    'weekly_plan_checkin_consistency_title':
        'Mejorar consistencia del check-in',
    'weekly_plan_checkin_consistency_desc':
        'Hiciste {days}/7 check-ins. Meta semanal: al menos 5 dias.',
    'weekly_plan_maintain_routine_title':
        'Mantener la rutina y revisar categorias',
    'weekly_plan_maintain_routine_desc':
        'Tu plan esta saludable. Revisa categorias una vez por semana para prevenir desvios.',
    'dashboard_premium_plan_title':
        'Recibe el siguiente paso correcto para mejorar tu mes',
    'dashboard_premium_plan_subtitle':
        'Desbloquea el plan de la semana y los insights que muestran prioridades, riesgos y oportunidades para actuar en el momento correcto.',
    'insight_high_commitment_message':
        'Ya comprometiste mas del 80% de tu ingreso este mes. Atencion a los proximos gastos.',
    'insight_credit_red_message':
        'Tu saldo aun parece positivo, pero la factura actual dejaria el mes en rojo. Revisa el credito antes de la proxima compra.',
    'insight_credit_over_debit_message':
        'Este mes, el credito supero al debito. Vale la pena seguirlo antes de que la factura crezca mas rapido que tu sobrante.',
    'insight_installments_weight_message':
        'Mas de la mitad de tu factura actual viene de cuotas. Mira cuanto ya esta comprometido antes de asumir nuevas compras.',
    'insight_category_concentration_message':
        'Una sola categoria ya concentra buena parte de tu mes. Revisa donde ese peso esta creciendo mas.',
    'insight_spending_speed_message':
        'Tu ritmo de gasto va mas rapido que el ritmo del mes. Vale la pena frenar variables en los proximos dias.',
    'insight_food_high_message':
        'Tus gastos con alimentacion estan por encima del promedio (25% del ingreso). Que tal cocinar mas en casa?',
    'insight_emergency_goal_message':
        'Aun no identificamos una meta de fondo de emergencia. Ese es el primer paso para tu seguridad financiera.',
    'insight_invest_free_cash_message':
        'Todavia hay saldo libre este mes. Que tal dirigir una parte a inversion en lugar de dejarlo parado?',
    'insight_empty_dashboard_message':
        'Tu dashboard esta vacio. Registra tu primer gasto para empezar el analisis.',
    'insight_action_review_spend': 'Revisar gastos',
    'insight_action_view_bill': 'Ver factura',
    'insight_action_view_entries': 'Ver movimientos',
    'insight_action_review_installments': 'Revisar cuotas',
    'insight_action_review_category': 'Revisar categoria',
    'insight_action_hold_spending': 'Frenar gastos',
    'insight_action_see_expenses': 'Ver gastos',
    'insight_action_create_reserve': 'Crear reserva',
    'insight_action_simulate_now': 'Simular ahora',
    'insight_action_add_expense': 'Agregar gasto',
    'notif_channel_reminders_name': 'Recordatorios de Voolo',
    'notif_channel_reminders_desc':
        'Avisos de vencimiento y revision de gastos.',
    'notif_channel_engagement_name': 'Check-ins de Voolo',
    'notif_channel_engagement_desc':
        'Recordatorios suaves para mantener el control.',
    'notif_due_today_title': 'Vence hoy',
    'notif_due_today_body': '{name} vence hoy. Revisa el pago.',
    'notif_due_soon_title': 'Vencimiento cerca',
    'notif_due_soon_body':
        '{name} vence en 3 dias. Anticipate para evitar intereses.',
    'notif_card_due_today_title': 'La factura vence hoy',
    'notif_card_due_today_body':
        'La factura de la tarjeta {name} vence hoy. Revisa el pago.',
    'notif_card_due_soon_title': 'Factura por vencer',
    'notif_card_due_soon_body':
        'La factura de la tarjeta {name} vence en 3 dias. Evita intereses.',
    'notif_weekly_review_title': 'Cierre de la semana',
    'notif_weekly_review_body':
        'Revisa tu resumen y ajusta lo que sea necesario.',
    'notif_monthly_entries_title': 'Es hora de actualizar tus entradas',
    'notif_monthly_entries_body':
        'Probablemente ya recibiste tu ingreso u otras entradas de este mes. ¿Quieres agregarlas en Volo para mantener tu salud financiera actualizada?',
    'goals_title_hint': 'Ej: Pagar tarjeta en 6 meses',
    'goals_title_required':
        'Escribe un titulo claro para la meta. Ejemplo: Ahorrar R\$ 200 por mes.',
    'goals_premium_subtitle':
        'Define objetivos, recibe sugerencias personalizadas y alcanza tus suenos con Voolo Pro.',
    'onboarding_step_progress': 'Paso {step} de {total}',
    'onboarding_objective_required_hint':
        'Elige un objetivo para continuar. Ejemplo: Ahorrar dinero.',
    'onboarding_profession_required_hint':
        'Escribe tu profesion. Ejemplo: Asistente administrativo.',
    'onboarding_income_required_hint':
        'Escribe tu ingreso mensual. Ejemplo: 2500,00.',
    'onboarding_success_next':
        'Perfecto. Ahora vamos al panel con tus proximos pasos.',
    'onboarding_profession_label': 'Profesion',
    'onboarding_profession_hint': 'Ej: Asistente administrativo',
    'onboarding_extra_income_label': 'Entrada extra',
    'onboarding_income_source_hint': 'Ej: Salario, prestación de servicios',
    'onboarding_add_extra_income': 'Agregar entrada',
    'investment_step_safety_note':
        'Antes de aumentar el riesgo, prioriza construir una reserva de emergencia.',
    'investment_step_aggressive_ipca_label':
        'Bonos ligados a la inflaci?n / renta fija m?s larga',
    'investment_step_aggressive_equity_label':
        'ETF de acciones amplio (Brasil y/o global)',
    'investment_step_moderate_ipca_label':
        'Bonos ligados a la inflaci?n / renta fija m?s corta',
    'investment_step_moderate_equity_label':
        'ETF de acciones amplio (Brasil y/o global)',
    'investment_step_conservative_ipca_label':
        'Bonos ligados a la inflaci?n / renta fija m?s corta',
    'investment_plan_reserve_range_error':
        'Define una meta de reserva entre 1 y 24 meses.',
    'investment_plan_monthly_amount_error': 'Define un aporte mensual v?lido.',
    'investment_plan_saved': 'Plan guardado.',
    'investment_plan_choice_saved_snack': 'Elecci?n guardada.',
    'investment_plan_setup_help':
        'Define metas simples (reserva y aporte). Puedes ajustarlas despu?s.',
    'investment_plan_reserve_months_hint': 'Ej.: 3, 4, 6',
    'investment_plan_profile_summary': 'Perfil: {risk} • Valor usado: {amount}',
    'investment_plan_suggestions_title': 'Sugerencias para este mes',
    'investment_plan_suggestions_empty':
        'Define un valor (aporte) para ver sugerencias.',
    'investment_profile_saved_hint':
        'Si quieres, puedes rehacer el cuestionario.',
    'investment_profile_mission_title': 'Misi?n: definir tu perfil',
    'investment_profile_calculating': 'Calculando…',
    'investment_profile_calculate_button': 'Calcular perfil',
    'investment_plan_quick_summary_label': 'Resumen r?pido de tu mes',
    'investment_plan_progress_label': 'Progreso',
    'investment_profile_local_fallback':
        'No fue posible calcular en l?nea; us? un c?lculo local simple.',
    'investment_question_1':
        '?Cu?nto tiempo piensas dejar el dinero invertido?',
    'investment_question_1_option_1': 'Hasta 1 a?o',
    'investment_question_1_option_2': '1 a 3 a?os',
    'investment_question_1_option_3': '3+ a?os',
    'investment_question_2':
        '?C?mo reaccionas a las oscilaciones de corto plazo?',
    'investment_question_2_option_1': 'Me molesta',
    'investment_question_2_option_2': 'Depende',
    'investment_question_2_option_3': 'Tranquilo',
    'investment_question_3': '?Qu? experiencia tienes con inversiones?',
    'investment_question_3_option_1': 'Ninguna',
    'investment_question_3_option_2': 'Alguna',
    'investment_question_3_option_3': 'Buena',
    'investment_question_4': '?Tienes fondo de emergencia?',
    'investment_question_4_option_1': 'No',
    'investment_question_4_option_2': 'Parcial',
    'investment_question_4_option_3': 'S?',
    'investment_question_5': '?Cu?l es tu prioridad hoy?',
    'investment_question_5_option_1': 'Seguridad',
    'investment_question_5_option_2': 'Equilibrio',
    'investment_question_5_option_3': 'Crecimiento',
    'investment_question_6': 'Si una inversi?n cae 10%, t?...',
    'investment_question_6_option_1': 'Vendes',
    'investment_question_6_option_2': 'Esperas',
    'investment_question_6_option_3': 'Aportas m?s',
  },
};
