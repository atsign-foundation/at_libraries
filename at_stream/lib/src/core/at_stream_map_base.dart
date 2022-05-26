import 'package:at_commons/at_commons.dart' show AtKey, AtValue;
import 'package:at_stream/src/core/at_stream_mixin.dart';

class AtStreamMapBase<K, V, I extends Map<K,V>> extends AtStreamMixin<I> implements Stream<I> {
  final Map<String, MapEntry<K,V>> _store = {};

  final I Function(Iterable<MapEntry<K,V>> values) _castTo;
  final String Function(AtKey key, AtValue value) _generateRef;

  @override
  void handleNotification(AtKey key, AtValue value, String? operation) {
    MapEntry<K,V> data = convert(key, value);
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

  AtStreamMapBase({
    required super.convert,
    super.regex,
    super.sharedBy,
    super.sharedWith,
    super.shouldGetKeys,
    String Function(AtKey key, AtValue value)? generateRef,
    I Function(Iterable<MapEntry<K,V>> values)? castTo,
  })  : _generateRef = generateRef ?? ((key, value) => key.key ?? ''),
        _castTo = castTo ?? ((Iterable<MapEntry<K,V>> values) => values as I);
}
