class PublicKeyHash {
  String? hash;
    PublicKeyHashingAlgo? publicKeyHashingAlgo;

  @override
  String toString() {
    return 'PublicKeyHash{hash: $hash, publicKeyHashingAlgo: $publicKeyHashingAlgo}';
  }
}

enum PublicKeyHashingAlgo { sha256, sha512 }
