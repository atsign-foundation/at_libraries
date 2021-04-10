import 'dart:convert';

import 'package:at_client/at_client.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_contact/src/config/AppConstants.dart';
import 'package:at_contact/src/model/at_contact.dart';
import 'package:at_contact/src/model/at_group.dart';
import 'package:at_contact/src/service/at_contacts_library.dart';
import 'package:at_utils/at_logger.dart';
import 'package:at_utils/at_utils.dart';
import 'package:uuid/uuid.dart';

class AtContactsImpl implements AtContactsLibrary {
  AtClientImpl _atClient;
  String atSign;
  var logger;

  AtContactsImpl(AtClient atClient, String atSign) {
    this.atSign = atSign;
    _atClient = atClient;
    logger = AtSignLogger(runtimeType.toString());
  }

  AtClientImpl get atClient => _atClient;

  set atClient(AtClient value) {
    _atClient = value;
  }

  static Future<AtContactsImpl> getInstance(String atSign) async {
    try {
      atSign = AtUtils.fixAtSign(AtUtils.formatAtSign(atSign));
    } on Exception {
      rethrow;
    }
    var atClient = await AtClientImpl.getClient(atSign);
    return AtContactsImpl(atClient, atSign);
  }

  /// returns  true on success otherwise false.
  /// has to pass the [AtContact] to add new contact into the contact_list
  /// if atSign value is 'null' then returns false
  @override
  Future<bool> add(AtContact contact) async {
    var atSign = contact.atSign;
    //check if atSign is 'null'
    if (atSign == null) return false;
    var modifiedKey = _formKey(atSign);
    var json = contact.toJson();
    var value = jsonEncode(json);
    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false
      ..isEncrypted = true;
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
  /// Throws [FormatException] on invalid json
  /// Throws class extending [AtException] on invalid atsign.
  @override
  Future<AtContact> get(String atSign) async {
    var contact;
    var modifiedKey = _formKey(atSign);
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
          var json;
          try {
            json = jsonDecode(value);
          } on FormatException catch (e) {
            logger.severe('Invalid JSON. ${e.message} found in JSON : $value');
            throw InvalidSyntaxException('Invalid JSON found');
          }
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
    var modifiedKey = _formKey(atSign);
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
    var atSign = contact.atSign;
    //check if atSign is 'null'
    if (atSign == null) return false;
    return await delete(atSign);
  }

  /// fetch all contacts in the list
  ///returns the list of [AtContact]
  @override
  Future<List<AtContact>> listContacts() async {
    var contactList = <AtContact>[];
    var atSign = this.atSign.replaceFirst('@', '');
    var regex =
        '${AppConstants.CONTACT_KEY_PREFIX}.*.${AppConstants.CONTACT_KEY_SUFFIX}.$atSign@$atSign'
            .toLowerCase();
    var scanList = await atClient.getKeys(regex: regex);
    if (scanList != null && scanList.isNotEmpty && scanList[0] == '') {
      return contactList;
    }
    for (var key in scanList) {
      key = reduceKey(key);
      var contact;
      try {
        contact = await get(key);
      } on Exception catch (e) {
        logger.severe('Invalid atsign contact found @$key : $e');
      }
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
    if (atGroup == null || atGroup.groupName == null) {
      throw Exception('Group name is null or empty String');
    }
    var id = atGroup.groupId;
    if (id != null) {
      var group = await getGroup(id);
      if (group != null) {
        throw AlreadyExistsException('Group is already exisits with id $id');
      }
    }
    //create groupID
    var groupId = Uuid().v1();
    atGroup.groupId = groupId;
    var groupName = atGroup.groupName;
    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    var atKey = AtKey()
      ..key = groupId
      ..metadata = metadata;
    //update atGroup
    atGroup.createdBy = AtUtils.fixAtSign(atSign);
    atGroup.updatedBy = AtUtils.fixAtSign(atSign);
    atGroup.createdOn = DateTime.now();
    atGroup.updatedOn = DateTime.now();

    var json = atGroup.toJson();
    var value = jsonEncode(json);
    var result = await atClient.put(atKey, value);
    if (result) {
      print('Group creation successful. Adding to group list');
      var atGroupBasicInfo = AtGroupBasicInfo(groupId, groupName);
      // add AtGroupBasicInfo object to list of groupNames
      var success = await _addToGroupList(atGroupBasicInfo);
      print('Add to group list result : $success');
      return atGroup;
    }
    return null;
  }

  /// takes AtGroup as an input and updates the group
  /// on success return AtGroup otherwise null
  @override
  Future<AtGroup> updateGroup(AtGroup atGroup) async {
    if (atGroup == null || atGroup.groupName == null) {
      throw Exception('Group name is null or empty String');
    }
    var groupId = atGroup.groupId;
    var group = await getGroup(groupId);
    if (group == null) {
      throw GroupNotExistsException(
          'There is no Group exisits with Id $groupId');
    }

    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    // creates atKey
    var atKey = AtKey()
      ..key = atGroup.groupId
      ..metadata = metadata;
    //update atGroup
    atGroup.updatedOn = DateTime.now();

    var json = atGroup.toJson();
    var value = jsonEncode(json);
    var success = await atClient.put(atKey, value);
    var result = success ? atGroup : null;
    return result;
  }

  /// takes AtGroup as an input and creates the group
  /// on success return AtGroup otherwise null
  @override
  Future<bool> deleteGroup(AtGroup atGroup) async {
    if (atGroup == null || atGroup.groupName == null) {
      throw Exception('Group name is null or empty String');
    }
    var groupId = atGroup.groupId;
    var groupName = atGroup.groupName;
    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    var atKey = AtKey()
      ..key = atGroup.groupId
      ..metadata = metadata;
    var result = await atClient.delete(atKey);
    if (result) {
      var atGroupBasicInfo = AtGroupBasicInfo(groupId, groupName);
      return await _deleteFromGroupList(atGroupBasicInfo);
    }
    return result;
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
    list = List<String>.from(list);
    var groupNames = <String>[];
    list.forEach((group) {
      var groupInfo = AtGroupBasicInfo.fromJson(jsonDecode(group));
      groupNames.add(groupInfo.atGroupName);
    });
    return groupNames;
  }

  /// fetches all the group Ids as a list
  /// on success return List of Group Ids otherwise []
  @override
  Future<List<String>> listGroupIds() async {
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
    list = List<String>.from(list);
    var groupIds = <String>[];
    list.forEach((group) {
      var groupInfo = AtGroupBasicInfo.fromJson(jsonDecode(group));
      groupIds.add(groupInfo.atGroupId);
    });
    return groupIds;
  }

  /// takes groupName as an input and
  /// get the group details
  /// on success return AtGroup otherwise null
  @override
  Future<AtGroup> getGroup(String groupId) async {
    if (groupId == null || groupId.isEmpty) {
      return null;
    }

    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    //create atKey
    var atKey = AtKey()
      ..key = groupId
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
    if (atGroup.groupId == null) {
      throw GroupNotExistsException('Group ID is null');
    }
    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    // create atkey
    var atKey = AtKey()
      ..key = atGroup.groupId
      ..metadata = metadata;
    // Add all contacts in atContacts from atGroup
    atContacts.forEach((contact) {
      if (!isMember(contact, atGroup)) {
        atGroup.members.add(contact);
      }
    });
    atGroup.updatedBy = AtUtils.fixAtSign(atSign);
    atGroup.updatedOn = DateTime.now();
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
    if (atGroup.groupId == null) {
      throw GroupNotExistsException('Group ID is null');
    }
    // set metadata
    var metadata = Metadata()
      ..isPublic = false
      ..namespaceAware = false;
    //create atkey
    var atKey = AtKey()
      ..key = atGroup.groupId
      ..metadata = metadata;
    // removing all contacts in atContacts from atGroup
    var members = atGroup.members;
    for (var atContact in atContacts) {
      var contactName = atContact.atSign;
      members.removeWhere((contact) => (contact.atSign == contactName));
    }
    atGroup.members = members;
    atGroup.updatedBy = AtUtils.fixAtSign(atSign);
    atGroup.updatedOn = DateTime.now();
    var json = atGroup.toJson();
    var value = jsonEncode(json);
    return await atClient.put(atKey, value);
  }

  /// Throw Exceptions on Invalid AtSigns.
  String _formKey(String key) {
    try {
      key = AtUtils.fixAtSign(AtUtils.formatAtSign(key));
    } on Exception {
      rethrow;
    }
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

  ///Adds a group to group list
  Future<bool> _deleteFromGroupList(AtGroupBasicInfo atGroupBasicInfo) async {
    if (atGroupBasicInfo == null || atGroupBasicInfo.atGroupId == null) ;
    var groupId = atGroupBasicInfo.atGroupId;
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
    list = List<String>.from(list);
    list.removeWhere((group) =>
        (AtGroupBasicInfo.fromJson(jsonDecode(group)).atGroupId == groupId));
    return await atClient.put(atKey, jsonEncode(list));
  }

  String getGroupsListKey() {
    var groupsListKey =
        '${AppConstants.CONTACT_KEY_PREFIX}.${AppConstants.GROUPS_LIST_KEY_PREFIX}.${atSign.replaceFirst('@', '')}';
    return groupsListKey;
  }

  @override
  bool isMember(AtContact atContact, AtGroup atGroup) {
    if (atGroup == null || atContact == null) {
      return false;
    }
    var result = false;
    var members = atGroup.members;
    for (var contact in members) {
      if (contact.atSign.toString() == atContact.atSign.toString()) {
        return true;
      }
    }
    return result;
  }
}
