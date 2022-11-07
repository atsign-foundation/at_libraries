import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/utils/string_utils.dart';

/// An abstract class implementing the [VerbBuilder].
/// Class contains the implementation for validating the key data and building
/// the key (common for all verb builder) from the verb builder instances.
abstract class AbstractVerbBuilder implements VerbBuilder {
  /// Represents the AtKey instance to populate the verb builder data
  AtKey atKeyObj = AtKey();

  /// From the [VerbBuilder] instances construct a string representation of an [AtKey]
  ///
  /// Returns a string representation of [AtKey]
  String buildKey() {
    String key = '';
    if (atKeyObj.metadata?.isCached == true) {
      key = 'cached:';
    }
    if (atKeyObj.isLocal == true) {
      key = 'local:';
    } else if (atKeyObj.metadata?.isPublic == true) {
      key += 'public:';
    } else if (atKeyObj.sharedWith.isNotNull) {
      key += '${VerbUtil.formatAtSign(atKeyObj.sharedWith)}:';
    }
    key += '${atKeyObj.key!}${VerbUtil.formatAtSign(atKeyObj.sharedBy)}';
    return key;
  }

  /// Validates the [AtKey]
  ///
  ///
  /// Throws [InvalidAtKeyException] when the following conditions are met
  /// * When [metadata.isCached] is set to true on a local key
  ///
  /// * When [metadata.isPublic] is set to true on a local key
  ///
  /// * When sharedWith is populated on a local key
  ///
  /// * When [metadata.isPublic] is set to true on a shared key
  ///
  /// * When [AtKey.key] is set to null or empty
  ///
  /// * When [AtKey.key] contains @ or : characters
  void validateKey() {
    if (atKeyObj.metadata?.isCached == true && atKeyObj.isLocal == true) {
      throw InvalidAtKeyException('Cached key cannot be a local key');
    }
    if (atKeyObj.isLocal == true &&
        (atKeyObj.metadata?.isPublic == true ||
            atKeyObj.sharedWith.isNotNull)) {
      throw InvalidAtKeyException(
          'When isLocal is set to true, cannot set isPublic and sharedWith');
    }
    if (atKeyObj.metadata?.isPublic == true && atKeyObj.sharedWith.isNotNull) {
      throw InvalidAtKeyException(
          'When isPublic is set to true, sharedWith cannot be populated');
    }
    if (atKeyObj.key.isNull) {
      throw InvalidAtKeyException('Key cannot be null or empty');
    }
    if (atKeyObj.key!.contains(RegExp('[@:]'))) {
      throw InvalidAtKeyException(
          'Key cannot cannot contains following characters - @, :');
    }
  }
}
