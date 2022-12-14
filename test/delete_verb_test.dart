import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

void main() {
  group('A group tests to validate delete verb builder', () {
    test('test to verify deletion command for a local key', () {
      var deleteVerbBuilder = DeleteVerbBuilder()
        ..isLocal = true
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(deleteVerbBuilder.buildCommand(), 'delete:local:phone@bob\n');
    });

    test('test to deletion of shared key', () {
      var deleteVerbBuilder = DeleteVerbBuilder()
        ..atKey = 'phone'
        ..sharedBy = '@bob'
        ..sharedWith = '@alice';

      expect(deleteVerbBuilder.buildCommand(), 'delete:@alice:phone@bob\n');
    });

    test('test to deletion of public key', () {
      var deleteVerbBuilder = DeleteVerbBuilder()
        ..isPublic = true
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(deleteVerbBuilder.buildCommand(), 'delete:public:phone@bob\n');
    });
  });

  group('A group of tests to validate the exceptions',(){
    test('test to verify cached local key throws invalid atkey exception', () {
      var deleteVerbBuilder = DeleteVerbBuilder()
        ..isCached = true
        ..isLocal = true
        ..sharedWith = '@alice'
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(
              () => deleteVerbBuilder.buildCommand(),
          throwsA(predicate((dynamic e) =>
          e is InvalidAtKeyException &&
              e.message ==
                  'sharedWith must be null when isLocal is set to true')));
    });

    test(
        'test to verify isPublic set to true with sharedWith populated throws invalid atkey exception',
            () {
          var deleteVerbBuilder = DeleteVerbBuilder()
            ..isPublic = true
            ..sharedWith = '@alice'
            ..atKey = 'phone'
            ..sharedBy = '@bob';

          expect(
                  () => deleteVerbBuilder.buildCommand(),
              throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
                  e.message ==
                      'When isPublic is set to true, sharedWith cannot be populated')));
        });

    test('test to verify Key cannot be null or empty', () {
      var deleteVerbBuilder = DeleteVerbBuilder()
        ..sharedWith = '@alice'
        ..atKey = ''
        ..sharedBy = '@bob';

      expect(
              () => deleteVerbBuilder.buildCommand(),
          throwsA(predicate((dynamic e) =>
          e is InvalidAtKeyException &&
              e.message == 'Key cannot be null or empty')));
    });
  });
}
