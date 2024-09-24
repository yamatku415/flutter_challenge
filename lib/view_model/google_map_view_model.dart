import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_app/model/charger_spot.dart';
import 'package:flutter_map_app/repository/charger_spots_repository.dart';
import 'package:flutter_map_app/model/map_page_model.dart';
import 'package:flutter_map_app/view/google_map_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:widget_to_marker/widget_to_marker.dart';

final googleMapAsyncNotifierProvider =
    AsyncNotifierProvider<GoogleMapAsyncNotifier, MapPageModel>(
        GoogleMapAsyncNotifier.new);

class GoogleMapAsyncNotifier extends AsyncNotifier<MapPageModel> {
  ChargerSpotsRepository chargerSpotsRepository = ChargerSpotsRepository();
  Map<String, ChargerSpot> plist = {};

  @override
  FutureOr<MapPageModel> build() async {
    return await determinePosition();
  }

  ///
  ///現在位置取得のパーミッション
  ///
  Future<MapPageModel> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 位置情報サービスが有効でない場合
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        //todo　エラーが出た場合のダイアログを実装する。　拒否された場合に設定画面まで飛ぶような
        // 拒否された場合エラーを返す
        return Future.error('Location permissions are denied');
      }
    }
    // 永久に拒否されている場合のエラーを返す
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    // デバイスの位置情報を返す。
    final currentPosition = await Geolocator.getCurrentPosition();
    return MapPageModel(
      currentPosition:
          LatLng(currentPosition.latitude, currentPosition.longitude),
      spots: [],
    );
  }

  ///
  ///Map画面が移動された後のMapPageModelを返す
  ///
  Future<MapPageModel> getVisibleRegion(
      MapPageModel mapPageModel, GoogleMapController? mapController) async {
    if (mapController != null) {
      LatLngBounds bounds = await mapController.getVisibleRegion();
      LatLng sw = bounds.southwest;
      LatLng ne = bounds.northeast;

      var screenLatLng = await chargerSpotsRepository.getChargerSpots(
          swLat: sw.latitude,
          swLng: sw.longitude,
          neLat: ne.latitude,
          neLng: ne.longitude);

      for (ChargerSpot spot in screenLatLng.spots) {
        plist.addAll({spot.uuid: spot});
      }

      state = await AsyncValue.guard(() async {
        return MapPageModel(
          currentPosition: mapPageModel.currentPosition,
          spots: plist.values.toList(),
        );
      });
    }
    return MapPageModel(
      currentPosition: mapPageModel.currentPosition,
      spots: plist.values.toList(),
    );
  }

  ///
  /// markerを追加する
  ///
  Future<Set<Marker>> addMarkersFromList(
      {required MapPageModel model,
      required GoogleMapController mapController,
      required PageController pageController,
      required ValueNotifier<bool> markerLoading,
      required ValueNotifier<bool> moreInformation,
      required WidgetRef ref,
      required Size size,
      int? prevSpotsLen = 0,
      int? nextSpotsLen = 0}) async {
    Set<Marker> markers = {};
    if (prevSpotsLen != nextSpotsLen) {
      markerLoading.value = true;
    }
    for (var spot in model.spots) {
      final BitmapDescriptor icon =
          await CountWidget(count: spot.chargerDevices.length)
              .toBitmapDescriptor(
                  logicalSize: const Size(100, 100),
                  imageSize: const Size(300, 300));

      markers.add(Marker(
        markerId: MarkerId(spot.uuid),
        position: LatLng(spot.latitude, spot.longitude),
        onTap: () {
          // タップしたマーカーのindexを取得
          final index = model.spots.indexWhere((v) => v == spot);
          // タップしたお店がPageViewで表示されるように飛ばす
          CardArea(
            mapPageModel: model,
            mapController: mapController,
            pageController: pageController,
            size: size,
            moreInformation: moreInformation,
          ).jumpToPage(index);
          moreInformation.value = true;
        },
        icon: icon,
      ));
    }
    markerLoading.value = false;
    return markers;
  }

  ///
  /// 営業時間を返す
  ///
  String getServiceTime(List<ServiceTime> serviceTimes) {
    DateTime now = DateTime.now();
    String currentDay = DateFormat('EEEE').format(now).toLowerCase();

    // 現在の曜日に該当する営業時間を取得
    for (var service in serviceTimes) {
      if (service.day.name == currentDay) {
        String? startTime = service.startTime;
        String? endTime = service.endTime;

        if (startTime != null && endTime != null) {
          return "$startTime - $endTime";
        } else {
          return "No service today";
        }
      }
    }
    return "Service time not found";
  }

  ///
  /// 営業時間内かを返す
  ///
  bool checkServiceTime(List<ServiceTime> serviceTimes) {
    DateTime now = DateTime.now();
    String currentDay = DateFormat('EEEE').format(now).toLowerCase();
    String currentTime = DateFormat('HH:mm').format(now);

    // service_times内の現在の曜日を見つける
    for (var service in serviceTimes) {
      if (service.day.name == currentDay && service.businessDay == true) {
        String? startTime = service.startTime;
        String? endTime = service.endTime;

        if (startTime != null && endTime != null) {
          // 現在の時間がstart_timeとend_timeの範囲内かどうかを確認
          if (currentTime.compareTo(startTime) >= 0 &&
              currentTime.compareTo(endTime) <= 0) {
            return true;
          }
        }
      }
    }
    return false;
  }

  ///
  /// 定休日を返す
  ///
  String convertDayToJapanese(String dayInEnglish) {
    Map<String, String> dayMap = {
      "sunday": "日曜日",
      "monday": "月曜日",
      "tuesday": "火曜日",
      "wednesday": "水曜日",
      "thursday": "木曜日",
      "friday": "金曜日",
      "saturday": "土曜日",
      "holiday": "祝日"
    };
    return dayMap[dayInEnglish] ?? dayInEnglish;
  }

  ///
  /// 画像データを表示できるかを返す
  ///
  Future<bool> checkImageUrl(String? imagePath) async {
    if (imagePath != null) {
      try {
        final response = await http.get(Uri.parse(imagePath));
        if (response.statusCode == 200) {
          return true;
        } else {
          return false;
        }
      } catch (e) {
        return false;
      }
    }
    return false;
  }
}

///
/// Mapのピンのデザイン
///
class CountWidget extends StatelessWidget {
  const CountWidget({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: loadSvgAndEditText(count.toString()),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SvgPicture.string(
              snapshot.data!,
              height: 80,
            );
          } else {
            return Container();
          }
        });
  }

  Future<String> loadSvgAndEditText(String count) async {
    try {
      final String svgData = await rootBundle.loadString('assets/Marker.svg');

      String editedSvgData = svgData.replaceAll(
        'dominant-baseline="middle">',
        'dominant-baseline="middle">$count',
      );

      return editedSvgData;
    } catch (e) {
      rethrow;
    }
  }
}
