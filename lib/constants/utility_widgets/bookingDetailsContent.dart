import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/constants/constants.dart';

class BookingInformationContent extends StatelessWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final String? notes;
  final String bookingID;
  final String date;
  final String time;
  const BookingInformationContent({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.notes,
    required this.bookingID,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pickup Location',
                style: TextStyle(
                  color: grayColor,
                )),
            Text(
              pickupLocation,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Divider(
          color: grayInputBox,
          height: 0.5,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dropoff Location',
              style: TextStyle(
                color: grayColor,
              ),
            ),
            Text(
              dropoffLocation,
              style: const TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Divider(
          color: grayInputBox,
          height: 0.5,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                color: grayColor,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 80,
              child: Text(
                notes != 'null' ? notes! : '',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
        const Divider(
          color: grayInputBox,
          height: 0.5,
        ),
        Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Booking ID:'),
                Text(
                  bookingID,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Date:'),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Time:'),
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
