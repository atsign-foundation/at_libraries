import 'dart:collection';

import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests to verify notify verb regex', () {
    test('Test to verify notify verb with encryptedSharedKey and checksum', () {
      var command =
          'notify:update:priority:low:strategy:all:latestN:1:sharedKeyEnc:GxIjM8e/nsga3:pubKeyCS:5d52f6f2868:@bob:phone.wavi@alice:989745456';
      var verbParams = getVerbParams(VerbSyntax.notify, command);
      expect(verbParams[OPERATION], 'update');
      expect(verbParams[SHARED_KEY_ENCRYPTED], 'GxIjM8e/nsga3');
      expect(verbParams[SHARED_WITH_PUBLIC_KEY_CHECK_SUM], '5d52f6f2868');
      expect(verbParams[PRIORITY], 'low');
      expect(verbParams[LATEST_N], '1');
      expect(verbParams[VALUE], '989745456');
      expect(verbParams[STRATEGY], 'all');
    });

    test('Test to verify notify verb with delete operation', () {
      var command =
          'notify:delete:priority:low:strategy:all:latestN:1:sharedKeyEnc:GxIjM8e/nsga3:pubKeyCS:5d52f6f2868:@bob:phone.wavi@alice:989745456';
      var verbParams = getVerbParams(VerbSyntax.notify, command);
      expect(verbParams[OPERATION], 'delete');
      expect(verbParams[SHARED_KEY_ENCRYPTED], 'GxIjM8e/nsga3');
      expect(verbParams[SHARED_WITH_PUBLIC_KEY_CHECK_SUM], '5d52f6f2868');
      expect(verbParams[PRIORITY], 'low');
      expect(verbParams[LATEST_N], '1');
      expect(verbParams[VALUE], '989745456');
      expect(verbParams[STRATEGY], 'all');
    });
  });

  group('A group of tests to verify notify delete verb', () {
    test('Valid id sent to notify delete', () {
      var command = 'notify:remove:abcd-1234';
      var verbParams = getVerbParams(VerbSyntax.notifyRemove, command);
      expect(verbParams[ID], 'abcd-1234');
    });

    test('id not sent to notify delete', () {
      var command = 'notify:remove:';
      expect(
          () => getVerbParams(VerbSyntax.notifyRemove, command),
          throwsA(predicate((dynamic e) =>
              e is InvalidSyntaxException &&
              e.message == 'command does not match the regex')));
    });
  });
  group('A group of tests to verify pkam verb regex', () {
    test('pkam regex without signing algo', () {
      var command = 'pkam:abcd1234';
      var verbParams = getVerbParams(VerbSyntax.pkam, command);
      expect(verbParams[AT_PKAM_SIGNATURE], 'abcd1234');
    });
    test('pkam regex with rsa signing algo', () {
      var command = 'pkam:signingAlgo:rsa256:abcd1234';
      var verbParams = getVerbParams(VerbSyntax.pkam, command);
      expect(verbParams[AT_PKAM_SIGNING_ALGO], 'rsa256');
      expect(verbParams[AT_PKAM_SIGNATURE], 'abcd1234');
    });
    test('pkam regex with ecc signing algo', () {
      var command = 'pkam:signingAlgo:ecc_secp256r1:abcd1234';
      var verbParams = getVerbParams(VerbSyntax.pkam, command);
      expect(verbParams[AT_PKAM_SIGNING_ALGO], 'ecc_secp256r1');
      expect(verbParams[AT_PKAM_SIGNATURE], 'abcd1234');
    });
    test('pkam regex with invalid signing algo', () {
      var command = 'pkam:signingAlgo:ecc:abcd1234';
      var verbParams = getVerbParams(VerbSyntax.pkam, command);
      expect(verbParams[AT_PKAM_SIGNING_ALGO], isNull);
    });
  });
}

Map getVerbParams(String regex, String command) {
  var regExp = RegExp(regex, caseSensitive: false);
  if (!regExp.hasMatch(command)) {
    throw InvalidSyntaxException('command does not match the regex');
  }
  var regexMatches = regExp.allMatches(command);
  var paramsMap = HashMap<String, String?>();
  for (var f in regexMatches) {
    for (var name in f.groupNames) {
      paramsMap.putIfAbsent(name, () => f.namedGroup(name));
    }
  }
  return paramsMap;
}
