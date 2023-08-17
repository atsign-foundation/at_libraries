import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_lookup/src/cache/secondary_address_finder.dart';

abstract class AtLookUp {
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

  Future<String?> executeCommand(String command, {bool auth = false});

  /// performs a PKAM authentication using private key on the client side and public key on secondary server
  /// Pkam private key should be set in  [atChops.atChopsKeys]
  /// Default signing algorithm for pkam signature is [SigningAlgoType.rsa2048] and default hashing algorithm is [HashingAlgoType.sha256]
  /// Optionally pass enrollmentId if the client is enrolled using APKAM
  Future<bool> pkamAuthenticate({String? enrollmentId});

  /// set an instance of  [AtChops] for signing and verification operations.
  set atChops(AtChops? atChops);

  AtChops? get atChops;

  set secondaryAddressFinder(SecondaryAddressFinder secondaryAddressFinder);

  SecondaryAddressFinder get secondaryAddressFinder;

  /// Signing algorithm for pkam signature
  set signingAlgoType(SigningAlgoType signingAlgoType);

  SigningAlgoType get signingAlgoType;

  /// Hashing algorithm for pkam signature
  set hashingAlgoType(HashingAlgoType hashingAlgoType);

  HashingAlgoType get hashingAlgoType;

  /// EnrollmentId has to be set for clients that are enrolled through APKAM.
  set enrollmentId(String? enrollmentId);

  String? get enrollmentId;
}
