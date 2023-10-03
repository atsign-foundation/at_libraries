// ignore_for_file: constant_identifier_names
class AtConstants {
  static const String AT_SIGN = 'atSign';
  static const String FOR_AT_SIGN = 'forAtSign';
  static const String AT_KEY = 'atKey';
  static const String AT_VALUE = 'value';
  static const String AT_DIGEST = 'digest';
  static const String AT_PKAM_SIGNATURE = 'signature';
  static const String AT_PKAM_SIGNING_ALGO = 'signingAlgo';
  static const String AT_PKAM_HASHING_ALGO = 'hashingAlgo';
  static const String PUBLIC_SCOPE_PARAM = 'publicScope';
  static const String AT_PKAM_PRIVATE_KEY = 'privatekey:at_pkam_privatekey';
  static const String AT_PKAM_PUBLIC_KEY = 'privatekey:at_pkam_publickey';
  static const String AT_ENCRYPTION_PUBLIC_KEY = 'public:publickey';
  static const String AT_ENCRYPTION_PRIVATE_KEY = 'privatekey:privatekey';
  static const String AT_ENCRYPTION_SHARED_KEY = 'shared_key';
  static const String AT_ENCRYPTION_SELF_KEY = 'privatekey:self_encryption_key';
  static const String AT_SIGNING_PRIVATE_KEY = 'signing_privatekey';
  static const String AT_SIGNING_PUBLIC_KEY = 'public:signing_publickey';
  static const String AT_CRAM_SECRET = 'privatekey:at_secret';
  static const String AT_CRAM_SECRET_DELETED = 'privatekey:at_secret_deleted';
  static const String AT_SIGNING_KEYPAIR_GENERATED = 'privatekey:signing_keypair_generated';
  static const String AT_STAT_ID = 'statId';
  static const String AT_TTL = 'ttl';
  static const String AT_TTB = 'ttb';
  static const String AT_TTR = 'ttr';
  static const String AT_TTL_NOTIFICATION = 'ttln';
  static const String AT_FROM_COMMIT_SEQUENCE = 'from_commit_seq';
  static const String AT_OPERATION = 'operation';
  static const String AT_VALUE_REFERENCE = 'atsign://';
  static const String AT_REGEX = 'regex';
  static const String CONFIG_NEW = 'configNew';
  static const String FROM_AT_SIGN = 'fromAtSign';
  static const String TO_AT_SIGN = 'toAtSign';
  static const String NOTIFICATION = 'notification';
  static const String FROM = 'from';
  static const String TO = 'to';
  static const String KEY = 'key';
  static const String EPOCH_MILLIS = 'epochMillis';
  static const String MONITOR_STRICT_MODE = 'strict';
  static const String MONITOR_MULTIPLEXED_MODE = 'multiplexed';
  static const String MONITOR_REGEX = 'regex';
  static const String MONITOR_SELF_NOTIFICATIONS = 'selfNotifications';
  static const String ID = 'id';
  static const String OPERATION = 'operation';
  static const String SET_OPERATION = 'setOperation';
  static const String UPDATE_META = 'meta';
  static const String UPDATE_JSON = 'update:json';
  static const String VALUE = 'value';
  static const String UPDATE_ALL = 'all';
  static const String CCD = 'ccd';
  static const String CACHED = 'cached';
  static const String REFRESH_AT = 'refreshAt';
  static const String IS_BINARY = 'isBinary';
  static const String IS_ENCRYPTED = 'isEncrypted';
  static const String IS_PUBLIC = 'isPublic';
  static const String ENCRYPTING_KEY_NAME = 'encKeyName';
  static const String ENCRYPTING_ALGO = 'encAlgo';
  static const String IV_OR_NONCE = 'ivNonce';
  static const String PUBLIC_DATA_SIGNATURE = 'dataSignature';
  static const String SHARED_KEY_STATUS = 'sharedKeyStatus';
  static const String SHARED_KEY_ENCRYPTED = 'sharedKeyEnc';
  static const String SHARED_WITH_PUBLIC_KEY_CHECK_SUM = 'pubKeyCS';
  static const String SHARED_KEY_ENCRYPTED_ENCRYPTING_KEY_NAME = 'skeEncKeyName';
  static const String SHARED_KEY_ENCRYPTED_ENCRYPTING_ALGO = 'skeEncAlgo';
  static const String FIRST_BYTE = '#';
  static const String CREATED_AT = 'createdAt';
  static const String UPDATED_AT = 'updatedAt';
  static const String PRIORITY = 'priority';
  static const String STRATEGY = 'strategy';
  static const String NOTIFIER = 'notifier';
  static const String LATEST_N = 'latestN';
  static const String SYSTEM = 'SYSTEM';
  static const String MESSAGE_TYPE = 'messageType';
  static const String PAGE = 'page';
  static const String commitLogCompactionKey = 'privatekey:commitLogCompactionStats';
  static const String accessLogCompactionKey = 'privatekey:accessLogCompactionStats';
  static const String notificationCompactionKey = 'privatekey:notificationCompactionStats';
  static const String bypassCache = 'bypassCache';
  static const String showHidden = 'showhidden';
  static const String statsNotificationId = '_latestNotificationIdv2';
  static const String ENCODING = 'encoding';
  static const String CLIENT_CONFIG = 'clientConfig';
  static const String VERSION = 'version';
  static const String IS_LOCAL = 'isLocal';
  static const String CLIENT_ID = 'clientId';
  static const String APP_NAME = 'appName';
  static const String APP_VERSION = 'appVersion';
  static const String PLATFORM = 'platform';
  static const String enrollmentId = 'enrollmentId';
  static const String keyType = 'keyType';
  static const String keyValue = 'keyValue';
  static const String visibility = 'visibility';
  static const String namespace = 'namespace';
  static const String keyName = 'keyName';
  static const String deviceName = 'deviceName';
  static const String encryptionKeyName = 'encryptionKeyName';
  static const String apkamEncryptedDefaultPrivateKey = 'encryptedDefaultEncPrivateKey';
  static const String apkamEncryptedDefaultSelfEncryptionKey = 'encryptedDefaultSelfEncryptionKey';
  static const String apkamEncryptedSymmetricKey = 'encryptedApkamSymmetricKey';
  static const String apkamPublicKey = 'apkamPublicKey';
  static const String apkamNamespaces = 'namespaces';
  static const String defaultEncryptionPrivateKey = 'default_enc_private_key';
  static const String defaultSelfEncryptionKey = 'default_self_enc_key';
  static const String enrollParams = 'enrollParams';
}

@Deprecated('Use AtConstants.AT_SIGN instead')
const String AT_SIGN = AtConstants.AT_SIGN;

@Deprecated('Use AtConstants.FOR_AT_SIGN instead')
const String FOR_AT_SIGN = AtConstants.FOR_AT_SIGN;

@Deprecated('Use AtConstants.AT_KEY instead')
const String AT_KEY = AtConstants.AT_KEY;

@Deprecated('Use AtConstants.AT_VALUE instead')
const String AT_VALUE = AtConstants.AT_VALUE;

@Deprecated('Use AtConstants.AT_DIGEST instead')
const String AT_DIGEST = AtConstants.AT_DIGEST;

@Deprecated('Use AtConstants.AT_PKAM_SIGNATURE instead')
const String AT_PKAM_SIGNATURE = AtConstants.AT_PKAM_SIGNATURE;

@Deprecated('Use AtConstants.AT_PKAM_SIGNING_ALGO instead')
const String AT_PKAM_SIGNING_ALGO = AtConstants.AT_PKAM_SIGNING_ALGO;

@Deprecated('Use AtConstants.AT_PKAM_HASHING_ALGO instead')
const String AT_PKAM_HASHING_ALGO = AtConstants.AT_PKAM_HASHING_ALGO;

@Deprecated('Use AtConstants.PUBLIC_SCOPE_PARAM instead')
const String PUBLIC_SCOPE_PARAM = AtConstants.PUBLIC_SCOPE_PARAM;

@Deprecated('Use AtConstants.AT_PKAM_PRIVATE_KEY instead')
const String AT_PKAM_PRIVATE_KEY = AtConstants.AT_PKAM_PRIVATE_KEY;

@Deprecated('Use AtConstants.AT_PKAM_PUBLIC_KEY instead')
const String AT_PKAM_PUBLIC_KEY = AtConstants.AT_PKAM_PUBLIC_KEY;

@Deprecated('Use AtConstants.AT_ENCRYPTION_PUBLIC_KEY instead')
const String AT_ENCRYPTION_PUBLIC_KEY = AtConstants.AT_ENCRYPTION_PUBLIC_KEY;

@Deprecated('Use AtConstants.AT_ENCRYPTION_PRIVATE_KEY instead')
const String AT_ENCRYPTION_PRIVATE_KEY = AtConstants.AT_ENCRYPTION_PRIVATE_KEY;

@Deprecated('Use AtConstants.AT_ENCRYPTION_SHARED_KEY instead')
const String AT_ENCRYPTION_SHARED_KEY = AtConstants.AT_ENCRYPTION_SHARED_KEY;

@Deprecated('Use AtConstants.AT_ENCRYPTION_SELF_KEY instead')
const String AT_ENCRYPTION_SELF_KEY = AtConstants.AT_ENCRYPTION_SELF_KEY;

@Deprecated('Use AtConstants.AT_SIGNING_PRIVATE_KEY instead')
const String AT_SIGNING_PRIVATE_KEY = AtConstants.AT_SIGNING_PRIVATE_KEY;

@Deprecated('Use AtConstants.AT_SIGNING_PUBLIC_KEY instead')
const String AT_SIGNING_PUBLIC_KEY = AtConstants.AT_SIGNING_PUBLIC_KEY;

@Deprecated('Use AtConstants.AT_CRAM_SECRET instead')
const String AT_CRAM_SECRET = AtConstants.AT_CRAM_SECRET;

@Deprecated('Use AtConstants.AT_CRAM_SECRET_DELETED instead')
const String AT_CRAM_SECRET_DELETED = AtConstants.AT_CRAM_SECRET_DELETED;

@Deprecated('Use AtConstants.AT_SIGNING_KEYPAIR_GENERATED instead')
const String AT_SIGNING_KEYPAIR_GENERATED = AtConstants.AT_SIGNING_KEYPAIR_GENERATED;

@Deprecated('Use AtConstants.AT_STAT_ID instead')
const String AT_STAT_ID = AtConstants.AT_STAT_ID;

@Deprecated('Use AtConstants.AT_TTL instead')
const String AT_TTL = AtConstants.AT_TTL;

@Deprecated('Use AtConstants.AT_TTB instead')
const String AT_TTB = AtConstants.AT_TTB;

@Deprecated('Use AtConstants.AT_TTR instead')
const String AT_TTR = AtConstants.AT_TTR;

@Deprecated('Use AtConstants.AT_TTL_NOTIFICATION instead')
const String AT_TTL_NOTIFICATION = AtConstants.AT_TTL_NOTIFICATION;

@Deprecated('Use AtConstants.AT_FROM_COMMIT_SEQUENCE instead')
const String AT_FROM_COMMIT_SEQUENCE = AtConstants.AT_FROM_COMMIT_SEQUENCE;

@Deprecated('Use AtConstants.AT_OPERATION instead')
const String AT_OPERATION = AtConstants.AT_OPERATION;

@Deprecated('Use AtConstants.AT_VALUE_REFERENCE instead')
const String AT_VALUE_REFERENCE = AtConstants.AT_VALUE_REFERENCE;

@Deprecated('Use AtConstants.AT_REGEX instead')
const String AT_REGEX = AtConstants.AT_REGEX;

@Deprecated('Use AtConstants.CONFIG_NEW instead')
const String CONFIG_NEW = AtConstants.CONFIG_NEW;

@Deprecated('Use AtConstants.FROM_AT_SIGN instead')
const String FROM_AT_SIGN = AtConstants.FROM_AT_SIGN;

@Deprecated('Use AtConstants.TO_AT_SIGN instead')
const String TO_AT_SIGN = AtConstants.TO_AT_SIGN;

@Deprecated('Use AtConstants.NOTIFICATION instead')
const String NOTIFICATION = AtConstants.NOTIFICATION;

@Deprecated('Use AtConstants.FROM instead')
const String FROM = AtConstants.FROM;

@Deprecated('Use AtConstants.TO instead')
const String TO = AtConstants.TO;

@Deprecated('Use AtConstants.KEY instead')
const String KEY = AtConstants.KEY;

@Deprecated('Use AtConstants.EPOCH_MILLIS instead')
const String EPOCH_MILLIS = AtConstants.EPOCH_MILLIS;

@Deprecated('Use AtConstants.MONITOR_STRICT_MODE instead')
const String MONITOR_STRICT_MODE = AtConstants.MONITOR_STRICT_MODE;

@Deprecated('Use AtConstants.MONITOR_MULTIPLEXED_MODE instead')
const String MONITOR_MULTIPLEXED_MODE = AtConstants.MONITOR_MULTIPLEXED_MODE;

@Deprecated('Use AtConstants.MONITOR_REGEX instead')
const String MONITOR_REGEX = AtConstants.MONITOR_REGEX;

@Deprecated('Use AtConstants.MONITOR_SELF_NOTIFICATIONS instead')
const String MONITOR_SELF_NOTIFICATIONS = AtConstants.MONITOR_SELF_NOTIFICATIONS;

@Deprecated('Use AtConstants.ID instead')
const String ID = AtConstants.ID;

@Deprecated('Use AtConstants.OPERATION instead')
const String OPERATION = AtConstants.OPERATION;

@Deprecated('Use AtConstants.SET_OPERATION instead')
const String SET_OPERATION = AtConstants.SET_OPERATION;

@Deprecated('Use AtConstants.UPDATE_META instead')
const String UPDATE_META = AtConstants.UPDATE_META;

@Deprecated('Use AtConstants.UPDATE_JSON instead')
const String UPDATE_JSON = AtConstants.UPDATE_JSON;

@Deprecated('Use AtConstants.VALUE instead')
const String VALUE = AtConstants.VALUE;

@Deprecated('Use AtConstants.UPDATE_ALL instead')
const String UPDATE_ALL = AtConstants.UPDATE_ALL;

@Deprecated('Use AtConstants.CCD instead')
const String CCD = AtConstants.CCD;

@Deprecated('Use AtConstants.CACHED instead')
const String CACHED = AtConstants.CACHED;

@Deprecated('Use AtConstants.REFRESH_AT instead')
const String REFRESH_AT = AtConstants.REFRESH_AT;

@Deprecated('Use AtConstants.IS_BINARY instead')
const String IS_BINARY = AtConstants.IS_BINARY;

@Deprecated('Use AtConstants.IS_ENCRYPTED instead')
const String IS_ENCRYPTED = AtConstants.IS_ENCRYPTED;

@Deprecated('Use AtConstants.IS_PUBLIC instead')
const String IS_PUBLIC = AtConstants.IS_PUBLIC;

@Deprecated('Use AtConstants.ENCRYPTING_KEY_NAME instead')
const String ENCRYPTING_KEY_NAME = AtConstants.ENCRYPTING_KEY_NAME;

@Deprecated('Use AtConstants.ENCRYPTING_ALGO instead')
const String ENCRYPTING_ALGO = AtConstants.ENCRYPTING_ALGO;

@Deprecated('Use AtConstants.IV_OR_NONCE instead')
const String IV_OR_NONCE = AtConstants.IV_OR_NONCE;

@Deprecated('Use AtConstants.PUBLIC_DATA_SIGNATURE instead')
const String PUBLIC_DATA_SIGNATURE = AtConstants.PUBLIC_DATA_SIGNATURE;

@Deprecated('Use AtConstants.SHARED_KEY_STATUS instead')
const String SHARED_KEY_STATUS = AtConstants.SHARED_KEY_STATUS;

@Deprecated('Use AtConstants.SHARED_KEY_ENCRYPTED instead')
const String SHARED_KEY_ENCRYPTED = AtConstants.SHARED_KEY_ENCRYPTED;

@Deprecated('Use AtConstants.SHARED_WITH_PUBLIC_KEY_CHECK_SUM instead')
const String SHARED_WITH_PUBLIC_KEY_CHECK_SUM = AtConstants.SHARED_WITH_PUBLIC_KEY_CHECK_SUM;

@Deprecated('Use AtConstants.SHARED_KEY_ENCRYPTED_ENCRYPTING_KEY_NAME instead')
const String SHARED_KEY_ENCRYPTED_ENCRYPTING_KEY_NAME = AtConstants.SHARED_KEY_ENCRYPTED_ENCRYPTING_KEY_NAME;

@Deprecated('Use AtConstants.SHARED_KEY_ENCRYPTED_ENCRYPTING_ALGO instead')
const String SHARED_KEY_ENCRYPTED_ENCRYPTING_ALGO = AtConstants.SHARED_KEY_ENCRYPTED_ENCRYPTING_ALGO;

@Deprecated('Use AtConstants.FIRST_BYTE instead')
const String FIRST_BYTE = AtConstants.FIRST_BYTE;

@Deprecated('Use AtConstants.CREATED_AT instead')
const String CREATED_AT = AtConstants.CREATED_AT;

@Deprecated('Use AtConstants.UPDATED_AT instead')
const String UPDATED_AT = AtConstants.UPDATED_AT;

@Deprecated('Use AtConstants.PRIORITY instead')
const String PRIORITY = AtConstants.PRIORITY;

@Deprecated('Use AtConstants.STRATEGY instead')
const String STRATEGY = AtConstants.STRATEGY;

@Deprecated('Use AtConstants.NOTIFIER instead')
const String NOTIFIER = AtConstants.NOTIFIER;

@Deprecated('Use AtConstants.LATEST_N instead')
const String LATEST_N = AtConstants.LATEST_N;

@Deprecated('Use AtConstants.SYSTEM instead')
const String SYSTEM = AtConstants.SYSTEM;

@Deprecated('Use AtConstants.MESSAGE_TYPE instead')
const String MESSAGE_TYPE = AtConstants.MESSAGE_TYPE;

@Deprecated('Use AtConstants.PAGE instead')
const String PAGE = AtConstants.PAGE;

@Deprecated('Use AtConstants.commitLogCompactionKey instead')
const String commitLogCompactionKey = AtConstants.commitLogCompactionKey;

@Deprecated('Use AtConstants.accessLogCompactionKey instead')
const String accessLogCompactionKey = AtConstants.accessLogCompactionKey;

@Deprecated('Use AtConstants.notificationCompactionKey instead')
const String notificationCompactionKey = AtConstants.notificationCompactionKey;

@Deprecated('Use AtConstants.bypassCache instead')
const String bypassCache = AtConstants.bypassCache;

@Deprecated('Use AtConstants.showHidden instead')
const String showHidden = AtConstants.showHidden;

@Deprecated('Use AtConstants.statsNotificationId instead')
const String statsNotificationId = AtConstants.statsNotificationId;

@Deprecated('Use AtConstants.ENCODING instead')
const String ENCODING = AtConstants.ENCODING;

@Deprecated('Use AtConstants.CLIENT_CONFIG instead')
const String CLIENT_CONFIG = AtConstants.CLIENT_CONFIG;

@Deprecated('Use AtConstants.VERSION instead')
const String VERSION = AtConstants.VERSION;

@Deprecated('Use AtConstants.IS_LOCAL instead')
const String IS_LOCAL = AtConstants.IS_LOCAL;

@Deprecated('Use AtConstants.CLIENT_ID instead')
const String CLIENT_ID = AtConstants.CLIENT_ID;

@Deprecated('Use AtConstants.APP_NAME instead')
const String APP_NAME = AtConstants.APP_NAME;

@Deprecated('Use AtConstants.APP_VERSION instead')
const String APP_VERSION = AtConstants.APP_VERSION;

@Deprecated('Use AtConstants.PLATFORM instead')
const String PLATFORM = AtConstants.PLATFORM;

@Deprecated('Use AtConstants.enrollmentId instead')
const String enrollmentId = AtConstants.enrollmentId;

@Deprecated('Use AtConstants.keyType instead')
const String keyType = AtConstants.keyType;

@Deprecated('Use AtConstants.keyValue instead')
const String keyValue = AtConstants.keyValue;

@Deprecated('Use AtConstants.visibility instead')
const String visibility = AtConstants.visibility;

@Deprecated('Use AtConstants.namespace instead')
const String namespace = AtConstants.namespace;

@Deprecated('Use AtConstants.keyName instead')
const String keyName = AtConstants.keyName;

@Deprecated('Use AtConstants.deviceName instead')
const String deviceName = AtConstants.deviceName;

@Deprecated('Use AtConstants.encryptionKeyName instead')
const String encryptionKeyName = AtConstants.encryptionKeyName;

@Deprecated('Use AtConstants.apkamEncryptedDefaultPrivateKey instead')
const String apkamEncryptedDefaultPrivateKey = AtConstants.apkamEncryptedDefaultPrivateKey;

@Deprecated('Use AtConstants.apkamEncryptedDefaultSelfEncryptionKey instead')
const String apkamEncryptedDefaultSelfEncryptionKey = AtConstants.apkamEncryptedDefaultSelfEncryptionKey;

@Deprecated('Use AtConstants.apkamEncryptedSymmetricKey instead')
const String apkamEncryptedSymmetricKey = AtConstants.apkamEncryptedSymmetricKey;

@Deprecated('Use AtConstants.apkamPublicKey instead')
const String apkamPublicKey = AtConstants.apkamPublicKey;

@Deprecated('Use AtConstants.apkamNamespaces instead')
const String apkamNamespaces = AtConstants.apkamNamespaces;

@Deprecated('Use AtConstants.defaultEncryptionPrivateKey instead')
const String defaultEncryptionPrivateKey = AtConstants.defaultEncryptionPrivateKey;

@Deprecated('Use AtConstants.defaultSelfEncryptionKey instead')
const String defaultSelfEncryptionKey = AtConstants.defaultSelfEncryptionKey;

@Deprecated('Use AtConstants.enrollParams instead')
const String enrollParams = AtConstants.enrollParams;
