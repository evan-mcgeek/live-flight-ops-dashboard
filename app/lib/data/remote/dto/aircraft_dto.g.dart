// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aircraft_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AircraftDto _$AircraftDtoFromJson(Map<String, dynamic> json) => AircraftDto(
  icao24: json['icao24'] as String,
  callsign: json['callsign'] as String?,
  originCountry: json['originCountry'] as String,
  longitude: (json['longitude'] as num?)?.toDouble(),
  latitude: (json['latitude'] as num?)?.toDouble(),
  altitude: (json['altitude'] as num?)?.toDouble(),
  velocity: (json['velocity'] as num?)?.toDouble(),
  heading: (json['heading'] as num?)?.toDouble(),
  onGround: json['onGround'] as bool,
  lastUpdate: json['lastUpdate'] as String,
);
