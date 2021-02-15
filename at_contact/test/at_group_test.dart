import 'package:at_client/at_client.dart';
import 'package:at_contact/src/at_contacts_impl.dart';
import 'package:at_contact/src/model/at_contact.dart';
import 'package:at_contact/src/model/at_group.dart';
import 'package:test/test.dart';
import 'test_util.dart';

Future<void> main() async {
  AtContactsImpl atContactsImpl;
  AtGroup atGroup;
  var atSign = '@colin';
  try {
    await AtClientImpl.createClient(
        '@colin', '', TestUtil.getPreferenceLocal());

    atContactsImpl = await AtContactsImpl.getInstance('@colin');
    // set contact details
    atGroup = AtGroup(atSign, description: 'test', displayName: 'test1');
  } on Exception catch (e, trace) {
    print(e.toString());
    print(trace);
  }
  group('A group of at_group  tests', () {
    //test create contact
    test(' test create a group', () async {
      var result = await atContactsImpl.createGroup(atGroup);
      print('create result : $result');
      expect(result, true);
    });

    test(' test add members to group', () async {
      var contact1 =  AtContact(type: ContactType.Individual, atSign: '@colin');
      var contact2 =  AtContact(type: ContactType.Individual, atSign: '@bob');
      Set atContacts;
      atContacts.add(contact1);
      atContacts.add(contact2);
      var result = await atContactsImpl.addMembers(atContacts, atGroup);
      print('create result : $result');
      expect(result, true);
    });

    test(' test get group members', () async {
      var result = await atContactsImpl.getGroupMembers(atGroup);
      print('create result : $result');
      expect((result.length > 1), true);
    });

    test(' test delete members from group', () async {
      var contact1 =  AtContact(type: ContactType.Individual, atSign: '@colin');
      Set atContacts;
      atContacts.add(contact1);
      var result = await atContactsImpl.deleteMembers(atContacts, atGroup);
      print('create result : $result');
      expect(result, true);
    });

  });
}
