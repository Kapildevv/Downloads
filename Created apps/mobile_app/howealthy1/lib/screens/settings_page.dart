import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/oracle_state.dart';
import '../services/pin_service.dart';
import '../theme/app_colors.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _hasPinSet = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await PinService.hasPin();
    if (mounted) setState(() => _hasPinSet = hasPin);
  }

  // ─── PIN SETUP DIALOG ────────────────────────────────────
  Future<void> _showPinSetupDialog() async {
    String newPin = '';
    String confirmPin = '';
    bool isConfirmStep = false;
    String errorText = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.darkTextSecondary,
              title: Text(
                isConfirmStep ? 'Confirm Your PIN' : 'Set App PIN',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isConfirmStep
                        ? 'Re-enter your 4-digit PIN'
                        : 'Choose a 4-digit PIN to secure your app',
                    style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  // PIN dots display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final currentPin = isConfirmStep ? confirmPin : newPin;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < currentPin.length
                              ? Colors.tealAccent
                              : Colors.transparent,
                          border:
                              Border.all(color: Colors.tealAccent, width: 2),
                        ),
                      );
                    }),
                  ),
                  if (errorText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Compact numeric keypad
                  _buildDialogKeypad(
                    onDigit: (digit) {
                      setDialogState(() {
                        errorText = '';
                        if (isConfirmStep) {
                          if (confirmPin.length < 4) confirmPin += digit;
                        } else {
                          if (newPin.length < 4) newPin += digit;
                        }
                      });
                    },
                    onBackspace: () {
                      setDialogState(() {
                        if (isConfirmStep && confirmPin.isNotEmpty) {
                          confirmPin = confirmPin.substring(
                            0,
                            confirmPin.length - 1,
                          );
                        } else if (!isConfirmStep && newPin.isNotEmpty) {
                          newPin = newPin.substring(0, newPin.length - 1);
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.darkTextSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!isConfirmStep) {
                      if (newPin.length != 4) {
                        setDialogState(
                          () => errorText = 'PIN must be 4 digits',
                        );
                        return;
                      }
                      setDialogState(() => isConfirmStep = true);
                    } else {
                      if (confirmPin != newPin) {
                        setDialogState(() {
                          errorText = 'PINs do not match';
                          confirmPin = '';
                        });
                        return;
                      }
                      try {
                        await PinService.setPin(newPin);
                        if (context.mounted) Navigator.pop(context);
                        _checkPinStatus();
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ App PIN set successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(
                          () => errorText = 'Failed to set PIN',
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                  ),
                  child: Text(
                    isConfirmStep ? 'Confirm' : 'Next',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogKeypad({
    required void Function(String) onDigit,
    required VoidCallback onBackspace,
  }) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '⌫'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((d) {
                if (d.isEmpty) return const SizedBox(width: 52, height: 42);
                if (d == '⌫') {
                  return SizedBox(
                    width: 52,
                    height: 42,
                    child: TextButton(
                      onPressed: onBackspace,
                      child: const Icon(
                        Icons.backspace_outlined,
                        color: AppColors.darkTextSecondary,
                        size: 18,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  width: 52,
                  height: 42,
                  child: TextButton(
                    onPressed: () => onDigit(d),
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _removePinDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkTextSecondary,
        title: const Text(
          'Remove App PIN?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your app will only be protected by biometric authentication.',
          style: TextStyle(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PinService.clearPin();
        _checkPinStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN removed'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove PIN'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final textScale = MediaQuery.textScalerOf(context);
    final userName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Operator';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Environmental Controls'),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Operator Identity (fixes BUG-009 — no more hardcoded "Kapil")
          ListTile(
            leading: const Icon(Icons.fingerprint, color: Colors.tealAccent),
            title: const Text(
              'Operator Identity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(userName),
          ),

          const Divider(color: Colors.white10),

          // ─── SECURITY SECTION ────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '🔐 SECURITY',
              style: TextStyle(
                color: Colors.tealAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          // App PIN Lock
          ListTile(
            leading: Icon(
              _hasPinSet ? Icons.lock : Icons.lock_open,
              color: _hasPinSet ? Colors.tealAccent : AppColors.darkTextSecondary,
            ),
            title: Text(
              _hasPinSet ? 'Change App PIN' : 'Set App PIN',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _hasPinSet ? 'PIN lock is active' : 'Add a 4-digit PIN lock',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.darkTextSecondary),
            onTap: _showPinSetupDialog,
          ),

          if (_hasPinSet)
            ListTile(
              leading: const Icon(Icons.lock_open, color: AppColors.error),
              title: const Text(
                'Remove App PIN',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: _removePinDialog,
            ),

          // Encryption status (informational)
          const ListTile(
            leading: Icon(Icons.enhanced_encryption, color: Colors.tealAccent),
            title: Text(
              'AES-256 Encryption',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'All local data encrypted at rest',
              style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
            trailing: Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ),

          // App Check status (informational)
          const ListTile(
            leading: Icon(Icons.verified_user, color: Colors.tealAccent),
            title: Text(
              'Firebase App Check',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'API requests are attested',
              style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
            trailing: Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ),

          const Divider(color: Colors.white10),

          // ─── APPEARANCE SECTION ──────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '🎨 APPEARANCE',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          SwitchListTile(
            activeThumbColor: Colors.tealAccent,
            title: Text(
              'Dark Theme',
              style: TextStyle(fontSize: textScale.scale(16)),
            ),
            subtitle: Text(
              'Toggle dark/light interface',
              style: TextStyle(fontSize: textScale.scale(12)),
            ),
            value: isDarkMode,
            onChanged: (bool value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),

          ListTile(
            leading: const Icon(Icons.remove_red_eye, color: AppColors.darkTextSecondary),
            title: Text(
              'Optical Typography Scaling',
              style: TextStyle(fontSize: textScale.scale(16)),
            ),
            subtitle: Text(
              'Adapts automatically via device text bounds',
              style: TextStyle(fontSize: textScale.scale(12)),
            ),
            trailing: const Icon(
              Icons.auto_awesome,
              color: Colors.yellowAccent,
              size: 16,
            ),
          ),

          const Divider(color: Colors.white10),

          // ─── DANGER ZONE ─────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '⚠️ DANGER ZONE',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text(
              'Purge Local Cache',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              // Future: Wipe Hive box and local state
            },
          ),
        ],
      ),
    );
  }
}
