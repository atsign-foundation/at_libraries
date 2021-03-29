import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:at_lookup/src/connection/outbound_message_listener.dart';

class SyncMessageListener extends OutboundMessageListener {
  Queue pendingData = Queue<List<int>>();

  SyncMessageListener(connection) : super(connection);

  @override
  Future<void> messageHandler(sync_data) async {
    if (sync_data.length == 1 && sync_data.first == 64) {
      return;
    }
    if (sync_data.last == 64 && sync_data.contains(10)) {
      await super.messageHandler(sync_data);
      return;
    }
    if (sync_data.last == 36) {
      if (pendingData.isNotEmpty) {
        var builder = BytesBuilder();
        while (pendingData.isNotEmpty) {
          builder.add(pendingData.removeFirst());
        }
        builder.add(sync_data);
        _process(builder.takeBytes());
      } else {
        _process(sync_data);
      }
    } else {
      if (sync_data.lastIndexOf(36) != -1) {
        var builder = BytesBuilder();
        if (pendingData.isNotEmpty) {
          builder.add(pendingData.removeFirst());
        }
        builder.add(sync_data.sublist(0, sync_data.lastIndexOf(36)));
        var incompleteData = sync_data.sublist(sync_data.lastIndexOf(36) + 1);
        pendingData.addLast(incompleteData);
        _process(builder.takeBytes());
      } else {
        pendingData.addLast(sync_data);
      }
    }
  }

  void _process(sync_records) {
    var recordsReceived = utf8.decode(sync_records);
    logger.finer('Records received t process: $recordsReceived');
    var startIndex = 0, endIndex = 0;
    while (startIndex < recordsReceived.length &&
        endIndex < recordsReceived.length) {
      var startOfRecord = recordsReceived.indexOf('#', startIndex) + 1;
      if (startOfRecord == 0) break;
      var recordLengthStr =
          recordsReceived.substring(startIndex, startOfRecord - 1);
      startIndex = startIndex + recordLengthStr.length + 1;
      endIndex = startIndex + int.parse(recordLengthStr);
      var jsonString = recordsReceived.substring(startIndex, endIndex);
      var jsonRecord = jsonDecode(jsonString);
      jsonRecord.forEach((element) {
        syncCallback(element);
      });
      startIndex = endIndex + 1;
    }
  }
}
