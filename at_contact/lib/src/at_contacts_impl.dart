import 'dart:convert';
import 'package:at_client/at_client.dart';
import 'package:at_contact/src/model/at_contact.dart';
import 'package:at_contact/src/model/at_group.dart';
import 'package:at_contact/src/service/at_contacts_library.dart';
import 'package:at_contact/src/config/AppConstants.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_utils.dart';

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

  /// takes AtGroup as an input and creates the group
  /// on success return AtGroup otherwise null
  @override
  Future<AtGroup> createGroup(AtGroup atGroup) async {
    var groupName = atGroup.name;
    if (atGroup == null || atGroup.name == null) {
      throw Exception('Group name is null or empty String');
    }
    var group = await getGroup(groupName);
    if (group != null) {
      throw AlreadyExistsException(
          'Group is already exisits with name $groupName');
    }

    // create key from group name.
    var atGroupKey = formGroupKey(groupName);
    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    var atKey = AtKey()
      ..key = atGroupKey
      ..metadata = metadata;
//    //update atGroup
    atGroup.createdBy = AtUtils.fixAtSign(atSign);
    atGroup.updatedBy = AtUtils.fixAtSign(atSign);
    atGroup.createdOn = DateTime.now();
    atGroup.updatedOn = DateTime.now();

    var json = atGroup.toJson();
    var value = jsonEncode(json);
    var result = await atClient.put(atKey, value);
    if (result) {
      var atGroupBasicInfo = AtGroupBasicInfo(groupName, atGroupKey);
      // add AtGroupBasicInfo object to list of groupNames
      var success = await _addToGroupList(atGroupBasicInfo);
      return atGroup;
    }
    return null;
  }

  /// fetches all the group names as a list
  /// on success return List of Group names otherwise []
  @override
  Future<List<String>> listGroupNames() async {
    var groupsListKey = getGroupsListKey();
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    var atKey = AtKey()
      ..key = groupsListKey
      ..metadata = metadata;
    var result = await atClient.get(atKey);
    // get name from AtGroupBasicInfo for all the groups.
    var list = [];
    if (result != null) {
      list = (result.value != null) ? jsonDecode(result.value) : [];
    }
    var groupNames = [];
    list.forEach((group) {
      var groupInfo = AtGroupBasicInfo.fromJson(jsonDecode(group));
      groupNames.add(groupInfo.atGroupName);
    });
    return groupNames;
  }

  @override
  List<AtGroup> listGroups() {
    // <TODO>
  }

  /// takes groupName as an input and
  /// get the group details
  /// on success return AtGroup otherwise null
  @override
  Future<AtGroup> getGroup(String groupName) async {
    if (groupName == null || groupName.isEmpty) {
      return null;
    }
    // create key from group name.
    var atGroupKey = formGroupKey(groupName);
    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    //create atKey
    var atKey = AtKey()
      ..key = atGroupKey
      ..metadata = metadata;
    var group;
    await atClient.get(atKey).then((atValue) {
      if (atValue != null) {
        var value = atValue.value;
        value = value?.replaceAll('data:', '');
        if (value != null && value != 'null') {
          var json = jsonDecode(value);
          if (json != null) {
            group = AtGroup.fromJson(json);
          }
        }
      }
    });
    return group;
  }

  /// takes Set of AtContacts as an input and
  /// Adds the contacts to the group members
  /// on success return true otherwise false
  @override
  Future<bool> addMembers(Set<AtContact> atContacts, AtGroup atGroup) async {
    if (atContacts.isEmpty || atGroup == null) {
      return false;
    }
    //create groupKey from group name
    var atGroupKey = formGroupKey(atGroup.name);
    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    // create atkey
    var atKey = AtKey()
      ..key = atGroupKey
      ..metadata = metadata;
    // Add all contacts in atContacts from atGroup
    atGroup.members.addAll(atContacts);
    var json = atGroup.toJson();
    var value = jsonEncode(json);
    return await atClient.put(atKey, value);
  }

  /// takes Set of AtContacts as an input and
  /// deletes the contacts to the group members
  /// on success return true otherwise false
  @override
  Future<bool> deleteMembers(Set<AtContact> atContacts, AtGroup atGroup) async {
    if (atContacts.isEmpty || atGroup == null) {
      return false;
    }
    //create groupKey from group name
    var atGroupKey = formGroupKey(atGroup.name);
    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    //create atkey
    var atKey = AtKey()
      ..key = atGroupKey
      ..metadata = metadata;
    // removing all contacts in atContacts from atGroup
    atGroup.members.removeAll(atContacts);
    var json = atGroup.toJson();
    var value = jsonEncode(json);
    return await atClient.put(atKey, value);
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

  /// Created group key from the group name provided
  String formGroupKey(String groupName) {
    var key = AtUtils.formatAtSign(groupName);
    key = AtUtils.fixAtSign(key);
    key = key.replaceFirst('@', '');
    var modifiedKey =
        '${AppConstants.CONTACT_KEY_PREFIX}.${AppConstants.GROUP_KEY_PREFIX}.$key.${atSign.replaceFirst('@', '')}';
    return modifiedKey;
  }

  ///Adds a group to group list
  Future<bool> _addToGroupList(AtGroupBasicInfo atGroupBasicInfo) async {
    var groupsListKey = getGroupsListKey();
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    var atKey = AtKey()
      ..key = groupsListKey
      ..metadata = metadata;
    var result = await atClient.get(atKey);
    var list = [];
    if (result != null) {
      list = (result.value != null) ? jsonDecode(result.value) : [];
    }
    list.add(jsonEncode(atGroupBasicInfo));
    return await atClient.put(atKey, jsonEncode(list));
  }

  String getGroupsListKey() {
    var groupsListKey =
        '${AppConstants.CONTACT_KEY_PREFIX}.${AppConstants.GROUPS_LIST_KEY_PREFIX}.${atSign.replaceFirst('@', '')}';
    return groupsListKey;
  }

  @override
  Future<bool> isMember(AtContact atContact, AtGroup atGroup) {
    // TODO: implement isMember
    return null;
  }
}
