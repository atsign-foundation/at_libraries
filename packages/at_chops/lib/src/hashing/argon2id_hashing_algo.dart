import 'dart:async';
import 'dart:convert';

import 'package:at_chops/src/hashing/at_hashing_algorithm.dart';
import 'package:cryptography/cryptography.dart';

/// A class that implements the Argon2id hashing algorithm for password hashing.
///
/// This class provides a method to hash a given password using the Argon2id
/// algorithm, which is a memory-hard, CPU-intensive key derivation function
/// suitable for password hashing and encryption key derivation.
///
/// The class uses the `cryptography` package's `Argon2id` algorithm for deriving
/// a key from a password and encodes the result into a Base64 string.
class Argon2idHashingAlgo implements AtHashingAlgorithm<String, String> {
  /// Hashes a given password using the Argon2id algorithm.
  ///
  /// The [password] parameter is required, and it represents the password or
  /// passphrase to be hashed.
  ///
  /// The [hashParams] parameter is optional. It allows customizing the Argon2id
  /// parameters, such as:
  /// - [HashParams.parallelism]: The degree of parallelism (threads) to use.
  /// - [HashParams.memory]: The amount of memory (in KB) to use.
  /// - [HashParams.iterations]: The number of iterations (time cost) to apply.
  /// - [HashParams.hashLength]: The length of the resulting hash (in bytes).
  ///
  /// If [hashParams] is not provided, default values will be used.
  ///
  /// The method returns a [Future] that resolves to a Base64-encoded string
  /// representing the hashed value of the input password.
  ///
  /// Throws:
  /// - [ArgumentError] if the provided password is null or empty.
  ///
  /// Returns a Base64-encoded string representing the derived key.
  @override
  Future<String> hash(String password, {ArgonHashParams? hashParams}) async {
    hashParams ??= ArgonHashParams();
    final argon2id = Argon2id(
        parallelism: hashParams.parallelism,
        memory: hashParams.memory,
        iterations: hashParams.iterations,
        hashLength: hashParams.hashLength);

    SecretKey secretKey = await argon2id.deriveKeyFromPassword(
        password: password, nonce: password.codeUnits);

    return Base64Encoder().convert(await secretKey.extractBytes());
  }
}

/// A class that holds the parameters for configuring a hashing algorithm.
///
/// This class is used to customize the behavior of a hashing algorithm by
/// providing control over key parameters such as parallelism, memory usage,
/// iteration count, and the length of the resulting hash.
///
/// These parameters are particularly useful when working with algorithms
/// like Argon2id, which can be adjusted for performance and security needs.

class ArgonHashParams extends HashParams {
  /// The degree of parallelism, representing the number of threads used during hashing.
  ///
  /// The default value is 2, meaning the hashing algorithm will use 2 threads.
  int parallelism = 2;

  /// The amount of memory (in KB) to be used during the hashing process.
  ///
  /// The default value is 10,000 KB (10 MB). Increasing the memory value
  /// can make the hashing process more resistant to brute-force attacks.
  int memory = 10000;

  /// The number of iterations (time cost) applied during the hashing process.
  ///
  /// The default value is 2. A higher iteration count increases the time
  /// required to compute the hash, providing greater security.
  int iterations = 2;

  /// The length of the resulting hash in bytes.
  ///
  /// The default value is 32 bytes. This value controls the size of the
  /// derived hash or key.
  int hashLength = 32;
}
