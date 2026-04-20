import 'package:new_idea_works/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/app_notification.dart';
import '../services/supabase_service.dart';
import 'notification_provider.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _db = SupabaseService();
  UserProfile? _currentUser;
  bool _isLoading = true;
  dynamic _userRealtimeChannel;
  NotificationProvider? _notifProv;

  void setNotificationProvider(NotificationProvider prov) {
    _notifProv = prov;
  }

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _supabase.auth.currentUser != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get uid => _supabase.auth.currentUser?.id;

  AuthProvider() {
    _supabase.auth.onAuthStateChange.listen((data) {
      if (!_initialCheckDone) return; // skip until initial check completes
      _onAuthStateChanged(data.session?.user);
    });
    _checkInitialAuth();
  }

  bool _initialCheckDone = false;

  Future<void> _checkInitialAuth() async {
    final user = _supabase.auth.currentUser;
    appLog('AUTH INIT: currentUser = ${user?.id}');
    
    if (user == null) {
      appLog('AUTH INIT: No session, showing login');
      _isLoading = false;
      _initialCheckDone = true;
      notifyListeners();
      return;
    }

    try {
      // Try to load user profile with a timeout
      _currentUser = await _db.getUser(user.id).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          appLog('AUTH INIT: getUser timed out');
          return null;
        },
      );

      if (_currentUser == null) {
        appLog('AUTH INIT: No profile in DB, creating...');
        _currentUser = UserProfile(
          id: user.id,
          name: user.userMetadata?['full_name'] ?? 'Игрок',
          email: user.email,
          balance: 0,
        );
        try {
          await _db.createUser(_currentUser!).timeout(const Duration(seconds: 5));
          appLog('AUTH INIT: Profile created!');
        } catch (e) {
          appLog('AUTH INIT: Create failed: $e');
        }
      } else {
        appLog('AUTH INIT: Profile loaded: ${_currentUser!.name}');
      }
      // Subscribe to realtime user profile changes
      if (_currentUser != null) {
        _subscribeToUserRealtime(_currentUser!.id);
      }
    } catch (e) {
      appLog('AUTH INIT ERROR: $e');
    }

    _isLoading = false;
    _initialCheckDone = true;
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? supabaseUser) async {
    try {
      if (supabaseUser != null) {
        appLog('AUTH STATE: User changed: ${supabaseUser.id}');
        _currentUser = await _db.getUser(supabaseUser.id);
        if (_currentUser == null) {
          _currentUser = UserProfile(
            id: supabaseUser.id,
            name: supabaseUser.userMetadata?['full_name'] ?? 'Игрок',
            email: supabaseUser.email,
            balance: 0,
          );
          try {
            await _db.createUser(_currentUser!);
          } catch (_) {
            _currentUser = await _db.getUser(supabaseUser.id);
          }
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      appLog('AUTH STATE ERROR: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // success
    } on AuthException catch (e) {
      return _mapAuthError(e.message);
    }
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      appLog('AUTH: Starting registration for $email');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      appLog('AUTH: SignUp response: user=${response.user?.id}, session=${response.session != null}');

      if (response.user != null && response.session != null) {
        // Session exists — email confirmation disabled or auto-confirmed
        _currentUser = UserProfile(
          id: response.user!.id,
          name: name,
          email: email,
          balance: 0,
        );
        appLog('AUTH: Creating user profile in DB...');
        await _db.createUser(_currentUser!);
        appLog('AUTH: User profile created!');
        notifyListeners();
        return null; // success — logged in
      } else if (response.user != null && response.session == null) {
        // User created but email confirmation required
        // Pre-create profile in DB so it's ready when user confirms
        try {
          final profile = UserProfile(
            id: response.user!.id,
            name: name,
            email: email,
            balance: 0,
          );
          await _db.createUser(profile);
          appLog('AUTH: Profile pre-created, awaiting email confirmation');
        } catch (e) {
          appLog('AUTH: Pre-create profile failed (may already exist): $e');
        }
        return 'EMAIL_CONFIRM'; // special marker for UI
      }
      return 'Неизвестная ошибка регистрации';
    } on AuthException catch (e) {
      appLog('AUTH ERROR (AuthException): ${e.message}');
      return _mapAuthError(e.message);
    } catch (e) {
      appLog('AUTH ERROR (General): $e');
      return 'Ошибка: $e';
    }
  }

  Future<void> updateBalance(double amount) async {
    if (_currentUser == null) return;
    final prevBalance = _currentUser!.balance;
    _currentUser!.balance += amount;
    notifyListeners();
    try {
      await _db.updateUser(_currentUser!.id, {'balance': _currentUser!.balance});
      _notifProv?.add(
        type: amount >= 0 ? NotificationType.balanceTopUp : NotificationType.balanceCharge,
        title: amount >= 0 ? 'Баланс пополнен' : 'Списание',
        body: amount >= 0
            ? '+${amount.toInt()} ₽ — текущий баланс ${_currentUser!.balance.toInt()} ₽'
            : '${amount.toInt()} ₽ — текущий баланс ${_currentUser!.balance.toInt()} ₽',
      );
    } catch (e) {
      // Rollback
      _currentUser!.balance = prevBalance;
      notifyListeners();
      appLog('AUTH: updateBalance rollback — $e');
    }
  }

  /// Перечитать баланс из БД (после изменений другими провайдерами)
  Future<void> refreshBalance() async {
    if (_currentUser == null) return;
    try {
      final profile = await _db.getUser(_currentUser!.id);
      if (profile != null) {
        _currentUser!.balance = profile.balance;
        notifyListeners();
      }
    } catch (e) {
      appLog('AUTH: refreshBalance error: $e');
    }
  }

  Future<void> updatePosition(String position) async {
    if (_currentUser == null) return;
    final prevPosition = _currentUser!.position;
    _currentUser!.position = position;
    notifyListeners();
    try {
      await _db.updateUser(_currentUser!.id, {'position': position});
    } catch (e) {
      _currentUser!.position = prevPosition;
      notifyListeners();
      appLog('AUTH: updatePosition rollback — $e');
    }
  }

  /// Update position for a specific sport
  Future<void> updateSportPosition(String sportName, String position) async {
    if (_currentUser == null) return;
    final prevPosition = _currentUser!.position;
    final prevSportPositions = Map<String, String>.from(_currentUser!.sportPositions);
    _currentUser!.setPositionForSport(sportName, position);
    notifyListeners();
    try {
      await _db.updateUser(_currentUser!.id, {
        'position': _currentUser!.position,
        'sportPositions': _currentUser!.sportPositions,
      });
    } catch (e) {
      _currentUser!.position = prevPosition;
      _currentUser!.sportPositions
        ..clear()
        ..addAll(prevSportPositions);
      notifyListeners();
      appLog('AUTH: updateSportPosition rollback — $e');
    }
  }

  Future<void> addCommunityToUser(String communityId) async {
    if (_currentUser == null || _currentUser!.communityIds.contains(communityId)) return;
    _currentUser!.communityIds.add(communityId);
    notifyListeners();
    try {
      await _db.updateUser(_currentUser!.id, {
        'communityIds': _currentUser!.communityIds,
      });
    } catch (e) {
      _currentUser!.communityIds.remove(communityId);
      notifyListeners();
      appLog('AUTH: addCommunityToUser rollback — $e');
    }
  }

  /// Убрать из профиля communityIds, которых нет в БД
  Future<void> removeStaleCommunityIds(List<String> staleIds) async {
    if (_currentUser == null || staleIds.isEmpty) return;
    _currentUser!.communityIds.removeWhere((id) => staleIds.contains(id));
    await _db.updateUser(_currentUser!.id, {
      'communityIds': _currentUser!.communityIds,
    });
    notifyListeners();
  }

  /// Update a single field on the user profile (e.g. gender, height_cm, weight_kg, age)
  Future<void> updateUserField(String field, dynamic value) async {
    if (_currentUser == null) return;
    // Save snapshot for rollback
    final prevGender = _currentUser!.gender;
    final prevHeight = _currentUser!.heightCm;
    final prevWeight = _currentUser!.weightKg;
    final prevAge = _currentUser!.age;
    // Update local model
    switch (field) {
      case 'gender':
        _currentUser!.gender = value as String?;
        break;
      case 'height_cm':
        _currentUser!.heightCm = value as int?;
        break;
      case 'weight_kg':
        _currentUser!.weightKg = (value as num?)?.toDouble();
        break;
      case 'age':
        _currentUser!.age = value as int?;
        break;
    }
    notifyListeners();
    try {
      await _db.updateUser(_currentUser!.id, {field: value});
    } catch (e) {
      // Rollback
      _currentUser!.gender = prevGender;
      _currentUser!.heightCm = prevHeight;
      _currentUser!.weightKg = prevWeight;
      _currentUser!.age = prevAge;
      notifyListeners();
      appLog('AUTH: updateUserField($field) rollback — $e');
    }
  }

  Future<void> updateAvatar(String url) async {
    if (_currentUser == null) return;
    final prevUrl = _currentUser!.avatarUrl;
    _currentUser!.avatarUrl = url;
    notifyListeners();
    try {
      await _db.updateUser(_currentUser!.id, {'avatarUrl': url});
    } catch (e) {
      _currentUser!.avatarUrl = prevUrl;
      notifyListeners();
      appLog('AUTH: updateAvatar rollback — $e');
    }
  }

  /// Сброс пароля — отправить письмо на email
  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return null; // success
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  Future<void> logout() async {
    _userRealtimeChannel?.unsubscribe();
    _userRealtimeChannel = null;
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Subscribe to Realtime changes for user profile
  void _subscribeToUserRealtime(String userId) {
    _userRealtimeChannel?.unsubscribe();
    _userRealtimeChannel = _db.watchUserChannel(
      userId,
      onChanged: () => _refreshUserProfile(userId),
    );
  }

  /// Refresh user profile from DB when realtime event fires
  Future<void> _refreshUserProfile(String userId) async {
    try {
      final fresh = await _db.getUser(userId);
      if (fresh != null && _currentUser != null) {
        _currentUser = fresh;
        appLog('REALTIME: User profile refreshed — balance=${fresh.balance}, communities=${fresh.communityIds.length}');
        notifyListeners();
      }
    } catch (e) {
      appLog('REALTIME: Failed to refresh user profile: $e');
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) return 'Неверный логин или пароль';
    if (message.contains('Email not confirmed')) return 'EMAIL_CONFIRM';
    if (message.contains('User already registered')) return 'Email уже используется';
    if (message.contains('Password should be')) return 'Слишком простой пароль';
    return 'Ошибка авторизации: $message';
  }
}
