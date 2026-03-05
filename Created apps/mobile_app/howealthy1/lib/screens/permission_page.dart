import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:howealthy1/l10n/app_localizations.dart';
import 'login_page.dart';
import '../theme/app_colors.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});
  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool _isChecked = false;

  Future<void> _handlePermissions() async {
    await [Permission.sms, Permission.location, Permission.notification]
        .request();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const Color brandColor = Color(0xFF1B4D3E);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(
              header: true,
              child: Text(l10n.permissionsTitle,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            _buildPermissionItem(Icons.sms_outlined, l10n.sms, l10n.smsDesc),
            const SizedBox(height: 20),
            _buildPermissionItem(
                Icons.location_on_outlined, l10n.location, l10n.locationDesc),
            const SizedBox(height: 20),
            _buildPermissionItem(Icons.notifications_active_outlined,
                l10n.notifications, l10n.notificationsDesc),
            const Spacer(),
            Row(children: [
              Checkbox(
                value: _isChecked,
                activeColor: brandColor,
                checkColor: Colors.white,
                side: const BorderSide(color: brandColor, width: 2.0),
                onChanged: (val) => setState(() => _isChecked = val!),
              ),
              Expanded(
                  child: Text(l10n.privacyConsent,
                      style: const TextStyle(
                          color: AppColors.lightTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500))),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: l10n.iDisagree,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: brandColor),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: Text(l10n.iDisagree,
                        style: const TextStyle(color: brandColor)),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Semantics(
                  button: true,
                  label: l10n.iAgree,
                  child: ElevatedButton(
                    onPressed: _isChecked ? _handlePermissions : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        disabledBackgroundColor: AppColors.darkTextSecondary,
                        disabledForegroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: Text(l10n.iAgree,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String desc) {
    return Semantics(
      label: '$title: $desc',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.darkTextSecondary,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppColors.lightTextSecondary)),
          const SizedBox(width: 15),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 5),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.darkTextSecondary, fontSize: 12, height: 1.5)),
              ])),
        ],
      ),
    );
  }
}
