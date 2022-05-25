import 'package:at_app_flutter/at_app_flutter.dart';
import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_stream/at_stream.dart';
import 'package:at_stream_example/models/my_data.dart';
import 'package:flutter/material.dart';
import 'package:at_commons/at_commons.dart';

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen(this.atsign, {Key? key}) : super(key: key);

  final String atsign;

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final Map<AtKey, MyData> data = {};

  late AtStreamIterable<MyData> stream;

  static const Widget emptyListText = Center(child: Text('No Items 😭'));

  @override
  void initState() {
    // Initialize your AtStream here
    stream = AtStreamIterable(
      convert: (AtKey key, AtValue value) => MyData.fromJson(value.value ?? '{}'),
      sharedBy: widget.atsign,
      sharedWith: AtClientManager.getInstance().atClient.getCurrentAtSign(),
      regex: AtEnv.appNamespace,
    );

    super.initState();
  }

  @override
  void dispose() {
    // Dispose of your AtStream here
    stream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Iterable<MyData>>(
        stream: stream,
        initialData: [],
        builder: (context, AsyncSnapshot<Iterable<MyData>> snapshot) {
          return (snapshot.data?.isEmpty ?? true)
              ? emptyListText
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: snapshot.data!.map((MyData data) => Text('${data.key} ${data.myNumber}')).toList(),
                );
        },
      ),
    );
  }
}
