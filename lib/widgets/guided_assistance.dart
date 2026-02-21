import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContextHelpIcon extends StatelessWidget {
  final String title;
  final String whatIs;
  final String whyItMatters;
  final String example;

  const ContextHelpIcon({
    super.key,
    required this.title,
    required this.whatIs,
    required this.whyItMatters,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Ajuda',
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HelpSection(label: 'O que e', value: whatIs),
                  const SizedBox(height: 12),
                  _HelpSection(label: 'Por que importa', value: whyItMatters),
                  const SizedBox(height: 12),
                  _HelpSection(label: 'Exemplo', value: example),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.help_outline),
    );
  }
}

class PersistentHelpButton extends StatelessWidget {
  const PersistentHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: () => showSupportSheet(context),
      tooltip: 'Ajuda',
      child: const Icon(Icons.help_outline),
    );
  }
}

Future<void> showSupportSheet(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajuda',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Fale com nosso suporte por e-mail.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mark_email_read_outlined),
              title: const Text('contato@voolo.com.br'),
              subtitle: const Text('Toque para copiar o e-mail'),
              onTap: () async {
                await Clipboard.setData(
                  const ClipboardData(text: 'contato@voolo.com.br'),
                );
                if (context.mounted) Navigator.pop(context);
                messenger?.showSnackBar(
                  const SnackBar(
                    content: Text('E-mail de suporte copiado.'),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _HelpSection extends StatelessWidget {
  final String label;
  final String value;

  const _HelpSection({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}
