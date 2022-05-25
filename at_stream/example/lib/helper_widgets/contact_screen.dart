import 'package:at_contacts_flutter/at_contacts_flutter.dart';
import 'package:at_stream_example/receiver_screen.dart';
import 'package:at_stream_example/sender_screen.dart';
import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  @override
  Widget build(BuildContext context) {
    return ContactsScreen(
      // * When the send icon is pressed for a particular contact
      onSendIconPressed: (String atsign) {
        showDialog(context: context, builder: (_) => CustomDialog(atsign));
      },
    );
  }
}

class CustomDialog extends StatelessWidget {
  const CustomDialog(this.atsign, {Key? key}) : super(key: key);

  final String atsign;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReceiverScreen(atsign)),
            );
          },
          child: Text('Receiver'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SenderScreen(atsign)),
            );
          },
          child: Text('Sender'),
        ),
      ],
    );
  }
}
