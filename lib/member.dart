import 'package:flutter/material.dart';

class MemberWidget extends StatefulWidget {
  final Map<String, String> members;
  const MemberWidget({super.key, required this.members});

  @override
  State<MemberWidget> createState() => _MemberWidgetState();
}

class _MemberWidgetState extends State<MemberWidget> {
  late final TextEditingController _memberController;
  late final TextEditingController _aliasNameController;
  late Map<String, String> _members;

  @override
  void initState() {
    super.initState();
    _memberController = TextEditingController();
    _aliasNameController = TextEditingController();
    _members = widget.members;

    // Update aliasNameController whenever memberController changes
    _memberController.addListener(() {
      _aliasNameController.text = _memberController.text;
    });
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
    return MemberTab(
      memberController: _memberController,
      aliasNameController: _aliasNameController,
      members: _members,
      addMember: _addMember,
      deleteMember: _deleteMember,
    );
  }
}

class MemberTab extends StatelessWidget {
  final TextEditingController memberController;
  final TextEditingController aliasNameController;
  final Map<String, String> members;
  final VoidCallback addMember;
  final Function(String) deleteMember;

  const MemberTab({
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
          onPressed: addMember,
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
                  onPressed: () => deleteMember(member),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
