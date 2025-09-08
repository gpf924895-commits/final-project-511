import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'change_password_page.dart';
import 'package:path/path.dart' as path;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  String gender = 'ذكر';
  DateTime? birthDate;
  File? profileImage;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefsAndData();
  }

  Future<void> _initPrefsAndData() async {
    _prefs = await SharedPreferences.getInstance();
    // load saved image path
    final savedPath = _prefs.getString('profile_image');
    if (savedPath != null && await File(savedPath).exists()) {
      setState(() {
        profileImage = File(savedPath);
      });
    }
    // load other data if حاب تحفظها بعدين
  }

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // انسخ الصورة لمجلد التطبيق (حتى تبقى موجودة)
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(picked.path);
    final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

    // احفظ المسار في SharedPreferences
    await _prefs.setString('profile_image', savedImage.path);

    setState(() {
      profileImage = savedImage;
    });
  }

  void _saveProfileData() {
    // هنا تقدر تحفظ الاسم والجنس وتاريخ الميلاد في SharedPreferences برضه
    print("✅ تم الحفظ:");
    print("الاسم: ${_nameController.text}");
    print("الجنس: $gender");
    print("تاريخ الميلاد: $birthDate");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ المعلومات (تجريبي فقط)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: ListView(
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
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
