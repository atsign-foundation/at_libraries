<img width=250px src="https://atsign.dev/assets/img/@platform_logo_grey.svg?sanitize=true">

## Now for some internet optimism.

[![pub package](https://img.shields.io/pub/v/at_contact)](https://pub.dev/packages/at_contact) [![pub points](https://badges.bar/at_contact/pub%20points)](https://pub.dev/packages/at_contact/score) [![gitHub license](https://img.shields.io/badge/license-BSD3-blue.svg)](./LICENSE)

# at_contact

### Introduction

at_contact library persists contacts across different @platform applications. at_contact library provides a contact feature where we can add a new contact. Update/delete an existing contact.
**at_contact** package is written in Dart.

## Get Started

Initially to get a basic overview of the @protocol packages, You must read the [atsign docs](https://atsign.dev/docs/overview/).

> To use this package you must be having a basic setup, Follow here to [get started](https://atsign.dev/docs/get-started/setup-your-env/).

# Usage

- Create an instance of `AtContactsImpl`, We make use of `AtClientManager`.

```dart
// Create an instace of AtClient.
AtClient atClientInstance = AtClientManager.getInstance().atClient;

// Create an instace of AtContactsImpl.
// It takes 2 positional arguments called AtClient and atSign.
AtContactsImpl _atContact = AtContactsImpl(atClientInstance, atClientInstance.getCurrentAtSign());
```

### Contacts

- If the user wants to add a contact, call `add()` method. 

```dart

Future<void> _addContact() async {
    // Pass the user input data to respective fields of AtContact.
    AtContact contact = AtContact()
    // Pass the user atSign here
    ..atSign = atSign
    ..createdOn = DateTime.now()
    // Pass this value if you want to make the contact your favourite.
    ..favourite = _isFavouriteSelected
    // Contact type can be - Individual / Institute / Other
    ..type = ContactType.Individual;
    bool isContactAdded = await _atContact.add(contact);
    print(isContactAdded ? 'Contact added successfully' : 'Failed to add contact');
}
```

- If user wants to get the data of a contact, call `get()` method by passing the user's atSign as the positional argument.

```dart
AtContact? userContact;

@override
Future<void> _getContactDetails() async {
    AtContact? _contact = await _atContact.get(atSign);
    if(_contact == null){
        print("Failed to fetch contact data.");
    } else {
        // Assign the fetched contact value to userContact.
        // And use the value accordingly in the UI.
        setState(() => userContact = _contact);
    }
}

```

- If user wants to delete a contact, Call `deleteContact()` or `delete()` method.

- You can implement deleting a contact functionality using either of the methods.

    - If you use `deleteContact()` method, It needs the user's contact as a positional parameter.

    - If you use `delete()` method, It needs just the atSign of the user's contact. And it can be fetched from the user contact itself.

    - Let us see the both implementations.

```dart
/// Using `delete()` method
String? _atSign;

Future<void> _deleteContact() async {
    if(_atSign == null || _atSign.isEmpty){
        print("AtSign was't passed or empty.");
    } else {
        bool _isContactDeleted = await _atContact.delete(_atSign);
        print(_isContactDeleted ? 'Contact deleted successfully' : 'Failed to delete contact.');
    }
}
```

```dart
/// Using `deleteContact()` method.
Future<void> _deleteContact() async {
    AtContact? _contact = await _atContact.get(atSign);
    if(_contact == null){
        print("Failed to fetch contact data.");
    } else {
        bool _isContactDeleted = await _atContact.deleteContact(_contact);
        print(_isContactDeleted ? 'Contact deleted successfully' : 'Failed to delete contact.');
    }
}
```

- Show the list of the user's contacts. Then call the `listContacts()` method.

```dart
/// In Contacts list screen, call the `listContacts()`.
List<AtContact> contactsList = await _atContact.listContacts();

// Use this contactsList in the UI part and render the data as you wish.
// Or use FutureBuilder and ListView to show the contact data as a list.
```

- If the user wants to list out their favorite contacts, Then call `listFavoriteContacts()` method.

```dart
Future<void> _listFavoriteContacts() async {
    List<AtContact> _favContactsList = await _atContact.listFavoriteContacts();
    if(_favContactsList.isEmpty){
        print("No favorite contacts found");
    } else {
        setState(() => favContactsList = _favContactsList);
    }
}
```

### Groups

- So far we have looked into contacts, Now let us know how `AtGroup`s to be used.

- If the user wants to create a group, Then call `createGroup()` method.

```dart
Future<void> _createGroup() async {
    // Pass the user input data to respective fields of AtGroup.
    AtGroup group = AtGroup('The @platform team')
        ..createdBy = _myAtSign
        ..createdOn = DateTime.now()
        ..description = 'Team with awesome spirit'
        ..updatedOn = DateTime.now()
        ..groupId = 'T@PT101'
        ..displayName = 'at_contact team';
    AtGroup? myGroup = await _atContact.createGroup(group);
    if(myGroup == null){
        print('Failed to create group')
    } else {
        print(group.id + ' has been created successfully');
    }
}
```

- If the user wants to get the details about group, Then call `getGroup()` method.

```dart

String groupName = 'The @platform team';

Future<void> _getGroup() async {
    AtGroup? myGroup = await _atContact.getGroup(groupName);
    if(myGroup == null){
        print('Failed to get group details')
    } else {
        print('Group Name: ${myGroup.groupName}\n'
        'Group ID : ${myGroup.groupId}\n'
        'Created by : ${myGroup.createdBy}\n'
        'Created on : ${myGroup.createdOn}');
    }
}
```

- If the user wants to delete the group, Then call `deleteGroup()` method.

```dart
Future<void> _deleteGroup() async {
    AtGroup? _myGroup = await _atContact.getGroup(groupName);
    if(_myGroup == null){
        print('Failed to get group details');
    } else {
        bool _isGroupDeleted = await _atContact.deleteGroup(_myGroup);
        print(_isGroupDeleted ? _myGroup.groupName + ' group deleted' : 'Failed to delete group');
    }
}
```

- If user wants to get the list of group names, Then call `listGroupNames()` method.

```dart
Future<void> _listGroupNames() async {
    List<String?> _groupNames = await _atContact.listGroupNames();
    if(_groupNames.isEmpty){
        print('No groups found');
    } else {
        // Iterate through the list and print names 
        for(String _groupName in _groupNames){
            print(_groupName);
        }
    }
}
```

- If user wants to get the list of group names, Then call `listGroupIds()` method.

```dart
Future<void> _listGroupIds() async {
    List<String?> _groupIds = await _atContact.listGroupIds();
    if(_groupIds == null){
        print('No groups found');
    } else {
        // Iterate through the list and print ids 
        for(String _groupId in _groupIds){
            print(_groupId);
        }
    }
}
```

- If user wants to add someone to the group, then call `addMembers()` method.

```dart
Set<AtContact> selectedContacts = <AtContact>{};

Future<void> _addMembers() async {
    for(String _atSign in selectedAtSignsList){
        AtContact? _fetchedContact = await _atContact.get(_atSign);
        if(_fetchedContact != null){
            selectedContacts.add(_fetchedContact);
        } else{
            print('Failed to get contact for $_atSign');
        }
    }
    AtGroup? _myGroup = await _atContact.getGroup(groupName);
    bool _isMembersAdded = await _atContact.addMembers(selectedContacts, _myGroup);
    print(_isMembersAdded ? 'Members added to the group' : 'Failed to add members to the group');
}
``` 

- If a user wants to delete a contact from the group , Then call `deleteMembers()` method

```dart
Set<AtContact> selectedContacts = <AtContact>{};

Future<void> _deleteMembers() async {
    for(String _atSign in selectedAtSignsList){
        AtContact? _fetchedContact = await _atContact.get(_atSign);
        if(_fetchedContact != null){
            selectedContacts.add(_fetchedContact);
        } else{
            print('Failed to get contact for $_atSign');
        }
    }
    AtGroup? _myGroup = await _atContact.getGroup(groupName);
    bool _isMembersRemoved = await _atContact.deleteMembers(selectedContacts, _myGroup);
    print(_isMembersRemoved ? 'Member removed from the group' : 'Failed to remove member from the group')
}
```

- To check if the user is a member of the group you are looking for, Then call `isMember()` method.

```dart
AtContact? _userContact = await _atContact.get(atSign);
bool isAMember = await _atContact.isMember(_userContact, groupName);
print(atSign + ' is ${isAMember ? '' : 'not'} a member of ' + groupName); 
// @colin is a member of The @platform team 
// @somerandomatsign is not a member of The @Platform team
```

## Additional content

- We have developed some realtime Applications using this library called [@mosphere-pro](https://atsign.com/apps/atmosphere-pro/), [@buzz](https://atsign.com/apps/buzz/), [@rrive (Google play store)](https://play.google.com/store/apps/details?id=com.atsign.arrive) / [@rrive (App Store)](https://apps.apple.com/in/app/rrive/id1542050548).

- Flutter implementation of this library can be found in [at_contacts_flutter](https://pub.dev/packages/at_contacts_flutter) package.