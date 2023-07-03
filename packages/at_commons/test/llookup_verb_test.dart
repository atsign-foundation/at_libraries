import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

void main() {
  group('A group tests to validate llookup verb builder', () {
    test('test to build local key', () {
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..isLocal = true
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(llookupVerbBuilder.buildCommand(), 'llookup:local:phone@bob\n');
    });

    test('test to build sharedWith key', () {
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..sharedWith = '@alice'
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(llookupVerbBuilder.buildCommand(), 'llookup:@alice:phone@bob\n');
    });

    test('test to build public key', () {
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..isPublic = true
        ..atKey = 'phone'
        ..sharedBy = '@bob'
        ..sharedWith = null;

      expect(llookupVerbBuilder.buildCommand(), 'llookup:public:phone@bob\n');
    });

    test('test to build cached-sharedWith key', () {
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..isCached = true
        ..sharedWith = '@alice'
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(llookupVerbBuilder.buildCommand(),
          'llookup:cached:@alice:phone@bob\n');
    });

    test('test to build cached-public key', () {
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..isCached = true
        ..isPublic = true
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(llookupVerbBuilder.buildCommand(),
          'llookup:cached:public:phone@bob\n');
    });

    test('test to verify cached local key throws invalid atkey exception', () {
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..isCached = true
        ..isLocal = true
        ..sharedWith = '@alice'
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(
          () => llookupVerbBuilder.buildCommand(),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message ==
                  'sharedWith must be null when isLocal is set to true')));
    });

    test(
        'test to verify local key with isPublic set to true throws invalid atkey exception',
        () {
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..isPublic = true
        ..isLocal = true
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(
          () => llookupVerbBuilder.buildCommand(),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message ==
                  'When isLocal is set to true, cannot set isPublic to true or set a non-null sharedWith')));
    });

    test(
        'test to verify local key with sharedWith populated throws invalid atkey exception',
        () {
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..isLocal = true
        ..sharedWith = '@alice'
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(
          () => llookupVerbBuilder.buildCommand(),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message ==
                  'sharedWith must be null when isLocal is set to true')));
    });

    test(
        'test to verify isPublic set to true with sharedWith populated throws invalid atkey exception',
        () {
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..isPublic = true
        ..sharedWith = '@alice'
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(
          () => llookupVerbBuilder.buildCommand(),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message ==
                  'When isPublic is set to true, sharedWith cannot be populated')));
    });

    test('test to verify Key cannot be null or empty', () {
      var llookupVerbBuilder = LLookupVerbBuilder()
        ..sharedWith = '@alice'
        ..atKey = ''
        ..sharedBy = '@bob';

      expect(
          () => llookupVerbBuilder.buildCommand(),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message == 'Key cannot be null or empty')));
    });
  });
}
