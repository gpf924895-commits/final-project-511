import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'change_password_page.dart';
import 'package:path/path.dart' as path;
import '../widgets/app_drawer.dart';
import '../utils/page_transition.dart';
import '../database/firebase_service.dart';
import '../provider/pro_login.dart';

class ProfilePage extends StatefulWidget {
  final Function(bool)? toggleTheme;
  
  const ProfilePage({Key? key, this.toggleTheme}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String gender = 'ذكر';
  DateTime? birthDate;
  File? profileImage;
  late SharedPreferences _prefs;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initPrefsAndData();
  }

  Future<void> _initPrefsAndData() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Get current user ID from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.currentUser?['id'];
    
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    // Load profile data from Firebase
    await _loadProfileFromFirebase();
    
    // Load saved image path from SharedPreferences
    final savedPath = _prefs.getString('profile_image_${_userId}');
    if (savedPath != null && await File(savedPath).exists()) {
      setState(() {
        profileImage = File(savedPath);
      });
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadProfileFromFirebase() async {
    if (_userId == null) return;
    
    final userData = await _firebaseService.getUserProfile(_userId!);
    if (userData != null) {
      setState(() {
        _nameController.text = userData['name'] ?? userData['username'] ?? '';
        gender = userData['gender'] ?? 'ذكر';
        
        // Parse birth date if exists
        if (userData['birth_date'] != null) {
          try {
            final parts = userData['birth_date'].split('/');
            if (parts.length == 3) {
              birthDate = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
            }
          } catch (e) {
            // If parsing fails, keep birthDate as null
          }
        }
      });
    }
  }

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // انسخ الصورة لمجلد التطبيق (حتى تبقى موجودة)
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(picked.path);
    final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

    // احفظ المسار في SharedPreferences (per user)
    if (_userId != null) {
      await _prefs.setString('profile_image_${_userId}', savedImage.path);
    }

    setState(() {
      profileImage = savedImage;
    });
  }

  Future<void> _saveProfileData() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: لم يتم العثور على معلومات المستخدم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Format birth date as string
    String? birthDateStr;
    if (birthDate != null) {
      birthDateStr = '${birthDate!.year}/${birthDate!.month}/${birthDate!.day}';
    }

    // Save to Firebase
    final result = await _firebaseService.updateUserProfile(
      userId: _userId!,
      name: _nameController.text.trim(),
      gender: gender,
      birthDate: birthDateStr,
    );

    // Close loading dialog
    Navigator.of(context).pop();

    // Show result message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: widget.toggleTheme != null ? [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ] : null,
      ),
      drawer: widget.toggleTheme != null ? AppDrawer(toggleTheme: widget.toggleTheme!) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userId == null
          ? const Center(
              child: Text(
                'يرجى تسجيل الدخول لعرض الملف الشخصي',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundImage: profileImage != null
                      ? FileImage(profileImage!)
                      : const AssetImage('assets/profile.png')
                          as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      onPressed: _pickAndSaveImage,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'الاسم',
              border: OutlineInputBorder(),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: gender,
            decoration: const InputDecoration(
              labelText: 'الجنس',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
              DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => gender = value);
            },
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'تاريخ الميلاد',
              border: OutlineInputBorder(),
            ),
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: birthDate ?? DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => birthDate = picked);
                }
              },
              child: Text(
                birthDate != null
                    ? '${birthDate!.year}/${birthDate!.month}/${birthDate!.day}'
                    : 'اختر تاريخ',
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveProfileData,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('حفظ المعلومات'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              SmoothPageTransition.navigateTo(
                context,
                const ChangePasswordPage(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('تغيير كلمة المرور'),
          ),
        ],
      ),
    );
  }
}
