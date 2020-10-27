import 'package:at_contact/src/model/at_contact.dart';

abstract class AtContactsLibrary {
  // Create a new contact in secondary
  Future<bool> add(AtContact contact);

// Updates contact
  Future<bool> update(AtContact contact);

  // delete contact
  Future<bool> deleteContact(AtContact contact);

  // delete contact by atSign
  Future<bool> delete(String atSign);

  //fetch all contacts
  Future<List<AtContact>> listContacts();

  //get contact by atSign
  Future<AtContact> get(String atSign);

  // fetch all active contacts
  Future<List<AtContact>> listActiveContacts();

  // fetch all blocked contacts
  Future<List<AtContact>> listBlockedContacts();

  // fetch favorite contacts
  Future<List<AtContact>> listFavoriteContacts();
}
