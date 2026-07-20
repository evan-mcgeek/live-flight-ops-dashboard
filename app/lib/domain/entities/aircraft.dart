import 'package:equatable/equatable.dart';

class Aircraft extends Equatable {
  const Aircraft({
    required this.icao24,
    required this.callsign,
    required this.originCountry,
    required this.longitude,
    required this.latitude,
    required this.altitude,
    required this.velocity,
    required this.heading,
    required this.onGround,
    required this.lastUpdate,
  });

  final String icao24;
  final String? callsign;
  final String originCountry;
  final double? longitude;
  final double? latitude;
  final double? altitude;
  final double? velocity;
  final double? heading;
  final bool onGround;
  final DateTime lastUpdate;

  @override
  List<Object?> get props => [
    icao24,
    callsign,
    originCountry,
    longitude,
    latitude,
    altitude,
    velocity,
    heading,
    onGround,
    lastUpdate,
  ];
}
