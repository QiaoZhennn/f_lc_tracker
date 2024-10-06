import 'package:f_lc_tracker/firestore.dart';
import 'package:f_lc_tracker/pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArchiveWidget extends StatefulWidget {
  const ArchiveWidget({super.key});

  @override
  State<ArchiveWidget> createState() => _MemberWidgetState();
}

class _MemberWidgetState extends State<ArchiveWidget> {
  Map<String, String> _members = {};
  late Future<void> _fetchMembersFuture;

  final FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fetchMembersFuture = fetchMembers();
  }

  Future<void> fetchMembers() async {
    _members = await firestoreService.fetchMembers('archive');
  }

  Widget buildListView() {
    return ListView.builder(
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members.keys.elementAt(index);
        final aliasName = _members[member]!;
        return ListTile(
          title: Text(aliasName),
          subtitle: Text(member),
          trailing: IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () async {
              bool proceed = await showPinDialog(context, firestoreService);
              if (!proceed) {
                return;
              }
              final success = await firestoreService.deleteMember(member);
              if (success) {
                await firestoreService.addMember(member, aliasName);
                setState(() {
                  _members.remove(member);
                });
              }
            },
          ),
        );
      },
    );
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
            return buildListView();
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
