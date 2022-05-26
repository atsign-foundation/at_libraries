import 'package:at_commons/at_commons.dart' show AtKey, AtValue;
import 'package:at_stream/src/collection/map/at_stream_map_impl.dart';
import 'package:at_stream/src/core/at_stream_mixin.dart';

abstract class AtStreamMap<K, V> extends Stream<Map<K, V>> implements AtStreamMixin<Map<K, V>> {
  factory AtStreamMap({
    String? regex,
    required MapEntry<K, V> Function(AtKey key, AtValue value) convert,
    String Function(AtKey key, AtValue value)? generateRef,
    String? sharedBy,
    String? sharedWith,
    bool shouldGetKeys = true,
  }) {
    return AtStreamMapImpl<K, V>(
      regex: regex,
      convert: convert,
      generateRef: generateRef,
      sharedBy: sharedBy,
      sharedWith: sharedWith,
      shouldGetKeys: shouldGetKeys,
    );
  }
}
