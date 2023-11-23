part 'at_constants_legacy.dart';

class AtConstants {
  static const String atSign = 'atSign';
  static const String forAtSign = 'forAtSign';
  static const String atKey = 'atKey';
  static const String atValue = 'value';
  static const String atDigest = 'digest';
  static const String atPkamSignature = 'signature';
  static const String atPkamSigningAlgo = 'signingAlgo';
  static const String atPkamHashingAlgo = 'hashingAlgo';
  static const String publicScopeParam = 'publicScope';
  static const String atPkamPrivateKey = 'privatekey:at_pkam_privatekey';
  static const String atPkamPublicKey = 'privatekey:at_pkam_publickey';
  static const String atEncryptionPublicKey = 'public:publickey';
  static const String atEncryptionPrivateKey = 'privatekey:privatekey';
  static const String atEncryptionSharedKey = 'shared_key';
  static const String atEncryptionSelfKey = 'privatekey:self_encryption_key';
  static const String atSigningPrivateKey = 'signing_privatekey';
  static const String atSigningPublicKey = 'public:signing_publickey';
  static const String atCramSecret = 'privatekey:at_secret';
  static const String atCramSecretDeleted = 'privatekey:at_secret_deleted';
  static const String atBlocklist = 'private:blocklist'; // contains @atsign postfix
  static const String atSigningKeypairGenerated =
      'privatekey:signing_keypair_generated';
  static const String statId = 'statId';
  static const String ttl = 'ttl';
  static const String ttb = 'ttb';
  static const String ttr = 'ttr';
  static const String ttlNotification = 'ttln';
  static const String fromCommitSequence = 'from_commit_seq';
  static const String atOperation = 'operation';
  static const String atValueReference = 'atsign://';
  static const String regex = 'regex';
  static const String configNew = 'configNew';
  static const String fromAtSign = 'fromAtSign';
  static const String toAtSign = 'toAtSign';
  static const String notification = 'notification';
  static const String from = 'from';
  static const String to = 'to';
  static const String key = 'key';
  static const String epochMilliseconds = 'epochMillis';
  static const String monitorStrictMode = 'strict';
  static const String monitorMultiplexedMode = 'multiplexed';
  static const String monitorRegex = 'regex';
  static const String monitorSelfNotifications = 'selfNotifications';
  static const String id = 'id';
  static const String operation = 'operation';
  static const String setOperation = 'setOperation';
  static const String updateMeta = 'meta';
  static const String updateJson = 'update:json';
  static const String value = 'value';
  static const String updateAll = 'all';
  static const String ccd = 'ccd';
  static const String cached = 'cached';
  static const String refreshAt = 'refreshAt';
  static const String isBinary = 'isBinary';
  static const String isEncrypted = 'isEncrypted';
  static const String isPublic = 'isPublic';
  static const String encryptingKeyName = 'encKeyName';
  static const String encryptingAlgo = 'encAlgo';
  static const String ivOrNonce = 'ivNonce';
  static const String publicDataSignature = 'dataSignature';
  static const String sharedKeyStatus = 'sharedKeyStatus';
  static const String sharedKeyEncrypted = 'sharedKeyEnc';
  static const String sharedWithPublicKeyCheckSum = 'pubKeyCS';
  static const String sharedKeyEncryptedEncryptingKeyName = 'skeEncKeyName';
  static const String sharedKeyEncryptedEncryptingAlgo = 'skeEncAlgo';
  static const String firstByte = '#';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String priority = 'priority';
  static const String strategy = 'strategy';
  static const String notifier = 'notifier';
  static const String latestN = 'latestN';
  static const String system = 'SYSTEM';
  static const String messageType = 'messageType';
  static const String page = 'page';
  static const String commitLogCompactionKey =
      'privatekey:commitLogCompactionStats';
  static const String accessLogCompactionKey =
      'privatekey:accessLogCompactionStats';
  static const String notificationCompactionKey =
      'privatekey:notificationCompactionStats';
  static const String bypassCache = 'bypassCache';
  static const String showHidden = 'showhidden';
  static const String statsNotificationId = '_latestNotificationIdv2';
  static const String encoding = 'encoding';
  static const String clientConfig = 'clientConfig';
  static const String version = 'version';
  static const String isLocal = 'isLocal';
  static const String clientId = 'clientId';
  static const String appName = 'appName';
  static const String appVersion = 'appVersion';
  static const String platform = 'platform';
  static const String enrollmentId = 'enrollmentId';
  static const String keyType = 'keyType';
  static const String keyValue = 'keyValue';
  static const String visibility = 'visibility';
  static const String namespace = 'namespace';
  static const String keyName = 'keyName';
  static const String deviceName = 'deviceName';
  static const String encryptionKeyName = 'encryptionKeyName';
  static const String apkamEncryptedDefaultPrivateKey =
      'encryptedDefaultEncPrivateKey';
  static const String apkamEncryptedDefaultSelfEncryptionKey =
      'encryptedDefaultSelfEncryptionKey';
  static const String apkamEncryptedSymmetricKey = 'encryptedApkamSymmetricKey';
  static const String apkamPublicKey = 'apkamPublicKey';
  static const String apkamNamespaces = 'namespaces';
  static const String defaultEncryptionPrivateKey = 'default_enc_private_key';
  static const String defaultSelfEncryptionKey = 'default_self_enc_key';
  static const String enrollParams = 'enrollParams';
}
