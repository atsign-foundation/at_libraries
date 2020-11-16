<img src="https://atsign.dev/assets/img/@developersmall.png?sanitize=true">

### Now for a little internet optimism

# at_contact
A library for Dart developers.

## Installation:
To use this library in your app, first add it to your pubspec.yaml
```  
dependencies:
  at_contact: ^1.0.0
```
### Add to your project 
```
pub get 
```
### Import in your application code
```
import 'package:at_contact/at_contact.dart';
```
## Usage
```
var atSign = '@alice';
var atContact = await AtContactsImpl.getInstance(atSign);
    // set contact details
    contact = AtContact(atSign: atSign,
      personas: ['finance_persona', 'health_persona'],);
//add contact
var result = await atContact.add(contact);
//update contact
contact.type = ContactType.Institute;
result = await atContact.update(contact);
//get contact by atSign
var contact = await atContact.get(atSign);
//Get all active contacts
var contactList = await atContact.listActiveContacts();
// Block contact
contact.blocked = true;
var updateResult = await atContact.update(contact);
// Get all blocked contacts
var blockedContacts = await atContact.listBlockedContacts();
```