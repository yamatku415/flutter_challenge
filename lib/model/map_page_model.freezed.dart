// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_page_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MapPageModel {
  LatLng get currentPosition => throw _privateConstructorUsedError;
  List<ChargerSpot> get spots => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MapPageModelCopyWith<MapPageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapPageModelCopyWith<$Res> {
  factory $MapPageModelCopyWith(
          MapPageModel value, $Res Function(MapPageModel) then) =
      _$MapPageModelCopyWithImpl<$Res, MapPageModel>;
  @useResult
  $Res call({LatLng currentPosition, List<ChargerSpot> spots});
}

/// @nodoc
class _$MapPageModelCopyWithImpl<$Res, $Val extends MapPageModel>
    implements $MapPageModelCopyWith<$Res> {
  _$MapPageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentPosition = null,
    Object? spots = null,
  }) {
    return _then(_value.copyWith(
      currentPosition: null == currentPosition
          ? _value.currentPosition
          : currentPosition // ignore: cast_nullable_to_non_nullable
              as LatLng,
      spots: null == spots
          ? _value.spots
          : spots // ignore: cast_nullable_to_non_nullable
              as List<ChargerSpot>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MapPageModelImplCopyWith<$Res>
    implements $MapPageModelCopyWith<$Res> {
  factory _$$MapPageModelImplCopyWith(
          _$MapPageModelImpl value, $Res Function(_$MapPageModelImpl) then) =
      __$$MapPageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({LatLng currentPosition, List<ChargerSpot> spots});
}

/// @nodoc
class __$$MapPageModelImplCopyWithImpl<$Res>
    extends _$MapPageModelCopyWithImpl<$Res, _$MapPageModelImpl>
    implements _$$MapPageModelImplCopyWith<$Res> {
  __$$MapPageModelImplCopyWithImpl(
      _$MapPageModelImpl _value, $Res Function(_$MapPageModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentPosition = null,
    Object? spots = null,
  }) {
    return _then(_$MapPageModelImpl(
      currentPosition: null == currentPosition
          ? _value.currentPosition
          : currentPosition // ignore: cast_nullable_to_non_nullable
              as LatLng,
      spots: null == spots
          ? _value._spots
          : spots // ignore: cast_nullable_to_non_nullable
              as List<ChargerSpot>,
    ));
  }
}

/// @nodoc

class _$MapPageModelImpl implements _MapPageModel {
  const _$MapPageModelImpl(
      {this.currentPosition = const LatLng(35.681236, 139.767125),
      final List<ChargerSpot> spots = const []})
      : _spots = spots;

  @override
  @JsonKey()
  final LatLng currentPosition;
  final List<ChargerSpot> _spots;
  @override
  @JsonKey()
  List<ChargerSpot> get spots {
    if (_spots is EqualUnmodifiableListView) return _spots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_spots);
  }

  @override
  String toString() {
    return 'MapPageModel(currentPosition: $currentPosition, spots: $spots)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapPageModelImpl &&
            (identical(other.currentPosition, currentPosition) ||
                other.currentPosition == currentPosition) &&
            const DeepCollectionEquality().equals(other._spots, _spots));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentPosition,
      const DeepCollectionEquality().hash(_spots));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MapPageModelImplCopyWith<_$MapPageModelImpl> get copyWith =>
      __$$MapPageModelImplCopyWithImpl<_$MapPageModelImpl>(this, _$identity);
}

abstract class _MapPageModel implements MapPageModel {
  const factory _MapPageModel(
      {final LatLng currentPosition,
      final List<ChargerSpot> spots}) = _$MapPageModelImpl;

  @override
  LatLng get currentPosition;
  @override
  List<ChargerSpot> get spots;
  @override
  @JsonKey(ignore: true)
  _$$MapPageModelImplCopyWith<_$MapPageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
