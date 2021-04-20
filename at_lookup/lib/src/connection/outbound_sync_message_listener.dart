import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:at_lookup/src/connection/outbound_message_listener.dart';

class SyncMessageListener extends OutboundMessageListener {
  Queue pendingData = Queue<List<int>>();
  final AT_UTF_CODE = '@'.codeUnitAt(0);
  final DOLLAR_UTF_CODE = '\$'.codeUnitAt(0);
  final NEWLINE_UTF_CODE = '\n'.codeUnitAt(0);
  final HASH_UTF_CODE = '#'.codeUnitAt(0);
  static const HASH_SIGN = '#';
  var builder = BytesBuilder();

  SyncMessageListener(connection) : super(connection);

  @override
  Future<void> messageHandler(sync_data) async {
    if (sync_data.length == 1 && sync_data.first == AT_UTF_CODE) {
      return;
    }
    if (sync_data.last == AT_UTF_CODE && sync_data.contains(NEWLINE_UTF_CODE)) {
      await super.messageHandler(sync_data);
      return;
    }
    if (sync_data.last == DOLLAR_UTF_CODE) {
      //var builder = BytesBuilder();
      while (pendingData.isNotEmpty) {
        builder.add(pendingData.removeFirst());
      }
      builder.add(sync_data);
      _process(builder.takeBytes());
      return;
    }
    if (sync_data.contains(DOLLAR_UTF_CODE)) {
      //var builder = BytesBuilder();
      while (pendingData.isNotEmpty) {
        builder.add(pendingData.removeFirst());
      }
      builder.add(sync_data.sublist(0, sync_data.lastIndexOf(DOLLAR_UTF_CODE)));
      var incompleteData =
          sync_data.sublist(sync_data.lastIndexOf(DOLLAR_UTF_CODE) + 1);
      pendingData.addLast(incompleteData);
      _process(builder.takeBytes());
    }
    if (!sync_data.contains(DOLLAR_UTF_CODE)) {
      pendingData.addLast(sync_data);
    }
  }

  void _process(sync_records) {
    var startIndex = 0, endIndex = 0;
    var recordsReceived = utf8.decode(sync_records);
    while (startIndex < recordsReceived.length &&
        endIndex < recordsReceived.length) {
      var startOfRecord = recordsReceived.indexOf(HASH_SIGN, startIndex) + 1;
      if (startOfRecord == 0) break;
      var recordLengthStr =
          recordsReceived.substring(startIndex, startOfRecord - 1);
      startIndex = startIndex + recordLengthStr.length + 1;
      endIndex = startIndex + int.parse(recordLengthStr);
      var jsonRecord =
          jsonDecode(recordsReceived.substring(startIndex, endIndex));
      syncCallback(jsonRecord);
      startIndex = endIndex + 1;
    }
  }
}
