import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'user_database.db');

    // هذا رقم النسخخه تحدثونه كل ماغيرتو في الجداول
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // ----------------------------------------------------------------------------

  // هنا تحطون كل الجداول
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        is_admin INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  //-------------------------------------------------------------

  // هنا الحذف والتعديل وباقي الاشياء
  // تسجيل مستخدم جديد
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;

      // التحقق من وجود الإيميل مسبقاً
      List<Map<String, dynamic>> existingUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existingUser.isNotEmpty) {
        return {'success': false, 'message': 'الإيميل موجود مسبقاً'};
      }

      // إدراج المستخدم الجديد
      int userId = await db.insert('users', {
        'username': username,
        'email': email,
        'password': password,
        'is_admin': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'تم إنشاء الحساب بنجاح',
        'user_id': userId,
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء إنشاء الحساب: $e'};
    }
  }

  // تسجيل الدخول
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;

      List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (result.isEmpty) {
        return {
          'success': false,
          'message': 'الإيميل أو كلمة المرور غير صحيحة',
        };
      }

      Map<String, dynamic> user = result.first;

      return {
        'success': true,
        'message': 'تم تسجيل الدخول بنجاح',
        'user': {
          'id': user['id'],
          'username': user['username'],
          'email': user['email'],
          'is_admin': user['is_admin'] == 1,
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء تسجيل الدخول: $e'};
    }
  }

  // تسجيل دخول المشرف
  Future<Map<String, dynamic>> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;

      List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'email = ? AND password = ? AND is_admin = 1',
        whereArgs: [email, password],
      );

      if (result.isEmpty) {
        return {'success': false, 'message': 'بيانات المشرف غير صحيحة'};
      }

      Map<String, dynamic> admin = result.first;

      return {
        'success': true,
        'message': 'مرحباً بك أيها المشرف',
        'admin': {
          'id': admin['id'],
          'username': admin['username'],
          'email': admin['email'],
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تسجيل دخول المشرف: $e',
      };
    }
  }

  // الحصول على جميع المستخدمين (للمشرف)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users', where: 'is_admin = 0');
  }

  // حذف مستخدم
  Future<bool> deleteUser(int userId) async {
    try {
      final db = await database;
      int result = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  // إغلاق قاعدة البيانات
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
