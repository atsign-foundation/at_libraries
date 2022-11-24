import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/keystore/at_key_builder_impl.dart';
import 'package:at_commons/src/utils/at_key_regex_utils.dart';
import 'package:at_commons/src/utils/string_utils.dart';

class AtKey {
  String? key;
  String? _sharedWith;
  String? _sharedBy;
  String? namespace;
  Metadata? metadata;
  bool isRef = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtKey &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          _sharedWith == other._sharedWith &&
          _sharedBy == other._sharedBy &&
          namespace == other.namespace &&
          metadata == other.metadata &&
          isRef == other.isRef &&
          _isLocal == other._isLocal;

  @override
  int get hashCode =>
      key.hashCode ^
      _sharedWith.hashCode ^
      _sharedBy.hashCode ^
      namespace.hashCode ^
      metadata.hashCode ^
      isRef.hashCode ^
      _isLocal.hashCode;

  /// When set to true, represents the [LocalKey]
  /// These keys will never be synced between the client and secondary server.
  bool _isLocal = false;

  String? get sharedBy => _sharedBy;

  set sharedBy(String? sharedByAtSign) {
    assertStartsWithAtIfNotEmpty(sharedByAtSign);
    _sharedBy = sharedByAtSign;
  }

  String? get sharedWith => _sharedWith;

  set sharedWith(String? sharedWithAtSign) {
    assertStartsWithAtIfNotEmpty(sharedWithAtSign);
    if (sharedWithAtSign.isNotNullOrEmpty &&
        (isLocal == true || metadata?.isPublic == true)) {
      throw InvalidAtKeyException(
          'isLocal or isPublic cannot be true when sharedWith is set');
    }
    _sharedWith = sharedWithAtSign;
  }

  bool get isLocal => _isLocal;

  set isLocal(bool isLocal) {
    if (isLocal == true && sharedWith != null) {
      throw InvalidAtKeyException(
          'sharedWith must be null when isLocal is set to true');
    }
    _isLocal = isLocal;
  }

  String _dotNamespaceIfPresent() {
    if (namespace != null && namespace!.isNotEmpty) {
      return '.$namespace';
    } else {
      return '';
    }
  }

  @override
  String toString() {
    if (key.isNullOrEmpty) {
      throw InvalidAtKeyException('Key cannot be null or empty');
    }
    enforceLowercase();
    // If metadata.isPublic is true and metadata.isCached is true,
    // return cached public key
    if (key!.startsWith('cached:public:') ||
        (metadata != null &&
            (metadata!.isPublic != null && metadata!.isPublic!) &&
            (metadata!.isCached))) {
      return 'cached:public:$key${_dotNamespaceIfPresent()}$_sharedBy';
    }
    // If metadata.isPublic is true, return public key
    if (key!.startsWith('public:') ||
        (metadata != null &&
            metadata!.isPublic != null &&
            metadata!.isPublic!)) {
      return 'public:$key${_dotNamespaceIfPresent()}$_sharedBy';
    }
    //If metadata.isCached is true, return shared cached key
    if (key!.startsWith('cached:') ||
        (metadata != null && metadata!.isCached)) {
      return 'cached:$_sharedWith:$key${_dotNamespaceIfPresent()}$_sharedBy';
    }
    // If key starts with privatekey:, return private key
    if (key!.startsWith('privatekey:')) {
      return '$key';
    }
    //If _sharedWith is not null, return sharedKey
    if (_sharedWith != null && _sharedWith!.isNotEmpty) {
      return '$_sharedWith:$key${_dotNamespaceIfPresent()}$_sharedBy';
    }
    // if key starts with local: or isLocal set to true, return local key
    if (isLocal == true) {
      String localKey = '$key${_dotNamespaceIfPresent()}$sharedBy';
      if (localKey.startsWith('local:')) {
        return localKey;
      }
      return 'local:$localKey';
    }
    // Defaults to return a self key.
    return '$key${_dotNamespaceIfPresent()}$_sharedBy';
  }

  static void assertStartsWithAtIfNotEmpty(String? atSign) {
    if (atSign != null && atSign.isNotEmpty && !atSign.startsWith('@')) {
      throw InvalidSyntaxException('atSign $atSign does not start with an "@"');
    }
  }

  /// Public keys are visible to everyone and shown in an authenticated/unauthenticated scan
  ///
  /// Builds a public key and returns a [PublicKeyBuilder]
  ///
  ///Example: public:phone.wavi@alice.
  ///```dart
  ///AtKey publicKey = AtKey.public('phone', namespace: 'wavi', sharedBy: '@alice').build();
  ///```
  static PublicKeyBuilder public(String key,
      {String? namespace, String sharedBy = ''}) {
    assertStartsWithAtIfNotEmpty(sharedBy);
    return PublicKeyBuilder()
      ..key(key)
      ..namespace(namespace)
      ..sharedBy(sharedBy);
  }

  /// Shared Keys are shared with other atSign. The owner can see the keys on
  /// authenticated scan. The sharedWith atSign can lookup the value of the key.
  ///
  ///Builds a sharedWith key and returns a [SharedKeyBuilder]. Optionally the key
  ///can be cached on the [AtKey.sharedWith] atSign.
  ///
  ///Example: @bob:phone.wavi@alice.
  ///```dart
  ///AtKey sharedKey = (AtKey.shared('phone', 'wavi')
  ///     ..sharedWith('@bob')).build();
  ///```
  /// To cache a key on the @bob atSign.
  /// ```dart
  ///AtKey atKey = (AtKey.shared('phone', namespace: 'wavi', sharedBy: '@alice')
  ///  ..sharedWith('@bob')
  ///  ..cache(1000, true))
  ///  .build();
  /// ```
  static SharedKeyBuilder shared(String key,
      {String? namespace, String sharedBy = ''}) {
    assertStartsWithAtIfNotEmpty(sharedBy);
    return SharedKeyBuilder()
      ..key(key)
      ..namespace(namespace)
      ..sharedBy(sharedBy);
  }

  /// Self keys that are created by the owner of the atSign and the keys can be
  /// accessed by the owner of the atSign only.
  ///
  /// Builds a self key and returns a [SelfKeyBuilder].
  ///
  ///
  /// Example: phone.wavi@alice
  /// ```dart
  /// AtKey selfKey = AtKey.self('phone', namespace: 'wavi', sharedBy: '@alice').build();
  /// ```
  static SelfKeyBuilder self(String key,
      {String? namespace, String sharedBy = ''}) {
    assertStartsWithAtIfNotEmpty(sharedBy);
    return SelfKeyBuilder()
      ..key(key)
      ..namespace(namespace)
      ..sharedBy(sharedBy);
  }

  /// Private key's that are created by the owner of the atSign and these keys
  /// are not shown in the scan.
  ///
  /// Builds a private key and returns a [PrivateKeyBuilder]. Private key's are not
  /// returned when fetched for key's of atSign.
  ///
  /// Example: privatekey:phone.wavi@alice
  /// ```dart
  /// AtKey privateKey = AtKey.private('phone', namespace: 'wavi').build();
  /// ```
  static PrivateKeyBuilder private(String key, {String? namespace}) {
    return PrivateKeyBuilder()
      ..key(key)
      ..namespace(namespace);
  }

  /// Local key are confined to the client(device)/server it is created.
  /// The key does not sync between the local-secondary and the cloud-secondary.
  ///
  /// Builds a local key and return a [LocalKeyBuilder].
  ///
  /// Example: local:phone.wavi@alice
  /// ```dart
  /// AtKey localKey = AtKey.local('phone',namespace:'wavi').build();
  /// ```
  static LocalKeyBuilder local(String key, String sharedBy,
      {String? namespace}) {
    return LocalKeyBuilder()
      ..key(key)
      ..namespace(namespace)
      ..sharedBy(sharedBy);
  }

  static AtKey fromString(String key) {
    var atKey = AtKey();
    var metaData = Metadata();
    if (key.startsWith(AT_PKAM_PRIVATE_KEY) ||
        key.startsWith(AT_PKAM_PUBLIC_KEY)) {
      atKey.key = key;
      atKey.metadata = metaData;
      atKey.enforceLowercase();
      return atKey;
    } else if (key.startsWith(AT_ENCRYPTION_PRIVATE_KEY)) {
      atKey.key = key.split('@')[0];
      atKey._sharedBy = '@${key.split('@')[1]}';
      atKey.metadata = metaData;
      atKey.enforceLowercase;
      return atKey;
    }
    //If key does not contain '@'. or key has space, it is not a valid key.
    if (!key.contains('@') || key.contains(' ')) {
      throw InvalidSyntaxException('$key is not well-formed key');
    }
    var keyParts = key.split(':');
    // If key does not contain ':' Ex: phone@bob; then keyParts length is 1
    // where phone is key and @bob is sharedBy
    if (keyParts.length == 1) {
      atKey._sharedBy = '@${keyParts[0].split('@')[1]}';
      atKey.key = keyParts[0].split('@')[0];
    } else {
      // Example key: public:phone@bob
      if (keyParts[0] == 'public') {
        metaData.isPublic = true;
      } else if (keyParts[0] == 'local') {
        atKey.isLocal = true;
      }
      // Example key: cached:@alice:phone@bob
      else if (keyParts[0] == CACHED) {
        metaData.isCached = true;
        atKey._sharedWith = keyParts[1];
      } else {
        atKey._sharedWith = keyParts[0];
      }

      List<String> keyArr = [];
      if (keyParts[0] == CACHED) {
        //cached:@alice:phone@bob
        keyArr = keyParts[2].split('@'); //phone@bob ==> 'phone', 'bob'
      } else {
        // @alice:phone@bob
        keyArr = keyParts[1].split('@'); // phone@bob ==> 'phone', 'bob'
      }
      if (keyArr.length == 2) {
        atKey._sharedBy =
            '@${keyArr[1]}'; // keyArr[1] is 'bob' so sharedBy needs to be @bob
        atKey.key = keyArr[0];
      } else {
        atKey.key = keyArr[0];
      }
    }
    //remove namespace
    if (atKey.key != null && atKey.key!.contains('.')) {
      var namespaceIndex = atKey.key!.lastIndexOf('.');
      if (namespaceIndex > -1) {
        atKey.namespace = atKey.key!.substring(namespaceIndex + 1);
        atKey.key = atKey.key!.substring(0, namespaceIndex);
      }
    } else {
      metaData.namespaceAware = false;
    }
    atKey.metadata = metaData;
    atKey.enforceLowercase();
    return atKey;
  }

  /// Returns one of the valid keys from [KeyType] if there is a regex match. Otherwise returns [KeyType.invalidKey]
  /// Set enforceNamespace=true for strict namespace validation in the key.
  static KeyType getKeyType(String key, {bool enforceNameSpace = false}) {
    return RegexUtil.keyType(key, enforceNameSpace);
  }

  ///converts the AtKey to lowercase
  void enforceLowercase() {
    key = key?.toLowerCase();
    _sharedBy = _sharedBy?.toLowerCase();
    _sharedWith = _sharedWith?.toLowerCase();
    namespace = namespace?.toLowerCase();
  }
}

/// Represents a public key.
class PublicKey extends AtKey {
  PublicKey() {
    super.metadata = Metadata();
    super.metadata!.isPublic = true;
  }

  @override
  String toString() {
    return 'public:$key${_dotNamespaceIfPresent()}$_sharedBy';
  }
}

///Represents a Self key.
class SelfKey extends AtKey {
  SelfKey() {
    super.metadata = Metadata();
    super.metadata?.isPublic = false;
  }

  @override
  String toString() {
    // If sharedWith is populated and sharedWith is equal to sharedBy, then
    // keys is a self key.
    // @alice:phone@alice or phone@alice
    if (_sharedWith != null && _sharedWith!.isNotEmpty) {
      return '$_sharedWith:$key${_dotNamespaceIfPresent()}$_sharedBy';
    }
    return '$key${_dotNamespaceIfPresent()}$_sharedBy';
  }
}

/// Represents a key shared to another atSign.
class SharedKey extends AtKey {
  SharedKey() {
    super.metadata = Metadata();
  }

  @override
  String toString() {
    return '$_sharedWith:$key${_dotNamespaceIfPresent()}$_sharedBy';
  }
}

/// Represents a Private key.
class PrivateKey extends AtKey {
  PrivateKey() {
    super.metadata = Metadata();
  }

  @override
  String toString() {
    return 'privatekey:$key${_dotNamespaceIfPresent()}';
  }
}

/// Represents a local key
/// Local key are confined to the client(device)/server it is created.
/// The key does not sync between the local-secondary and the cloud-secondary.
class LocalKey extends AtKey {
  LocalKey() {
    isLocal = true;
    super.metadata = Metadata();
  }

  @override
  String toString() {
    return 'local:$key${_dotNamespaceIfPresent()}$sharedBy';
  }
}

class Metadata {
  /// Represents the time in milliseconds beyond which the key expires
  int? ttl;

  /// Represents the time in milliseconds from when the key becomes active
  int? ttb;

  /// Represents the time frequency in seconds when the cached key gets refreshed
  int? ttr;

  /// CCD (Cascade Delete) means if a shared key is deleted, then the corresponding cached key will also be deleted
  ///
  /// When set to true, on deleting the original key, the corresponding cached key will be deleted,
  /// When set to false, the cached key remains even after the original key is deleted.
  bool? ccd;

  /// This is a derived field representing [ttb] in [DateTime] format
  DateTime? availableAt;

  /// This is a derived field representing [ttl] in [DateTime] format
  DateTime? expiresAt;

  /// This is a derived field representing [ttr] in [DateTime] format
  DateTime? refreshAt;

  /// A date and time representing when the key is created
  DateTime? createdAt;

  /// A date and time representing when the key is last modified
  DateTime? updatedAt;

  /// The [dataSignature] is used to verify authenticity of the public data.
  ///
  /// The public data is signed using the key owner's [ReservedKey.encryptionPrivateKey] and resultant is stored into dataSignature.
  String? dataSignature;

  /// Represents the status of the [SharedKey]
  String? sharedKeyStatus;

  /// When set to true, implies the key is a [PublicKey]
  bool? isPublic = false;

  /// When set to true, implies the key is a HiddenKey
  bool isHidden = false;

  /// Indicates if the namespace should be appended to the key
  ///
  /// By default, is set to true which implies the namespace is appended key
  ///
  /// For reserved key's, [namespaceAware] is set to false to ignore the namespace appending to key
  bool namespaceAware = true;

  /// Determines whether a value is stored as binary data
  /// If value of the key is blob (images, videos etc), the binary data is encoded to text and [isBinary] is set to true.
  bool? isBinary = false;

  /// Represents if the notify text is encrypted
  /// When set to true, implies the value is encrypted
  bool? isEncrypted;

  /// When set to true, indicates the key is a cached key
  bool isCached = false;

  /// Stores the encrypted shared key
  ///
  /// The value is encrypted with the shared key and shared key is encrypted with the sharedWith atSign encryption public key
  String? sharedKeyEnc;

  /// Stores the checksum of the [ReservedKey.encryptionPublicKey] of the SharedWith atSign.
  ///
  /// Used to verify if the encryption key-pair used to encrypt and decrypt the value are same
  String? pubKeyCS;

  /// Represents the type of encoding (ex: base64) when the value contains a new line character's
  String? encoding;

  @override
  String toString() {
    return 'Metadata{ttl: $ttl, ttb: $ttb, ttr: $ttr,ccd: $ccd, isPublic: $isPublic, isHidden: $isHidden, availableAt : ${availableAt?.toUtc().toString()}, expiresAt : ${expiresAt?.toUtc().toString()}, refreshAt : ${refreshAt?.toUtc().toString()}, createdAt : ${createdAt?.toUtc().toString()},updatedAt : ${updatedAt?.toUtc().toString()},isBinary : $isBinary, isEncrypted : $isEncrypted, isCached : $isCached, dataSignature: $dataSignature, sharedKeyStatus: $sharedKeyStatus, encryptedSharedKey: $sharedKeyEnc, pubKeyCheckSum: $pubKeyCS, encoding: $encoding}';
  }

  Map toJson() {
    var map = {};
    map['availableAt'] = availableAt?.toUtc().toString();
    map['expiresAt'] = expiresAt?.toUtc().toString();
    map['refreshAt'] = refreshAt?.toUtc().toString();
    map[CREATED_AT] = createdAt?.toUtc().toString();
    map[UPDATED_AT] = updatedAt?.toUtc().toString();
    map['isPublic'] = isPublic;
    map[AT_TTL] = ttl;
    map[AT_TTB] = ttb;
    map[AT_TTR] = ttr;
    map[CCD] = ccd;
    map[IS_BINARY] = isBinary;
    map[IS_ENCRYPTED] = isEncrypted;
    map[PUBLIC_DATA_SIGNATURE] = dataSignature;
    map[SHARED_KEY_STATUS] = sharedKeyStatus;
    map[SHARED_KEY_ENCRYPTED] = sharedKeyEnc;
    map[SHARED_WITH_PUBLIC_KEY_CHECK_SUM] = pubKeyCS;
    map[ENCODING] = encoding;
    return map;
  }

  static Metadata fromJson(Map json) {
    var metaData = Metadata();
    try {
      metaData.expiresAt =
          (json['expiresAt'] == null || json['expiresAt'] == 'null')
              ? null
              : DateTime.parse(json['expiresAt']);
      metaData.refreshAt =
          (json['refreshAt'] == null || json['refreshAt'] == 'null')
              ? null
              : DateTime.parse(json['refreshAt']);
      metaData.availableAt =
          (json['availableAt'] == null || json['availableAt'] == 'null')
              ? null
              : DateTime.parse(json['availableAt']);
      metaData.createdAt =
          (json[CREATED_AT] == null || json[CREATED_AT] == 'null')
              ? null
              : DateTime.parse(json[CREATED_AT]);
      metaData.updatedAt =
          (json[UPDATED_AT] == null || json[UPDATED_AT] == 'null')
              ? null
              : DateTime.parse(json[UPDATED_AT]);
      metaData.ttl = (json[AT_TTL] is String)
          ? int.parse(json[AT_TTL])
          : (json[AT_TTL] == null)
              ? 0
              : json[AT_TTL];
      metaData.ttb = (json[AT_TTB] is String)
          ? int.parse(json[AT_TTB])
          : (json[AT_TTB] == null)
              ? 0
              : json[AT_TTB];
      metaData.ttr = (json[AT_TTR] is String)
          ? int.parse(json[AT_TTR])
          : (json[AT_TTR] == null)
              ? 0
              : json[AT_TTR];
      metaData.ccd = json[CCD];
      metaData.isBinary = json[IS_BINARY];
      metaData.isEncrypted = json[IS_ENCRYPTED];
      metaData.isPublic = json[IS_PUBLIC];
      metaData.dataSignature = json[PUBLIC_DATA_SIGNATURE];
      metaData.sharedKeyStatus = json[SHARED_KEY_STATUS];
      metaData.sharedKeyEnc = json[SHARED_KEY_ENCRYPTED];
      metaData.pubKeyCS = json[SHARED_WITH_PUBLIC_KEY_CHECK_SUM];
      metaData.encoding = json[ENCODING];
    } catch (error) {
      // TODO swallowing the error does not seem like the right thing to do
      print('AtMetaData.fromJson error: ${error.toString()}');
    }
    return metaData;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Metadata &&
          runtimeType == other.runtimeType &&
          ttl == other.ttl &&
          ttb == other.ttb &&
          ttr == other.ttr &&
          ccd == other.ccd &&
          availableAt == other.availableAt &&
          expiresAt == other.expiresAt &&
          refreshAt == other.refreshAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          dataSignature == other.dataSignature &&
          sharedKeyStatus == other.sharedKeyStatus &&
          isPublic == other.isPublic &&
          isHidden == other.isHidden &&
          namespaceAware == other.namespaceAware &&
          isBinary == other.isBinary &&
          isEncrypted == other.isEncrypted &&
          isCached == other.isCached &&
          sharedKeyEnc == other.sharedKeyEnc &&
          pubKeyCS == other.pubKeyCS &&
          encoding == other.encoding;

  @override
  int get hashCode =>
      ttl.hashCode ^
      ttb.hashCode ^
      ttr.hashCode ^
      ccd.hashCode ^
      availableAt.hashCode ^
      expiresAt.hashCode ^
      refreshAt.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      dataSignature.hashCode ^
      sharedKeyStatus.hashCode ^
      isPublic.hashCode ^
      isHidden.hashCode ^
      namespaceAware.hashCode ^
      isBinary.hashCode ^
      isEncrypted.hashCode ^
      isCached.hashCode ^
      sharedKeyEnc.hashCode ^
      pubKeyCS.hashCode ^
      encoding.hashCode;
}

class AtValue {
  dynamic value;
  Metadata? metadata;

  @override
  String toString() {
    return 'AtValue{value: $value, metadata: $metadata}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtValue &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          metadata == other.metadata;

  @override
  int get hashCode => value.hashCode ^ metadata.hashCode;
}
