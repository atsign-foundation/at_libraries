import 'package:at_client/at_client.dart';
import 'package:at_contact/at_contact.dart';
import 'package:at_contact/src/model/at_group.dart';
import 'package:test/test.dart';
import 'test_util.dart';

Future<void> main() async {
  AtContactsImpl atContactImpl;
  AtGroup atGroup;
  var atSign = '@colin';
  try {
    await AtClientImpl.createClient(
        '@colin', '', TestUtil.getPreferenceLocal());

    atContactImpl = await AtContactsImpl.getInstance('@<atSign>');
    // set contact details
    atGroup = AtGroup( 'test_group1', description: 'test group 1');
  } on Exception catch (e, trace) {
    print(e.toString());
    print(trace);
  }
  group('A group of at_group tests', () {
    //test create group
    test(' test create a contact ', () async {
      print('Group name : ${atGroup.name}');
      var result = await atContactImpl.createGroup(atGroup);
      print('create result : $result');
      expect(result is AtGroup, true);
    });

    // test get group
    test(' test get contact by atSign', () async {
      var result = await atContactImpl.getGroup('test_group1');
      print('get result : $result');
      expect(result is AtGroup, true);
      expect(result.name, 'test_group1');
    });

    // test get all group names
    test(' test get all group names', () async {
      var result = await atContactImpl.listGroupNames();
      print('result : $result');
      expect(result.length, greaterThan(0));
    });

    // Add members to group
    test(' test add members to group', () async {
      var atContacts = Set();
      var group1 = AtGroup('test_group');
      atContacts.add(group1);
      var result = await atContactImpl.addMembers(atContacts, atGroup);
      print('result : $result');
      expect(result, true);
    });

    // Delete members to group
    test(' test add members to group', () async {
      var atContacts = Set();
      var group1 = AtGroup('test_group');
      atContacts.add(group1);
      var result = await atContactImpl.deleteMembers(atContacts, atGroup);
      print('result : $result');
      expect(result, true);
    });

  });
}