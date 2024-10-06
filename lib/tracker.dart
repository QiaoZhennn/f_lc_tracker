import 'package:f_lc_tracker/firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'member_tracker_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;

class TrackerWidget extends StatefulWidget {
  const TrackerWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<TrackerWidget> createState() => _TrackerWidgetState();
}

class _TrackerWidgetState extends State<TrackerWidget> {
  Map<String, String> _members = {};
  // final Map<String, String> _members = {
  //   "QiaoZhennn": "Zhen Qiao",
  //   "RachelLiu66": "Rachel",
  //   "haomiaovast": "Emma",
  //   "chenyuxian198": "Yuxian",
  // };
  final Map<String, List<Map<String, dynamic>>> _userSubmissions = {};
  final FirestoreService firestoreService = FirestoreService();
  late Future<void> _fetchMembersFuture;

  String _timeLabel = '';
  DateTime? _lastQueryTime;

  @override
  void initState() {
    super.initState();
    _fetchMembersFuture = fetchMembers();
  }

  Future<void> fetchMembers() async {
    _members = await firestoreService.fetchMembers('active');
  }

  Future<void> querySubmission(String username) async {
    if (kIsWeb) {
      await querySubmissionWeb(username);
    } else {
      await querySubmissionMobile(username);
    }
  }

  Future<void> querySubmissionWeb(String username) async {
    final url = Uri.parse(
        "https://us-central1-f-lc-tracker.cloudfunctions.net/proxyLeetCode");
    final headers = {"Content-Type": "application/json"};
    final body = json.encode({"username": username});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final submissions = data['data']['recentAcSubmissionList'] ?? [];
        final subs = formatSubmissions(submissions);

        final filteredSubs = filterSubmissions(subs);
        // print("$username total submission: ${filteredSubs.length}");
        setState(() {
          _userSubmissions[username] = filteredSubs;
        });
        // Handle the submissions as needed
      } else {
        // Handle the error response
        print('Error: ${response.body}');
      }
    } catch (e) {
      // Handle the exception
      print('Exception: $e');
    }
  }

  Future<void> querySubmissionMobile(String username) async {
    final url = Uri.parse("https://leetcode.com/graphql");
    final headers = {"Content-Type": "application/json"};
    final query = {
      "query": """
      {
        recentAcSubmissionList(username: "$username", limit: 100) {
          id
          title
          titleSlug
          timestamp
        }
      }
    """
    };

    final response =
        await http.post(url, headers: headers, body: json.encode(query));
    final data = json.decode(response.body);
    final submissions = data['data']['recentAcSubmissionList'] ?? [];

    final subs = formatSubmissions(submissions);

    final filteredSubs = filterSubmissions(subs);
    // print("$username total submission: ${filteredSubs.length}");
    setState(() {
      _userSubmissions[username] = filteredSubs;
    });
  }

  List<Map<String, dynamic>> formatSubmissions(List<dynamic> submissions) {
    return submissions.map((submission) {
      return {
        'id': submission['id'],
        'title': submission['title'],
        'titleSlug': submission['titleSlug'],
        'timestamp': submission['timestamp'],
      };
    }).toList();
  }

  List<Map<String, dynamic>> filterSubmissions(
      List<Map<String, dynamic>> submissions) {
    final now = tz.TZDateTime.now(tz.getLocation('America/Los_Angeles'));
    final startOfWeek = now.weekday >= DateTime.wednesday
        ? now.subtract(Duration(days: now.weekday - DateTime.monday))
        : now.subtract(Duration(days: now.weekday - DateTime.monday + 7));
    final startTime = tz.TZDateTime(tz.getLocation('America/Los_Angeles'),
        startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endTime = now.weekday >= DateTime.wednesday
        ? now
        : tz.TZDateTime(tz.getLocation('America/Los_Angeles'), startOfWeek.year,
            startOfWeek.month, startOfWeek.day + 7);

    _timeLabel =
        'Start: ${DateFormat('yyyy-MM-dd HH:mm').format(startTime)}, End: ${DateFormat('yyyy-MM-dd HH:mm').format(endTime)}';

    final filtered_submissions = submissions.where((submission) {
      final submissionTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
          tz.getLocation('America/Los_Angeles'),
          int.parse(submission['timestamp']) * 1000);
      return submissionTime.isAfter(startTime) &&
          submissionTime.isBefore(endTime);
    }).toList();
    return filtered_submissions;
  }

  Map<String, dynamic> bucketSubmissions(
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

  void _checkSubmissions() {
    final currentTime = DateTime.now();
    if (_lastQueryTime != null &&
        currentTime.difference(_lastQueryTime!).inSeconds < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Query submission is called too frequently. Please wait."),
        ),
      );
      return;
    }

    _lastQueryTime = currentTime;
    _members.forEach((member, _) {
      querySubmission(member);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _fetchMembersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading members: ${snapshot.error}'));
          } else {
            return buildTracker(
              context = context,
            );
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget buildTracker(BuildContext context) {
    return Column(
      children: <Widget>[
        ElevatedButton(
          onPressed: _checkSubmissions,
          child: const Text('Check status'),
        ),
        Text(_timeLabel),
        Expanded(
          child: _userSubmissions.isEmpty
              ? Center(
                  child: Column(
                  children: [
                    const Text('Click "Check status" to begin'),
                    const Text('Active members:'),
                    Wrap(
                      spacing: 8.0, // gap between adjacent chips
                      runSpacing: 4.0, // gap between lines
                      children: _members.values.map((alias) {
                        return Chip(
                          label: Text(alias),
                        );
                      }).toList(),
                    ),
                  ],
                ))
              : ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final String member = _members.keys.elementAt(index);
                    final String aliasName = _members[member]!;
                    final List<Map<String, dynamic>> submissions =
                        _userSubmissions[member] ?? [];
                    return MemberTrackerCard(
                        aliasName: aliasName, submissions: submissions);
                  },
                ),
        ),
      ],
    );
  }
}
