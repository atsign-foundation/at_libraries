class EnrollResponse {
  String enrollmentId;
  EnrollStatus enrollStatus;

  EnrollResponse(this.enrollmentId, this.enrollStatus);

  @override
  String toString() {
    return 'EnrollResponse{enrollmentId: $enrollmentId, enrollStatus: $enrollStatus}';
  }
}

enum EnrollStatus { pending, approved, denied, revoked }

EnrollStatus getEnrollStatusFromString(String value) {
  switch (value) {
    case 'approved':
      return EnrollStatus.approved;
    case 'denied':
      return EnrollStatus.denied;
    case 'pending':
      return EnrollStatus.pending;
    case 'revoked':
      return EnrollStatus.revoked;
    default:
      throw ArgumentError('Unknown enroll status string: $value');
  }
}
