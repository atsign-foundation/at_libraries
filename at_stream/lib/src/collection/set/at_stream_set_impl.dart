import 'package:at_stream/src/collection/set/at_stream_set.dart';
import 'package:at_stream/src/core/at_stream_iterable_base.dart';

class AtStreamSetImpl<T> extends AtStreamIterableBase<T, Set<T>> implements AtStreamSet<T> {
  AtStreamSetImpl({
    required super.convert,
    super.regex,
    super.generateRef,
    super.sharedBy,
    super.sharedWith,
    super.shouldGetKeys,
  }) : super(castTo: (values) => values.toSet());
}
