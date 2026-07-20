import 'package:json_annotation/json_annotation.dart';

import '../../../domain/entities/aircraft_snapshot.dart';
import 'aircraft_dto.dart';

part 'aircraft_snapshot_dto.g.dart';

@JsonSerializable(createToJson: false)
class AircraftSnapshotDto {
  AircraftSnapshotDto({required this.aircraft, required this.stale});

  factory AircraftSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$AircraftSnapshotDtoFromJson(json);

  final List<AircraftDto> aircraft;
  final bool stale;

  AircraftSnapshot toDomain() {
    return AircraftSnapshot(
      aircraft: aircraft.map((dto) => dto.toDomain()).toList(),
      stale: stale,
    );
  }
}
