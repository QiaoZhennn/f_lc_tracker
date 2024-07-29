import 'dart:convert';
import 'package:f_lc_tracker/tracker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'member.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  tz.initializeTimeZones();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Leetcode weekly tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final Map<String, String> _members = {
    "QiaoZhennn": "Zhen Qiao",
    "RachelLiu66": "Rachel",
    "haomiaovast": "Emma",
    "chenyuxian198": "Yuxian",
  };
  final Map<String, List<Map<String, dynamic>>> _userSubmissions = {};
  final TextEditingController _memberController = TextEditingController();

  String _timeLabel = '';
  DateTime? _lastQueryTime;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _selectedIndex == 0
          ? TrackerWidget(
              checkSubmissions: _checkSubmissions,
              timeLabel: _timeLabel,
              userSubmissions: _userSubmissions,
              members: _members)
          : MemberWidget(members: _members),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Member',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
