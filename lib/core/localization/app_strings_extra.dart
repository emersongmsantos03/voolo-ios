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
    'ratio_housing': 'Moradia',
    'essential_balance_title': 'Saldo do mes',
    'essential_balance_entries': 'Entradas: {value}',
    'essential_balance_exits': 'Saidas: {value}',
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
    'onboarding_extra_income_label': 'Renda extra',
    'onboarding_income_source_hint': 'Ex: Salario principal',
    'onboarding_add_extra_income': 'Adicionar renda extra',
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
    'onboarding_extra_income_label': 'Extra income',
    'onboarding_income_source_hint': 'Ex: Main salary',
    'onboarding_add_extra_income': 'Add extra income',
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
    'onboarding_extra_income_label': 'Ingreso extra',
    'onboarding_income_source_hint': 'Ej: Salario principal',
    'onboarding_add_extra_income': 'Agregar ingreso extra',
  },
};
