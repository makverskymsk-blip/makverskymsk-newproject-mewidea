import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_button.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  bool _isCreate = true;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();


  SportCategory _selectedSport = SportCategory.football;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();


    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Введите название');
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    final auth = context.read<AuthProvider>();
    final communityProv = context.read<CommunityProvider>();

    try {
      await communityProv.createCommunityFirestore(
        name: _nameCtrl.text.trim(),
        sport: _selectedSport,
        ownerId: auth.uid!,

      );
      await auth.addCommunityToUser(communityProv.activeCommunity!.id);
    } catch (e) {
      if (mounted) setState(() => _error = 'Ошибка: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _join() async {
    if (_codeCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Введите код приглашения');
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    final auth = context.read<AuthProvider>();
    final communityProv = context.read<CommunityProvider>();

    try {
      final success = await communityProv.joinCommunityFirestore(
        _codeCtrl.text.trim(),
        auth.uid!,
      );

      if (mounted) {
        if (success) {
          await auth.addCommunityToUser(communityProv.activeCommunity!.id);
          // Загружаем данные нового сообщества
          if (communityProv.activeCommunity != null) {
            final cid = communityProv.activeCommunity!.id;
            await communityProv.loadSubscriptions(cid);
          }
          if (mounted) {
            Navigator.of(context).pop(); // Вернуться к списку сообществ
          }
        } else {
          setState(() => _error = 'Сообщество не найдено. Проверьте код.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Ошибка при вступлении: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.of(context).scaffoldBg),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded,
                        color: AppColors.primary, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Ваше сообщество',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Создайте новое или присоединитесь по коду',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Toggle
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            text: 'Создать',
                            icon: Icons.add_rounded,
                            color: _isCreate ? AppColors.primary : AppColors.textHint,
                            onPressed: () => setState(() { _isCreate = true; _error = null; }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassButton(
                            text: 'Вступить',
                            icon: Icons.login_rounded,
                            color: !_isCreate ? AppColors.primary : AppColors.textHint,
                            onPressed: () => setState(() { _isCreate = false; _error = null; }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (_error != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                            textAlign: TextAlign.center),
                      ),

                    // Forms
                    if (_isCreate) _buildCreateForm() else _buildJoinForm(),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_isCreate ? _create : _join),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                _isCreate ? 'Создать сообщество' : 'Присоединиться',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return GlassCard(
      child: Column(
        children: [
          _field(_nameCtrl, 'Название сообщества', Icons.group_rounded),
          const SizedBox(height: 14),
          DropdownButtonFormField<SportCategory>(
            dropdownColor: Colors.white,
            initialValue: _selectedSport,
            decoration: InputDecoration(
              labelText: 'Вид спорта',
              labelStyle: TextStyle(color: AppColors.textHint),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            items: SportCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedSport = v);
            },
          ),

        ],
      ),
    );
  }

  Widget _buildJoinForm() {
    return GlassCard(
      child: Column(
        children: [
          _field(_codeCtrl, 'Код приглашения', Icons.vpn_key_rounded),
          const SizedBox(height: 8),
          Text(
            'Попросите код у владельца сообщества',
            style: TextStyle(
                color: AppColors.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.backgroundCard.withValues(alpha: 0.6),
      ),
    );
  }
}
