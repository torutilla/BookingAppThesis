import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/constants/screenSizes.dart';
import 'package:flutter_try_thesis/models/cache_manager/sqlite_operations/sqliteOperations.dart';
import 'package:flutter_try_thesis/models/providers/bookingProvider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class SavedPlaces extends StatefulWidget {
  final bool assignToBooking;
  final Function(String address, LatLng coordinates, {bool? pickup})?
      onTapCallback;
  const SavedPlaces(
      {super.key, this.assignToBooking = false, this.onTapCallback});

  @override
  State<SavedPlaces> createState() => _SavedPlacesState();
}

class _SavedPlacesState extends State<SavedPlaces> {
  final SqliteOperations sql = SqliteOperations();
  List<Map<String, Object?>> savedPlaces = [];
  @override
  void initState() {
    super.initState();
    _retrieveSavedPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        'Saved Places',
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: softWhite,
              fontWeight: FontWeight.w500,
            ),
      )),
      body: Consumer<SuggestionsProvider>(builder: (context, provider, child) {
        return Container(
          height: ScreenUtil.parentHeight(context),
          width: ScreenUtil.parentWidth(context),
          color: softWhite,
          child: Column(
            children: [
              ListTile(
                onTap: () {},
                title: const Text('Add Home'),
                leading: const Icon(
                  Icons.home,
                  color: primaryColor,
                ),
                trailing: const Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: accentColor,
                ),
              ),
              const Divider(),
              ListTile(
                onTap: () {},
                title: const Text('Add Work'),
                leading: const Icon(
                  Icons.work,
                  color: Color.fromARGB(255, 80, 50, 39),
                ),
                trailing: const Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: accentColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
                width: ScreenUtil.parentWidth(context),
                color: grayInputBox,
                child: const Text('Places'),
              ),
              SizedBox(
                height: ScreenUtil.parentHeight(context) * 0.7,
                child: ListView.separated(
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: savedPlaces.length,
                    itemBuilder: (context, index) {
                      return Ink(
                        color: secondaryColor.withOpacity(0.2),
                        child: ListTile(
                          selectedTileColor: grayColor,
                          title: Text('${savedPlaces[index]['Location']}'),
                          leading: const Icon(
                            Icons.location_on_sharp,
                            color: Colors.red,
                          ),
                          onTap: widget.assignToBooking
                              ? () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              alignment: Alignment.center,
                                              width: ScreenUtil.parentWidth(
                                                      context) *
                                                  0.8,
                                              height: ScreenUtil.parentWidth(
                                                      context) *
                                                  0.4,
                                              child: Card(
                                                clipBehavior: Clip.hardEdge,
                                                child: ListView.separated(
                                                    shrinkWrap: true,
                                                    itemBuilder:
                                                        (context, titleIndex) {
                                                      List<String> title = [
                                                        'Set as pickup location',
                                                        'Set as dropoff location',
                                                      ];
                                                      List<Icon> icons = [
                                                        const Icon(Icons
                                                            .my_location_rounded),
                                                        const Icon(Icons
                                                            .location_on_rounded),
                                                      ];
                                                      return ListTile(
                                                        leading:
                                                            icons[titleIndex],
                                                        title: Text(
                                                            title[titleIndex]),
                                                        onTap: () {
                                                          Navigator.pop(
                                                              context);
                                                          final locationLat =
                                                              savedPlaces[index]
                                                                      [
                                                                      'Location_Lat']
                                                                  as double;
                                                          final locationLng =
                                                              savedPlaces[index]
                                                                      [
                                                                      'Location_Lng']
                                                                  as double;
                                                          if (titleIndex == 0) {
                                                            widget.onTapCallback!(
                                                                '${savedPlaces[index]['Location']}',
                                                                LatLng(
                                                                    locationLat,
                                                                    locationLng),
                                                                pickup: true);
                                                          } else {
                                                            widget.onTapCallback!(
                                                                '${savedPlaces[index]['Location']}',
                                                                LatLng(
                                                                    locationLat,
                                                                    locationLng),
                                                                pickup: false);
                                                          }
                                                        },
                                                      );
                                                    },
                                                    separatorBuilder:
                                                        (context, index) =>
                                                            const Divider(),
                                                    itemCount: 2),
                                              ),
                                            ),
                                          ],
                                        );
                                      });
                                }
                              : () {},
                        ),
                      );
                    }),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _retrieveSavedPlaces() async {
    final sqlvalues = await sql.retrieveValuesInTable('savedPlaces');
    setState(() {
      savedPlaces = sqlvalues;
    });
  }
}
