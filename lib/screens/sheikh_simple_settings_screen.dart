import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/pro_login.dart';
import '../provider/sheikh_provider.dart';

class SheikhSimpleSettingsScreen extends StatelessWidget {
  const SheikhSimpleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SheikhProvider>(
      builder: (context, authProvider, sheikhProvider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('الإعدادات'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'معلومات الشيخ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (sheikhProvider.sheikhData != null) ...[
                              Text(
                                'الاسم: ${sheikhProvider.sheikhData?['name'] ?? 'غير محدد'}',
                              ),
                              Text(
                                'البريد: ${sheikhProvider.sheikhData?['email'] ?? 'غير محدد'}',
                              ),
                              Text(
                                'معرف الشيخ: ${sheikhProvider.sheikhData?['sheikhId'] ?? 'غير محدد'}',
                              ),
                            ] else ...[
                              const Text('جاري تحميل البيانات...'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Settings options
                    const Text(
                      'خيارات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('تسجيل الخروج'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Directionality(
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              title: const Text('تأكيد تسجيل الخروج'),
                              content: const Text(
                                'هل أنت متأكد من تسجيل الخروج؟',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await authProvider.signOut();
                                    if (context.mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/guest',
                                        (route) => false,
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('تسجيل الخروج'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
