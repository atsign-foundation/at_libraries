import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/src/cli/auth_cli.dart' as auth_cli;
import 'package:at_onboarding_cli/src/cli/auth_cli_args.dart' as auth_cli_args;
import 'package:test/test.dart';

void main() {
  final baseDirPath = 'test/keys';
  group('A group of tests to verify write permission of apkam file path', () {
    final dirPath = '$baseDirPath/@alice-apkam-keys.atKeys';

    test(
        'A test to verify isWritable returns false if directory has read-only permissions',
        () async {
      final directory = Directory(dirPath);
      // Create the directory first to ensure it exists before calling isWritable.
      await directory.create(recursive: true);
      // Set permission to read only.
      await Process.run('chmod', ['444', baseDirPath]);
      expect(auth_cli.canCreateFile(File(dirPath)), false);
    });

    test(
        'A test verify isWritable returns true if directory does not have a file already',
        () {
      expect(auth_cli.canCreateFile(File(dirPath)), true);
    });

    tearDown(() async {
      // Set full permissions to delete the directory.
      await Process.run('chmod', ['777', baseDirPath]);
      Directory(baseDirPath).deleteSync(recursive: true);
    });
  });

  group('A group of test to assert encrypt command', () {
    test(
        'A test to verify encrypt command throw exception if pass phrase is not supplied',
        () {
      List<String> args = [
        'encrypt',
        '-a',
        '@alice',
        '-k',
        '/home/user/.atsign/@alice_key.atKeys',
        '-E',
        '/home/user/.atsign/@alice_encrypted_key'
      ];

      ArgParser argParser =
          auth_cli_args.AuthCliArgs().createEncryptCommandParser();
      ArgResults argResults = argParser.parse(args);

      expect(
          () async => await auth_cli.encryptAtKeys(argResults),
          throwsA(predicate((dynamic e) =>
              e is AtException &&
              e.message ==
                  'pass-phrase is mandatory to password protect the atKeys file')));
    });

    test('A test to verify encrypt and decrypt commands', () async {
      File aliceAtKeysFile = File('test/data/@alice🛠_key.atKeys');
      String aliceEncodedAtKeys = aliceAtKeysFile.readAsStringSync();
      Map<String, dynamic> aliceKeys = jsonDecode(aliceEncodedAtKeys);

      List<String> args = [
        'encrypt',
        '-a',
        '@alice',
        '-k',
        'test/data/@alice🛠_key.atKeys',
        '-E',
        'test/data/@alice🛠_encrypted_key.atKeys',
        '-P',
        'abcd'
      ];

      ArgParser argParser =
          auth_cli_args.AuthCliArgs().createEncryptCommandParser();
      ArgResults argResults = argParser.parse(args);
      await auth_cli.encryptAtKeys(argResults);

      args = [
        'decrypt',
        '-a',
        '@alice',
        '-k',
        'test/data/@alice🛠_encrypted_key.atKeys',
        '-P',
        'abcd'
      ];

      argParser = auth_cli_args.AuthCliArgs().createEncryptCommandParser();
      argResults = argParser.parse(args);
      String decryptedKeys = await auth_cli.decryptAtKeys(argResults);
      Map<String, dynamic> decryptedAtKeys = jsonDecode(decryptedKeys);
      expect(
          decryptedAtKeys['aesPkamPublicKey'], aliceKeys['aesPkamPublicKey']);
      expect(decryptedAtKeys['aesEncryptPublicKey'],
          aliceKeys['aesEncryptPublicKey']);
      expect(decryptedAtKeys['aesEncryptPrivateKey'],
          aliceKeys['aesEncryptPrivateKey']);
      expect(
          decryptedAtKeys['selfEncryptionKey'], aliceKeys['selfEncryptionKey']);
      expect(
          decryptedAtKeys['aesPkamPrivateKey'], aliceKeys['aesPkamPrivateKey']);
      expect(
          decryptedAtKeys['apkamSymmetricKey'], aliceKeys['apkamSymmetricKey']);

      // Remove the encrypted atKeys file after the test.
      File('test/data/@alice🛠_encrypted_key.atKeys').deleteSync();
    });
  });
}
