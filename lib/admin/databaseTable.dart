import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../constants/constants.dart';
import '../constants/screenSizes.dart';
import '../constants/titleText.dart';

class DbTableStream extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>>? stream;
  final List<String> columnHeader;
  final List<String> titles;
  final String tableInfoTitle;
  const DbTableStream(
      {super.key,
      required this.stream,
      required this.columnHeader,
      required this.tableInfoTitle,
      required this.titles});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              alignment: Alignment.center,
              height: ScreenUtil.parentHeight(context) * 0.8,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error retrieving data. ${snapshot.error}'),
            );
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final firstEntry = '${snapshot.data![0][columnHeader[0]]}';

            // userEntryValues = snapshot.data!;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: firstEntry.isEmpty ? 80 : 30,
                columns: List.generate(titles.length, (columnIndex) {
                  return DataColumn(
                      label: TextTitle(
                    text: titles[columnIndex],
                    fontSize: 12,
                  ));
                }),
                rows: List.generate(snapshot.data!.length, (rowIndex) {
                  return DataRow(
                      onLongPress: () {
                        showOverlayDialog(rowIndex, context, snapshot.data!);
                      },
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 90,
                            child: TextTitle(
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                              text: '${snapshot.data![rowIndex][titles[0]]}',
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 90,
                            child: TextTitle(
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                              text: '${snapshot.data![rowIndex][titles[1]]}',
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        if (titles.length > 3)
                          DataCell(
                            SizedBox(
                              width: 90,
                              child: TextTitle(
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                text: '${snapshot.data![rowIndex][titles[2]]}',
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        DataCell(TextButton(
                            style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8))),
                                foregroundColor:
                                    const WidgetStatePropertyAll(Colors.white),
                                backgroundColor:
                                    const WidgetStatePropertyAll(accentColor)),
                            onPressed: () {
                              showOverlayDialog(
                                  rowIndex, context, snapshot.data!);
                            },
                            child: const Text('Details'))),
                      ]);
                }),
              ),
            );
          }
          return Container(
            alignment: Alignment.center,
            height: ScreenUtil.parentHeight(context) * 0.8,
            child: const Text(
              'No data.',
              style: TextStyle(color: Colors.white),
            ),
          );
        });
  }

  void showOverlayDialog(int userIndex, BuildContext context,
      List<Map<String, dynamic>> snapshot) {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Container(
              decoration: BoxDecoration(
                  color: adminGradientColor2,
                  borderRadius: BorderRadius.circular(8)),
              height: columnHeader.length <= 4
                  ? ScreenUtil.parentHeight(context) * 0.6
                  : ScreenUtil.parentHeight(context) * 0.90,
              width: ScreenUtil.parentWidth(context) * 0.90,
              child: LayoutBuilder(builder: (context, constraints) {
                return Column(
                  children: [
                    AppBar(
                      backgroundColor: adminGradientColor1,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      )),
                      leading: IconButton(
                          color: softWhite,
                          onPressed: () {},
                          icon: const Icon(Icons.menu)),
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: SvgPicture.asset(
                            'assets/images/Icons/quit-pip-svgrepo-com.svg',
                            colorFilter: const ColorFilter.mode(
                                accentColor, BlendMode.srcIn),
                          ),
                        ),
                      ],
                      centerTitle: true,
                      title: TextTitle(
                        text: tableInfoTitle,
                        fontSize: 18,
                      ),
                    ),
                    const Divider(
                      color: adminGradientColor1,
                      thickness: 0.5,
                    ),
                    SizedBox(
                      width: constraints.maxWidth * 0.90,
                      height: constraints.maxHeight * 0.85,
                      child: GridView.count(
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          children:
                              List.generate(columnHeader.length, (valueIndex) {
                            final filteredValues = snapshot.map((entry) {
                              return {
                                for (var key in columnHeader)
                                  key: entry.containsKey(key)
                                      ? entry[key]
                                      : 'N/A',
                              };
                            }).toList();
                            var value;

                            if (filteredValues[userIndex]['Time Stamp'] !=
                                    'N/A' &&
                                valueIndex ==
                                    filteredValues[userIndex]
                                        .keys
                                        .toList()
                                        .indexOf('Time Stamp')) {
                              value = _getDateInTimeStamp(
                                  filteredValues[userIndex]['Time Stamp']);
                            } else if (filteredValues[userIndex]['Elapsed'] !=
                                    'N/A' &&
                                valueIndex ==
                                    filteredValues[userIndex]
                                        .keys
                                        .toList()
                                        .indexOf('Elapsed')) {
                              value = _getDateInTimeStamp(
                                  filteredValues[userIndex]['Elapsed']);
                            } else {
                              value = filteredValues[userIndex]
                                      .values
                                      .elementAt(valueIndex)
                                      ?.toString() ??
                                  'N/A';
                            }

                            return Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: adminGradientColor1,
                                          width: 0.5)),
                                  height: 120,
                                  width: 140,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          columnHeader[valueIndex],
                                          style: const TextStyle(
                                            color: accentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${value.isNotEmpty ? value : 'N/A'}',
                                          style: const TextStyle(
                                            color: softWhite,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          })),
                    ),
                  ],
                );
              })),
        );
      },
    );
  }

  String _getDateInTimeStamp(dynamic data) {
    final timestamp = data;
    return '${DateFormat.jm().format(timestamp.toDate())} ${DateFormat.yMd('en_US').format(timestamp.toDate())}';
  }
}
