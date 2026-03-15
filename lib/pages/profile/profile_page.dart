import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:path_provider/path_provider.dart';
import '../../core/catalogs/gender_catalog.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/formatters/money_text_input_formatter.dart';
import '../../core/ui/responsive.dart';
import '../../core/utils/sensitive_display.dart';
import '../../models/user_profile.dart';
import '../../models/credit_card.dart';
import '../../models/income_source.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_input.dart';
import '../../utils/date_utils.dart';
import '../../widgets/money_visibility_button.dart';
import '../../widgets/modals/income_modal.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _user;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final professionController = TextEditingController();
  final photoPathController =
      TextEditingController(); // por enquanto: caminho manual
  final propertyValueController = TextEditingController();
  final investBalanceController = TextEditingController();

  DateTime? birthDate;
  String? _pendingPhotoPath;
  Uint8List? _pendingPhotoBytes;
  bool _saving = false;
  String gender = GenderCatalog.notInformed;
  static const List<String> _genderOptions = GenderCatalog.codes;
  final ImagePicker _imagePicker = ImagePicker();
  List<CreditCard> _cards = [];

  @override
  void initState() {
    super.initState();
    _load();
    LocalStorageService.userNotifier.addListener(_onUserChanged);
    LocalStorageService.incomeNotifier.addListener(_onIncomesChanged);
  }

  void _onIncomesChanged() {
    if (!mounted || _saving) return;
    setState(() {}); // Just rebuild to fetch from storage
  }

  void _onUserChanged() {
    if (!mounted || _saving) return;

    final newUser = LocalStorageService.getUserProfile();
    if (newUser == null) return;

    setState(() {
      _user = newUser;

      // Update controllers only if they are not being edited or are empty
      if (!firstNameController.selection.isValid ||
          firstNameController.text.isEmpty) {
        firstNameController.text = newUser.firstName;
      }
      if (!lastNameController.selection.isValid ||
          lastNameController.text.isEmpty) {
        lastNameController.text = newUser.lastName;
      }
      if (!emailController.selection.isValid || emailController.text.isEmpty) {
        emailController.text = newUser.email;
      }
      if (!professionController.selection.isValid ||
          professionController.text.isEmpty) {
        professionController.text = newUser.profession;
      }
      if (!propertyValueController.selection.isValid ||
          propertyValueController.text.isEmpty) {
        propertyValueController.text = formatMoneyInput(newUser.propertyValue);
      }
      if (!investBalanceController.selection.isValid ||
          investBalanceController.text.isEmpty) {
        investBalanceController.text = formatMoneyInput(newUser.investBalance);
      }

      birthDate = newUser.birthDate;
      gender = newUser.gender;
      _cards = List<CreditCard>.from(newUser.creditCards);
    });
  }

  void _load() {
    _user = LocalStorageService.getUserProfile();

    if (_user != null) {
      firstNameController.text = _user!.firstName;
      lastNameController.text = _user!.lastName;
      emailController.text = _user!.email;
      professionController.text = _user!.profession;
      propertyValueController.text = formatMoneyInput(_user!.propertyValue);
      investBalanceController.text = formatMoneyInput(_user!.investBalance);
      _cards = List<CreditCard>.from(_user!.creditCards);
      if (!_genderOptions.contains(gender)) {
        gender = _genderOptions.first;
      }

      _onIncomesChanged();
    }
    _pendingPhotoPath = null;

    setState(() {});
  }

  @override
  void dispose() {
    LocalStorageService.userNotifier.removeListener(_onUserChanged);
    LocalStorageService.incomeNotifier.removeListener(_onIncomesChanged);
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    professionController.dispose();
    photoPathController.dispose();
    propertyValueController.dispose();
    investBalanceController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final initial = birthDate ?? DateTime(2000, 1, 1);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => birthDate = date);
    }
  }

  Future<void> _pickProfilePhoto() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    _pendingPhotoPath = file.path;
    if (kIsWeb) {
      _pendingPhotoBytes = await file.readAsBytes();
    }

    photoPathController.text = file.path;
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    if (_user == null) {
      _snack(AppStrings.t(context, 'profile_no_user'));
      setState(() => _saving = false);
      return;
    }

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final profession = professionController.text.trim();
    final propertyValue = parseMoneyInput(propertyValueController.text);
    final investBalance = parseMoneyInput(investBalanceController.text);
    final emailValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

    if (firstName.isEmpty || lastName.isEmpty) {
      _snack('Preencha nome e sobrenome para salvar seu perfil.');
      setState(() => _saving = false);
      return;
    }
    if (!emailValid) {
      _snack('Digite um e-mail no formato nome@dominio.com');
      setState(() => _saving = false);
      return;
    }

    if (password.isNotEmpty && password != confirmPassword) {
      _snack(AppStrings.t(context, 'register_password_mismatch'));
      setState(() => _saving = false);
      return;
    }

    final path = photoPathController.text.trim();
    String? finalPhotoPath = path.isEmpty ? null : path;

    if (_pendingPhotoPath != null && _pendingPhotoPath!.isNotEmpty) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final localFile = File('${dir.path}/$fileName');

        if (kIsWeb && _pendingPhotoBytes != null) {
          await localFile.writeAsBytes(_pendingPhotoBytes!);
        } else {
          final originalFile = File(_pendingPhotoPath!);
          if (await originalFile.exists()) {
            await originalFile.copy(localFile.path);
          }
        }
        finalPhotoPath = localFile.path;
      } catch (e) {
        debugPrint('ProfilePage: Error saving local photo: $e');
        _snack('Erro ao salvar foto localmente');
        setState(() => _saving = false);
        return;
      }
    }

    final previousCards = List<CreditCard>.from(_user!.creditCards);
    final newUser = UserProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password.isEmpty ? _user!.password : password,
      birthDate: birthDate ?? _user!.birthDate,
      profession: profession,
      monthlyIncome:
          _user!.monthlyIncome, // Handled by separate income collection
      incomeSources: _user!.incomeSources,
      gender: gender,
      photoPath: finalPhotoPath,
      propertyValue: propertyValue,
      investBalance: investBalance,
      objectives: _user!.objectives,
      setupCompleted: _user!.setupCompleted,
      isPremium: _user!.isPremium,
      isActive: _user!.isActive,
      totalXp: _user!.totalXp,
      completedMissions: _user!.completedMissions,
      lastReportViewedAt: _user!.lastReportViewedAt,
      lastCalculatorOpenedAt: _user!.lastCalculatorOpenedAt,
      creditCards: _cards,
    );

    // Individual incomes are saved directly in Modal,
    // so we don't need to save them here anymore.

    final ok = await LocalStorageService.updateUserProfile(
      previous: _user!,
      updated: newUser,
    );
    if (!mounted) return;
    if (!ok) {
      _snack(AppStrings.t(context, 'register_email_in_use'));
      setState(() => _saving = false);
      return;
    }

    final nextCardsById = {for (final c in newUser.creditCards) c.id: c};
    final prevCardsById = {for (final c in previousCards) c.id: c};

    for (final removedId in prevCardsById.keys) {
      if (nextCardsById.containsKey(removedId)) continue;
      await NotificationService.cancelCreditCardBillReminder(removedId);
    }
    for (final card in newUser.creditCards) {
      await NotificationService.scheduleCreditCardBillReminder(card);
    }

    _user = newUser;
    _pendingPhotoPath = null;
    _pendingPhotoBytes = null;
    photoPathController.text = finalPhotoPath ?? '';
    setState(() => _saving = false);
    if (!mounted) return;
    _snack(AppStrings.t(context, 'profile_updated'));
    final syncError = LocalStorageService.lastSyncError;
    if (syncError != null) {
      _snack(syncError);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _askIncomeDeleteScope() async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Apagar renda fixa'),
        content: const Text(
          'Deseja remover apenas este mês ou apagar para todos os meses seguintes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'month'),
            child: const Text('Somente este mês'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: const Text('Meses seguintes'),
          ),
        ],
      ),
    );
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  bool _shouldShowIncome(IncomeSource income, String monthKey) {
    if (income.activeUntil != null &&
        monthKey.compareTo(income.activeUntil!) > 0) {
      return false;
    }
    return true;
  }

  ImageProvider? _photoProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (kIsWeb && _pendingPhotoBytes != null && path == _pendingPhotoPath) {
      return MemoryImage(_pendingPhotoBytes!);
    }
    final file = File(path);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  Future<void> _addCard() async {
    final nameController = TextEditingController();
    int? dueDay;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppStrings.t(context, 'card_add')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                  labelText: AppStrings.t(context, 'card_name')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: dueDay,
              decoration: InputDecoration(
                  labelText: AppStrings.t(context, 'card_due_day')),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(AppStrings.t(context, 'select')),
                ),
                ...List.generate(
                  31,
                  (i) => DropdownMenuItem<int?>(
                    value: i + 1,
                    child: Text('Dia ${i + 1}'),
                  ),
                ),
              ],
              onChanged: (v) => dueDay = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.t(context, 'save')),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty || dueDay == null || dueDay! <= 0) return;
    setState(() {
      _cards.add(
        CreditCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          dueDay: dueDay!,
        ),
      );
    });
  }

  void _removeCard(CreditCard card) {
    setState(() {
      _cards.removeWhere((c) => c.id == card.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t(context, 'profile'))),
        body: Padding(
          padding: Responsive.pagePadding(context),
          child: Center(
            child: Text(
              AppStrings.t(context, 'profile_no_user_body'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
        ),
      );
    }

    final photo = _photoProvider(_user!.photoPath);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'profile')),
        actions: [
          const MoneyVisibilityButton(),
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            tooltip: AppStrings.t(context, 'save'),
          ),
        ],
      ),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mantenha apenas o essencial atualizado: nome, e-mail e renda.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary,
                backgroundImage: photo,
                child: photo == null
                    ? const Icon(Icons.person, color: Colors.black, size: 34)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: _pickProfilePhoto,
                icon: const Icon(Icons.photo_library),
                label: Text(AppStrings.t(context, 'profile_change_photo')),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                  labelText: AppStrings.t(context, 'first_name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                  labelText: AppStrings.t(context, 'last_name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  InputDecoration(labelText: AppStrings.t(context, 'email')),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppStrings.t(context, 'birth_date'),
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
              subtitle: Text(
                birthDate == null
                    ? AppStrings.t(context, 'select')
                    : DateUtilsJetx.formatDate(
                        birthDate!,
                        locale: Localizations.localeOf(context).toLanguageTag(),
                      ),
                style: TextStyle(color: AppTheme.textPrimary(context)),
              ),
              trailing: const Icon(Icons.calendar_month, color: Colors.amber),
              onTap: _pickBirthDate,
            ),
            DropdownButtonFormField<String>(
              initialValue: _genderOptions.contains(gender)
                  ? gender
                  : _genderOptions.first,
              decoration:
                  InputDecoration(labelText: AppStrings.t(context, 'gender')),
              items: _genderOptions
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(AppStrings.t(context, 'gender_$value')),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => gender = v ?? _genderOptions.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: professionController,
              decoration: InputDecoration(
                  labelText: AppStrings.t(context, 'profession')),
            ),
            const SizedBox(height: 12),
            ..._buildIncomeSources(),
            const SizedBox(height: 22),
            Text(
              AppStrings.t(context, 'wealth_info_title'),
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: propertyValueController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [MoneyTextInputFormatter()],
              decoration: InputDecoration(
                labelText: AppStrings.t(context, 'profile_property_value'),
                prefixText: 'R\$ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: investBalanceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [MoneyTextInputFormatter()],
              decoration: InputDecoration(
                labelText: AppStrings.t(context, 'profile_invest_balance'),
                prefixText: 'R\$ ',
              ),
            ),
            const SizedBox(height: 22),
            Text(
              AppStrings.t(context, 'credit_cards_title'),
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            if (_cards.isEmpty)
              Text(
                AppStrings.t(context, 'credit_cards_empty'),
                style:
                    TextStyle(color: AppTheme.textMuted(context), fontSize: 12),
              )
            else
              ..._cards.map(
                (card) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(card.name,
                      style: TextStyle(color: AppTheme.textPrimary(context))),
                  subtitle: Text(
                    AppStrings.tr(
                      context,
                      'card_due_day_label',
                      {'day': '${card.dueDay}'},
                    ),
                    style: TextStyle(
                        color: AppTheme.textSecondary(context), fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.textSecondary(context),
                    onPressed: () => _removeCard(card),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addCard,
                icon: const Icon(Icons.add),
                label: Text(AppStrings.t(context, 'card_add')),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.t(context, 'save')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIncomeSources() {
    final monthKey = _monthKey(DateTime.now());
    final visibleIncomes = LocalStorageService.getIncomes()
        .where((income) => _shouldShowIncome(income, monthKey))
        .toList();
    return [
      if (Responsive.isCompactPhone(context))
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(context, 'monthly_income'),
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => IncomeModal.show(context),
                icon: const Icon(Icons.add, size: 16),
                label: Text(AppStrings.t(context, 'add_extra_income')),
              ),
            ),
          ],
        )
      else
        Row(
          children: [
            Text(
              AppStrings.t(context, 'monthly_income'),
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => IncomeModal.show(context),
              icon: const Icon(Icons.add, size: 16),
              label: Text(AppStrings.t(context, 'add_extra_income')),
            ),
          ],
        ),
      ...visibleIncomes.map((income) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => IncomeModal.show(context, income: income),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          income.title,
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (income.isPrimary)
                          Text(
                            'Renda Principal',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    SensitiveDisplay.money(context, income.amount),
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined,
                      size: 18, color: AppTheme.textSecondary(context)),
                  if (!income.isPrimary) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent, size: 20),
                      onPressed: () async {
                        final choice = await _askIncomeDeleteScope();
                        if (choice == null) return;
                        final now = DateTime.now();
                        bool ok = false;
                        if (choice == 'month') {
                          ok = await LocalStorageService.excludeIncomeForMonth(
                              income.id, now);
                        } else if (choice == 'all') {
                          final prev = DateTime(now.year, now.month - 1, 1);
                          final prevKey = _monthKey(prev);
                          ok = await LocalStorageService.setIncomeActiveUntil(
                              income.id, prevKey);
                        }
                        if (!ok && mounted) {
                          _snack(AppStrings.t(context, 'error_delete_primary'));
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: 6),
      Text(
        AppStrings.t(context, 'income_variable_tip'),
        style: TextStyle(
          color: AppTheme.textPrimary(context).withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    ];
  }
}
