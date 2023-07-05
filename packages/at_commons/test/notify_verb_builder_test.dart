import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

import 'syntax_test.dart';

void main() {
  group('A group of notify verb builder tests to check notify command', () {
    test('notify public key', () {
      var notifyVerbBuilder = NotifyVerbBuilder()
        ..id = '123'
        ..value = 'alice@gmail.com'
        ..isPublic = true
        ..atKey = 'email'
        ..sharedBy = 'alice'
        ..ttln = 100;
      var command = notifyVerbBuilder.buildCommand();
      expect(command,
          'notify:id:123:notifier:SYSTEM:ttln:100:public:email@alice:alice@gmail.com\n');
      var params = VerbUtil.getVerbParam(VerbSyntax.notify, command.trim())!;
      expect(params.length, 7);
      expect(params[ID], '123');
      expect(params[VALUE], 'alice@gmail.com');
      expect(params[PUBLIC_SCOPE_PARAM], 'public');
      expect(params[AT_KEY], 'email');
      expect(params[AT_SIGN], 'alice');
      expect(params[NOTIFIER], 'SYSTEM');
      expect(params[AT_TTL_NOTIFICATION], '100');
    });

    test('notify public key with ttl', () {
      var notifyVerbBuilder = NotifyVerbBuilder()
        ..id = '123'
        ..value = 'alice@gmail.com'
        ..isPublic = true
        ..atKey = 'email'
        ..sharedBy = 'alice'
        ..ttl = 1000;
      var command = notifyVerbBuilder.buildCommand();
      expect(command,
          'notify:id:123:notifier:SYSTEM:ttl:1000:public:email@alice:alice@gmail.com\n');
      var params = VerbUtil.getVerbParam(VerbSyntax.notify, command.trim())!;
      expect(params.length, 7);
      expect(params[ID], '123');
      expect(params[VALUE], 'alice@gmail.com');
      expect(params[PUBLIC_SCOPE_PARAM], 'public');
      expect(params[AT_KEY], 'email');
      expect(params[AT_SIGN], 'alice');
      expect(params[AT_TTL], '1000');
      expect(params[NOTIFIER], 'SYSTEM');
    });

    test('notify shared key command', () {
      var notifyVerbBuilder = NotifyVerbBuilder()
        ..id = '123'
        ..value = 'alice@atsign.com'
        ..atKey = 'email'
        ..sharedBy = 'alice'
        ..sharedWith = 'bob'
        ..pubKeyChecksum = '123'
        ..sharedKeyEncrypted = 'abc'
        ..ttln = 100;
      var command = notifyVerbBuilder.buildCommand();
      expect(command,
          'notify:id:123:notifier:SYSTEM:ttln:100:sharedKeyEnc:abc:pubKeyCS:123:@bob:email@alice:alice@atsign.com\n');
      var params = VerbUtil.getVerbParam(VerbSyntax.notify, command.trim())!;
      expect(params.length, 9);
      expect(params[ID], '123');
      expect(params[VALUE], 'alice@atsign.com');
      expect(params[AT_KEY], 'email');
      expect(params[AT_SIGN], 'alice');
      expect(params[FOR_AT_SIGN], 'bob');
      expect(params[NOTIFIER], 'SYSTEM');
      expect(params[SHARED_WITH_PUBLIC_KEY_CHECK_SUM], '123');
      expect(params[SHARED_KEY_ENCRYPTED], 'abc');
    });

    test('notify text message with isEncrypted set to true', () {
      var notifyVerbBuilder = NotifyVerbBuilder()
        ..id = '123'
        ..value = 'alice@atsign.com'
        ..atKey = 'email'
        ..sharedBy = 'alice'
        ..sharedWith = 'bob'
        ..pubKeyChecksum = '123'
        ..sharedKeyEncrypted = 'abc'
        ..isTextMessageEncrypted = true;
      var command = notifyVerbBuilder.buildCommand();
      expect(command,
          'notify:id:123:notifier:SYSTEM:isEncrypted:true:sharedKeyEnc:abc:pubKeyCS:123:@bob:email@alice:alice@atsign.com\n');
      var params = VerbUtil.getVerbParam(VerbSyntax.notify, command.trim())!;
      expect(params.length, 9);
      expect(params[PUBLIC_SCOPE_PARAM], null);
      expect(params[ID], '123');
      expect(params[VALUE], 'alice@atsign.com');
      expect(params[AT_KEY], 'email');
      expect(params[AT_SIGN], 'alice');
      expect(params[FOR_AT_SIGN], 'bob');
      expect(params[NOTIFIER], 'SYSTEM');
      expect(params[IS_ENCRYPTED], 'true');
      expect(params[SHARED_WITH_PUBLIC_KEY_CHECK_SUM], '123');
      expect(params[SHARED_KEY_ENCRYPTED], 'abc');
    });

    test('notify with every piece of encryption metadata', () {
      var notifyVerbBuilder = NotifyVerbBuilder()
        ..id = '123'
        ..value = 'alice@atsign.com'
        ..atKey = 'email'
        ..sharedBy = 'alice'
        ..sharedWith = 'bob'
        ..pubKeyChecksum = '123'
        ..sharedKeyEncrypted = 'abc'
        ..encKeyName = 'ekn'
        ..encAlgo = 'ea'
        ..ivNonce = 'ivn'
        ..skeEncKeyName = 'ske_ekn'
        ..skeEncAlgo = 'ske_ea';
      var command = notifyVerbBuilder.buildCommand();
      expect(
          command,
          'notify:id:123:notifier:SYSTEM'
          ':sharedKeyEnc:abc:pubKeyCS:123'
          ':encKeyName:ekn:encAlgo:ea:ivNonce:ivn'
          ':skeEncKeyName:ske_ekn:skeEncAlgo:ske_ea'
          ':@bob:email@alice:alice@atsign.com\n');
      var params = VerbUtil.getVerbParam(VerbSyntax.notify, command.trim())!;
      expect(params.length, 13);
      expect(params[PUBLIC_SCOPE_PARAM], null);
      expect(params[ID], '123');
      expect(params[VALUE], 'alice@atsign.com');
      expect(params[AT_KEY], 'email');
      expect(params[AT_SIGN], 'alice');
      expect(params[FOR_AT_SIGN], 'bob');
      expect(params[NOTIFIER], 'SYSTEM');
      expect(params[SHARED_WITH_PUBLIC_KEY_CHECK_SUM], '123');
      expect(params[SHARED_KEY_ENCRYPTED], 'abc');
      expect(params[ENCRYPTING_KEY_NAME], 'ekn');
      expect(params[ENCRYPTING_ALGO], 'ea');
      expect(params[IV_OR_NONCE], 'ivn');
      expect(params[SHARED_KEY_ENCRYPTED_ENCRYPTING_KEY_NAME], 'ske_ekn');
      expect(params[SHARED_KEY_ENCRYPTED_ENCRYPTING_ALGO], 'ske_ea');
    });
  });

  try {
    group('A group of tests to verify notification id generation', () {
      // The below test validates the following:
      //  1. custom notification id overrides default notification id
      //  2. IsEncrypted flag when set true is added to verb params.
      test('Test to verify all notify fields in the verb builder', () {
        var verbHandler = NotifyVerbBuilder()
          ..id = 'abc-123'
          ..atKey = 'phone'
          ..sharedWith = '@alice'
          ..sharedBy = '@bob'
          ..isTextMessageEncrypted = true;

        var notifyCommand = verbHandler.buildCommand();
        var verbParams = getVerbParams(VerbSyntax.notify, notifyCommand.trim());
        expect(verbParams[ID], 'abc-123');
        expect(verbParams[IS_ENCRYPTED], 'true');
      });

      // The below test validates the following:
      //  1. Default notification id is generated
      //  2. IsEncrypted flag is not set by default.
      test('Test to verify default notification id is generated', () {
        var verbHandler = NotifyVerbBuilder()
          ..atKey = 'phone'
          ..sharedWith = '@alice'
          ..sharedBy = '@bob';

        var notifyCommand = verbHandler.buildCommand();
        var verbParams = getVerbParams(VerbSyntax.notify, notifyCommand.trim());
        expect(verbParams[ID] != null, true);
        expect(verbParams[IS_ENCRYPTED], null);
      });
      test('Test to verify custom set notification id to verb builder', () {
        var verbHandler = NotifyVerbBuilder()
          ..id = 'abc-123'
          ..atKey = 'phone'
          ..sharedWith = '@alice'
          ..sharedBy = '@bob';

        var notifyCommand = verbHandler.buildCommand();
        var verbParams = getVerbParams(VerbSyntax.notify, notifyCommand.trim());
        expect(verbParams[ID], 'abc-123');
      });
    });
  } catch (e, s) {
    print(s);
  }

  group('A group of test to validate notify fetch verb', () {
    test('Test to verify to notify:fetch', () {
      var notifyFetch = NotifyFetchVerbBuilder()..notificationId = '123';
      var notifyFetchCommand = notifyFetch.buildCommand();
      expect(notifyFetchCommand, 'notify:fetch:123\n');
      var verbParams =
          getVerbParams(VerbSyntax.notifyFetch, notifyFetchCommand.trim());
      expect(verbParams['notificationId'], '123');
    });

    test('Negative test to verify to notify:fetch when notification id not set',
        () {
      var notifyFetch = NotifyFetchVerbBuilder();
      expect(() => notifyFetch.buildCommand(),
          throwsA(predicate((dynamic e) => e is InvalidSyntaxException)));
    });

    test('Negative test to verify to notify:fetch when empty string is set',
        () {
      var notifyFetch = NotifyFetchVerbBuilder()..notificationId = '';
      expect(() => notifyFetch.buildCommand(),
          throwsA(predicate((dynamic e) => e is InvalidSyntaxException)));
    });
  });
}
