import 'dart:async';

import 'package:at_commons/at_commons.dart' show AtKey, AtValue;
import 'package:at_stream/src/collection/element/at_stream_impl.dart';
import 'package:at_stream/src/core/at_stream_mixin.dart';

abstract class AtStream<T> extends Stream<T?> implements AtStreamMixin<T?> {
  factory AtStream({
    String? regex,
    required T? Function(AtKey key, AtValue value) convert,
    String? sharedBy,
    String? sharedWith,
    bool shouldGetKeys = true,
  }) {
    return AtStreamImpl(
      regex: regex,
      convert: convert,
      sharedBy: sharedBy,
      sharedWith: sharedWith,
      shouldGetKeys: shouldGetKeys,
    );
  }
}
