import 'package:f_lc_tracker/week_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class MemberTrackerCard extends StatelessWidget {
  const MemberTrackerCard({
    super.key,
    required this.aliasName,
    required this.submissions,
  });

  final String aliasName;
  final List<Map<String, dynamic>> submissions;
  final int threshold = 5;
  final int eachPenalty = 2;

  Map<String, List<dynamic>> bucketSubmissions(
      List<Map<String, dynamic>> submissions) {
    final Map<String, List<dynamic>> buckets = {
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
      'Sunday': [],
    };

    for (var submission in submissions) {
      final submissionTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
          tz.getLocation('America/Los_Angeles'),
          int.parse(submission['timestamp']) * 1000);
      final weekday = DateFormat('EEEE').format(submissionTime);
      buckets[weekday]?.add(submission);
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = submissions.length;
    final int totalPenalty =
        totalCount < threshold ? (threshold - totalCount) * eachPenalty : 0;

    final buckets = bucketSubmissions(submissions);
    final double screenWidth = MediaQuery.of(context).size.width;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  aliasName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(padding: const EdgeInsets.only(left: 10)),
                Text(
                  'Total submissions: ${submissions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (totalCount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: screenWidth < 600 ? 200 : screenWidth * 0.7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                              itemCount: submissions.length,
                              itemBuilder: (context, index) {
                                return Text(
                                  "${index + 1}. ${submissions[index]['title']}",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                );
                              }),
                        ),
                      ],
                    ),
                  ),
                  WeekChartWidget(buckets: buckets),
                ],
              )
            else
              const Text('0 submissions'),
            if (totalPenalty > 0)
              Text('Penalty: \$$totalPenalty',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
