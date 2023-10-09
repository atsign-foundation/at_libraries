class AtAuthResponse {
  String atSign;
  AtAuthResponse(this.atSign);
  bool isSuccessful = false;

  @override
  String toString() {
    return 'AtAuthResponse{atSign: $atSign, isSuccessful: $isSuccessful}';
  }
}
