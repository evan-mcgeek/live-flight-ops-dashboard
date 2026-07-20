// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aircraft_snapshot_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AircraftSnapshotDto _$AircraftSnapshotDtoFromJson(Map<String, dynamic> json) =>
    AircraftSnapshotDto(
      aircraft: (json['aircraft'] as List<dynamic>)
          .map((e) => AircraftDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      stale: json['stale'] as bool,
    );
