/// Represents hash of an atsign's public encryption key and the hashing algorithm used
class PublicKeyHash {
  String? hash;
  PublicKeyHashingAlgo? publicKeyHashingAlgo;

  @override
  String toString() {
    return 'PublicKeyHash{hash: $hash, publicKeyHashingAlgo: $publicKeyHashingAlgo}';
  }

  Map toJson() {
    var map = {};
    map['hash'] = hash;
    map['algo'] = publicKeyHashingAlgo;
    return map;
  }
}

enum PublicKeyHashingAlgo { sha256, sha512 }
