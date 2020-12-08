import 'package:at_client/at_client.dart';
import 'package:at_contact/at_contact.dart';
import 'package:at_contact/src/model/at_group.dart';
import 'package:test/test.dart';
import 'test_util.dart';

Future<void> main() async {
  AtContactsImpl atContactImpl;
  AtGroup atGroup;
  var atSign = '@sitaram';
  try {
    await AtClientImpl.createClient(
        atSign, '', TestUtil.getPreferenceLocal());

    atContactImpl = await AtContactsImpl.getInstance(atSign);
    //atContactImpl.atClient.getSyncManager().sync();
    // set contact details
    atGroup = AtGroup( 'test_group1', description: 'test group 1');
  } on Exception catch (e, trace) {
    print(e.toString());
    print(trace);
  }
  group('A group of at_group tests', () {
    //test create group
    test(' test create a group ', () async {
      print('Group name : ${atGroup.name}');
      var result = await atContactImpl.createGroup(atGroup);
      //print('create result : $result');
      expect(result is AtGroup, true);
    });

    // test get group
    test(' test get group by groupName', () async {
      var result = await atContactImpl.getGroup('test_group1');
      print('Group size : ${result.members.length}');
      expect(result is AtGroup, true);
      expect(result.name, atGroup.name);
    });

    // test get all group names
    test(' test get all group names', () async {
      var result = await atContactImpl.listGroupNames();
      print('group names list : $result');
      expect(result.length, greaterThan(0));
    });

    // test get group
    test(' test delete group by groupName', () async {
      var group = AtGroup( 'test_group2', description: 'test group 2');
      var result = await atContactImpl.deleteGroup(group);
      expect(result, true);
    });

    // Add members to group
    test(' test add members to group', () async {
      var group = await atContactImpl.getGroup(atGroup.name);
      print('Group size before adding members : ${group.members.length}');
      var atContacts = Set<AtContact>();
      var contact1 = AtContact(atSign: 'test1', type: ContactType.Individual);
      atContacts.add(contact1);
      var contact2 = AtContact(atSign: 'test2', type: ContactType.Individual);
      atContacts.add(contact2);
      var result = await atContactImpl.addMembers(atContacts, group);
      group = await atContactImpl.getGroup(atGroup.name);
      print('Group size after adding members : ${group.members.length}');
      expect(result, true);
    });

    // Delete members to group
    test(' test delete members to group', () async {
      var group = await atContactImpl.getGroup(atGroup.name);
      print('Group size beofre deleting a member : ${group.members.length}');
      var atContacts = Set<AtContact>();
      var contact1 = AtContact(atSign: 'test1', type: ContactType.Individual);
      atContacts.add(contact1);
      var result = await atContactImpl.deleteMembers(atContacts, group);
      group = await atContactImpl.getGroup(atGroup.name);
      group = await atContactImpl.getGroup(atGroup.name);
      print('Group size after deleting a member : ${group.members.length}');
      expect(result, true);
    });

    // check is member
    test(' test to check contact is member or not', () async {
      var group = await atContactImpl.getGroup(atGroup.name);
      AtContact contact1 = AtContact(atSign: 'test1', type: ContactType.Individual);
      AtContact contact2 = AtContact(atSign: 'test2', type: ContactType.Individual);
      var result = atContactImpl.isMember(contact1, group);
      expect(result, false);
      result = atContactImpl.isMember(contact2, group);
      expect(result, true);
    });

  });
}