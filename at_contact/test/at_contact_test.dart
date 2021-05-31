import 'dart:convert';

import 'package:at_client/at_client.dart';
import 'package:at_contact/at_contact.dart';
import 'package:at_contact/src/model/at_contact.dart';
import 'package:test/test.dart';
import 'package:at_commons/at_commons.dart';

import 'test_util.dart';

Future<void> main() async {
  AtContactsImpl atContact;
  AtContact contact;
  var newNamespace = 'buzz.at_contact';
  var atSign = '@bob🛠';
  var currentAtSign = '@alice🛠';
  try {
    var currentAtSignPreference =
        TestUtil.getPreferenceLocal(currentAtSign, 'buzz');
    await AtClientImpl.createClient(
        currentAtSign, 'buzz', currentAtSignPreference);
    var atClient = await AtClientImpl.getClient(currentAtSign);
    atClient.getSyncManager().init(currentAtSign, currentAtSignPreference,
        atClient.getRemoteSecondary(), atClient.getLocalSecondary());
    await atClient.getSyncManager().sync();
    await TestUtil.setEncryptionKeys(atClient, currentAtSign);
    atContact = await AtContactsImpl.getInstance(currentAtSign);
    // set contact details
    contact = AtContact(
      atSign: atSign,
      personas: ['persona1', 'persona22', 'persona33'],
    );
  } on Exception catch (e, trace) {
    print(e.toString());
    print(trace);
  }
  group('A group of at_contact  tests', () {
    //test create contact
    test(' test create a contact ', () async {
      var result = await atContact.add(contact);
      print('create result : $result');
      expect(result, true);
    });

    //test update contact
    test(' test update contact', () async {
      // update the contact type
      contact.type = ContactType.Institute;
      var result = await atContact.update(contact);
      print('update result : $result');
      expect(result, true);
    });

    // test get contact
    test(' test get contact by atSign', () async {
      var result = await atContact.get(atSign);
      print('get result : $result');
      expect(result is AtContact, true);
      expect(result.atSign, atSign);
    });

    // test active contact
    test(' test check active contact ', () async {
      // update the contact type
      contact.type = ContactType.Institute;
      contact.blocked = false;
      var updateResult = await atContact.update(contact);
      print('update result : $updateResult');
      expect(updateResult, true);

      var result = await atContact.get(atSign);
      expect(result is AtContact, true);
      expect(result.blocked, false);
    });

    // test get all active contacts
    test(' test get all active contacts', () async {
      var result = await atContact.listActiveContacts();
      print('result : $result');
      expect(result.length, greaterThan(0));
    });

    // test blocked contact
    test(' test check blocked  contact', () async {
      // update the contact type
      contact.type = ContactType.Institute;
      contact.blocked = true;
      var updateResult = await atContact.update(contact);
      print('update result : $updateResult');
      expect(updateResult, true);

      var result = await atContact.get(atSign);
      print(result);
      expect(result is AtContact, true);
      expect(result.blocked, true);
    });

    //test get all blocked contacts
    test(' test get all blocked contacts', () async {
      var result = await atContact.listBlockedContacts();
      print('result : $result');
      expect(result.length, greaterThan(0));
    });

    // test favorite contact
    test('test check favorite  contact', () async {
      // update the contact type
      contact.type = ContactType.Institute;
      contact.favourite = true;
      var updateResult = await atContact.update(contact);
      print('update result : $updateResult');
      expect(updateResult, true);

      var result = await atContact.get(atSign);
      print(result);
      expect(result is AtContact, true);
      expect(result.favourite, true);
    });

    // test get all favorite contacts
    test(' test get all favorite contacts', () async {
      var result = await atContact.listFavoriteContacts();
      print('result : $result');
      expect(result.length, greaterThan(0));
    });

    // test get all contacts
    test(' test get all contacts', () async {
      var result = await atContact.listContacts();
      print('getAll result : $result');
      expect(result.length, greaterThan(0));
    });

    //delete contact
    test(' test delete contact by atSign', () async {
      var result = await atContact.delete(atSign);
      print('delete result : $result');
      expect(result, true);
    });
  });

  group('test at_contact namespace migration tests', () {
    test(' test create a contact ', () async {
      var result = await atContact.add(contact);
      expect(result, true);
      var atContactResult = await atContact.atClient.getAtKeys(regex: '.buzz');
      expect(atContactResult.length, greaterThan(0));
    });

    //test update contact
    test('update oldnamespace contact', () async {
      var deleteResult = await atContact.delete('@kevin🛠');
      expect(deleteResult, true);
      var kevinContact = AtContact(
        atSign: '@kevin🛠',
        personas: ['persona1', 'persona22', 'persona33'],
      );
      var atMetadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var oldAtKey = AtKey()
        ..key = 'atconnections.kevin🛠.contacts.alice🛠'
        ..metadata = atMetadata;
      var result = await atContact.atClient
          .put(oldAtKey, jsonEncode(kevinContact.toJson()));
      var atContactResult =
          await atContact.atClient.getAtKeys(regex: 'kevin🛠.*.$newNamespace');
      expect(atContactResult.length, 0);

      // update the contact type
      kevinContact.type = ContactType.Institute;
      result = await atContact.update(kevinContact);
      expect(result, true);

      atContactResult =
          await atContact.atClient.getAtKeys(regex: 'kevin🛠.*.$newNamespace');
      expect(atContactResult.length, greaterThan(0));
      deleteResult = await atContact.delete('@kevin🛠');
      expect(deleteResult, true);
    });

    test(' test get oldnamespace contact by atSign', () async {
      var barbaraContact = AtContact(
        atSign: '@barbara🛠',
        personas: ['persona1', 'persona22', 'persona33'],
      );
      var atMetadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var oldAtKey = AtKey()
        ..key = 'atconnections.barbara🛠.contacts.alice🛠'
        ..metadata = atMetadata;
      var result = await atContact.atClient
          .put(oldAtKey, jsonEncode(barbaraContact.toJson()));
      var atContactResult = await atContact.atClient
          .getAtKeys(regex: 'barbara🛠.*.$newNamespace');
      expect(atContactResult.length, 0);
      var atContactresult = await atContact.get('@barbara🛠');
      print('get result : $result');
      expect(atContactresult is AtContact, true);
      expect(atContactresult.atSign, '@barbara🛠');
      atContactResult = await atContact.atClient
          .getAtKeys(regex: 'barbara🛠.*.$newNamespace');
      expect(atContactResult.length, greaterThan(0));

      var deleteResult = await atContact.delete('@barbara🛠');
      expect(deleteResult, true);
    });

    test('delete oldnamespace and new namespace contact by atSign', () async {
      var kevinContact = AtContact(
        atSign: '@sameeraja🛠',
        personas: ['persona1', 'persona22', 'persona33'],
      );
      var atMetadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var oldAtKey = AtKey()
        ..key = 'atconnections.sameeraja🛠.contacts.alice🛠'
        ..metadata = atMetadata;
      var result = await atContact.atClient
          .put(oldAtKey, jsonEncode(kevinContact.toJson()));
      var atContactResult = await atContact.atClient
          .getAtKeys(regex: 'sameeraja🛠.*.$newNamespace');
      expect(atContactResult.length, 0);
      var atContactresult = await atContact.get('@sameeraja🛠');
      expect(atContactresult is AtContact, true);
      expect(atContactresult.atSign, '@sameeraja🛠');
      result = await atContact.delete('@sameeraja🛠');
      print('delete result : $result');
      expect(result, true);

      await atContact.add(contact);
      result = await atContact.delete(contact.atSign);
      expect(result, true);
    });
    // test active contact
    test('check active contact for oldnamespace and new namespace ', () async {
      var barbaraContact = AtContact(
        atSign: '@barbara🛠',
        blocked: false,
        personas: ['persona1', 'persona22', 'persona33'],
      );
      var atMetadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var oldAtKey = AtKey()
        ..key = 'atconnections.barbara🛠.contacts.alice🛠'
        ..metadata = atMetadata;
      var result = await atContact.atClient
          .put(oldAtKey, jsonEncode(barbaraContact.toJson()));
      expect(result, true);

      var getResult = await atContact.get('@barbara🛠');
      expect(getResult is AtContact, true);
      expect(getResult.blocked, false);

      //test new namespace contact
      contact.type = ContactType.Institute;
      contact.blocked = false;
      var updateResult = await atContact.update(contact);
      print('update result : $updateResult');
      expect(updateResult, true);
      getResult = await atContact.get(atSign);
      expect(getResult is AtContact, true);
      expect(getResult.blocked, false);

      var deleteResult = await atContact.delete('@barbara🛠');
      expect(deleteResult, true);
    });

    // test get all active contacts
    test(' test get all active contacts containing old or newnamespaces',
        () async {
      var barbaraContact = AtContact(
        atSign: '@sameeraja🛠',
        blocked: false,
        personas: ['persona1', 'persona22', 'persona33'],
      );
      var atMetadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var oldAtKey = AtKey()
        ..key = 'atconnections.sameeraja🛠.contacts.alice🛠'
        ..metadata = atMetadata;
      var result = await atContact.atClient
          .put(oldAtKey, jsonEncode(barbaraContact.toJson()));
      expect(result, true);
      var atContactResult = await atContact.atClient
          .getAtKeys(regex: 'sameeraja🛠.*.$newNamespace');
      expect(atContactResult.length, 0);

      var resultList = await atContact.listActiveContacts();
      print('result : $result');
      expect(resultList.length, greaterThan(0));
      resultList.retainWhere((data) => data.atSign == '@sameeraja🛠');
      expect(resultList.length, 1);

      var deleteResult = await atContact.delete('@sameeraja🛠');
      expect(deleteResult, true);
    });

    // test blocked contact
    test('check blocked contact for old and new namespace', () async {
      var barbaraContact = AtContact(
        atSign: '@barbara🛠',
        blocked: true,
        personas: ['persona1', 'persona22', 'persona33'],
      );
      var atMetadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var oldAtKey = AtKey()
        ..key = 'atconnections.barbara🛠.contacts.alice🛠'
        ..metadata = atMetadata;
      var result = await atContact.atClient
          .put(oldAtKey, jsonEncode(barbaraContact.toJson()));
      expect(result, true);
      var getResult = await atContact.get('barbara🛠');
      expect(getResult.blocked, true);

      //testing new namespace.
      // update the contact type
      contact.type = ContactType.Institute;
      contact.blocked = true;
      var updateResult = await atContact.update(contact);
      print('update result : $updateResult');
      expect(updateResult, true);

      getResult = await atContact.get(atSign);
      print(getResult);
      expect(getResult is AtContact, true);
      expect(getResult.blocked, true);

      var deleteResult = await atContact.delete('@barbara🛠');
      expect(deleteResult, true);
    });

    test(
      ' test get all blocked contacts',
      () async {
        var barbaraContact = AtContact(
          atSign: '@barbara🛠',
          blocked: true,
          personas: ['persona1', 'persona22', 'persona33'],
        );
        var atMetadata = Metadata()
          ..isPublic = false
          ..namespaceAware = false;
        var oldAtKey = AtKey()
          ..key = 'atconnections.barbara🛠.contacts.alice🛠'
          ..metadata = atMetadata;
        var result = await atContact.atClient
            .put(oldAtKey, jsonEncode(barbaraContact.toJson()));
        expect(result, true);

        contact.type = ContactType.Institute;
        contact.blocked = true;
        var updateResult = await atContact.update(contact);
        print('update result : $updateResult');
        expect(updateResult, true);

        var atContactResultList = await atContact.listBlockedContacts();
        print('atContactResultList : $atContactResultList');
        expect(atContactResultList.length, 2);

        var deleteResult = await atContact.delete('@barbara🛠');
        expect(deleteResult, true);
      },
    );

    // test favorite contact
    test('test check favorite  contact', () async {
      var barbaraContact = AtContact(
        atSign: '@barbara🛠',
        favourite: true,
        personas: ['persona1', 'persona22', 'persona33'],
      );
      var atMetadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var oldAtKey = AtKey()
        ..key = 'atconnections.barbara🛠.contacts.alice🛠'
        ..metadata = atMetadata;
      var result = await atContact.atClient
          .put(oldAtKey, jsonEncode(barbaraContact.toJson()));
      expect(result, true);
      var getResult = await atContact.get('@barbara🛠');
      print(getResult);
      expect(getResult is AtContact, true);
      expect(getResult.favourite, true);
      // update the contact type
      contact.type = ContactType.Institute;
      contact.favourite = true;
      var updateResult = await atContact.update(contact);
      print('update result : $updateResult');
      expect(updateResult, true);
      //testing for newnamespace contact
      getResult = await atContact.get(atSign);
      print(getResult);
      expect(getResult is AtContact, true);
      expect(getResult.favourite, true);

      var deleteResult = await atContact.delete('@barbara🛠');
      expect(deleteResult, true);
    });

    // test get all favorite contacts
    test(' test get all favorite contacts', () async {
      var barbaraContact = AtContact(
        atSign: '@barbara🛠',
        favourite: true,
        personas: ['persona1', 'persona22', 'persona33'],
      );
      var atMetadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var oldAtKey = AtKey()
        ..key = 'atconnections.barbara🛠.contacts.alice🛠'
        ..metadata = atMetadata;
      var result = await atContact.atClient
          .put(oldAtKey, jsonEncode(barbaraContact.toJson()));
      expect(result, true);
      var getResult = await atContact.get('@barbara🛠');
      print(getResult);
      expect(getResult is AtContact, true);
      expect(getResult.favourite, true);

      contact.type = ContactType.Institute;
      contact.favourite = true;
      var updateResult = await atContact.update(contact);
      print('update result : $updateResult');
      expect(updateResult, true);

      getResult = await atContact.get(atSign);
      print(getResult);
      expect(getResult is AtContact, true);
      expect(getResult.favourite, true);

      var getResultList = await atContact.listFavoriteContacts();
      print('getResultList : $getResultList');
      expect(getResultList.length, 2);
    });

    // test get all contacts
    test(' test get all contacts', () async {
      //deleting new namespace contacts
      var result = await atContact.delete('@barbara🛠');
      print('delete result : $result');
      expect(result, true);
      var barbaraContact = AtContact(
        atSign: '@barbara🛠',
        favourite: true,
        personas: ['persona1', 'persona22', 'persona33'],
      );
      var atMetadata = Metadata()
        ..isPublic = false
        ..namespaceAware = false;
      var oldAtKey = AtKey()
        ..key = 'atconnections.barbara🛠.contacts.alice🛠'
        ..metadata = atMetadata;
      var putResult = await atContact.atClient
          .put(oldAtKey, jsonEncode(barbaraContact.toJson()));
      expect(putResult, true);
      var getResult = await atContact.listContacts();
      print('getAll getResult : $getResult');
      expect(getResult.length, greaterThan(0));
    });

    test(' delete contact by atSign', () async {
      var result = await atContact.delete(atSign);
      print('delete result : $result');
      expect(result, true);
      result = await atContact.delete('kevin🛠');
      print('delete result : $result');
      expect(result, true);
      result = await atContact.delete('barbara🛠');
      print('delete result : $result');
      expect(result, true);
      result = await atContact.delete('sameeraja🛠');
      print('delete result : $result');
      expect(result, true);
    });
  });
}
