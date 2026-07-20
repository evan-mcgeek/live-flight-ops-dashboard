part of 'active_region_bloc.dart';

sealed class ActiveRegionEvent extends Equatable {
  const ActiveRegionEvent();

  @override
  List<Object?> get props => [];
}

class UpdateRegionRequested extends ActiveRegionEvent {
  const UpdateRegionRequested(this.bbox);

  final BoundingBox bbox;

  @override
  List<Object?> get props => [bbox];
}
