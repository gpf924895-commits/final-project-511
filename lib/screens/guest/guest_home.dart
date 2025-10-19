import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/provider/prayer_times_provider.dart';
import 'package:new_project/provider/location_provider.dart';
import 'package:new_project/screens/fiqh_section.dart';
import 'package:new_project/screens/seerah_section.dart';
import 'package:new_project/screens/tafsir_section.dart';
import 'package:new_project/screens/hadith_section.dart';
import 'dart:async';

class GuestHome extends StatefulWidget {
  final String? continueLabel;
  final VoidCallback? onContinue;

  const GuestHome({super.key, this.continueLabel, this.onContinue});

  @override
  State<GuestHome> createState() => _GuestHomeState();
}

class _GuestHomeState extends State<GuestHome> {
  Timer? _prayerTimer;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _startPrayerTimer();
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final prayerTimesProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
      
      if (locationProvider.currentPosition != null) {
        await prayerTimesProvider.calculatePrayerTimes(locationProvider.currentPosition);
      }
    } catch (e) {
      print('Error loading prayer times: $e');
    }
  }

  void _startPrayerTimer() {
    _prayerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update countdown
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4E5D3),
        appBar: AppBar(
          title: const Text('محاضرات'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          centerTitle: true,
          leading: const Icon(Icons.mosque, size: 28),
          actions: [
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              tooltip: 'تسجيل الدخول',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Four Category Buttons
              _buildCategoryGrid(),
              const SizedBox(height: 24),

              // Prayer Times Card
              _buildPrayerTimesCard(),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Guest Browse Button
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('أنت تتصفح حالياً كضيف'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('تصفح كضيف', style: TextStyle(fontSize: 16)),
                ),
              ),

              // Continue button (if provided)
              if (widget.continueLabel != null && widget.onContinue != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: widget.onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.continueLabel ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // Location Footer
              const Text(
                'المدينة المنورة – السعودية',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildCategoryButton(
          icon: Icons.gavel,
          title: 'الفقه',
          onTap: () => _navigateToSection(context, 'fiqh'),
        ),
        _buildCategoryButton(
          icon: Icons.history,
          title: 'السيرة',
          onTap: () => _navigateToSection(context, 'seerah'),
        ),
        _buildCategoryButton(
          icon: Icons.menu_book,
          title: 'التفسير',
          onTap: () => _navigateToSection(context, 'tafsir'),
        ),
        _buildCategoryButton(
          icon: Icons.chat_bubble,
          title: 'الحديث',
          onTap: () => _navigateToSection(context, 'hadith'),
        ),
      ],
    );
  }

  Widget _buildCategoryButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.green, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesCard() {
    return Consumer2<PrayerTimesProvider, LocationProvider>(
      builder: (context, prayerProvider, locationProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الصلاة القادمة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.green),
                    onPressed: _loadPrayerTimes,
                    tooltip: 'تحديث أوقات الصلاة',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (prayerProvider.isLoading || locationProvider.isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
              else if (prayerProvider.errorMessage != null)
                Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      prayerProvider.errorMessage ?? 'خطأ في تحميل أوقات الصلاة',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loadPrayerTimes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              else if (prayerProvider.prayerTimes != null)
                Column(
                  children: [
                    // Next prayer info
                    if (prayerProvider.nextPrayer.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${prayerProvider.getArabicPrayerName(prayerProvider.nextPrayer)} ${prayerProvider.getFormattedPrayerTime(prayerProvider.nextPrayer)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              prayerProvider.getTimeUntilNextPrayer(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Prayer times grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.5,
                      children: [
                        _buildPrayerTimeItem('الفجر', prayerProvider, 'fajr'),
                        _buildPrayerTimeItem('الشروق', prayerProvider, 'sunrise'),
                        _buildPrayerTimeItem('الظهر', prayerProvider, 'dhuhr'),
                        _buildPrayerTimeItem('العصر', prayerProvider, 'asr'),
                        _buildPrayerTimeItem('المغرب', prayerProvider, 'maghrib'),
                        _buildPrayerTimeItem('العشاء', prayerProvider, 'isha'),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const Icon(Icons.location_off, color: Colors.grey, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'غير متوفر - تحقق من الموقع',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loadPrayerTimes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('تحديث'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrayerTimeItem(String name, PrayerTimesProvider provider, String prayerKey) {
    final time = provider.getFormattedPrayerTime(prayerKey);
    final isNext = provider.nextPrayer == prayerKey;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isNext ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: isNext ? Border.all(color: Colors.green, width: 1) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: isNext ? Colors.green : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isNext ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSection(BuildContext context, String section) {
    switch (section) {
      case 'fiqh':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FiqhSectionPage(
              isDarkMode: false,
              toggleTheme: (isDark) {},
            ),
          ),
        );
        break;
      case 'seerah':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeerahSectionPage(
              isDarkMode: false,
              toggleTheme: (isDark) {},
            ),
          ),
        );
        break;
      case 'tafsir':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TafsirSectionPage(
              isDarkMode: false,
              toggleTheme: (isDark) {},
            ),
          ),
        );
        break;
      case 'hadith':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HadithSectionPage(
              isDarkMode: false,
              toggleTheme: (isDark) {},
            ),
          ),
        );
        break;
    }
  }
}

class GuestHomeWithSession extends StatelessWidget {
  final AuthProvider auth;
  final Function(String role) onContinue;

  const GuestHomeWithSession({
    super.key,
    required this.auth,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // Check if user has an existing session
    final hasSession = auth.isLoggedIn && auth.currentUser != null;
    final role = auth.role;
    final userName =
        auth.currentUser?['name'] ?? auth.currentUser?['username'] ?? '';

    return GuestHome(
      continueLabel: hasSession ? 'متابعة كـ $userName ($role)' : null,
      onContinue: hasSession ? () => onContinue(role ?? 'user') : null,
    );
  }
}
