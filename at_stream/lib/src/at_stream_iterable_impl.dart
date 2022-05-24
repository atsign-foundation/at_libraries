part of 'at_stream.dart';

class _AtStreamIterableImpl<T> with _AtStreamMixin<Iterable<T>> implements AtStreamIterable<T> {
  final Map<String, T> _store = {};

  @override
  void handleNotification(AtKey key, AtValue value, String? operation) {
    T data = convert(key, value);
    switch (operation) {
      case 'delete':
      case 'remove':
        _store.remove(generateRef(key, value));
        return;
      case 'init':
      case 'update':
      case 'append':
      default:
        _store[generateRef(key, value)] = data;
    }
    controller.add(_store.values);
  }

  _AtStreamIterableImpl({
    this.regex,
    required this.convert,
    String Function(AtKey key, AtValue value)? generateRef,
    this.sharedBy,
    this.sharedWith,
    this.shouldGetKeys = true,
  }) : generateRef = generateRef ?? ((key, value) => key.key ?? '') {
    init();
  }

  @override
  final String? regex;

  @override
  final T Function(AtKey key, AtValue value) convert;

  final String Function(AtKey key, AtValue value) generateRef;

  @override
  final String? sharedBy;

  @override
  final String? sharedWith;

  @override
  final bool shouldGetKeys;
}
