import 'dart:async';
import 'package:at_client/at_client.dart' show AtClient, AtClientManager, AtNotification;
import 'package:at_commons/at_commons.dart' show AtKey, AtValue;
import 'package:meta/meta.dart';

part 'at_stream_mixin.dart';
part 'at_stream_impl.dart';
part 'at_stream_iterable_impl.dart';

abstract class AtStream<T> extends Stream<T> with _AtStreamMixin<T> {
  factory AtStream({
    String? regex,
    required T Function(AtKey key, AtValue value) convert,
    String? sharedBy,
    String? sharedWith,
    bool shouldGetKeys = true,
  }) {
    return _AtStreamImpl(
      regex: regex,
      convert: convert,
      sharedBy: sharedBy,
      sharedWith: sharedWith,
      shouldGetKeys: shouldGetKeys,
    );
  }
}

abstract class AtStreamIterable<T> extends Stream<Iterable<T>> with _AtStreamMixin<Iterable<T>> {
  factory AtStreamIterable({
    String? regex,
    required T Function(AtKey key, AtValue value) convert,
    String Function(AtKey key, AtValue value)? generateRef,
    String? sharedBy,
    String? sharedWith,
    bool shouldGetKeys = true,
  }) {
    return _AtStreamIterableImpl(
      regex: regex,
      convert: convert,
      generateRef: generateRef,
      sharedBy: sharedBy,
      sharedWith: sharedWith,
      shouldGetKeys: shouldGetKeys,
    );
  }
}
