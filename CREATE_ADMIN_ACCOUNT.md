# إنشاء حساب مشرف - Create Admin Account

## نظرة عامة / Overview

لاختبار ميزات إدارة المحاضرات، تحتاج إلى حساب مشرف (Admin). يمكنك إنشاء حساب مشرف بطريقتين:

To test the lecture management features, you need an admin account. You can create an admin account in two ways:

---

## الطريقة 1: باستخدام كود مؤقت / Method 1: Using Temporary Code

### إضافة كود إنشاء مشرف في `main.dart`

أضف هذا الكود في دالة `main()` في ملف `lib/main.dart`:

```dart
import 'package:new_project/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // إنشاء حساب مشرف للاختبار (احذف هذا الكود بعد إنشاء الحساب)
  await _createTestAdmin();
  
  runApp(const MyApp());
}

// دالة إنشاء مشرف للاختبار
Future<void> _createTestAdmin() async {
  final db = DatabaseHelper();
  
  final result = await db.createAdminAccount(
    username: 'admin',
    email: 'admin@mosque.com',
    password: 'admin123',
  );
  
  print('Admin Creation Result: ${result['message']}');
}
```

### الخطوات:

1. أضف الكود أعلاه في `lib/main.dart`
2. قم بتشغيل التطبيق
3. سيتم إنشاء حساب المشرف تلقائياً
4. **مهم:** احذف دالة `_createTestAdmin()` بعد إنشاء الحساب

### بيانات تسجيل الدخول:
```
اسم المستخدم / Username: admin
البريد الإلكتروني / Email: admin@mosque.com
كلمة المرور / Password: admin123
```

---

## الطريقة 2: باستخدام صفحة اختبار / Method 2: Using Test Page

### إنشاء صفحة تسجيل مشرف

قم بإنشاء ملف جديد `lib/screens/create_admin_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:new_project/database/app_database.dart';

class CreateAdminPage extends StatefulWidget {
  const CreateAdminPage({super.key});

  @override
  State<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdminPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createAdmin() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تعبئة جميع الحقول'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _databaseHelper.createAdminAccount(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );

    if (result['success']) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب مشرف'),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFE4E5D3),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'إنشاء حساب مشرف جديد',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _createAdmin,
                    icon: const Icon(Icons.add_moderator),
                    label: const Text(
                      'إنشاء حساب المشرف',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'تحذير أمني',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• استخدم كلمة مرور قوية\n'
                          '• لا تشارك بيانات المشرف مع أحد\n'
                          '• احذف هذه الصفحة من الإنتاج النهائي\n'
                          '• هذه الصفحة للاختبار فقط',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

### إضافة زر للوصول إلى صفحة إنشاء المشرف

في `lib/main.dart` أو صفحة تسجيل الدخول، أضف زراً مخفياً:

```dart
// في صفحة تسجيل الدخول
GestureDetector(
  onLongPress: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateAdminPage(),
      ),
    );
  },
  child: const Text(
    'للمطورين فقط',
    style: TextStyle(fontSize: 10, color: Colors.grey),
  ),
)
```

---

## الطريقة 3: باستخدام أدوات قاعدة البيانات / Method 3: Using Database Tools

إذا كنت تستخدم أداة لإدارة قواعد بيانات SQLite:

### الخطوات:

1. افتح ملف قاعدة البيانات: `user_database.db`
2. قم بتنفيذ هذا الأمر SQL:

```sql
INSERT INTO users (username, email, password, is_admin, created_at)
VALUES ('admin', 'admin@mosque.com', 'admin123', 1, datetime('now'));
```

3. احفظ التغييرات

---

## التحقق من إنشاء الحساب / Verify Account Creation

### الطريقة 1: تسجيل الدخول

1. افتح صفحة تسجيل دخول المشرف
2. أدخل البيانات:
   - اسم المستخدم أو البريد: `admin` أو `admin@mosque.com`
   - كلمة المرور: `admin123`
3. إذا نجح تسجيل الدخول، تم إنشاء الحساب بنجاح ✓

### الطريقة 2: التحقق من قاعدة البيانات

أضف هذا الكود المؤقت:

```dart
Future<void> _checkAdmins() async {
  final db = DatabaseHelper();
  final database = await db.database;
  
  final admins = await database.query(
    'users',
    where: 'is_admin = 1',
  );
  
  print('عدد المشرفين: ${admins.length}');
  for (var admin in admins) {
    print('مشرف: ${admin['username']} - ${admin['email']}');
  }
}
```

---

## حسابات مشرفين متعددة / Multiple Admin Accounts

يمكنك إنشاء أكثر من حساب مشرف:

```dart
// مشرف رئيسي
await db.createAdminAccount(
  username: 'super_admin',
  email: 'super@mosque.com',
  password: 'superadmin123',
);

// مشرف المحاضرات
await db.createAdminAccount(
  username: 'lecture_admin',
  email: 'lectures@mosque.com',
  password: 'lectures123',
);

// مشرف المستخدمين
await db.createAdminAccount(
  username: 'user_admin',
  email: 'users@mosque.com',
  password: 'users123',
);
```

---

## الأمان / Security

### ملاحظات هامة:

1. **في الإنتاج:** استخدم تشفير لكلمات المرور
   ```dart
   import 'package:crypto/crypto.dart';
   import 'dart:convert';
   
   String hashPassword(String password) {
     return sha256.convert(utf8.encode(password)).toString();
   }
   ```

2. **احذف كود الاختبار:** بعد إنشاء الحسابات
   - احذف دالة `_createTestAdmin()`
   - احذف صفحة `CreateAdminPage`
   - احذف أي أزرار مخفية للوصول إليها

3. **استخدم كلمات مرور قوية:**
   - على الأقل 8 أحرف
   - مزيج من الأحرف والأرقام والرموز
   - غير سهلة التخمين

4. **حماية بيانات المشرف:**
   - لا تحفظ بيانات المشرف في ملفات نصية
   - لا تشارك بيانات الدخول
   - غيّر كلمة المرور بانتظام

---

## استكشاف الأخطاء / Troubleshooting

### "المستخدم أو الإيميل موجود مسبقاً"

الحل:
- استخدم اسم مستخدم وبريد إلكتروني مختلفين
- أو احذف الحساب القديم من قاعدة البيانات

### "بيانات المشرف غير صحيحة"

الأسباب المحتملة:
1. اسم المستخدم أو كلمة المرور خاطئة
2. الحساب ليس حساب مشرف (is_admin = 0)
3. الحساب غير موجود في قاعدة البيانات

الحل:
- تحقق من البيانات المدخلة
- تأكد من إنشاء الحساب بنجاح
- تحقق من قاعدة البيانات مباشرة

### خطأ في قاعدة البيانات

الحل:
1. تأكد من تشغيل `flutter pub get`
2. أعد تشغيل التطبيق
3. إذا استمرت المشكلة، احذف قاعدة البيانات وأعد إنشاءها

---

## مثال كامل / Complete Example

```dart
// في lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/database/app_database.dart';
import 'package:new_project/provider/pro_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // إنشاء حساب مشرف للاختبار (استخدم هذا مرة واحدة فقط)
  await _createInitialAdmin();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _createInitialAdmin() async {
  try {
    final db = DatabaseHelper();
    
    // التحقق من وجود مشرفين
    final database = await db.database;
    final admins = await database.query('users', where: 'is_admin = 1');
    
    if (admins.isEmpty) {
      // إنشاء مشرف إذا لم يكن موجوداً
      final result = await db.createAdminAccount(
        username: 'admin',
        email: 'admin@mosque.com',
        password: 'admin123',
      );
      
      debugPrint('✅ Admin Account: ${result['message']}');
    } else {
      debugPrint('✅ Admin account already exists');
    }
  } catch (e) {
    debugPrint('❌ Error creating admin: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mosque App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
```

---

## ملاحظات نهائية / Final Notes

1. **للاختبار فقط:** هذه الطرق مناسبة للتطوير والاختبار فقط
2. **احذف الكود:** احذف كود إنشاء المشرف بعد الاستخدام
3. **الأمان:** في الإنتاج، استخدم نظام أمان أقوى
4. **النسخ الاحتياطي:** احتفظ بنسخة احتياطية من بيانات المشرف

---

**تاريخ الإنشاء:** 2025-10-11  
**الإصدار:** 1.0.0

