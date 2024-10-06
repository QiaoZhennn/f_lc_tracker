import 'package:f_lc_tracker/firestore.dart';
import 'package:f_lc_tracker/pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemberWidget extends StatefulWidget {
  const MemberWidget({super.key});

  @override
  State<MemberWidget> createState() => _MemberWidgetState();
}

class _MemberWidgetState extends State<MemberWidget> {
  late final TextEditingController _memberController;
  late final TextEditingController _aliasNameController;
  late Map<String, String> _members;
  late Future<void> _fetchMembersFuture;

  final FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _memberController = TextEditingController();
    _aliasNameController = TextEditingController();
    _fetchMembersFuture = fetchMembers();

    // Update aliasNameController whenever memberController changes
    _memberController.addListener(() {
      _aliasNameController.text = _memberController.text;
    });
  }

  Future<void> fetchMembers() async {
    _members = await firestoreService.fetchMembers('active');
  }

  void _addMember() {
    setState(() {
      _members[_memberController.text] = _aliasNameController.text;
      _memberController.clear();
      _aliasNameController.clear();
    });
  }

  void _deleteMember(String member) {
    setState(() {
      _members.remove(member);
    });
  }

  @override
  void dispose() {
    _memberController.dispose();
    _aliasNameController.dispose();
    super.dispose();
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
            return MemberTab(
              memberController: _memberController,
              aliasNameController: _aliasNameController,
              members: _members,
              addMember: _addMember,
              deleteMember: _deleteMember,
            );
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class MemberTab extends StatelessWidget {
  final TextEditingController memberController;
  final TextEditingController aliasNameController;
  final Map<String, String> members;
  final VoidCallback addMember;
  final Function(String) deleteMember;
  final FirestoreService firestoreService = FirestoreService();

  MemberTab({
    required this.memberController,
    required this.aliasNameController,
    required this.members,
    required this.addMember,
    required this.deleteMember,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: memberController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Add Member',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: aliasNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Alias Name',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            bool proceed = await showPinDialog(context, firestoreService);
            if (!proceed) {
              return;
            }
            bool success = await firestoreService.addMember(
                memberController.text, aliasNameController.text);
            if (success) {
              addMember();
            }
          },
          child: const Text('Add Member'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members.keys.elementAt(index);
              final aliasName = members[member]!;
              return ListTile(
                title: Text(aliasName),
                subtitle: Text(member),
                trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      bool proceed =
                          await showPinDialog(context, firestoreService);
                      if (!proceed) {
                        return;
                      }
                      final success =
                          await firestoreService.deleteMember(member);
                      if (success) {
                        deleteMember(member);
                      }
                    }),
              );
            },
          ),
        ),
      ],
    );
  }
}
