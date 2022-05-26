import 'package:at_commons/at_commons.dart' show AtKey, AtValue;
import 'package:at_stream/src/collection/iterable/at_stream_iterable_impl.dart';
import 'package:at_stream/src/core/at_stream_mixin.dart';

abstract class AtStreamIterable<T> extends Stream<Iterable<T>> implements AtStreamMixin<Iterable<T>> {
  factory AtStreamIterable({
    String? regex,
    required T Function(AtKey key, AtValue value) convert,
    String Function(AtKey key, AtValue value)? generateRef,
    String? sharedBy,
    String? sharedWith,
    bool shouldGetKeys = true,
  }) {
    return AtStreamIterableImpl<T>(
      regex: regex,
      convert: convert,
      generateRef: generateRef,
      sharedBy: sharedBy,
      sharedWith: sharedWith,
      shouldGetKeys: shouldGetKeys,
    );
  }
}
