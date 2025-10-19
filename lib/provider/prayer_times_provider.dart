import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

class PrayerTimesProvider extends ChangeNotifier {
  PrayerTimes? _prayerTimes;
  String _nextPrayer = '';
  bool _isLoading = false;
  String? _errorMessage;

  PrayerTimes? get prayerTimes => _prayerTimes;
  String get nextPrayer => _nextPrayer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // أسماء الصلوات بالعربية
  final Map<String, String> _prayerNamesArabic = {
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  // الحصول على أوقات الصلاة بناءً على الموقع
  Future<void> calculatePrayerTimes(Position? position) async {
    if (position == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // إعداد الإحداثيات
      final coordinates = Coordinates(position.latitude, position.longitude);

      // إعداد معاملات الحساب (استخدام طريقة أم القرى المستخدمة في السعودية)
      final params = CalculationMethod.umm_al_qura.getParameters();
      params.madhab = Madhab.shafi; // المذهب الشافعي

      // حساب أوقات الصلاة
      final prayerTimes = PrayerTimes.today(coordinates, params);

      _prayerTimes = prayerTimes;
      _determineNextPrayer();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'خطأ في حساب أوقات الصلاة: $e';
      notifyListeners();
    }
  }

  // تحديد الصلاة القادمة
  void _determineNextPrayer() {
    if (_prayerTimes == null) return;

    final now = DateTime.now();

    if (now.isBefore(_prayerTimes?.fajr ?? DateTime.now())) {
      _nextPrayer = 'fajr';
    } else if (now.isBefore(_prayerTimes?.sunrise ?? DateTime.now())) {
      _nextPrayer = 'sunrise';
    } else if (now.isBefore(_prayerTimes?.dhuhr ?? DateTime.now())) {
      _nextPrayer = 'dhuhr';
    } else if (now.isBefore(_prayerTimes?.asr ?? DateTime.now())) {
      _nextPrayer = 'asr';
    } else if (now.isBefore(_prayerTimes?.maghrib ?? DateTime.now())) {
      _nextPrayer = 'maghrib';
    } else if (now.isBefore(_prayerTimes?.isha ?? DateTime.now())) {
      _nextPrayer = 'isha';
    } else {
      // إذا كان الوقت بعد العشاء، الصلاة القادمة هي فجر الغد
      _nextPrayer = 'fajr';
    }
  }

  // الحصول على وقت الصلاة منسق
  String getFormattedPrayerTime(String prayer) {
    if (_prayerTimes == null) return '--:--';

    DateTime? time;
    switch (prayer) {
      case 'fajr':
        time = _prayerTimes!.fajr;
        break;
      case 'sunrise':
        time = _prayerTimes!.sunrise;
        break;
      case 'dhuhr':
        time = _prayerTimes!.dhuhr;
        break;
      case 'asr':
        time = _prayerTimes!.asr;
        break;
      case 'maghrib':
        time = _prayerTimes!.maghrib;
        break;
      case 'isha':
        time = _prayerTimes!.isha;
        break;
      default:
        return '--:--';
    }

    // استخدام تنسيق بسيط بدون اللغة العربية لتجنب مشاكل التهيئة
    return DateFormat('h:mm a').format(time);
  }

  // الحصول على الاسم العربي للصلاة
  String getArabicPrayerName(String prayer) {
    return _prayerNamesArabic[prayer] ?? '';
  }

  // التحقق من كون الصلاة هي القادمة
  bool isNextPrayer(String prayer) {
    return _nextPrayer == prayer;
  }

  // الحصول على الوقت المتبقي للصلاة القادمة
  String getTimeUntilNextPrayer() {
    if (_prayerTimes == null || _nextPrayer.isEmpty) return '';

    DateTime? nextPrayerTime;
    switch (_nextPrayer) {
      case 'fajr':
        nextPrayerTime = _prayerTimes!.fajr;
        // إذا كان فجر اليوم التالي
        if (nextPrayerTime.isBefore(DateTime.now())) {
          nextPrayerTime = nextPrayerTime.add(const Duration(days: 1));
        }
        break;
      case 'sunrise':
        nextPrayerTime = _prayerTimes!.sunrise;
        break;
      case 'dhuhr':
        nextPrayerTime = _prayerTimes!.dhuhr;
        break;
      case 'asr':
        nextPrayerTime = _prayerTimes!.asr;
        break;
      case 'maghrib':
        nextPrayerTime = _prayerTimes!.maghrib;
        break;
      case 'isha':
        nextPrayerTime = _prayerTimes!.isha;
        break;
    }

    if (nextPrayerTime == null) return '';

    final duration = nextPrayerTime.difference(DateTime.now());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return 'خلال $hours ساعة و $minutes دقيقة';
    } else if (minutes > 0) {
      return 'خلال $minutes دقيقة';
    } else {
      return 'الآن';
    }
  }

  // تحديث أوقات الصلاة
  Future<void> refreshPrayerTimes(Position? position) async {
    await calculatePrayerTimes(position);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _prayerTimes = null;
    _nextPrayer = '';
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
