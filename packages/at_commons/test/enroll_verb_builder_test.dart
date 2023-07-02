import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/verb/enroll_verb_builder.dart';
import 'package:test/test.dart';

void main() {
  group('A group of enroll verb builder tests', () {
    test('enroll verb - check enroll request build command', () {
      var enrollVerbBuilder = EnrollVerbBuilder()
        ..operation = EnrollOperationEnum.request
        ..appName = 'wavi'
        ..deviceName = 'pixel'
        ..namespaces = ['wavi,rw', '__manage,r']
        ..apkamPublicKey = 'abcd1234';
      var command = enrollVerbBuilder.buildCommand();
      expect(command,
          'enroll:request:appName:wavi:deviceName:pixel:namespaces:[wavi,rw;__manage,r]:apkamPublicKey:abcd1234\n');
    });
    test('enroll verb - check enroll approve build command', () {
      var enrollVerbBuilder = EnrollVerbBuilder()
        ..operation = EnrollOperationEnum.approve
        ..appName = 'wavi'
        ..deviceName = 'pixel'
        ..namespaces = ['wavi,rw']
        ..apkamPublicKey = 'abcd1234';
      var command = enrollVerbBuilder.buildCommand();
      expect(command,
          'enroll:approve:appName:wavi:deviceName:pixel:namespaces:[wavi,rw]:apkamPublicKey:abcd1234\n');
    });
    test('enroll verb - check enroll deny build command', () {
      var enrollVerbBuilder = EnrollVerbBuilder()
        ..operation = EnrollOperationEnum.approve
        ..appName = 'wavi'
        ..deviceName = 'pixel'
        ..totp = 3446
        ..namespaces = ['wavi,rw', '__manage,r']
        ..apkamPublicKey = 'abcd1234';
      var command = enrollVerbBuilder.buildCommand();
      expect(command,
          'enroll:approve:appName:wavi:deviceName:pixel:namespaces:[wavi,rw;__manage,r]:totp:3446:apkamPublicKey:abcd1234\n');
    });

    test('enroll verb - check enroll request verb params', () {
      var enrollVerbBuilder = EnrollVerbBuilder()
        ..operation = EnrollOperationEnum.request
        ..appName = 'wavi'
        ..deviceName = 'pixel'
        ..namespaces = ['wavi,rw', '__manage,r']
        ..totp = 1234
        ..apkamPublicKey = 'abcd1234';

      var command = enrollVerbBuilder.buildCommand();
      print(command);
      try {
        var params = VerbUtil.getVerbParam(VerbSyntax.enroll, command.trim())!;
        expect(params['operation'], 'request');
        expect(params['appName'], 'wavi');
        expect(params['deviceName'], 'pixel');
        expect(params['namespaces'], 'wavi,rw;__manage,r');
        expect(params['totp'], '1234');
        expect(params['apkamPublicKey'], 'abcd1234');
      } catch(e, trace) {
        print(trace);
      }
    });

    test('enroll verb - invalid syntax - no app name', () {
      var command =
          'enroll:request:deviceName:pixel:namespaces:wavi,rw;__manage,r:apkamPublicKey:abcd1234';
      var params = VerbUtil.getVerbParam(VerbSyntax.enroll, command.trim());
      expect(params, null);
    });

    test('enroll verb - invalid syntax - no device name', () {
      var command =
          'enroll:request:appName:wavi:namespaces:wavi,rw;__manage,r:apkamPublicKey:abcd1234';
      var params = VerbUtil.getVerbParam(VerbSyntax.enroll, command.trim());
      expect(params, null);
    });

    test('enroll verb - invalid syntax - no namespace', () {
      var command =
          'enroll:request:appName:wavi:deviceName:pixel:apkamPublicKey:abcd1234';
      var params = VerbUtil.getVerbParam(VerbSyntax.enroll, command.trim())!;
      expect(params['namespaces'], null);
    });
    test('enroll verb - invalid syntax - no apkam public key', () {
      var command =
          'enroll:request:appName:wavi:deviceName:pixel:namespaces:wavi,r;_manage';
      var params = VerbUtil.getVerbParam(VerbSyntax.enroll, command.trim());
      expect(params, null);
    });
  });
}
