import 'package:flutter/material.dart';

/// Dados coletados no onboarding.
/// (Sem banco por enquanto: retornamos isso para quem chamou.)
class OnboardingData {
  final String objective;

  const OnboardingData({
    required this.objective,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  String objective = 'Controle financeiro';

  final objectives = const [
    'Sair de dívidas',
    'Controle financeiro',
    'Começar a investir',
    'Montar aposentadoria',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre você'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Qual é seu objetivo com o Jetx?',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Isso ajuda a personalizar seu dashboard e suas metas.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: objectives.map((item) {
                final selected = objective == item;
                return ChoiceChip(
                  selected: selected,
                  label: Text(item),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: Colors.amber,
                  backgroundColor: const Color(0xFF1E1E1E),
                  onSelected: (_) => setState(() => objective = item),
                );
              }).toList(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Retorna para quem chamou (Login/Register/Dashboard)
                  Navigator.pop(
                    context,
                    OnboardingData(objective: objective),
                  );
                },
                child: const Text('Continuar'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  // Caso o usuário não queira escolher agora
                  Navigator.pop(
                    context,
                    const OnboardingData(objective: 'Controle financeiro'),
                  );
                },
                child: const Text('Pular por enquanto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
