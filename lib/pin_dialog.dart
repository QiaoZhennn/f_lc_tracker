import 'package:f_lc_tracker/firestore.dart';
import 'package:flutter/material.dart';

Future<bool> showPinDialog(
    BuildContext context, FirestoreService firestoreService) async {
  TextEditingController pinController = TextEditingController();
  bool proceed = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Enter database pin'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Pin',
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: Text('Confirm'),
            onPressed: () async {
              String pin = pinController.text.trim();
              bool isCorrect = await firestoreService.pinCorrect(pin);
              if (isCorrect) {
                proceed = true;
                Navigator.of(context).pop(); // Close the dialog
              } else {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Incorrect pin'),
                    duration: Duration(seconds: 2),
                  ),
                );
                pinController.clear();
              }
            },
          ),
        ],
      );
    },
  );

  return proceed;
}
