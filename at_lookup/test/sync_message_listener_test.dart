import 'dart:convert';

import 'package:at_lookup/src/connection/outbound_sync_message_listener.dart';
import 'package:test/test.dart';

var demo_data = {
  'public:publickey@responsibleplum': jsonEncode({
    'atKey': 'public:publickey@responsibleplum',
    'operation': '+',
    'opTime': '2021-03-08 20:03:15.278',
    'commitId': 0,
    'value':
        'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ#8AM\$IIBCgKCAQEAlGeVHT5LZbBQ+/GKi8eymOXsCpQ/0AkgQ16SEgysi47'
  }),
  'public:contentKey@alice': jsonEncode({
    'atKey': 'public:contentKey@alice',
    'operation': '+',
    'opTime': '2021-03-08 20:03:15.278',
    'commitId': 0,
    'value':
        'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AM#IIBCgKCAQEAlGeVHT\$5LZbBQ+/GKi8eymOXsCpQ/0AkgQ16SEgysi47'
  })
};

void main() {
  test('test to verify with separator in the content', () {
    var input = demo_data['public:publickey@responsibleplum'];
    var sync_data = utf8.encode('${input.length}#$input\$');
    var sync = SyncMessageListener(null);
    sync.syncCallback = validate;
    sync.messageHandler(sync_data);
  });

  test('test to verify pending data', () {
    var input = demo_data['public:contentKey@alice'];
    List sync_data = utf8.encode('${input.length}#$input\$');
    var sync = SyncMessageListener(null);
    sync.syncCallback = validate;
    var midIndex = sync_data.length ~/ 2;
    var sync_data_1 = sync_data.sublist(0, midIndex);
    var sync_data_2 = sync_data.sublist(midIndex, sync_data.length);
    sync.messageHandler(sync_data_1);
    sync.messageHandler(sync_data_2);
  });

  test('test to verify multiple records', () {
    var data1 = demo_data['public:contentKey@alice'];
    var data2 = demo_data['public:publickey@responsibleplum'];
    List sync_data =
        utf8.encode('${data1.length}#$data1\$${data2.length}#$data2\$');
    var sync = SyncMessageListener(null);
    sync.syncCallback = validate;
    sync.messageHandler(sync_data);
  });
}

void validate(dynamic syncResponse) {
  Map actualResponse = jsonDecode(demo_data[syncResponse['atKey']]);
  actualResponse.keys.forEach((element) {
    expect(syncResponse[element], actualResponse[element]);
  });
}
