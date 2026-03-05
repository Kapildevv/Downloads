import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pin_service.dart';
import 'cinematic_loader.dart';
import 'welcome_page.dart';
import '../theme/app_colors.dart';

/// ============================================================
/// Biometric + PIN Guard
/// Dual-layer authentication: biometric (fingerprint/face) with
/// PIN fallback. After 5 failed PIN attempts, forces Firebase
/// re-authentication for account security.
/// ============================================================
class BiometricGuard extends StatefulWidget {
  const BiometricGuard({super.key});
  @override
  State<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends State<BiometricGuard>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = true;
  bool _showPinEntry = false;
  bool _isLockedOut = false;
  String _pin = '';
  String _errorMessage = '';
  int _failedAttempts = 0;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _startAuthentication();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _startAuthentication() async {
    // Check if locked out from too many PIN attempts
    final lockedOut = await PinService.isLockedOut();
    if (lockedOut) {
      setState(() {
        _isLoading = false;
        _isLockedOut = true;
      });
      return;
    }

    // Try biometric first
    await _authenticateWithBiometrics();
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      bool isAvailable =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

      if (!isAvailable) {
        // No biometrics available — fall back to PIN if set
        final hasPin = await PinService.hasPin();
        if (hasPin) {
          setState(() {
            _isLoading = false;
            _showPinEntry = true;
          });
        } else {
          // No biometrics AND no PIN — let them through
          _pushToLoader();
        }
        return;
      }

      bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authenticate to access your wealth',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        _pushToLoader();
      } else {
        // Biometric failed — show PIN if available
        final hasPin = await PinService.hasPin();
        setState(() {
          _isLoading = false;
          _showPinEntry = hasPin;
        });
      }
    } catch (e) {
      // Biometric error — fall back to PIN
      final hasPin = await PinService.hasPin();
      setState(() {
        _isLoading = false;
        _showPinEntry = hasPin;
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_pin.length != 4) return;

    final isValid = await PinService.verifyPin(_pin);
    if (isValid) {
      _pushToLoader();
    } else {
      _failedAttempts = await PinService.getFailedAttempts();
      final remaining = PinService.maxFailedAttempts - _failedAttempts;

      if (_failedAttempts >= PinService.maxFailedAttempts) {
        setState(() {
          _isLockedOut = true;
          _showPinEntry = false;
        });
      } else {
        _shakeController.forward(from: 0);
        setState(() {
          _pin = '';
          _errorMessage = 'Wrong PIN. $remaining attempts left.';
        });
      }
    }
  }

  void _onDigitPressed(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _errorMessage = '';
    });
    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = '';
    });
  }

  void _pushToLoader() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CinematicLoader()),
      );
    }
  }

  Future<void> _forceReAuth() async {
    // Sign out and force re-login to reset lockout
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );
    }

    if (_isLockedOut) {
      return _buildLockedOutScreen();
    }

    if (_showPinEntry) {
      return _buildPinEntryScreen();
    }

    return _buildBiometricRetryScreen();
  }

  // ─── LOCKED OUT (5 failed attempts) ──────────────────────
  Widget _buildLockedOutScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: AppColors.error),
              const SizedBox(height: 24),
              const Text(
                'Account Locked',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Too many failed PIN attempts.\nPlease sign in again to verify your identity.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _forceReAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'Sign In Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PIN ENTRY ───────────────────────────────────────────
  Widget _buildPinEntryScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(
              Icons.shield_outlined,
              size: 60,
              color: Colors.tealAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter PIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _authenticateWithBiometrics,
              icon: const Icon(
                Icons.fingerprint,
                color: Colors.tealAccent,
                size: 18,
              ),
              label: const Text(
                'Use Biometrics Instead',
                style: TextStyle(color: Colors.tealAccent, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final offset = _shakeController.isAnimating
                    ? 10.0 *
                        (0.5 - _shakeController.value).abs() *
                        (_shakeController.value < 0.5 ? 1 : -1)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length
                          ? Colors.tealAccent
                          : Colors.transparent,
                      border: Border.all(color: Colors.tealAccent, width: 2),
                    ),
                  );
                }),
              ),
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],

            const Spacer(),

            // Numeric keypad
            _buildNumPad(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((d) => _buildKeypadButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((d) => _buildKeypadButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((d) => _buildKeypadButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 75), // Empty space
            _buildKeypadButton('0'),
            _buildBackspaceButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit) {
    return SizedBox(
      width: 75,
      height: 60,
      child: TextButton(
        onPressed: () => _onDigitPressed(digit),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.darkDivider),
          ),
        ),
        child: Text(
          digit,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return SizedBox(
      width: 75,
      height: 60,
      child: TextButton(
        onPressed: _onBackspace,
        child: const Icon(Icons.backspace_outlined, color: AppColors.darkTextSecondary),
      ),
    );
  }

  // ─── BIOMETRIC RETRY (no PIN set) ────────────────────────
  Widget _buildBiometricRetryScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.tealAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'Locked',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _authenticateWithBiometrics();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Unlock App',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
