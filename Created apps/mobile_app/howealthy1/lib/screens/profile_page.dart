import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:howealthy1/l10n/app_localizations.dart';
import '../theme/app_colors.dart';

// Helper functions
String capitalizeName(String name) {
  if (name.isEmpty) return "";
  return name.split(' ').map((word) {
    if (word.isEmpty) return "";
    return "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}";
  }).join(' ');
}

Future<int> _getNextSequence(String counterName, {int incrementBy = 1}) async {
  final docRef =
      FirebaseFirestore.instance.collection('counters').doc(counterName);
  return FirebaseFirestore.instance.runTransaction((transaction) async {
    DocumentSnapshot snapshot = await transaction.get(docRef);
    if (!snapshot.exists) {
      transaction.set(docRef, {'count': 0});
      return 0;
    }
    int current = (snapshot.data() as Map<String, dynamic>)['count'] ?? 0;
    int next = current + incrementBy;
    transaction.update(docRef, {'count': next});
    return current + 1;
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  final _cityController = TextEditingController();
  File? _imageFile;
  String? _base64Image;
  int? _existingNumericId;
  bool _isLoading = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    _emailController.text = currentUser!.email ?? "";
    _nameController.text = capitalizeName(currentUser!.displayName ?? "");
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          _nameController.text =
              capitalizeName(data['name'] ?? _nameController.text);
          _phoneController.text = data['phone'] ?? "";
          _occupationController.text = data['occupation'] ?? "";
          _cityController.text = data['city'] ?? "";
          _existingNumericId = data['customer_id'];
          if (data['photoBase64'] != null) _base64Image = data['photoBase64'];
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 400);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _imageFile = File(pickedFile.path);
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String phone = _phoneController.text.trim();
      String uid = currentUser!.uid;
      if (phone.isNotEmpty) {
        var query = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phone)
            .get();
        for (var doc in query.docs) {
          if (doc.id != uid) {
            throw "This mobile number is already associated with another account.";
          }
        }
      }
      int customerIdToSave;
      if (_existingNumericId != null) {
        customerIdToSave = _existingNumericId!;
      } else {
        customerIdToSave = await _getNextSequence('customers');
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'customer_id': customerIdToSave,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': phone,
        'occupation': _occupationController.text.trim(),
        'city': _cityController.text.trim(),
        'photoBase64': _base64Image,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await currentUser!.updateDisplayName(_nameController.text.trim());
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          AppBar(title: Text(l10n.editProfile), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Semantics(
                button: true,
                label: l10n.tapToChangePhoto,
                child: GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    builder: (ctx) => Wrap(children: [
                      ListTile(
                          leading: const Icon(Icons.camera),
                          title: Text(l10n.camera),
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickImage(ImageSource.camera);
                          }),
                      ListTile(
                          leading: const Icon(Icons.photo),
                          title: Text(l10n.gallery),
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickImage(ImageSource.gallery);
                          }),
                    ]),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.darkTextSecondary,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_base64Image != null
                            ? MemoryImage(base64Decode(_base64Image!))
                                as ImageProvider
                            : null),
                    child: (_imageFile == null && _base64Image == null)
                        ? Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : "U",
                            style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(l10n.tapToChangePhoto,
                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
              const SizedBox(height: 30),
              if (_existingNumericId != null) ...[
                Text(l10n.customerIdLabel(_existingNumericId!.toString()),
                    style: const TextStyle(
                        color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
              ],
              TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      labelText: l10n.fullName,
                      prefixIcon:
                          const Icon(Icons.person, color: Colors.tealAccent),
                      border: const OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? l10n.nameEmpty : null),
              const SizedBox(height: 20),
              TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  style: const TextStyle(color: AppColors.darkTextSecondary),
                  decoration: InputDecoration(
                      labelText: l10n.emailId,
                      prefixIcon: const Icon(Icons.email, color: AppColors.darkTextSecondary),
                      border: const OutlineInputBorder(),
                      fillColor: Colors.white10,
                      filled: true)),
              const SizedBox(height: 20),
              TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      labelText: l10n.mobileNumber,
                      prefixIcon:
                          const Icon(Icons.phone, color: Colors.tealAccent),
                      border: const OutlineInputBorder()),
                  validator: (val) {
                    if (val == null || val.isEmpty) return l10n.mobileRequired;
                    if (val.length < 10) return l10n.mobileInvalid;
                    return null;
                  }),
              const SizedBox(height: 40),
              SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(l10n.saveProfile,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _occupationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: l10n.occupation,
                        prefixIcon:
                            const Icon(Icons.work, color: Colors.tealAccent),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: l10n.city,
                        prefixIcon: const Icon(Icons.location_city,
                            color: Colors.tealAccent),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
