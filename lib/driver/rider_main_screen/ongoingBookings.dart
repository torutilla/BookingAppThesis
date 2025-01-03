import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/constants/screenSizes.dart';
import 'package:flutter_try_thesis/constants/titleText.dart';
import 'package:flutter_try_thesis/models/providers/bookingProvider.dart';
import 'package:flutter_try_thesis/models/providers/historyProvider.dart';
import 'package:provider/provider.dart';

class OngoingBookings extends StatelessWidget {
  const OngoingBookings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body:
          Consumer<BookingHistoryProvider>(builder: (context, provider, child) {
        return provider.ongoingBooking.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pickup Location',
                            style: TextStyle(
                              color: grayColor,
                            )),
                        Text(
                          '${provider.ongoingBooking['Pickup Location']} ',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      color: grayInputBox,
                      height: 0.5,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dropoff Location',
                          style: TextStyle(
                            color: grayColor,
                          ),
                        ),
                        Text(
                          '${provider.ongoingBooking['Dropoff Location']}',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      color: grayInputBox,
                      height: 0.5,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: TextStyle(
                            color: grayColor,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          height: 80,
                          child: Text(
                            provider.ongoingBooking['Note'] != 'null'
                                ? ' ${provider.ongoingBooking['Note']} '
                                : '',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      color: grayInputBox,
                      height: 0.5,
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Booking ID:'),
                            Text('${provider.ongoingBooking['Booking ID']}'),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Date:'),
                            Text('${provider.ongoingBooking['Date']}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Time:'),
                            Text('${provider.ongoingBooking['Time']}'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Center(
                child: Text('No Active Bookings'),
              );
      }),
    );
  }
}
