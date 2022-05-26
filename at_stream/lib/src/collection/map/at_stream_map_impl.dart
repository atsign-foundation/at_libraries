import 'dart:core';

import 'package:at_stream/at_stream.dart';
import 'package:at_stream/src/collection/map/at_stream_map.dart';
import 'package:at_stream/src/core/at_stream_map_base.dart';

class AtStreamMapImpl<K, V> extends AtStreamMapBase<K,V, Map<K,V>> implements AtStreamMap<K,V> {
  AtStreamMapImpl({
    required super.convert,
    super.regex,
    super.generateRef,
    super.sharedBy,
    super.sharedWith,
    super.shouldGetKeys,
  }) : super(castTo: (values) => Map.fromIterable(values));
}
