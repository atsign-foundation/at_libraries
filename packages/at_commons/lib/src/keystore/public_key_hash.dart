/// Represents hash of an atsign's public encryption key and the hashing algorithm used
class PublicKeyHash {
  String hash;
  PublicKeyHashingAlgo publicKeyHashingAlgo;

  PublicKeyHash(this.hash, this.publicKeyHashingAlgo);

  @override
  String toString() {
    return 'PublicKeyHash{hash: $hash, publicKeyHashingAlgo: $publicKeyHashingAlgo}';
  }

  Map toJson() {
    var map = {};
    map['hash'] = hash;
    map['algo'] = publicKeyHashingAlgo.name;
    return map;
  }

  static PublicKeyHash fromJson(Map json) {
    return PublicKeyHash(
        json['hash'], PublicKeyHashingAlgo.values.byName(json['algo']));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicKeyHash &&
          runtimeType == other.runtimeType &&
          hash == other.hash &&
          publicKeyHashingAlgo == other.publicKeyHashingAlgo;

  @override
  int get hashCode => hash.hashCode ^ publicKeyHashingAlgo.hashCode;
}

enum PublicKeyHashingAlgo { sha256, sha512 }
