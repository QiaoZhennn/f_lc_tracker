import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference members =
      FirebaseFirestore.instance.collection('members');

  final CollectionReference pin = FirebaseFirestore.instance.collection('pin');

  Future<bool> pinCorrect(final String pinCode) async {
    final QuerySnapshot snapshot = await pin.get();
    if (snapshot.docs.isNotEmpty) {
      final String correctPin = snapshot.docs.first['members_pin'];
      return correctPin == pinCode;
    }
    return false;
  }

  Future<Map<String, String>> fetchMembers(final String status) async {
    print("start fetching members");
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('members')
        .where('status', isEqualTo: status)
        .get();

    final Map<String, String> members = {};
    for (var doc in snapshot.docs) {
      members[doc['userid']] = doc['alias'];
    }

    print("members: $members");
    return members;
  }

  Future<bool> addMember(final String userid, final String alias) async {
    try {
      final QuerySnapshot snapshot =
          await members.where('userid', isEqualTo: userid).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        // User ID exists, update the status to 'active'
        final DocumentReference docRef = snapshot.docs.first.reference;
        await docRef.update({
          'status': 'active',
          'alias': alias,
          'updated_at': FieldValue.serverTimestamp(),
        });
        print('Member $userid status updated to active');
      } else {
        // User ID does not exist, add a new member
        await members.add({
          'userid': userid,
          'alias': alias,
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
        });
        print('Member $userid added successfully');
      }
      return true;
    } catch (e) {
      print('Failed to add/update member: $userid, exception: $e');
      return false;
    }
  }

  Future<bool> deleteMember(String userid) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('userid', isEqualTo: userid)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'status': 'archive'});
      }
      print('Member $userid archived successfully');
      return true;
    } catch (e) {
      print('Failed to archive member $userid: $e');
    }
    return false;
  }
}
