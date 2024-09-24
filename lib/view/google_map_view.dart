import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map_app/model/charger_spot.dart';
import 'package:flutter_map_app/model/map_page_model.dart';
import 'package:flutter_map_app/api_key.dart';
import 'package:flutter_map_app/theme_color.dart';
import 'package:flutter_map_app/view_model/google_map_view_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class GoogleMapView extends HookConsumerWidget {
  const GoogleMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(googleMapAsyncNotifierProvider);
    final notifier = ref.read(googleMapAsyncNotifierProvider.notifier);
    final Size size = MediaQuery.of(context).size;
    final mapController = useState<GoogleMapController?>(null);
    final marker = useState<Set<Marker>>({});
    final markerLoading = useState<bool>(false);
    final moreInformation = useState<bool>(false);
    final prevSpotsLen = useState<int?>(0);
    final nextSpotsLen = useState<int?>(0);
    final textEditingController =
        useState<TextEditingController>(TextEditingController());
    final pageController = useState<PageController>(PageController(
      viewportFraction: 0.85,
    ));

    return asyncValue.when(
        data: (mapPageModel) {
          ref.listen<AsyncValue<MapPageModel>>(googleMapAsyncNotifierProvider,
              (previous, next) {
            prevSpotsLen.value = previous?.valueOrNull?.spots.length;
            nextSpotsLen.value = next.valueOrNull?.spots.length;
          });

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                SystemChannels.textInput.invokeMethod('TextInput.hide'),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GoogleMap(
                    myLocationEnabled: true,
                    initialCameraPosition: CameraPosition(
                        target: mapPageModel.currentPosition, zoom: 15.0),
                    onMapCreated: (GoogleMapController controller) {
                      mapController.value = controller;
                    },
                    onCameraIdle: () async {
                      await notifier
                          .getVisibleRegion(mapPageModel, mapController.value)
                          .then((v) async {
                        if (mapController.value != null) {
                          marker.value = await notifier.addMarkersFromList(
                              model: v,
                              ref: ref,
                              size: size,
                              mapController: mapController.value!,
                              pageController: pageController.value,
                              markerLoading: markerLoading,
                              moreInformation: moreInformation,
                              prevSpotsLen: prevSpotsLen.value,
                              nextSpotsLen: nextSpotsLen.value);
                        }
                      });
                    },
                    markers: marker.value),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Align(
                        alignment: Alignment.bottomRight,
                        child: goToCurrentPositionButton(
                            ref, mapController.value)),
                    mapController.value != null
                        ? CardArea(
                            mapPageModel: mapPageModel,
                            mapController: mapController.value!,
                            pageController: pageController.value,
                            size: size,
                            moreInformation: moreInformation,
                          )
                        : Container(),
                  ],
                ),
                mapController.value != null
                    ? placesTextField(
                        mapController: mapController.value!,
                        textEditingController: textEditingController.value,
                        moreInformation: moreInformation,
                        size: size)
                    : Container(),
                markerLoading.value
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 70,
                            width: 70,
                            child: CircularProgressIndicator(
                                color: ThemeColor.green,
                                backgroundColor: ThemeColor.white,
                                strokeWidth: 5),
                          ),
                          Text(
                            'search now...',
                            style: TextStyle(
                                color: ThemeColor.green,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      )
                    : Container()
              ],
            ),
          );
        },
        error: (error, _) {
          return Align(
              alignment: Alignment.center, child: Text('error：$error'));
        },
        loading: () => const Align(
            alignment: Alignment.center, child: Text('loading...')));
  }

  placesTextField(
      {required GoogleMapController mapController,
      required TextEditingController textEditingController,
      required ValueNotifier<bool> moreInformation,
      required Size size}) {
    double padHeight = size.height * 0.075;
    double padWidth = size.width * 0.03;
    return Padding(
      padding: EdgeInsets.only(left: padWidth, right: padWidth, top: padHeight),
      child: Column(
        children: [
          GooglePlaceAutoCompleteTextField(
            textEditingController: textEditingController,
            googleAPIKey: GoogleMapApiKey.googleMapApiKey,
            boxDecoration:
                BoxDecoration(border: Border.all(style: BorderStyle.none)),
            inputDecoration: InputDecoration(
              hintText: 'このエリアでスポットを検索',
              fillColor: ThemeColor.lightGreen,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              suffixIcon: const Icon(
                Icons.search,
                color: ThemeColor.green,
              ),
            ),
            debounceTime: 800,
            countries: const ['JP'],
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (Prediction prediction) {
              if (prediction.lat != null && prediction.lng != null) {
                moreInformation.value = false;

                mapController.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                        target: LatLng(double.parse(prediction.lat!),
                            double.parse(prediction.lng!)),
                        zoom: 15.0),
                  ),
                );
              }
            },
            itemClick: (Prediction prediction) {
              textEditingController.text = prediction.description!;
              textEditingController.selection = TextSelection.fromPosition(
                  TextPosition(offset: prediction.description!.length));
              SystemChannels.textInput.invokeMethod('TextInput.hide');
            },
          ),
        ],
      ),
    );
  }

  Widget goToCurrentPositionButton(
    WidgetRef ref,
    GoogleMapController? mapController,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(55, 55),
        backgroundColor: ThemeColor.darkGray,
        foregroundColor: ThemeColor.white,
        shape: const CircleBorder(),
      ),
      onPressed: () async {
        final notifier = ref.read(googleMapAsyncNotifierProvider.notifier);
        final mapPageModel = await notifier.determinePosition();
        if (mapController != null) {
          mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(mapPageModel.currentPosition.latitude,
                      mapPageModel.currentPosition.longitude),
                  zoom: 15),
            ),
          );
        }
      },
      child: const Icon(Icons.my_location),
    );
  }
}

class CardArea extends HookConsumerWidget {
  final MapPageModel mapPageModel;
  final GoogleMapController mapController;
  final PageController pageController;
  final Size size;
  final ValueNotifier<bool> moreInformation;

  const CardArea({
    super.key,
    required this.mapPageModel,
    required this.mapController,
    required this.pageController,
    required this.size,
    required this.moreInformation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: moreInformation.value ? size.height * 0.33 : size.height * 0.21,
      child: PageView(
        onPageChanged: (int index) async {
          //スワイプ後のページのお店を取得
          final selectedSpot = mapPageModel.spots.elementAt(index);
          //スワイプ後のお店の座標までカメラを移動

          mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(selectedSpot.latitude, selectedSpot.longitude),
                zoom: 15,
              ),
            ),
          );
        },
        controller: pageController,
        children: spotTiles(ref: ref, model: mapPageModel, size: size),
      ),
    );
  }

  List<Widget> spotTiles(
      {required WidgetRef ref,
      required MapPageModel model,
      required Size size}) {
    final notifier = ref.read(googleMapAsyncNotifierProvider.notifier);
    String noImagePath = 'assets/Mask Group.svg';
    final spotTiles = model.spots.map(
      (spot) {
        return GestureDetector(
          onTap: () {
            moreInformation.value = !moreInformation.value;
          },
          child: Card(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(
                child: FutureBuilder(
                    future: notifier.checkImageUrl(spot.imageUrl),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return SizedBox(
                          height: size.height * 0.09,
                          width: double.infinity,
                          child: FittedBox(
                              fit: BoxFit.fill,
                              child: snapshot.data!
                                  ? Image.network(
                                      spot.imageUrl!,
                                    )
                                  : SvgPicture.asset(
                                      noImagePath,
                                    )),
                        );
                      } else {
                        return Container();
                      }
                    }),
              ),
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        Text(
                          spot.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
                        ),
                        chargers(spot, size),
                        moreInformation.value
                            ? Column(
                                children: [
                                  chargeOutput(spot, size),
                                  businessHours(spot, size),
                                  regularClosingDay(spot, size),
                                  GestureDetector(
                                    onTap: () async {
                                      final googleMap = Uri.parse(
                                          'https://www.google.com/maps/search/?api=1&query=${spot.latitude},${spot.longitude}');
                                      final appleMap = Uri.parse(
                                          'https://maps.apple.com/?q=${spot.latitude},${spot.longitude}');

                                      if (Platform.isAndroid) {
                                        if (await canLaunchUrl(googleMap)) {
                                          launchUrl(googleMap,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      } else if (Platform.isIOS) {
                                        if (await canLaunchUrl(appleMap)) {
                                          launchUrl(appleMap,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        } else {
                                          throw 'Could not launch ';
                                        }
                                      }
                                    },
                                    child: const Row(
                                      children: [
                                        Text('地図アプリで経路を見る',
                                            style: TextStyle(
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: ThemeColor.green,
                                              color: ThemeColor.green,
                                            )),
                                        Icon(
                                          Icons.copy_rounded,
                                          color: ThemeColor.green,
                                          size: 18,
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              )
                            : Container()
                      ])),
            ],
          )),
        );
      },
    ).toList();
    return spotTiles;
  }

  ///充電器数エリア
  Widget chargers(ChargerSpot spot, Size size) {
    int chargersLength = spot.chargerDevices.length;

    return utilWidget(
        iconPath: 'assets/icons/power.svg',
        title: '充電器数',
        text: '$chargersLength台',
        size: size);
  }

  ///充電出力エリア
  Widget chargeOutput(
    ChargerSpot spot,
    Size size,
  ) {
    List<dynamic> list = [];
    for (ChargerDevice chargerDevice in spot.chargerDevices) {
      list.add(chargerDevice.power);
    }
    return utilWidget(
        iconPath: 'assets/icons/bolt.svg',
        title: '充電出力',
        list: list,
        text: 'kw',
        separateText: '、',
        size: size);
  }

  ///営業時間エリア
  Widget businessHours(
    ChargerSpot spot,
    Size size,
  ) {
    GoogleMapAsyncNotifier googleMapAsyncNotifier = GoogleMapAsyncNotifier();
    bool checkBusinessHour =
        googleMapAsyncNotifier.checkServiceTime(spot.serviceTimes);
    String todayBusinessHour =
        googleMapAsyncNotifier.getServiceTime(spot.serviceTimes);

    return utilWidget(
        size: size,
        iconPath: 'assets/icons/watch_later.svg',
        title: checkBusinessHour ? '営業中' : '営業時間外',
        text: todayBusinessHour,
        judgeBusinessHour: checkBusinessHour);
  }

  ///定休日エリア
  Widget regularClosingDay(
    ChargerSpot spot,
    Size size,
  ) {
    List<dynamic> list = [];
    GoogleMapAsyncNotifier googleMapAsyncNotifier = GoogleMapAsyncNotifier();

    List<ServiceTime> closingDays = spot.serviceTimes
        .where((service) => service.businessDay == false)
        .toList();
    for (var i in closingDays) {
      list.add(googleMapAsyncNotifier.convertDayToJapanese(i.day.name));
    }

    return utilWidget(
        size: size,
        iconPath: 'assets/icons/today.svg',
        title: '定休日',
        list: list,
        text: list.isEmpty ? '-' : '',
        separateText: '、');
  }

  Widget utilWidget(
      {String iconPath = '',
      String title = '',
      List<dynamic> list = const [],
      String text = '',
      String separateText = '',
      required Size size,
      bool? judgeBusinessHour}) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.005),
      child: Stack(children: [
        Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 14,
              height: 14,
            ),
            Text(
              title,
              style: TextStyle(
                  color: judgeBusinessHour != null
                      ? judgeBusinessHour
                          ? ThemeColor.green
                          : ThemeColor.gray
                      : ThemeColor.black),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: size.width * 0.25),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  height: size.height * 0.02,
                  width: size.width * 0.45,
                  child: list.isNotEmpty
                      ? ListView.separated(
                          itemCount: list.length,
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (BuildContext context, int index) {
                            return Text(separateText);
                          },
                          itemBuilder: (context, index) {
                            return Row(
                              children: [
                                Text('${list[index]}'),
                                Text(text),
                              ],
                            );
                          },
                        )
                      : Text(text),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void jumpToPage(int index) {
    Future.delayed(const Duration(milliseconds: 100), () {
      pageController.jumpToPage(index);
    });
  }
}
