import 'dart:convert';

import 'package:at_contact/src/at_contacts_impl.dart';
import 'package:at_contact/src/model/at_contact.dart';
import 'package:at_contact/src/model/at_group.dart';
import 'package:test/test.dart';
import 'package:at_commons/at_commons.dart';
import 'package:uuid/uuid.dart';

import 'test_util.dart';

Future<void> main() async {
  AtContactsImpl atContactsImpl;
  AtGroup atGroup;
  var currentAtSign = '@alice🛠';
  try {
    atContactsImpl =
        await TestUtil.initializeAndGetContact('buzz', currentAtSign);
    // set contact details
    atGroup = AtGroup(currentAtSign, description: 'test', displayName: 'test1');
  } on Exception catch (e, trace) {
    print(e.toString());
    print(trace);
  }
  group('A group of at_group  tests', () {
    //test create contact
    test(' test create a group', () async {
      var result = await atContactsImpl.createGroup(atGroup);
      print('create result : $result');
      expect(result is AtGroup, true);
    });

    test(' test add members to group', () async {
      var contact1 =
          AtContact(type: ContactType.Individual, atSign: '@colin🛠');
      var contact2 = AtContact(type: ContactType.Individual, atSign: '@bob🛠');
      var atContacts = <AtContact>{};
      atContacts.add(contact1);
      atContacts.add(contact2);
      var result = await atContactsImpl.addMembers(atContacts, atGroup);
      print('create result : $result');
      expect(result, true);
    });

    test(' test get group names', () async {
      var result = await atContactsImpl.listGroupNames();
      print('create result : $result');
      expect((result.length), greaterThan(0));
    });

    test(' test get group Ids', () async {
      var result = await atContactsImpl.listGroupIds();
      print('create result : $result');
      expect((result.length), greaterThan(0));
    });

    test(' test delete members from group', () async {
      var contact1 =
          AtContact(type: ContactType.Individual, atSign: '@colin🛠');
      var atContacts = <AtContact>{};
      atContacts.add(contact1);
      var result = await atContactsImpl.deleteMembers(atContacts, atGroup);
      print('create result : $result');
      expect(result, true);
    });
  });

  group('test namespace migration', () {
    test(' test create a group', () async {
      var atGroupNew = AtGroup('aliceTest',
          description: 'migration test', displayName: 'NG');

      var putResult = await atContactsImpl.createGroup(atGroupNew);
      print('create putResult : $putResult');
      expect(putResult is AtGroup, true);
      //creating group with okd namespace.
      var atGroup1 = AtGroup('aliceFrnds',
          description: 'namespaceTest frnds', displayName: 'Frnds');
      var groupId = Uuid().v1();
      var metadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var atKey = AtKey()
        ..metadata = metadata
        ..key = groupId;
      atGroup1.groupId = groupId;
      var json = atGroup1.toJson();
      var value = jsonEncode(json);
      var result = await atContactsImpl.atClient.put(atKey, value);
      expect(result, true);
    });

    test(' test add members to group', () async {
      var contact1 =
          AtContact(type: ContactType.Individual, atSign: '@colin🛠');
      var contact2 = AtContact(type: ContactType.Individual, atSign: '@bob🛠');
      var atContacts = <AtContact>{};

      atContacts.add(contact1);
      atContacts.add(contact2);
      var result = await atContactsImpl.addMembers(atContacts, atGroup);

      //new namespace check
      var getResult = await atContactsImpl.getGroup(atGroup.groupId);
      print('get result : $getResult');
      expect(getResult is AtGroup, true);
      var contact3 =
          AtContact(type: ContactType.Individual, atSign: '@kevin🛠');
      atContacts.add(contact3);

      result = await atContactsImpl.addMembers(atContacts, atGroup);
      print('create result : $result');
      expect(result, true);
    });

    test(' test get group names', () async {
      //creating oldnamespace key
      var atGroup1 =
          AtGroup('aliceNT', description: 'namespaceTest', displayName: 'NT1');

      var groupId = Uuid().v1();
      var metadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var atKey = AtKey()
        ..metadata = metadata
        ..key = groupId;
      atGroup1.groupId = groupId;
      var json = atGroup1.toJson();
      var value = jsonEncode(json);
      var result = await atContactsImpl.atClient.put(atKey, value);
      expect(result, true);

      //adding oldnamespace key to groupList.
      var groupListKey = AtKey()
        ..key = 'atconnections.groupslist.alice🛠.buzz.at_contact'
        ..metadata = metadata;
      var groupInfo = AtGroupBasicInfo(atGroup1.groupId, 'aliceNT');

      var groupListResult = await atContactsImpl.atClient.get(groupListKey);
      var list = [];
      if (groupListResult != null) {
        list = (groupListResult.value != null)
            ? jsonDecode(groupListResult.value)
            : [];
      }
      list.add(jsonEncode(groupInfo));
      var putResult =
          await atContactsImpl.atClient.put(groupListKey, jsonEncode(list));
      expect(putResult, true);

      //fetching grouplist.
      var getResult = await atContactsImpl.listGroupNames();
      print('create result : $getResult');
      expect((getResult.length > 1), true);

      getResult.retainWhere((result) => result == 'aliceNT');
      expect((getResult.length), 1);
    }, timeout: Timeout(Duration(seconds: 180)));

    test(' test get group Ids', () async {
      var result = await atContactsImpl.listGroupIds();
      print('create result : $result');
      expect((result.length > 1), true);
    });

    test(' test delete members from group', () async {
      var contact1 =
          AtContact(type: ContactType.Individual, atSign: '@colin🛠');
      var atContacts = <AtContact>{};
      atContacts.add(contact1);
      var result = await atContactsImpl.deleteMembers(atContacts, atGroup);
      print('create result : $result');
      expect(result, true);
    });
  });

  group('test groups for different apps', () {
    test('create group in buzz namespace and fetch in mosphere namespace',
        () async {
      // set contact details
      var atContact =
          await TestUtil.initializeAndGetContact('buzz', currentAtSign);
      var group =
          AtGroup(currentAtSign, description: 'test', displayName: 'test1');

      //creates group.
      var result = await atContact.createGroup(group);
      print('create result : $result');
      expect(result is AtGroup, true);

      var contact1 =
          AtContact(type: ContactType.Individual, atSign: '@colin🛠');
      var contact2 = AtContact(type: ContactType.Individual, atSign: '@bob🛠');
      var atContacts = <AtContact>{};
      atContacts.add(contact1);
      atContacts.add(contact2);
      var boolResult = await atContact.addMembers(atContacts, group);
      print('create result : $boolResult');
      expect(boolResult, true);

      var resultList = await atContact.listGroupNames();
      print('create result : $result');
      expect((resultList.length), greaterThan(0));

      var mosphereContact =
          await TestUtil.initializeAndGetContact('mosphere', currentAtSign);
      resultList = await mosphereContact.listGroupNames();
      print(resultList);
      expect(resultList.length, greaterThan(0));
    });

    test(
        'delete group members in buzz namespace and fetch in mosphere namespace',
        () async {
      var atContact =
          await TestUtil.initializeAndGetContact('buzz', currentAtSign);
      var group =
          AtGroup(currentAtSign, description: 'test', displayName: 'test1');

      //creates group.
      var result = await atContact.createGroup(group);
      print('create result : $result');
      expect(result is AtGroup, true);

      var contact1 =
          AtContact(type: ContactType.Individual, atSign: '@colin🛠');
      var contact2 = AtContact(type: ContactType.Individual, atSign: '@bob🛠');
      var atContacts = <AtContact>{};
      atContacts.add(contact1);
      atContacts.add(contact2);
      var boolResult = await atContact.addMembers(atContacts, group);
      print('create result : $boolResult');
      expect(boolResult, true);

      contact1 = AtContact(type: ContactType.Individual, atSign: '@colin🛠');
      atContacts = <AtContact>{};
      atContacts.add(contact1);
      boolResult = await atContact.deleteMembers(atContacts, group);
      print('delete result : $boolResult');
      expect(boolResult, true);

      var resultList = await atContact.listGroupNames();
      print('create result : $result');
      expect((resultList.length), greaterThan(0));
      expect(resultList.contains('@bob🛠'), isFalse);

      var mosphereContact =
          await TestUtil.initializeAndGetContact('mosphere', currentAtSign);
      resultList = await mosphereContact.listGroupNames();
      print(resultList);
      expect(resultList.length, greaterThan(0));
      expect(resultList.contains('@bob🛠'), isFalse);
    });
  });
}
