import 'package:at_commons/at_commons.dart' show AtKey, AtValue;
import 'package:at_stream/src/collection/list/at_stream_list_impl.dart';
import 'package:at_stream/src/core/at_stream_mixin.dart';

abstract class AtStreamList<T> extends Stream<List<T>> implements AtStreamMixin<List<T>> {
  factory AtStreamList({
    String? regex,
    required T Function(AtKey key, AtValue value) convert,
    String Function(AtKey key, AtValue value)? generateRef,
    String? sharedBy,
    String? sharedWith,
    bool shouldGetKeys = true,
  }) {
    return AtStreamListImpl<T>(
      regex: regex,
      convert: convert,
      generateRef: generateRef,
      sharedBy: sharedBy,
      sharedWith: sharedWith,
      shouldGetKeys: shouldGetKeys,
    );
  }
}
