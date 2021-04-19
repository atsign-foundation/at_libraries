import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:at_lookup/src/connection/outbound_message_listener.dart';

class SyncMessageListener extends OutboundMessageListener {
  Queue pendingData = Queue<List<int>>();
  var atConst = '@'.codeUnitAt(0);
  var dollarConst = '\$'.codeUnitAt(0);

  SyncMessageListener(connection) : super(connection);

  @override
  Future<void> messageHandler(sync_data) async {
    // If sync_data contains only '@', return.
    if (sync_data.length == 1 && sync_data.first == atConst) {
      return;
    }
    // if sync_data last is '@' and contains a new line.
    if (sync_data.last == atConst && sync_data.contains(10)) {
      await super.messageHandler(sync_data);
      return;
    }
    var start = 0;
    // If sync_data does not contain '$', add the data into pending queue.
    if (!sync_data.contains(dollarConst)) {
      pendingData.addLast(sync_data);
    }
    // If sync_data contains '$', process the data.
    if (sync_data.contains(dollarConst)) {
      var bytes = BytesBuilder();
      while (pendingData.isNotEmpty) {
        bytes.add(pendingData.removeFirst());
      }
      while (sync_data.indexOf(dollarConst, start) != -1) {
        var index = sync_data.indexOf(dollarConst, start);
        bytes.add(sync_data.sublist(start, index));
        start = index + 1;
        _process(bytes.takeBytes());
      }
      if (sync_data.length > start) {
        pendingData.addLast(sync_data.sublist(start, sync_data.length));
      }
    }
  }

  void _process(sync_records) {
    var recordsReceived = utf8.decode(sync_records);
    var startIndex = recordsReceived.indexOf('#');
    var jsonRecord = jsonDecode(recordsReceived.substring(startIndex + 1));
    syncCallback(jsonRecord);
  }
}
