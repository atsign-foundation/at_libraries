import 'dart:convert';
import 'package:at_client/at_client.dart';
import 'package:at_contact/src/model/at_contact.dart';
import 'package:at_contact/src/service/at_contacts_library.dart';
import 'package:at_contact/src/config/AppConstants.dart';
import 'package:at_commons/at_commons.dart';

class AtContactsImpl implements AtContactsLibrary {
  AtClientImpl _atClient;
  String _atSign;

  String get atSign => _atSign;

  set atSign(String value) {
    _atSign = value;
  }

  AtContactsImpl(AtClient atClient, String atSign) {
    _atSign = atSign;
    _atClient = atClient;
  }

  AtClientImpl get atClient => _atClient;

  set atClient(AtClient value) {
    _atClient = value;
  }

  static Future<AtContactsImpl> getInstance(String atSign) async {
    var atClient = await AtClientImpl.getClient(atSign);
    return AtContactsImpl(atClient, atSign);
  }

  // TODO add more dart documentation

  /// returns  true on success otherwise false.
  /// has to pass the [AtContact] to add new contact into the contact_list
  /// if atSign value is 'null' then returns false
  @override
  Future<bool> add(AtContact contact) async {
    var atSign = '${contact.atSign}';
    //check if atSign is 'null'
    if (atSign == null) return false;
    var modifiedKey = formKey(atSign);
    var json = contact.toJson();
    var value = jsonEncode(json);
    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    var atKey = AtKey()
      ..key = modifiedKey
      ..metadata = metadata;
    return await atClient.put(atKey, value);
  }

  ///update the existing contact
  @override
  Future<bool> update(AtContact contact) async {
    contact.updatedOn = DateTime.now();
    return await add(contact);
  }

  ///returns the [AtContact].has to pass the 'atSign'
  @override
  Future<AtContact> get(String atSign) async {
    var contact;
    var modifiedKey = formKey(atSign);
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    var atKey = AtKey()
      ..key = modifiedKey
      ..metadata = metadata;
    await atClient.get(atKey).then((atValue) {
      if (atValue != null) {
        var value = atValue.value;
        value = value?.replaceAll('data:', '');
        if (value != null && value != 'null') {
          var json = jsonDecode(value);
          if (json != null) {
            contact = AtContact.fromJson(json);
          }
        }
      }
    });

    return contact;
  }

  /// takes atSign of the contact as an input and
  /// delete the contacts from the contact_list
  /// on success return true otherwise false
  @override
  Future<bool> delete(String atSign) async {
    var modifiedKey = formKey(atSign);
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    var atKey = AtKey()
      ..key = modifiedKey
      ..metadata = metadata;
    return atClient.delete(atKey);
  }

  /// takes   [AtContact]  as an input and
  /// delete the contacts from the contact_list
  /// on success return true otherwise false
  @override
  Future<bool> deleteContact(AtContact contact) async {
    var atSign = '${contact.atSign}';
    //check if atSign is 'null'
    if (atSign == null) return false;
    return await delete(atSign);
  }

  /// fetch all contacts in the list
  ///returns the list of [AtContact]
  @override
  Future<List<AtContact>> listContacts() async {
    var contactList = <AtContact>[];
    var atSign = _atSign.replaceFirst('@', '');
    var regex =
        '${AppConstants.CONTACT_KEY_PREFIX}.*.${AppConstants.CONTACT_KEY_SUFFIX}.$atSign@$atSign'
            .toLowerCase();
    var scanList = await atClient.getKeys(regex: '$regex');
    if (scanList != null && scanList.isNotEmpty && scanList[0] == '') {
      return contactList;
    }
    for (var key in scanList) {
      key = reduceKey(key);
      var contact = await get(key);
      if (contact != null) contactList.add(contact);
    }
    return contactList;
  }

  /// fetch all active contacts in the list
  ///returns the list of [AtContact]
  @override
  Future<List<AtContact>> listActiveContacts() async {
    var contactList = await listContacts();
    return contactList.where((element) => !element.blocked).toList();
  }

  /// fetch all blocked contacts in the list
  ///returns the list of [AtContact]
  @override
  Future<List<AtContact>> listBlockedContacts() async {
    var contactList = await listContacts();
    return contactList.where((element) => element.blocked).toList();
  }

  /// fetch all Favorite contacts in the list
  ///returns the list of [AtContact]
  @override
  Future<List<AtContact>> listFavoriteContacts() async {
    var contactList = await listContacts();
    return contactList.where((element) => element.favourite).toList();
  }

  String formKey(String key) {
    key = key.replaceFirst('@', '');
    var modifiedKey =
        '${AppConstants.CONTACT_KEY_PREFIX}.$key.${AppConstants.CONTACT_KEY_SUFFIX}.${atSign.replaceFirst('@', '')}';
    return modifiedKey;
  }

  String reduceKey(String key) {
    var modifiedKey = key
        .split('.')
        .where((element) =>
            element != AppConstants.CONTACT_KEY_PREFIX.toLowerCase() &&
            element != AppConstants.CONTACT_KEY_SUFFIX.toLowerCase() &&
            !element.contains(atSign))
        .join('');
    return modifiedKey;
  }
}
