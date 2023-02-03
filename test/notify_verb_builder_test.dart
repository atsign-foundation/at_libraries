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
        ..sharedBy = 'alice';
      var command = notifyVerbBuilder.buildCommand();
      expect(command,
          'notify:id:123:notifier:SYSTEM:public:email@alice:alice@gmail.com\n');
      var params = VerbUtil.getVerbParam(VerbSyntax.notify, command.trim())!;
      expect(params[ID], '123');
      expect(params[VALUE], 'alice@gmail.com');
      expect(params[IS_PUBLIC], 'true');
      expect(params[AT_KEY], 'email');
      expect(params[AT_SIGN], 'alice');
    });

    test('notify public key with ttl', () {
      var notifyVerbBuilder = NotifyVerbBuilder()
        ..id = '123'
        ..value = 'alice@gmail.com'
        ..isPublic = true
        ..atKey = 'email'
        ..sharedBy = 'alice'
        ..ttl = 1000;
      expect(notifyVerbBuilder.buildCommand(),
          'notify:id:123:notifier:SYSTEM:ttl:1000:public:email@alice:alice@gmail.com\n');
    });

    test('notify shared key command', () {
      var notifyVerbBuilder = NotifyVerbBuilder()
        ..id = '123'
        ..value = 'alice@atsign.com'
        ..atKey = 'email'
        ..sharedBy = 'alice'
        ..sharedWith = 'bob'
        ..pubKeyChecksum = '123'
        ..sharedKeyEncrypted = 'abc';
      expect(notifyVerbBuilder.buildCommand(),
          'notify:id:123:notifier:SYSTEM:sharedKeyEnc:abc:pubKeyCS:123:@bob:email@alice:alice@atsign.com\n');
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
      expect(notifyVerbBuilder.buildCommand(),
          'notify:id:123:notifier:SYSTEM:isEncrypted:true:sharedKeyEnc:abc:pubKeyCS:123:@bob:email@alice:alice@atsign.com\n');
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
