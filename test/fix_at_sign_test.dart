// ignore_for_file: unnecessary_string_escapes
import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_utils.dart';
import 'package:test/test.dart';

void main() {
  group('A group of positive atsign tests', () {
    test('atsign in upper case', () {
      var atSign = 'PHONE@BOB';
      atSign = AtUtils.fixAtSign(atSign);
      expect(atSign, 'phone@bob');
    });

    test('atsign contains .', () {
      var atSign = 'home.phone@colin.constable';
      atSign = AtUtils.fixAtSign(atSign);
      expect(atSign, 'home.phone@colinconstable');
    });
  });
  group('A group of invalid atsign test', () {
    test('empty atsign - InvalidAtSignException', () {
      var atSign = '';
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: must include one @ character and at least one character on the right')));
    });

    test('atsign without @ - InvalidAtSignException', () {
      var atSign = 'bob';
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: must include one @ character and at least one character on the right')));
    });

    test('atsign with more @ - InvalidAtSignException', () {
      var atSign = 'phone@bob@alice';
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: Cannot Contain more than one @ character')));
    });

    test('key with no atsign - InvalidAtSignException', () {
      var atSign = 'phone@';
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: must include one @ character and at least one character on the right')));
    });

    test('white spaces in atsign - InvalidAtSignException', () {
      var atSign = 'pho ne@bob';
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: Cannot Contain whitespace characters')));
    });

    test('reserved characters in atsign : + - InvalidAtSignException', () {
      var atSign = 'phone@\U+237E';
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: Cannot contain \!\*\'`\(\)\;\:\&\=\+\$\,\/\?\#\[\]\{\} characters')));
    });

    test('reserved characters with ascii codes - InvalidAtsignException', () {
      var atSign = 'phone@U' + String.fromCharCode(43);
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: Cannot contain \!\*\'`\(\)\;\:\&\=\+\$\,\/\?\#\[\]\{\} characters')));
    });

    test('reserved characters with unicode - InvalidAtsignException', () {
      var atSign = '@\u0021';
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: Cannot contain \!\*\'`\(\)\;\:\&\=\+\$\,\/\?\#\[\]\{\} characters')));
    });

    test('special characters in atsign - * InvalidAtSignException', () {
      var atSign = 'phone^:@b*b';
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: Cannot contain \!\*\'`\(\)\;\:\&\=\+\$\,\/\?\#\[\]\{\} characters')));
    });

    test('control characters in atsign - InvalidAtSignException', () {
      var atSign = 'phone@\u2400';
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: must not include control characters')));
    });

    test('control characters - InvalidAtSignException', () {
      var atSign = '@\u0019';
      expect(
          () => AtUtils.fixAtSign(atSign),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtSignException &&
              e.message ==
                  'invalid @sign: must not include control characters')));
    });

    test('Test to validate when atSign is null', () {
      var atSign = AtUtils.formatAtSign(null);
      expect(atSign, null);
    });
  });
}
