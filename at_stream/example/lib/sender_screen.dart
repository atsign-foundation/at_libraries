import 'package:at_app_flutter/at_app_flutter.dart';
import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_stream_example/models/my_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:at_commons/at_commons.dart';

// ignore: implementation_imports
import 'package:at_client/src/service/notification_service.dart';

class SenderScreen extends StatefulWidget {
  const SenderScreen(this.atsign, {Key? key}) : super(key: key);

  final String atsign;

  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  final TextEditingController keyController = TextEditingController();
  final TextEditingController numController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Key:'),
            TextField(controller: keyController),
            SizedBox(height: 40),
            Text('Number:'),
            TextField(
              controller: numController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: handleSend,
              child: Text('Send'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> handleSend() async {
    String key = keyController.text;
    int number = int.parse(numController.text);

    AtClientManager atClientManager = AtClientManager.getInstance();

    AtKey atKey = (AtKey.shared(
      key,
      namespace: AtEnv.appNamespace,
    )..sharedWith(widget.atsign))
        .build();

    String data = MyData(key, number).toJson();

    await atClientManager.atClient.put(atKey, data);
    await atClientManager.notificationService.notify(
      NotificationParams.forUpdate(atKey, value: data),
      onSuccess: (res) => print('Notify ${atKey.key} successful: $data'),
      onError: (res) => print('Notify ${atKey.key} failed'),
    );
  }
}
