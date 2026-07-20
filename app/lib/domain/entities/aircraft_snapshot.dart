import 'package:equatable/equatable.dart';

import 'aircraft.dart';

class AircraftSnapshot extends Equatable {
  const AircraftSnapshot({required this.aircraft, required this.stale});

  final List<Aircraft> aircraft;
  final bool stale;

  @override
  List<Object?> get props => [aircraft, stale];
}
