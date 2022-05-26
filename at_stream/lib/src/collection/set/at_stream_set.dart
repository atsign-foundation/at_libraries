import 'package:at_commons/at_commons.dart' show AtKey, AtValue;
import 'package:at_stream/src/collection/set/at_stream_set_impl.dart';
import 'package:at_stream/src/core/at_stream_mixin.dart';

abstract class AtStreamSet<T> extends Stream<Set<T>> implements AtStreamMixin<Set<T>> {
  factory AtStreamSet({
    String? regex,
    required T Function(AtKey key, AtValue value) convert,
    String Function(AtKey key, AtValue value)? generateRef,
    String? sharedBy,
    String? sharedWith,
    bool shouldGetKeys = true,
  }) {
    return AtStreamSetImpl<T>(
      regex: regex,
      convert: convert,
      generateRef: generateRef,
      sharedBy: sharedBy,
      sharedWith: sharedWith,
      shouldGetKeys: shouldGetKeys,
    );
  }
}
