import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

import 'syntax_test.dart';

void main() {
  group('A group of update verb builder tests to check update command', () {
    test('verify public at key command', () {
      var updateBuilder = UpdateVerbBuilder()
        ..value = 'alice@gmail.com'
        ..isPublic = true
        ..atKey = 'email'
        ..sharedBy = 'alice';
      expect(updateBuilder.buildCommand(),
          'update:public:email@alice alice@gmail.com\n');
    });

    test('verify private at key command', () {
      var updateBuilder = UpdateVerbBuilder()
        ..value = 'alice@atsign.com'
        ..atKey = 'email'
        ..sharedBy = 'alice';
      expect(updateBuilder.buildCommand(),
          'update:email@alice alice@atsign.com\n');
    });

    test('verify update command with the shared symmetric key inline and encrypted', () {
      var pubKeyCS = 'the_checksum_of_the_public_key_used_to_encrypted_the_AES_key';
      var ske = 'the_AES_key__encrypted_with_some_public_key__encoded_as_base64';
      var skeEncKeyName = 'key_45678.__public_keys.__global';
      var skeEncAlgo = 'ECC/SomeCurveName/blah';
      var updateBuilder = UpdateVerbBuilder()
        ..value = 'alice@atsign.com'
        ..atKey = 'email.wavi'
        ..sharedBy = 'alice'
        ..sharedWith = 'bob'
        ..pubKeyChecksum = pubKeyCS
        ..sharedKeyEncrypted = ske
        ..skeEncKeyName = skeEncKeyName
        ..skeEncAlgo = skeEncAlgo
      ;
      var updateCommand = updateBuilder.buildCommand();
      expect(
          updateCommand,
          'update'
          ':sharedKeyEnc:$ske'
          ':pubKeyCS:$pubKeyCS'
          ':skeEncKeyName:$skeEncKeyName'
          ':skeEncAlgo:$skeEncAlgo'
          ':@bob:email.wavi@alice alice@atsign.com'
          '\n');
      var updateVerbParams = getVerbParams(VerbSyntax.update, updateCommand.trim());
      expect (updateVerbParams[AT_KEY], 'email.wavi');
      expect (updateVerbParams[AT_SIGN], 'alice');
      expect (updateVerbParams[FOR_AT_SIGN], 'bob');
      expect (updateVerbParams[SHARED_WITH_PUBLIC_KEY_CHECK_SUM], pubKeyCS);
      expect (updateVerbParams[SHARED_KEY_ENCRYPTED], ske);
      expect (updateVerbParams[SHARED_KEY_ENCRYPTED_ENCRYPTING_KEY_NAME], skeEncKeyName);
      expect (updateVerbParams[SHARED_KEY_ENCRYPTED_ENCRYPTING_ALGO], skeEncAlgo);
    });

    test('verify local key command', () {
      var updateBuilder = UpdateVerbBuilder()
        ..value = 'alice@atsign.com'
        ..atKey = 'email'
        ..sharedBy = 'alice'
        ..isLocal = true;
      expect(updateBuilder.buildCommand(),
          'update:local:email@alice alice@atsign.com\n');
    });
  });

  group('A group of update verb builder tests to check update metadata command',
      () {
    test('verify isBinary metadata', () {
      var updateBuilder = UpdateVerbBuilder()
        ..isBinary = true
        ..atKey = 'phone'
        ..sharedBy = 'alice';
      expect(updateBuilder.buildCommandForMeta(),
          'update:meta:phone@alice:isBinary:true\n');
    });

    test('verify ttl metadata', () {
      var updateBuilder = UpdateVerbBuilder()
        ..ttl = 60000
        ..atKey = 'phone'
        ..sharedBy = 'alice';
      expect(updateBuilder.buildCommandForMeta(),
          'update:meta:phone@alice:ttl:60000\n');
    });

    test('verify ttr metadata', () {
      var updateBuilder = UpdateVerbBuilder()
        ..ttr = 50000
        ..atKey = 'phone'
        ..sharedBy = 'alice';
      expect(updateBuilder.buildCommandForMeta(),
          'update:meta:phone@alice:ttr:50000\n');
    });

    test('verify ttb metadata', () {
      var updateBuilder = UpdateVerbBuilder()
        ..ttb = 80000
        ..atKey = 'phone'
        ..sharedBy = 'alice';
      expect(updateBuilder.buildCommandForMeta(),
          'update:meta:phone@alice:ttb:80000\n');
    });

    test('verify update:meta command with the shared symmetric key inline and encrypted ', () {
      var pubKeyCS = 'the_checksum_of_the_public_key_used_to_encrypted_the_AES_key';
      var ske = 'the_AES_key__encrypted_with_some_public_key__encoded_as_base64';
      var skeEncKeyName = 'key_45678.__public_keys.__global';
      var skeEncAlgo = 'ECC/SomeCurveName/blah';
      var updateBuilder = UpdateVerbBuilder()
        ..isEncrypted = true
        ..atKey = 'cabbages_and_kings.wonderland'
        ..sharedBy = 'walrus'
        ..sharedWith = 'carpenter'
        ..pubKeyChecksum = pubKeyCS
        ..sharedKeyEncrypted = ske
        ..skeEncKeyName = skeEncKeyName
        ..skeEncAlgo = skeEncAlgo
      ;
      var updateMetaCommand = updateBuilder.buildCommandForMeta();
      expect(
          updateMetaCommand,
          'update:meta:@carpenter:cabbages_and_kings.wonderland@walrus:isEncrypted:true'
          ':sharedKeyEnc:$ske'
          ':pubKeyCS:$pubKeyCS'
          ':skeEncKeyName:$skeEncKeyName'
          ':skeEncAlgo:$skeEncAlgo'
          '\n');
      var updateMetaVerbParams = getVerbParams(VerbSyntax.update_meta, updateMetaCommand.trim());
      expect (updateMetaVerbParams[AT_KEY], 'cabbages_and_kings.wonderland');
      expect (updateMetaVerbParams[AT_SIGN], 'walrus');
      expect (updateMetaVerbParams[FOR_AT_SIGN], 'carpenter');
      expect (updateMetaVerbParams[SHARED_WITH_PUBLIC_KEY_CHECK_SUM], pubKeyCS);
      expect (updateMetaVerbParams[SHARED_KEY_ENCRYPTED], ske);
      expect (updateMetaVerbParams[SHARED_KEY_ENCRYPTED_ENCRYPTING_KEY_NAME], skeEncKeyName);
      expect (updateMetaVerbParams[SHARED_KEY_ENCRYPTED_ENCRYPTING_ALGO], skeEncAlgo);
    });
  });

  group('A group of positive tests to validate the update regex', () {
    var inputToExpectedOutput = {
      'update:ttl:10000:ttb:10000:ttr:10000:ccd:true:dataSignature:123456:encoding:base64:public:phone@bob 12345':
          {
        'ttl': '10000',
        'ttb': '10000',
        'ttr': '10000',
        'ccd': 'true',
        'dataSignature': '123456',
        'encoding': 'base64',
        'forAtSign': null,
        'atKey': 'phone',
        'atSign': 'bob',
        'value': '12345'
      }
    };
    inputToExpectedOutput.forEach((command, expectedVerbParams) {
      test('validating regex for $command', () {
        var actualVerbParams = getVerbParams(VerbSyntax.update, command);
        for (var key in expectedVerbParams.keys) {
          expect(actualVerbParams[key], expectedVerbParams[key]);
        }
      });
    });
    test('Validate the update command when encKeyName, encAlgo are set, but not ivNonce', () {
      var encKeyName = 'key_23456.__public_keys.__global';
      var encAlgo = 'RSA';
      final updateCommand =
          'update'
          ':ttl:-1:ttr:-1'
          ':dataSignature:abc:isBinary:false:isEncrypted:false'
          ':encKeyName:$encKeyName'
          ':encAlgo:$encAlgo'
          ':@bob:kryz.kryz_9850@alice {"stationName":"KRYZ","frequency":"98.5 Mhz"}';
      var updateVerbParams = getVerbParams(VerbSyntax.update, updateCommand);
      expect(updateVerbParams[AT_TTL], '-1');
      expect(updateVerbParams[AT_TTR], '-1');
      expect(updateVerbParams[AT_KEY], 'kryz.kryz_9850');
      expect(updateVerbParams[AT_SIGN], 'alice');
      expect(updateVerbParams[FOR_AT_SIGN], 'bob');
      expect(updateVerbParams[ENCRYPTING_KEY_NAME], encKeyName);
      expect(updateVerbParams[ENCRYPTING_ALGO], encAlgo);
      expect(updateVerbParams[IV_OR_NONCE], null);
    });
    test('Validate the update:meta command when encKeyName, encAlgo and ivNonce are set', () {
      var encKeyName = 'some_symmetric_key_name.some_app_namespace';
      var encAlgo = 'AES/SIC/PKCS7Padding';
      var ivNonce = 'ABCDEF12456';
      final updateMetaCommand =
          'update:meta:@bob:kryz.kryz_9850@alice'
          ':ttl:-1:ttb:1000000:ttr:-1'
          ':dataSignature:abc:isBinary:false:isEncrypted:false'
          ':encKeyName:$encKeyName'
          ':encAlgo:$encAlgo'
          ':ivNonce:$ivNonce'
          ;
      var updateMetaVerbParams = getVerbParams(VerbSyntax.update_meta, updateMetaCommand);
      expect(updateMetaVerbParams[AT_TTL], '-1');
      expect(updateMetaVerbParams[AT_TTR], '-1');
      expect(updateMetaVerbParams[AT_KEY], 'kryz.kryz_9850');
      expect(updateMetaVerbParams[AT_SIGN], 'alice');
      expect(updateMetaVerbParams[FOR_AT_SIGN], 'bob');
      expect(updateMetaVerbParams[ENCRYPTING_KEY_NAME], encKeyName);
      expect(updateMetaVerbParams[ENCRYPTING_ALGO], encAlgo);
      expect(updateMetaVerbParams[IV_OR_NONCE], ivNonce);
    });
    test('validate update command with negative ttl and ttr', () {
      final updateCommand =
          'update:ttl:-1:ttr:-1:dataSignature:abc:isBinary:false:isEncrypted:false:public:kryz.kryz_9850@kryz_9850 {"stationName":"KRYZ","frequency":"98.5 Mhz"}';
      var actualVerbParams = getVerbParams(VerbSyntax.update, updateCommand);
      expect(actualVerbParams[AT_TTL], '-1');
      expect(actualVerbParams[AT_TTR], '-1');
      expect(actualVerbParams[AT_KEY], 'kryz.kryz_9850');
      expect(actualVerbParams[AT_SIGN], 'kryz_9850');
    });
    test('validate update command with negative ttl and ttb', () {
      final updateCommand =
          'update:ttl:-1:ttb:-1:dataSignature:abc:isBinary:false:isEncrypted:false:public:kryz.kryz_9850@kryz_9850 {"stationName":"KRYZ","frequency":"98.5 Mhz"}';
      var actualVerbParams = getVerbParams(VerbSyntax.update, updateCommand);
      expect(actualVerbParams[AT_TTL], '-1');
      expect(actualVerbParams[AT_TTB], '-1');
      expect(actualVerbParams[AT_KEY], 'kryz.kryz_9850');
      expect(actualVerbParams[AT_SIGN], 'kryz_9850');
    });
    test('validate update meta command with negative ttl and ttr', () {
      final updateCommand =
          'update:meta:public:kryz.kryz_9850@kryz_9850:ttl:-1:ttr:-1';
      var actualVerbParams =
          getVerbParams(VerbSyntax.update_meta, updateCommand);
      expect(actualVerbParams[AT_TTL], '-1');
      expect(actualVerbParams[AT_TTR], '-1');
      expect(actualVerbParams[AT_KEY], 'kryz.kryz_9850');
      expect(actualVerbParams[AT_SIGN], 'kryz_9850');
    });
    test('validate update meta command with negative ttl and ttb', () {
      final updateCommand =
          'update:meta:public:kryz.kryz_9850@kryz_9850:ttl:-1:ttb:-1';
      var actualVerbParams =
          getVerbParams(VerbSyntax.update_meta, updateCommand);
      expect(actualVerbParams[AT_TTL], '-1');
      expect(actualVerbParams[AT_TTB], '-1');
      expect(actualVerbParams[AT_KEY], 'kryz.kryz_9850');
      expect(actualVerbParams[AT_SIGN], 'kryz_9850');
    });
  });

  group('A group of negative test on update verb regex', () {
    test('update verb with encoding value not specified', () {
      var command = 'update:encoding:@alice:phone@bob 123';
      expect(
          () => getVerbParams(VerbSyntax.update, command),
          throwsA(predicate((dynamic e) =>
              e is InvalidSyntaxException &&
              e.message == 'command does not match the regex')));
    });

    test(
        'test to verify local key with isPublic set to true throws invalid atkey exception',
        () {
      var updateVerbBuilder = UpdateVerbBuilder()
        ..isPublic = true
        ..isLocal = true
        ..atKey = 'phone'
        ..sharedBy = '@bob';

      expect(
          () => updateVerbBuilder.buildCommand(),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message ==
                  'When isLocal is set to true, cannot set isPublic to true or set a non-null sharedWith')));
    });

    test('test to verify local key with sharedWith populated throws invalid atkey exception', () {
      expect(() {
        UpdateVerbBuilder()
          ..isLocal = true
          ..sharedWith = '@alice'
          ..atKey = 'phone'
          ..sharedBy = '@bob';
      },
          throwsA(predicate(
              (dynamic e) => e is InvalidAtKeyException
                  && e.message == 'isLocal or isPublic cannot be true when sharedWith is set')));
    });

    test('test to verify isPublic set to true with sharedWith populated throws invalid atkey exception', () {
      expect(() {
        UpdateVerbBuilder()
          ..isPublic = true
          ..sharedWith = '@alice'
          ..atKey = 'phone'
          ..sharedBy = '@bob';
      },
          throwsA(predicate(
              (dynamic e) => e is InvalidAtKeyException
                  && e.message == 'isLocal or isPublic cannot be true when sharedWith is set')));
    });

    test('test to verify Key cannot be null or empty', () {
      var updateVerbBuilder = UpdateVerbBuilder()
        ..sharedWith = '@alice'
        ..atKey = ''
        ..sharedBy = '@bob';

      expect(
          () => updateVerbBuilder.buildCommand(),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message == 'Key cannot be null or empty')));
    });

    test(
        'A key with local is set and then sharedWith is set which throws exception',
        () {
      var updateVerbBuilder = UpdateVerbBuilder()
        ..atKey = 'phone'
        ..isLocal = true
        ..sharedBy = '@bob'
        ..value = '+445 334 3423';
      var command = updateVerbBuilder.buildCommand();
      expect(command, 'update:local:phone@bob +445 334 3423\n');
      expect(() => updateVerbBuilder.atKeyObj.sharedWith = '@alice',
          throwsA(predicate((dynamic e) => e is InvalidAtKeyException)));
    });
  });

  group('A group of tests to validate the buildKey', () {
    // The privatekey:<key> is used to insert the pkam keys
    test('privatekey assigned to atKey.key', () {
      var updateVerbBuilder = UpdateVerbBuilder()
        ..atKey = 'privatekey:at_private_key';
      expect(updateVerbBuilder.buildKey(), 'privatekey:at_private_key');
    });

    test('test to verify sharedWith is set to null on a local key', () {
      var updateVerbBuilder = UpdateVerbBuilder()
        ..atKey = 'phone'
        ..sharedBy = '@alice'
        ..isLocal = true;
      expect(updateVerbBuilder.buildKey(), 'local:phone@alice');
      updateVerbBuilder.sharedWith = null;
      expect(updateVerbBuilder.buildKey(), 'local:phone@alice');
    });

    test('test to verify sharedWith is set to null on a public key', () {
      var updateVerbBuilder = UpdateVerbBuilder()
        ..atKey = 'phone'
        ..sharedBy = '@alice'
        ..isPublic = true;
      expect(updateVerbBuilder.buildKey(), 'public:phone@alice');
      expect(updateVerbBuilder.sharedWith, null);
      updateVerbBuilder.sharedWith=null;
      expect(updateVerbBuilder.buildKey(), 'public:phone@alice');
    });

    UpdateVerbBuilder createBuilderWithAllMetadata({String? sharedWith}) {
      var ttl = 12345;
      var ttb = 54321;
      var ccd = false;
      var ttr = 1000;
      var dataSignature = 'someDataSignature';
      var sharedKeyStatus = SharedKeyStatus.LOCAL_UPDATED.name;
      var sharedKeyEncrypted = 'xyz123abc456';
      var pubKeyChecksum = 'the_checksum';
      var encoding = 'some_encoding';
      var encKeyName = 'some_enc_key_name';
      var encAlgo = 'some_enc_algo';
      var ivNonce = 'some_iv_or_nonce';
      var skeEncKeyName = 'some_ske_enc_key_name';
      var skeEncAlgo = 'some_ske_enc_algo';
      var isBinary = true;
      var isEncrypted = true;
      return UpdateVerbBuilder()
        ..atKey = 'phone.details.wavi'
        ..sharedBy = '@alice'
        ..sharedWith = sharedWith
        ..isPublic = (sharedWith == null)
        ..ttl=ttl
        ..ttb=ttb
        ..ccd=ccd
        ..ttr=ttr
        ..dataSignature=dataSignature
        ..sharedKeyStatus=sharedKeyStatus
        ..isBinary=isBinary
        ..isEncrypted=isEncrypted
        ..sharedKeyEncrypted=sharedKeyEncrypted
        ..pubKeyChecksum=pubKeyChecksum
        ..encoding=encoding
        ..encKeyName=encKeyName
        ..encAlgo=encAlgo
        ..ivNonce=ivNonce
        ..skeEncKeyName=skeEncKeyName
        ..skeEncAlgo=skeEncAlgo
        ..value='HELLO_WORLD'
      ;
    }
    test('verify metadata is fully passed from builder to the atKeyObj which is built by buildKey', () {
      var updateVerbBuilder = createBuilderWithAllMetadata(sharedWith: '@bob');
      expect(updateVerbBuilder.buildKey(), '@bob:phone.details.wavi@alice');
      expect(updateVerbBuilder.atKeyObj.metadata!.ttl, updateVerbBuilder.ttl);
      expect(updateVerbBuilder.atKeyObj.metadata!.ttb, updateVerbBuilder.ttb);
      expect(updateVerbBuilder.atKeyObj.metadata!.ccd, updateVerbBuilder.ccd);
      expect(updateVerbBuilder.atKeyObj.metadata!.ttr, updateVerbBuilder.ttr);
      expect(updateVerbBuilder.atKeyObj.metadata!.dataSignature, updateVerbBuilder.dataSignature);
      expect(updateVerbBuilder.atKeyObj.metadata!.sharedKeyStatus, updateVerbBuilder.sharedKeyStatus);
      expect(updateVerbBuilder.atKeyObj.metadata!.isBinary, updateVerbBuilder.isBinary);
      expect(updateVerbBuilder.atKeyObj.metadata!.isEncrypted, updateVerbBuilder.isEncrypted);
      expect(updateVerbBuilder.atKeyObj.metadata!.sharedKeyEnc, updateVerbBuilder.sharedKeyEncrypted);
      expect(updateVerbBuilder.atKeyObj.metadata!.pubKeyCS, updateVerbBuilder.pubKeyChecksum);
      expect(updateVerbBuilder.atKeyObj.metadata!.encoding, updateVerbBuilder.encoding);
      expect(updateVerbBuilder.atKeyObj.metadata!.encKeyName, updateVerbBuilder.encKeyName);
      expect(updateVerbBuilder.atKeyObj.metadata!.encAlgo, updateVerbBuilder.encAlgo);
      expect(updateVerbBuilder.atKeyObj.metadata!.ivNonce, updateVerbBuilder.ivNonce);
      expect(updateVerbBuilder.atKeyObj.metadata!.skeEncKeyName, updateVerbBuilder.skeEncKeyName);
      expect(updateVerbBuilder.atKeyObj.metadata!.skeEncAlgo, updateVerbBuilder.skeEncAlgo);
    });

    group('A group of tests to verify round-tripping of update commands from buildCommand and getBuilder', () {
      UpdateVerbBuilder roundTripUpdateTest({String? sharedWith}) {
        var initialBuilder = createBuilderWithAllMetadata(sharedWith: sharedWith);
        var command = initialBuilder.buildCommand();
        var roundTrippedBuilder = UpdateVerbBuilder.getBuilder(command.trim());
        expect(initialBuilder == roundTrippedBuilder, true);
        return roundTrippedBuilder!;
      }
      test('verify round trip from builder, to command for update, back to builder, for public key', () {
        var roundTrippedBuilder = roundTripUpdateTest(sharedWith: null);
        expect(roundTrippedBuilder.isPublic, true);
      });

      test('verify round trip from builder, to command for update, back to builder, for shared key', () {
        var roundTrippedBuilder = roundTripUpdateTest(sharedWith: '@bob');
        expect(roundTrippedBuilder.isPublic, false);
      });

      UpdateVerbBuilder roundTripUpdateMetaTest({String? sharedWith}) {
        var initialBuilder = createBuilderWithAllMetadata(sharedWith: sharedWith);
        initialBuilder.operation = UPDATE_META;

        // When the update:meta command is built, it will NOT include the value, so
        // we'll make two assertions: (1) builder after round-tripping via buildCommandForMeta()
        // will NOT be the same as the initial builder, and (2) builder after round-tripping via
        // buildCommandForMeta() WILL be the same as the initial builder, if the `value` in the
        // initial builder is set to null
        var command = initialBuilder.buildCommandForMeta();
        var roundTrippedBuilder = UpdateVerbBuilder.getBuilder(command.trim());
        expect(initialBuilder == roundTrippedBuilder, false);

        initialBuilder.value = null;
        expect(initialBuilder == roundTrippedBuilder, true);

        return roundTrippedBuilder!;
      }
      test('verify round trip from builder, to command for update meta, back to builder, for public key', () {
        var roundTrippedBuilder = roundTripUpdateMetaTest(sharedWith: null);
        expect(roundTrippedBuilder.isPublic, true);
      });
      test('verify round trip from builder, to command for update meta, back to builder, for shared key', () {
        var roundTrippedBuilder = roundTripUpdateMetaTest(sharedWith: '@bob');
        expect(roundTrippedBuilder.isPublic, false);
      });
    });
  });
}
