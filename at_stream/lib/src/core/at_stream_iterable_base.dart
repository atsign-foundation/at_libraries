import 'package:at_commons/at_commons.dart' show AtKey, AtValue;
import 'package:at_stream/src/core/at_stream_mixin.dart';

class AtStreamIterableBase<T, I extends Iterable<T>> extends AtStreamMixin<I> implements Stream<I> {
  final Map<String, T> _store = {};

  final I Function(Iterable<T> values) _castTo;
  final String Function(AtKey key, AtValue value) _generateRef;

  @override
  void handleNotification(AtKey key, AtValue value, String? operation) {
    T data = convert(key, value);
    switch (operation) {
      case 'delete':
      case 'remove':
        _store.remove(_generateRef(key, value));
        break;
      case 'init':
      case 'update':
      case 'append':
      default:
        _store[_generateRef(key, value)] = data;
    }
    controller.add(_castTo(_store.values));
  }

  AtStreamIterableBase({
    required super.convert,
    super.regex,
    super.sharedBy,
    super.sharedWith,
    super.shouldGetKeys,
    String Function(AtKey key, AtValue value)? generateRef,
    I Function(Iterable<T> values)? castTo,
  })  : _generateRef = generateRef ?? ((key, value) => key.key ?? ''),
        _castTo = castTo ?? ((Iterable<T> values) => values as I);
}
