// ignore_for_file: constant_identifier_names
enum SharedKeyStatus {
  LOCAL_UPDATED,
  REMOTE_UPDATED,
  SHARED_WITH_NOTIFIED,
  SHARED_WITH_LOOKED_UP,
  SHARED_WITH_READ
}

String getSharedKeyName(SharedKeyStatus d) => '$d'.split('.').last;
