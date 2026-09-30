import 'package:geolocator/geolocator.dart';

class GeoResult {
  const GeoResult(this.lat, this.lng, this.isMocked);
  final double lat;
  final double lng;
  final bool isMocked;
}

/// Ambil lokasi saat ini + tangani izin. Lempar String pesan bila gagal.
Future<GeoResult> getCurrentLocation() async {
  final serviceOn = await Geolocator.isLocationServiceEnabled();
  if (!serviceOn) {
    throw 'Layanan lokasi (GPS) tidak aktif';
  }

  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    throw 'Izin lokasi ditolak';
  }

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
  return GeoResult(pos.latitude, pos.longitude, pos.isMocked);
}

/// Pantau lokasi secara live (update tiap pergerakan ~3 m).
Stream<GeoResult> watchLocation() {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    ),
  ).map((p) => GeoResult(p.latitude, p.longitude, p.isMocked));
}

/// Jarak (meter) antara dua koordinat.
double distanceMeters(double lat1, double lng1, double lat2, double lng2) =>
    Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
