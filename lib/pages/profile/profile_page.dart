import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../../routes/app_routes.dart';
import '../../services/billing_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
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
  bool _billingBusy = false;
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

    final bytes = await file.readAsBytes();
    setState(() {
      _pendingPhotoPath = file.path;
      _pendingPhotoBytes = bytes;
      photoPathController.text = file.path;
    });
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

    String? finalPhotoPath =
        _user?.photoPath?.isNotEmpty == true ? _user!.photoPath : null;

    if (_pendingPhotoPath != null && _pendingPhotoPath!.isNotEmpty) {
      final userId =
          LocalStorageService.currentUserId ?? email.toLowerCase().trim();
      String? uploadedUrl;
      try {
        uploadedUrl = await StorageService.uploadUserPhoto(
          userId: userId,
          filePath: _pendingPhotoPath!,
          fileBytes: _pendingPhotoBytes,
        ).timeout(const Duration(seconds: 45));
      } catch (e) {
        debugPrint('ProfilePage: uploadUserPhoto failed, falling back: $e');
      }

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        finalPhotoPath = uploadedUrl;
      } else {
        finalPhotoPath = await _savePhotoLocallyFallback(
            _pendingPhotoPath!, _pendingPhotoBytes);
        if (finalPhotoPath == null || finalPhotoPath.isEmpty) {
          _snack('Erro ao salvar foto');
          setState(() => _saving = false);
          return;
        }
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

    if (finalPhotoPath != null && finalPhotoPath.isNotEmpty) {
      try {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          await authUser.updatePhotoURL(finalPhotoPath);
        }
      } catch (e) {
        debugPrint('ProfilePage: Error updating auth photoURL: $e');
      }
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

  Future<void> _cancelSubscription() async {
    if (_billingBusy) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _snack(
        AppStrings.t(
          context,
          'profile_subscription_login_required',
        ),
      );
      return;
    }

    setState(() => _billingBusy = true);

    try {
      await BillingService.cancelPaddleSubscription();

      await LocalStorageService.waitForSync(timeoutSeconds: 8);
      if (!mounted) return;
      final refreshedUser = LocalStorageService.getUserProfile();
      if (refreshedUser != null) {
        setState(() {
          _user = refreshedUser;
        });
      }

      _snack(
        AppStrings.t(
          context,
          'profile_subscription_cancelled',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _snack(
        AppStrings.t(
          context,
          'profile_subscription_action_error',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _billingBusy = false);
      }
    }
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.premiumCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Future<String?> _askIncomeDeleteScope() async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppStrings.t(context, 'profile_income_delete_title')),
        content: Text(AppStrings.t(context, 'profile_income_delete_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'month'),
            child: Text(
                AppStrings.t(context, 'profile_income_delete_scope_month')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: Text(
                AppStrings.t(context, 'profile_income_delete_scope_future')),
          ),
        ],
      ),
    );
  }

  Future<String?> _askDeleteAccountPassword() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: !_saving,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppStrings.t(context, 'profile_delete_account_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.t(context, 'profile_delete_account_body')),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.t(
                    context,
                    'profile_delete_account_password_label',
                  ),
                ),
                onSubmitted: (_) {
                  Navigator.pop(context, controller.text.trim());
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child:
                Text(AppStrings.t(context, 'profile_delete_account_confirm')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _deleteAccount() async {
    if (_saving) return;
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    final isPasswordProvider = authUser.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (!isPasswordProvider) {
      _snack(AppStrings.t(context, 'profile_delete_account_requires_password'));
      return;
    }

    final password = await _askDeleteAccountPassword();
    if (password == null || password.isEmpty) return;

    setState(() => _saving = true);
    final ok =
        await LocalStorageService.deleteCurrentAccount(password: password);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      final errorKey =
          LocalStorageService.lastLoginError ?? 'profile_delete_account_failed';
      _snack(AppStrings.t(context, errorKey));
      return;
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.login, (route) => false);
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  bool _shouldShowIncome(IncomeSource income, String monthKey) {
    return income.appliesToMonthKey(monthKey);
  }

  ImageProvider? _photoProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (_pendingPhotoBytes != null && path == _pendingPhotoPath) {
      return MemoryImage(_pendingPhotoBytes!);
    }
    final file = File(path);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  Future<String?> _savePhotoLocallyFallback(
    String sourcePath,
    Uint8List? bytes,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localFile = File('${dir.path}/$fileName');

      if (bytes != null) {
        await localFile.writeAsBytes(bytes);
      } else {
        final originalFile = File(sourcePath);
        if (!await originalFile.exists()) {
          debugPrint(
              'ProfilePage: Fallback photo file not found at $sourcePath');
          return null;
        }
        await originalFile.copy(localFile.path);
      }

      return localFile.path;
    } catch (e) {
      debugPrint('ProfilePage: Error saving local photo fallback: $e');
      return null;
    }
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

    final photo = _pendingPhotoBytes != null
        ? MemoryImage(_pendingPhotoBytes!)
        : _photoProvider(_user!.photoPath);
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
              decoration: AppTheme.premiumCardDecoration(context),
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
            Container(
              padding: const EdgeInsets.all(22),
              decoration: AppTheme.premiumCardDecoration(context),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.primary,
                    backgroundImage: photo,
                    child: photo == null
                        ? const Icon(Icons.person,
                            color: Colors.black, size: 34)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${firstNameController.text} ${lastNameController.text}'
                        .trim(),
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emailController.text,
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _pickProfilePhoto,
                    icon: const Icon(Icons.photo_library),
                    label: Text(AppStrings.t(context, 'profile_change_photo')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_user?.isPremium == true) ...[
              _sectionCard(
                title: AppStrings.t(
                  context,
                  'profile_premium_section_title',
                ),
                subtitle: AppStrings.t(
                  context,
                  'profile_premium_section_subtitle',
                ),
                children: [
                  Text(
                    AppStrings.t(
                      context,
                      'profile_premium_section_body',
                    ),
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _billingBusy ? null : _cancelSubscription,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary(context),
                        side:
                            BorderSide(color: AppTheme.textSecondary(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _billingBusy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined),
                      label: Text(
                        AppStrings.t(
                          context,
                          'profile_premium_cancel_cta',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            _sectionCard(
              title: AppStrings.t(context, 'profile_personal_data_title'),
              subtitle: AppStrings.t(
                context,
                'profile_personal_data_subtitle',
              ),
              children: [
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
                  decoration: InputDecoration(
                      labelText: AppStrings.t(context, 'email')),
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
                            locale:
                                Localizations.localeOf(context).toLanguageTag(),
                          ),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _pickBirthDate,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _genderOptions.contains(gender)
                      ? gender
                      : _genderOptions.first,
                  decoration: InputDecoration(
                      labelText: AppStrings.t(context, 'gender')),
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
              ],
            ),
            const SizedBox(height: 18),
            _sectionCard(
              title: AppStrings.t(context, 'profile_income_title'),
              subtitle: AppStrings.t(context, 'profile_income_subtitle'),
              children: _buildIncomeSources(),
            ),
            const SizedBox(height: 18),
            _sectionCard(
              title: AppStrings.t(context, 'wealth_info_title'),
              subtitle:
                  'Esses dados ajudam o Voolo a ler seu patrimônio com mais contexto.',
              children: [
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
              ],
            ),
            const SizedBox(height: 18),
            _sectionCard(
              title: AppStrings.t(context, 'credit_cards_title'),
              subtitle:
                  'Seus cartões alimentam a leitura correta da fatura no dashboard e nos relatórios.',
              children: [
                if (_cards.isEmpty)
                  Text(
                    AppStrings.t(context, 'credit_cards_empty'),
                    style: TextStyle(
                        color: AppTheme.textMuted(context), fontSize: 12),
                  )
                else
                  ..._cards.map(
                    (card) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(card.name,
                          style:
                              TextStyle(color: AppTheme.textPrimary(context))),
                      subtitle: Text(
                        AppStrings.tr(
                          context,
                          'card_due_day_label',
                          {'day': '${card.dueDay}'},
                        ),
                        style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12),
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
              ],
            ),
            const SizedBox(height: 18),
            _sectionCard(
              title: AppStrings.t(context, 'profile_delete_account_title'),
              subtitle:
                  AppStrings.t(context, 'profile_delete_account_subtitle'),
              children: [
                Text(
                  AppStrings.t(context, 'profile_delete_account_body'),
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _deleteAccount,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: Text(
                      AppStrings.t(context, 'profile_delete_account_confirm'),
                    ),
                  ),
                ),
              ],
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
              AppStrings.t(context, 'month_entries'),
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ],
        )
      else
        Row(
          children: [
            Text(
              AppStrings.t(context, 'month_entries'),
              style: TextStyle(color: AppTheme.textSecondary(context)),
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
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.14),
                ),
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
                            AppStrings.t(
                                context, 'profile_primary_income_label'),
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
