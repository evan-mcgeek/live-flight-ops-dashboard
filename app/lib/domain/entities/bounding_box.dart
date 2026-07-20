import 'package:equatable/equatable.dart';

class BoundingBox extends Equatable {
  const BoundingBox({
    required this.laMin,
    required this.loMin,
    required this.laMax,
    required this.loMax,
  });

  final double laMin;
  final double loMin;
  final double laMax;
  final double loMax;

  @override
  List<Object?> get props => [laMin, loMin, laMax, loMax];
}
