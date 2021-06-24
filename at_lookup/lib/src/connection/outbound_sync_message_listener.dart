import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:at_lookup/src/connection/outbound_message_listener.dart';

class SyncMessageListener extends OutboundMessageListener {
  Queue pendingData = Queue<List<int>>();
  final AT_UTF_CODE = '@'.codeUnitAt(0);
  final DOLLAR_UTF_CODE = '\$'.codeUnitAt(0);
  final NEWLINE_UTF_CODE = '\n'.codeUnitAt(0);
  final TILDE_UTF_CODE = '~'.codeUnitAt(0);
  static const TILDE_SIGN = '~';
  var bytesBuilder = BytesBuilder();

  SyncMessageListener(connection) : super(connection);

  @override
  Future<void> messageHandler(sync_data) async {
    // If sync_data contains only '@', do not do anything.
    if (sync_data.length == 1 && sync_data.first == AT_UTF_CODE) {
      return;
    }
    // If sync_data contains '@' and '\n'(response other than sync verb)
    // call base class
    if (sync_data.last == AT_UTF_CODE && sync_data.contains(NEWLINE_UTF_CODE)) {
      await super.messageHandler(sync_data);
      return;
    }
    // If last character of sync_data is '$', it is complete message.
    // If the there is a pendingData, add it to bytesBuilder.
    // send all the bytes to process method.
    if (sync_data.last == DOLLAR_UTF_CODE) {
      while (pendingData.isNotEmpty) {
        bytesBuilder.add(pendingData.removeFirst());
      }
      bytesBuilder.add(sync_data);
      _process(bytesBuilder.takeBytes());
      return;
    }
    // If sync_data contains '$',
    // Send bytes that has complete json record to process method and add remaining bytes to pendingData.
    if (sync_data.contains(DOLLAR_UTF_CODE)) {
      var hashIndex = int.parse(
          utf8.decode(sync_data.sublist(0, sync_data.indexOf(TILDE_UTF_CODE))));
      // If sync_data length is less than the hash index, incomplete data is received. Add to pendingData.
      if (sync_data.length < hashIndex) {
        pendingData.addLast(sync_data);
        return;
      }
      // Add pending data to bytesBuilder.
      while (pendingData.isNotEmpty) {
        bytesBuilder.add(pendingData.removeFirst());
      }
      bytesBuilder
          .add(sync_data.sublist(0, sync_data.lastIndexOf(DOLLAR_UTF_CODE)));
      var incompleteData =
      sync_data.sublist(sync_data.lastIndexOf(DOLLAR_UTF_CODE) + 1);
      pendingData.addLast(incompleteData);
      _process(bytesBuilder.takeBytes());
    }
    // If sync_data does not contain '$', incomplete data is received. Add to pendingData queue.
    if (!sync_data.contains(DOLLAR_UTF_CODE)) {
      pendingData.addLast(sync_data);
    }
  }

  /// Decodes the bytes and sends syncCallBack
  void _process(sync_records) {
    var startIndex = 0, endIndex = 0;
    var recordsReceived = utf8.decode(sync_records);
    while (startIndex < recordsReceived.length &&
        endIndex < recordsReceived.length) {
      var startOfRecord = recordsReceived.indexOf(TILDE_SIGN, startIndex) + 1;
      if (startOfRecord == 0) break;
      var recordLengthStr =
      recordsReceived.substring(startIndex, startOfRecord - 1);
      startIndex = startIndex + recordLengthStr.length + 1;
      endIndex = startIndex + int.parse(recordLengthStr);
      var jsonString = recordsReceived.substring(startIndex, endIndex);
      var jsonRecord = jsonDecode(jsonString);
      syncCallback!(jsonRecord);
      startIndex = endIndex + 1;
    }
  }
}