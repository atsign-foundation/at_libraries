class EnrollResponse {
  String enrollmentId;
  EnrollStatus enrollStatus;

  EnrollResponse(this.enrollmentId, this.enrollStatus);

  @override
  String toString() {
    return 'EnrollResponse{enrollmentId: $enrollmentId, enrollStatus: $enrollStatus}';
  }
}

enum EnrollStatus { pending, approved, denied, revoked, expired }

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
    case 'expired':
      return EnrollStatus.expired;
    default:
      throw ArgumentError('Unknown enroll status string: $value');
  }
}
