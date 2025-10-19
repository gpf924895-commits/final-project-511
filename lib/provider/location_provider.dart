import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String _locationName = '';
  bool _isLoading = false;
  String? _errorMessage;

  Position? get currentPosition => _currentPosition;
  String get locationName => _locationName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'تم رفض إذن الموقع';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage =
            'تم رفض إذن الموقع نهائياً. يرجى السماح بالوصول من الإعدادات';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage = 'خطأ في طلب إذن الموقع: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'خدمات الموقع غير مفعلة. يرجى تفعيلها من الإعدادات';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Request permission
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;

      // Get location name
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          _locationName = _formatLocationName(place);
        } else {
          _locationName = 'الموقع الحالي';
        }
      } catch (e) {
        _locationName = 'الموقع الحالي';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'خطأ في الحصول على الموقع: $e';
      notifyListeners();
    }
  }

  String _formatLocationName(Placemark place) {
    List<String> parts = [];

    if (place.locality?.isNotEmpty == true) {
      parts.add(place.locality ?? '');
    }
    if (place.administrativeArea?.isNotEmpty == true) {
      parts.add(place.administrativeArea ?? '');
    }
    if (place.country?.isNotEmpty == true) {
      parts.add(place.country ?? '');
    }

    return parts.isNotEmpty ? parts.join(', ') : 'الموقع الحالي';
  }

  Future<double> calculateDistance(double lat, double lng) async {
    if (_currentPosition == null) return 0.0;

    return Geolocator.distanceBetween(
      _currentPosition?.latitude ?? 0.0,
      _currentPosition?.longitude ?? 0.0,
      lat,
      lng,
    );
  }

  Future<String> getDistanceString(double lat, double lng) async {
    double distance = await calculateDistance(lat, lng);

    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} متر';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} كم';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _currentPosition = null;
    _locationName = '';
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
