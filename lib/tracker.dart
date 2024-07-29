import 'package:flutter/material.dart';
import 'member_tracker_card.dart';

class TrackerWidget extends StatelessWidget {
  final VoidCallback checkSubmissions;
  final String timeLabel;
  final Map<String, List<Map<String, dynamic>>> userSubmissions;
  final Map<String, String> members;

  const TrackerWidget({
    required this.checkSubmissions,
    required this.timeLabel,
    required this.userSubmissions,
    required this.members,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ElevatedButton(
          onPressed: checkSubmissions,
          child: const Text('Check status'),
        ),
        Text(timeLabel),
        Expanded(
          child: userSubmissions.isEmpty
              ? const Center(child: Text('Click Check to begin'))
              : ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final String member = members.keys.elementAt(index);
                    final String aliasName = members[member]!;
                    final List<Map<String, dynamic>> submissions =
                        userSubmissions[member] ?? [];
                    return MemberTrackerCard(
                        aliasName: aliasName, submissions: submissions);
                  },
                ),
        ),
      ],
    );
  }
}
