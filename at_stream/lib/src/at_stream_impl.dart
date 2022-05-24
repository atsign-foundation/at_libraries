part of 'at_stream.dart';

class _AtStreamImpl<T>  with _AtStreamMixin<T> implements AtStream<T>{
  @override
  void handleNotification(AtKey key, AtValue value, String? operation) {
    T data = convert(key, value);
    switch (operation) {
      case 'delete':
      case 'remove':
        return;
      case 'init':
      case 'update':
      case 'append':
      default:
        controller.add(data);
    }
  }

  _AtStreamImpl({
    this.regex,
    required this.convert,
    this.sharedBy,
    this.sharedWith,
    this.shouldGetKeys = true,
  }) {
    init();
  }

  @override
  final String? regex;

  @override
  final T Function(AtKey p1, AtValue p2) convert;

  @override
  final String? sharedBy;

  @override
  final String? sharedWith;

  @override
  final bool shouldGetKeys;
}
