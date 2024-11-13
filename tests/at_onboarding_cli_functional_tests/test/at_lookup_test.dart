import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_demo_data/at_demo_data.dart' as at_demos;
import 'package:at_lookup/at_lookup.dart';
import 'package:at_chops/at_chops.dart';

import 'package:test/test.dart';

void main() {
  String atSign = '@bob🛠';
  AtChops atChopsKeys = createAtChopsFromDemoKeys(atSign);

  group('A group of tests to assert on authenticate functionality', () {
    test(
        'A test to verify a websocket connection and do a cram authenticate and scan',
        () async {
      var atLookup =
          AtLookupImpl(atSign, 'vip.ve.atsign.zone', 64, useWebSocket: true);
      await atLookup.cramAuthenticate(at_demos.cramKeyMap[atSign]!);
      var command = 'scan\n';
      var response = await atLookup.executeCommand(command, auth: true);
      expect(response, contains('public:signing_publickey$atSign'));
    });

     test(
        'A test to verify a socket connection by passing useWebSocket to false and do a cram authenticate and scan',
        () async {
      var atLookup =
          AtLookupImpl(atSign, 'vip.ve.atsign.zone', 64, useWebSocket: true);
      await atLookup.cramAuthenticate(at_demos.cramKeyMap[atSign]!);
      var command = 'scan\n';
      var response = await atLookup.executeCommand(command, auth: true);
      expect(response, contains('public:signing_publickey$atSign'));
    });

    test(
        'A test to verify a websocket connection and do a cram authenticate and update',
        () async {
      var atLookup =
          AtLookupImpl(atSign, 'vip.ve.atsign.zone', 64, useWebSocket: true);
      await atLookup.cramAuthenticate(at_demos.cramKeyMap[atSign]!);
      // update public and private keys manually
      var command =
          'update:privatekey:at_pkam_publickey ${at_demos.pkamPublicKeyMap[atSign]}\n';
      var response = await atLookup.executeCommand(command, auth: true);
      expect(response, 'data:-1');
      command =
          'update:public:publickey${atSign} ${at_demos.encryptionPublicKeyMap[atSign]}\n';
      await atLookup.executeCommand(command, auth: true);
      print(response);
      assert((!response!.contains('Invalid syntax')) &&
          (!response.contains('null')));
    });

    test(
        'A test to verify a websocket connection and do a pkam authenticate and executeCommand',
        () async {
      var atLookup =
          AtLookupImpl(atSign, 'vip.ve.atsign.zone', 64, useWebSocket: true);
      atLookup.atChops = atChopsKeys;
      await atLookup.pkamAuthenticate();
      var command = 'update:public:username$atSign bob123\n';
      var response = await atLookup.executeCommand(command, auth: true);
      assert((!response!.contains('Invalid syntax')) &&
          (!response.contains('null')));
    });

    test(
        'A test to verify a websocket connection and do a pkam authenticate and execute verb',
        () async {
      var atLookup =
          AtLookupImpl(atSign, 'vip.ve.atsign.zone', 64, useWebSocket: true);
      atLookup.atChops = atChopsKeys;
      await atLookup.pkamAuthenticate();
      var atKey = 'key1';
      String value = 'value1';
      var updateBuilder = UpdateVerbBuilder()
        ..value = 'value1'
        ..atKey = (AtKey()
          ..key = atKey
          ..sharedBy = atSign
          ..metadata = (Metadata()..isPublic = true));
      var response = await atLookup.executeVerb(updateBuilder);
      print(response);
      assert((!response.contains('Invalid syntax')) &&
          (!response.contains('null')));
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..atKey = (AtKey()
          ..key = atKey
          ..sharedBy = atSign
          ..metadata = (Metadata()..isPublic = true));
      response = await atLookup.executeVerb(llookupVerbBuilder);
      expect(response, contains(value));
    }, timeout: Timeout(Duration(minutes: 5)));
  });
}

AtChops createAtChopsFromDemoKeys(String atSign) {
  var atEncryptionKeyPair = AtEncryptionKeyPair.create(
      at_demos.encryptionPublicKeyMap[atSign]!,
      at_demos.encryptionPrivateKeyMap[atSign]!);
  var atPkamKeyPair = AtPkamKeyPair.create(
      at_demos.pkamPublicKeyMap[atSign]!, at_demos.pkamPrivateKeyMap[atSign]!);
  final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, atPkamKeyPair);
  atChopsKeys.selfEncryptionKey = AESKey(at_demos.aesKeyMap[atSign]!);
  return AtChopsImpl(atChopsKeys);
}
