class AtAuthResponse {
  String atSign;
  AtAuthResponse(this.atSign);
  bool isSuccessful = false;
  String? enrollmentId;

  @override
  String toString() {
    return 'AtAuthResponse{atSign: $atSign, enrollmentId: $enrollmentId, isSuccessful: $isSuccessful}';
  }
}
