import 'package:at_commons/at_commons.dart' show AtKey, AtValue;
import 'package:at_stream/src/collection/element/at_stream.dart';
import 'package:at_stream/src/core/at_stream_mixin.dart';

class AtStreamImpl<T> extends AtStreamMixin<T?> implements AtStream<T> {
  @override
  void handleNotification(AtKey key, AtValue value, String? operation) {
    T? data = convert(key, value);
    if(data == null) return controller.add(null);
    switch (operation) {
      case 'delete':
      case 'remove':
        return controller.add(null);
      case 'init':
      case 'update':
      case 'append':
      default:
        controller.add(data);
    }
  }

  AtStreamImpl({
    required super.convert,
    super.regex,
    super.sharedBy,
    super.sharedWith,
    super.shouldGetKeys,
  });
}
