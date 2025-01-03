import 'package:flutter/material.dart';
import 'package:flutter_try_thesis/constants/constants.dart';
import 'package:flutter_try_thesis/constants/screenSizes.dart';
import 'package:flutter_try_thesis/models/providers/historyProvider.dart';
import 'package:provider/provider.dart';

class RiderBookingHistory extends StatefulWidget {
  const RiderBookingHistory({super.key});

  @override
  State<RiderBookingHistory> createState() => _RiderBookingHistoryState();
}

class _RiderBookingHistoryState extends State<RiderBookingHistory>
    with TickerProviderStateMixin {
  late TabController mainTabController;
  @override
  void initState() {
    super.initState();
    mainTabController = TabController(length: 2, vsync: this);
  }

// need to add localstorage or sqlite to save history locally. hays
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(ScreenUtil.parentWidth(context), 80),
        child: TabBar(
          dividerColor: primaryColor,
          controller: mainTabController,
          tabs: [
            Tab(
              text: 'Cancelled',
            ),
            Tab(
              text: 'Completed',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: mainTabController,
        children: [
          CancelledBookings(),
          CompletedBookings(),
        ],
      ),
    );
  }
}

class CancelledBookings extends StatelessWidget {
  CancelledBookings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingHistoryProvider>(
      builder: (context, provider, child) {
        return provider.cancelledBookingHistory.isNotEmpty
            ? ListView.builder(
                itemCount: provider.cancelledBookingHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                        '${provider.cancelledBookingHistory[index]['Pickup Location']}'),
                  );
                })
            : Center(
                child: Text('History is empty.'),
              );
      },
    );
  }
}

class CompletedBookings extends StatelessWidget {
  const CompletedBookings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
