import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/verb/scan_verb_builder.dart';
import 'package:test/test.dart';

import 'syntax_test.dart';

void main() {
  group('A group of tests to validate scan regex', () {
    test('test to validate scan verb for showHidden set to true', () {
      var command = 'scan:showHidden:true';
      var verbParams = getVerbParams(VerbSyntax.scan, command);
      expect(verbParams[showHidden], 'true');
    });

    test('test to validate scan verb for showHidden set to false', () {
      var command = 'scan:showHidden:false';
      var verbParams = getVerbParams(VerbSyntax.scan, command);
      expect(verbParams[showHidden], 'false');
    });

    test('test to validate scan verb', () {
      var command = 'scan:showHidden:true:@alice:page:1 .wavi';
      var verbParams = getVerbParams(VerbSyntax.scan, command);
      expect(verbParams[showHidden], 'true');
      expect(verbParams[PAGE], '1');
      expect(verbParams[FOR_AT_SIGN], '@alice');
      expect(verbParams[AT_REGEX], '.wavi');
    });
  });

  group('A group of tests related to scan verb builder', () {
    test('test to validate the scan verb builder', () {
      ScanVerbBuilder scanVerbBuilder = ScanVerbBuilder();
      scanVerbBuilder.showHiddenKeys = true;
      scanVerbBuilder.sharedBy = '@alice';
      scanVerbBuilder.regex = '.wavi';

      var verbParams =
          getVerbParams(VerbSyntax.scan, scanVerbBuilder.buildCommand().trim());
      expect(verbParams[showHidden], 'true');
      expect(verbParams[FOR_AT_SIGN], '@alice');
      expect(verbParams[AT_REGEX], '.wavi');
    });

    test(
        'test to validate the scan verb builder showHidden is not set when set to false',
        () {
      ScanVerbBuilder scanVerbBuilder = ScanVerbBuilder();
      scanVerbBuilder.showHiddenKeys = false;
      scanVerbBuilder.sharedBy = '@alice';
      scanVerbBuilder.regex = '.wavi';

      var verbParams =
          getVerbParams(VerbSyntax.scan, scanVerbBuilder.buildCommand().trim());
      expect(verbParams[showHidden], null);
      expect(verbParams[FOR_AT_SIGN], '@alice');
      expect(verbParams[AT_REGEX], '.wavi');
    });

    test(
        'test to validate the scan verb builder showHidden is not set by default',
        () {
      ScanVerbBuilder scanVerbBuilder = ScanVerbBuilder();
      scanVerbBuilder.sharedBy = '@alice';
      scanVerbBuilder.regex = '.wavi';

      var verbParams =
          getVerbParams(VerbSyntax.scan, scanVerbBuilder.buildCommand().trim());
      expect(verbParams[showHidden], null);
      expect(verbParams[FOR_AT_SIGN], '@alice');
      expect(verbParams[AT_REGEX], '.wavi');
    });
  });
}
