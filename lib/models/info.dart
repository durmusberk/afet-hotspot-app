class Info {
  final int batteryLevel;
  final double longitude;
  final double latitude;
  final String clientAddress;
  final int rssi;
  final double distance;

  Info({
    required this.batteryLevel,
    required this.longitude,
    required this.latitude,
    required this.clientAddress,
    required this.rssi,
    required this.distance,
  });
}
