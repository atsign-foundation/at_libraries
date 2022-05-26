import 'package:at_stream/src/collection/list/at_stream_list.dart';
import 'package:at_stream/src/core/at_stream_iterable_base.dart';

class AtStreamListImpl<T> extends AtStreamIterableBase<T, List<T>> implements AtStreamList<T> {
  AtStreamListImpl({
    required super.convert,
    super.regex,
    super.generateRef,
    super.sharedBy,
    super.sharedWith,
    super.shouldGetKeys,
  }) : super(castTo: (values) => values.toList());
}
