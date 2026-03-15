import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/user_state.dart';
import '../app_theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final user = userState.user;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: user?.photoPath == null
                  ? const Icon(Icons.person, size: 36)
                  : ClipOval(
                      child: Image.asset(user!.photoPath!, fit: BoxFit.cover),
                    ),
            ),
            accountName: Text(user?.name ?? 'Usuário'),
            accountEmail: const Text(''),
          ),
          _item(Icons.person, 'Perfil'),
          _item(Icons.lock, 'Segurança'),
          _item(Icons.settings, 'Configurações'),
        ],
      ),
    );
  }

  ListTile _item(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {},
    );
  }
}
