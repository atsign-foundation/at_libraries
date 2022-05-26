import 'package:at_stream/src/collection/iterable/at_stream_iterable.dart';
import 'package:at_stream/src/core/at_stream_iterable_base.dart';

class AtStreamIterableImpl<T> extends AtStreamIterableBase<T, Iterable<T>> implements AtStreamIterable<T> {
  AtStreamIterableImpl({
    required super.convert,
    super.regex,
    super.generateRef,
    super.sharedBy,
    super.sharedWith,
    super.shouldGetKeys,
  }) : super(castTo: (values) => values);
}
