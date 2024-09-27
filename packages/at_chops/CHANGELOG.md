## 2.0.2
- build[deps]: Upgraded the following packages:
  - at_commons to v5.0.0
  - at_utils to v3.0.18
## 2.0.1
- fix: throw Exception when input IV is null for decryption(with Symmetric Encryption)
## 2.0.0
- [Breaking Change] fix: removed deprecated methods and members
- [Breaking Change] feat: Introduced interface for ASymmetricEncryptionAlgorithm and modified DefaultEncryptionAlgorithm
- build[deps]:
    - changed minimum dart version in pubspec from 2.15.1 to 3.0.0
    - upgraded pointycastle to 3.7.4
## 1.0.7
- build[deps]: Upgraded the following packages:
    - at_commons to v4.0.0
    - at_utils to v3.0.16
    - crypton to v2.2.1
    - encrypt to v5.0.3
    - crypto to v3.0.3
    - ecdsa to v0.1.0
    - elliptic to v0.3.10
    - pointycastle to v3.7.3
    - dart_periphery to v0.9.5
## 1.0.6
- fix: Pass optional parameter "keyName" to encryptBytes and decryptBytes
- fix: Export "at_key_pair.dart" file
## 1.0.5
- feat: Changes for at_auth package
- chore: fixed analyzer issues
## 1.0.4
- feat: Deprecated symmetric key pair in AtChopsKeys and introduced selfEncryptionKey and apkamSymmetricKey
- chore: Upgrade at_commons to 3.0.53 and at_util to 3.0.15
- fix: Removed at_onboarding_cli dependency in pubspec
## 1.0.3
- chore: Changed the Dart SDK version to 2.15.1 from 2.18.3 to support dependent packages
## 1.0.2
- feat: changes for pkam using private key from secure element.
## 1.0.1
- feat: Added implementation for different signing algorithms.
## 1.0.0
- Initial version.