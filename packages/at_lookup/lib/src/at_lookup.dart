import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_chops/at_chops.dart';

abstract class AtLookUp {
  late AtChops _atChops;

  /// update
  Future<bool> update(String key, String value,
      {String? sharedWith, Metadata? metadata});

  /// lookup
  Future<String> lookup(String key, String sharedBy,
      {bool auth = true, bool verifyData = false});

  /// plookup
  Future<String> plookup(String key, String sharedBy);

  Future<String> llookup(String key,
      {String? sharedBy, String? sharedWith, bool isPublic = false});

  /// delete
  Future<bool> delete(String key, {String? sharedWith, bool isPublic = false});

  /// scan
  Future<List<String>> scan({String? regex, String? sharedBy});

  Future<String?> executeVerb(VerbBuilder builder, {bool sync = false});

  set atChops(AtChops atChops) {
    _atChops = atChops;
  }

  AtChops get atChops => _atChops;
}
