<img width="250" src="https://atsign.dev/assets/img/@platform_logo_grey.svg?sanitize=true"/>

## Now for some internet optimism

[![pub package](https://img.shields.io/pub/v/at_contact)](https://pub.dev/packages/at_contact) [![pub points](https://badges.bar/at_contact/pub%20points)](https://pub.dev/packages/at_contact/score) [![gitHub license](https://img.shields.io/badge/license-BSD3-blue.svg)](./LICENSE)

# at_contact

### Introduction

at_contact library persists contacts across different @platform applications. at_contact library provides a contact feature where we can add a new contact. Update/delete an existing contact.
**at_contact** package is written in Dart.

## Get Started

Initially to get a basic overview of the @protocol packages, You must read the [atsign docs](https://atsign.dev/docs/overview/).

> To use this package you must be having a basic setup, Follow here to [get started](https://atsign.dev/docs/get-started/setup-your-env/).

# Usage

- Create an instance of `AtContactsImpl`, We make use of `AtClientManager` for `AtClient` to be passed.

```dart
// Create an instance of AtClient.
AtClient atClientInstance = AtClientManager.getInstance().atClient;

// Create an instance of AtContactsImpl.
// It takes 2 positional arguments called AtClient and atSign.
// One optional argument called regexType.
AtContactsImpl _atContact = AtContactsImpl(atClientInstance, atClientInstance.getCurrentAtSign());
```

### Contacts

- If the user wants to add a contact, call `add()` function from the `_atContact` instance. Provide the contact details to `add()` function.

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

- If user wants to get the data of a contact, call `get()` function by passing the user's atSign as the positional argument.

```dart
AtContact? userContact;

@override
Future<void> _getContactDetails() async {
    // Optionally pass the atKeys.
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

- If user wants to delete a contact, Call `deleteContact()` or `delete()` function.

- You can implement deleting a contact functionality using either of the functions.

  - If you use `deleteContact()` function, It needs the user's contact as a positional parameter.

  - If you use `delete()` function, It needs just the atSign of the user's contact. And it can be fetched from the user contact itself.

  - Let us see the both implementations.

```dart
/// Using `delete()` function.
Future<void> _deleteContact(String _atSign) async {
    if(_atSign == null || _atSign.isEmpty){
        print("AtSign was't passed or empty.");
    } else {
        bool _isContactDeleted = await _atContact.delete(_atSign);
        print(_isContactDeleted ? 'Contact deleted successfully' : 'Failed to delete contact.');
    }
}
```

```dart
/// Using `deleteContact()` function.
Future<void> _deleteContact(AtContact _contact) async {
    bool _isContactDeleted = await _atContact.deleteContact(_contact);
    print(_isContactDeleted ? 'Contact deleted successfully' : 'Failed to delete contact.');
}
```

- Show the list of the user's contacts. Then call the `listContacts()` function.

```dart
/// In Contacts list screen, call the `listContacts()`.
List<AtContact> contactsList = await _atContact.listContacts();

// Use this contactsList in the UI part and render the data as you wish.
// Or use FutureBuilder and ListView to show the contact data as a list.
```

- If the user wants to list out their favorite contacts, Then call `listFavoriteContacts()` function.

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

- If the user wants to create a group, Then call `createGroup()` function where it take a `AtGroup` as a positional argument.

```dart
// Pass the user input data to respective fields of AtGroup.
AtGroup myGroup = AtGroup('The @platform team')
    ..createdBy = _myAtSign
    ..createdOn = DateTime.now()
    ..description = 'Team with awesome spirit'
    ..updatedOn = DateTime.now()
    ..groupId = 'T@PT101'
    ..displayName = 'at_contact team';
Future<void> _createGroup(AtGroup group) async {
    AtGroup? myGroup = await _atContact.createGroup(group);
    if(myGroup == null){
        print('Failed to create group')
    } else {
        print(group.id + ' has been created successfully');
    }
}
```

- If the user wants to update a group, Then call `updateGroup()` function where it take a `AtGroup` as a positional argument.

```dart
// Pass the user input data to respective fields of AtGroup.
AtGroup myGroup = AtGroup('The @platform team')
    ..createdBy = _myAtSign
    ..createdOn = DateTime.now()
    ..description = 'Team with awesome spirit'
    ..updatedOn = DateTime.now()
    ..groupId = 'T@PT101'
    ..displayName = 'at_contact team';
Future<void> _updateGroup(AtGroup group) async {
    try{
        AtGroup? myGroup = await _atContact.updateGroup(group);
        if(myGroup == null){
            print('Failed to create group')
        } else {
            print(group.id + ' has been created successfully');
        }
    } catch(e){
        if(e is GroupNotExistsException){
            print('Group not exists. Please create the group first.');
        } else {
            print('Failed to update group');
        }
    }
}
```

- If the user wants to get the details about group, Then call `getGroup()` function with `groupID` as positional argument.

```dart
String myGroupId = 'T@PT101';

Future<void> _getGroup(String groupId) async {
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

- If the user wants to delete the group, Then call `deleteGroup()` function with `AtGroup` as positional argument.

```dart
Future<void> _deleteGroup(AtGroup groupName) async {
    AtGroup? _myGroup = await _atContact.getGroup(groupName);
    if(_myGroup == null){
        print('Failed to get group details');
    } else {
        bool _isGroupDeleted = await _atContact.deleteGroup(_myGroup);
        print(_isGroupDeleted ? _myGroup.groupName + ' group deleted' : 'Failed to delete group');
    }
}
```

- If user wants to get the list of group names, Then call `listGroupNames()` function.

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

- If user wants to get the list of group names, Then call `listGroupIds()` function.

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

- If user wants to add someone to the group, then call `addMembers()` function. This function needs `Set<AtContact>` and `AtGroup` as positional arguments.

```dart
Set<AtContact> selectedContacts = <AtContact>{};

for(String _atSign in selectedAtSignsList){
    AtContact? _fetchedContact = await _atContact.get(_atSign);
    if(_fetchedContact != null){
        selectedContacts.add(_fetchedContact);
    } else{
        print('Failed to get contact for $_atSign');
    }
}
// Get your group details if you have the group id
AtGroup? _myGroup = await _atContact.getGroup(myGroupID);

Future<void> _addMembers(Set<AtContact> contacts, AtGroup group) async {
    bool _isMembersAdded = await _atContact.addMembers(contacts, group);
    print(_isMembersAdded ? 'Members added to the group' : 'Failed to add members to the group');
}
```

- If a user wants to delete a contact from the group , Then call `deleteMembers()` function.

```dart
Set<AtContact> selectedContacts = <AtContact>{};

for(String _atSign in selectedAtSignsList){
    AtContact? _fetchedContact = await _atContact.get(_atSign);
    if(_fetchedContact != null){
        selectedContacts.add(_fetchedContact);
    } else{
        print('Failed to get contact for $_atSign');
    }
}
AtGroup? _myGroup = await _atContact.getGroup(myGroupID);

Future<void> _deleteMembers(Set<AtContact> contacts, AtGroup group) async {
    bool _isMembersRemoved = await _atContact.deleteMembers(contacts, group);
    print(_isMembersRemoved ? 'Member removed from the group' : 'Failed to remove member from the group')
}
```

- To check if the user is a member of the group you are looking for, Then call `isMember()` function.

```dart
AtContact? _userContact = await _atContact.get(atSign);
bool isAMember = await _atContact.isMember(_userContact, myGroup);
print(atSign + ' is ${isAMember ? '' : 'not'} a member of ' + myGroup.groupName); 
// @colin is a member of The @platform team 
// @somerandomatsign is not a member of The @Platform team
```

## Additional content

- We have developed some realtime Applications using this library called [@mosphere-pro](https://atsign.com/apps/atmosphere-pro/), [@buzz](https://atsign.com/apps/buzz/), [@rrive (Google play store)](https://play.google.com/store/apps/details?id=com.atsign.arrive) / [@rrive (App Store)](https://apps.apple.com/in/app/rrive/id1542050548).

- Flutter implementation of this library can be found in [at_contacts_flutter](https://pub.dev/packages/at_contacts_flutter) package.
