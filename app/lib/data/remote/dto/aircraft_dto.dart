import 'package:json_annotation/json_annotation.dart';

import '../../../domain/entities/aircraft.dart';

part 'aircraft_dto.g.dart';

@JsonSerializable(createToJson: false)
class AircraftDto {
  AircraftDto({
    required this.icao24,
    this.callsign,
    required this.originCountry,
    this.longitude,
    this.latitude,
    this.altitude,
    this.velocity,
    this.heading,
    required this.onGround,
    required this.lastUpdate,
  });

  factory AircraftDto.fromJson(Map<String, dynamic> json) =>
      _$AircraftDtoFromJson(json);

  final String icao24;
  final String? callsign;
  final String originCountry;
  final double? longitude;
  final double? latitude;
  final double? altitude;
  final double? velocity;
  final double? heading;
  final bool onGround;
  final String lastUpdate;

  Aircraft toDomain() {
    return Aircraft(
      icao24: icao24,
      callsign: callsign,
      originCountry: originCountry,
      longitude: longitude,
      latitude: latitude,
      altitude: altitude,
      velocity: velocity,
      heading: heading,
      onGround: onGround,
      lastUpdate: DateTime.parse(lastUpdate),
    );
  }
}
