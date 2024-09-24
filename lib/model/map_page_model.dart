import 'package:flutter_map_app/model/charger_spot.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'map_page_model.freezed.dart';

@freezed
class MapPageModel with _$MapPageModel {
  const factory MapPageModel({
    @Default(LatLng(35.681236, 139.767125)) LatLng currentPosition,
    @Default([]) List<ChargerSpot> spots,
  }) = _MapPageModel;
}
