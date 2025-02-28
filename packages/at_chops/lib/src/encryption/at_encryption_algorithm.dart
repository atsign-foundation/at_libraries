import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/encryption/initalisation_vector.dart';
import 'package:at_chops/src/key/key.dart';

/// Interface for encrypting and decrypting data. Check [DefaultEncryptionAlgo] for sample implementation.
abstract class AtEncryptionAlgorithm<T, V> {
  /// Encrypts the passed bytes. Bytes are passed as [Uint8List]. Encode String data type to [Uint8List] using [utf8.encode].
  FutureOr<V> encrypt(T plainData);

  /// Decrypts the passed encrypted bytes.
  FutureOr<V> decrypt(T encryptedData);
}

/// Interface for symmetric encryption algorithms. Check [AESEncryptionAlgo] for sample implementation.
abstract class SymmetricEncryptionAlgorithm<T, V>
    extends AtEncryptionAlgorithm<T, V> {
  @override
  FutureOr<V> encrypt(T plainData, {InitialisationVector iv});

  @override
  FutureOr<V> decrypt(T encryptedData, {InitialisationVector iv});
}

/// Interface for asymmetric encryption algorithms. Check [DefaultEncryptionAlgo] for sample implementation.
abstract class AsymmetricEncryptionAlgorithm<Pub extends AtPublicKey,
        Priv extends AtPrivateKey>
    extends AtEncryptionAlgorithm<Uint8List, Uint8List> {
  Pub? atPublicKey;
  Priv? atPrivateKey;

  /// Encrypt [plainData] with [atPublicKey.publicKey]
  @override
  Uint8List encrypt(Uint8List plainData);

  /// Decrypt [encryptedData] with [atPrivateKey.privateKey]
  @override
  Uint8List decrypt(Uint8List encryptedData);
}
