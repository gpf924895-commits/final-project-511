import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_drawer.dart';

class MosqueMapPage extends StatefulWidget {
  final Function(bool)? toggleTheme;
  
  const MosqueMapPage({Key? key, this.toggleTheme}) : super(key: key);

  @override
  State<MosqueMapPage> createState() => _MosqueMapPageState();
}

class _MosqueMapPageState extends State<MosqueMapPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String _locationName = '';
  
  // Prophet's Mosque coordinates (Al-Masjid An-Nabawi)
  static const LatLng _mosqueLocation = LatLng(24.4681, 39.6142);
  
  // Important locations within the mosque
  final List<Map<String, dynamic>> _mosqueLocations = [
    {
      'name': 'الروضة الشريفة',
      'description': 'الروضة المباركة بين القبر والمنبر',
      'position': LatLng(24.4681, 39.6142),
      'type': 'sacred',
    },
    {
      'name': 'قبر النبي صلى الله عليه وسلم',
      'description': 'قبر النبي محمد صلى الله عليه وسلم',
      'position': LatLng(24.4680, 39.6140),
      'type': 'sacred',
    },
    {
      'name': 'قبر أبو بكر الصديق',
      'description': 'قبر الخليفة الأول أبو بكر الصديق رضي الله عنه',
      'position': LatLng(24.4680, 39.6141),
      'type': 'sacred',
    },
    {
      'name': 'قبر عمر بن الخطاب',
      'description': 'قبر الخليفة الثاني عمر بن الخطاب رضي الله عنه',
      'position': LatLng(24.4680, 39.6143),
      'type': 'sacred',
    },
    {
      'name': 'الباب الرئيسي',
      'description': 'الباب الرئيسي للمسجد النبوي',
      'position': LatLng(24.4685, 39.6145),
      'type': 'entrance',
    },
    {
      'name': 'باب الملك فهد',
      'description': 'باب الملك فهد بن عبد العزيز',
      'position': LatLng(24.4675, 39.6140),
      'type': 'entrance',
    },
    {
      'name': 'باب السلام',
      'description': 'باب السلام',
      'position': LatLng(24.4680, 39.6145),
      'type': 'entrance',
    },
    {
      'name': 'المكتبة',
      'description': 'مكتبة المسجد النبوي',
      'position': LatLng(24.4682, 39.6143),
      'type': 'facility',
    },
    {
      'name': 'المستشفى',
      'description': 'مستشفى المسجد النبوي',
      'position': LatLng(24.4678, 39.6141),
      'type': 'facility',
    },
  ];

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    _createMarkers();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Get location name
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          setState(() {
            _locationName = placemarks.first.locality ?? 'الموقع الحالي';
          });
        }
      } catch (e) {
        print('Error getting location name: $e');
      }
    } catch (e) {
      print('Error getting location: $e');
      _showLocationError();
    }
  }

  void _createMarkers() {
    _markers.clear();
    
    // Add current location marker
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'موقعك الحالي',
            snippet: _locationName.isNotEmpty ? _locationName : 'الموقع الحالي',
          ),
        ),
      );
    }

    // Add mosque location markers
    for (var location in _mosqueLocations) {
      Color markerColor;
      switch (location['type']) {
        case 'sacred':
          markerColor = Colors.red;
          break;
        case 'entrance':
          markerColor = Colors.green;
          break;
        case 'facility':
          markerColor = Colors.blue;
          break;
        default:
          markerColor = Colors.orange;
      }

      _markers.add(
        Marker(
          markerId: MarkerId(location['name']),
          position: location['position'],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            markerColor == Colors.red ? BitmapDescriptor.hueRed :
            markerColor == Colors.green ? BitmapDescriptor.hueGreen :
            markerColor == Colors.blue ? BitmapDescriptor.hueBlue :
            BitmapDescriptor.hueOrange
          ),
          infoWindow: InfoWindow(
            title: location['name'],
            snippet: location['description'],
          ),
          onTap: () => _showLocationDetails(location),
        ),
      );
    }
  }

  void _showLocationDetails(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(location['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(location['description']),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _navigateToLocation(location['position']),
                    icon: const Icon(Icons.navigation),
                    label: const Text('التنقل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _getDirections(location['position']),
                    icon: const Icon(Icons.directions),
                    label: const Text('الاتجاهات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLocation(LatLng destination) {
    if (_currentPosition != null) {
      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('navigation_route'),
            points: [
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              destination,
            ],
            color: Colors.blue,
            width: 5,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _currentPosition!.latitude < destination.latitude
                  ? _currentPosition!.latitude
                  : destination.latitude,
              _currentPosition!.longitude < destination.longitude
                  ? _currentPosition!.longitude
                  : destination.longitude,
            ),
            northeast: LatLng(
              _currentPosition!.latitude > destination.latitude
                  ? _currentPosition!.latitude
                  : destination.latitude,
              _currentPosition!.longitude > destination.longitude
                  ? _currentPosition!.longitude
                  : destination.longitude,
            ),
          ),
          100.0,
        ),
      );
    }
  }

  void _getDirections(LatLng destination) async {
    String url = '';
    if (_currentPosition != null) {
      url = 'https://www.google.com/maps/dir/${_currentPosition!.latitude},${_currentPosition!.longitude}/${destination.latitude},${destination.longitude}';
    } else {
      url = 'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';
    }
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorDialog('لا يمكن فتح تطبيق الخرائط');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إذن الموقع'),
          content: const Text(
            'يحتاج التطبيق إلى إذن الموقع لعرض موقعك الحالي على الخريطة. يرجى السماح بالوصول إلى الموقع في إعدادات التطبيق.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('فتح الإعدادات'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لا يمكن الحصول على الموقع الحالي'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('خطأ'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.toggleTheme != null ? AppDrawer(toggleTheme: widget.toggleTheme!) : null,
      appBar: AppBar(
        title: const Text('خريطة المسجد النبوي'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'تحديث الموقع',
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_mosqueLocation, 16.0),
              );
            },
            tooltip: 'التركيز على المسجد',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _getDirections(_mosqueLocation),
            tooltip: 'فتح في خرائط Google',
          ),
          if (widget.toggleTheme != null)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'القائمة',
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل الخريطة...'),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _mosqueLocation,
                    zoom: 16.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  compassEnabled: true,
                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                ),
                // Legend
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'دليل الأماكن',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem('الأماكن المقدسة', Colors.red),
                        _buildLegendItem('المداخل', Colors.green),
                        _buildLegendItem('المرافق', Colors.blue),
                        _buildLegendItem('موقعك', Colors.blue),
                      ],
                    ),
                  ),
                ),
                // Navigation info
                if (_currentPosition != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationName.isNotEmpty ? _locationName : 'الموقع الحالي',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _getDirections(_mosqueLocation),
                            child: const Text('الاتجاهات'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
