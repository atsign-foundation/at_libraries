/// Extending the String class to check null and empty.
extension NullCheck on String? {
  _isNull() {
    if (this == null || this!.isEmpty) {
      return true;
    }
    return false;
  }

  bool get isNull => _isNull();

  bool get isNotNull => !_isNull();
}