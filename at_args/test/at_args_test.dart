import 'dart:io';

import 'package:at_args/args.dart';
import 'package:at_args/src/config/dot_atsign.dart';
import 'package:test/test.dart';

void main() {
  group('DotAtsign', () {
    test('DotAtsign is created without errors', () {
      DotAtsign().root;
    });
  });
}
