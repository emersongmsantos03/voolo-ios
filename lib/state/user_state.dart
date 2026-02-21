import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/local_storage_service.dart';

class UserState extends ChangeNotifier {
  UserProfile? _user;

  UserProfile? get user => _user;

  bool get isLogged => _user != null;

  void loadUser() {
    _user = LocalStorageService.getUserProfile();
    notifyListeners();
  }

  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required DateTime birthDate,
    required String profession,
    required double monthlyIncome,
    String gender = 'Nao informado',
    String? photoPath,
    List<String> objectives = const [],
    bool setupCompleted = false,
    bool isPremium = false,
    int totalXp = 0,
  }) async {
    _user = UserProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      birthDate: birthDate,
      profession: profession,
      monthlyIncome: monthlyIncome,
      gender: gender,
      photoPath: photoPath,
      objectives: objectives,
      setupCompleted: setupCompleted,
      isPremium: isPremium,
      totalXp: totalXp,
    );

    await LocalStorageService.saveUserProfile(_user!);
    notifyListeners();
  }

  Future<void> updateIncome(double income) async {
    if (_user == null) return;

    _user!.monthlyIncome = income;
    await LocalStorageService.updateMonthlyIncome(income);
    notifyListeners();
  }
}
