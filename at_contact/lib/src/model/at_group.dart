import 'dart:convert';

import 'package:at_contact/src/model/at_contact.dart';
import 'package:at_contact/src/service/util_service.dart';

class AtGroup {
  //Group name
  String name;

  //Group display name
  String displayName;

  // Group description
  String description;

  // Group picture
  dynamic groupPicture;

  //Group members set
  Set<AtContact> members = {};

  //Additional tags if any
  Map<dynamic, dynamic> tags;

  // Group Creation time stamp
  DateTime createdOn;

  // Group update time stamp
  DateTime updatedOn;

  //group created by
  String createdBy;

  //group updated by
  String updatedBy;

  AtGroup(this.name,
      {this.displayName,
      this.description,
      this.groupPicture,
      this.members,
      this.tags,
      this.createdOn,
      this.updatedOn,
      this.createdBy,
      this.updatedBy}) {
    members ??= <AtContact>{};
    createdOn ??= DateTime.now();
    updatedOn ??= DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'description': description,
      'groupPicture': groupPicture,
      'members': members.toList(),
      'tags': tags,
      'createdOn': createdOn.toIso8601String(),
      'updatedOn': updatedOn.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  AtGroup.fromJson(Map json) {
    name = json['name'] as String;
    displayName = json['displayName'] as String;
    description = json['description'] as String;
    groupPicture = json['groupPicture'];
    members = (json['members'] as List)
        .map((e) => AtContact.fromJson(e as Map<String, dynamic>))
        .toSet();
    tags = json['tags'] as Map<String, dynamic>;
    createdOn = DateTime.parse(json['createdOn'] as String);
    updatedOn = DateTime.parse(json['updatedOn'] as String);
    createdBy = json['createdBy'] as String;
    updatedBy = json['updatedBy'] as String;
  }

  @override
  String toString() {
    return 'AtGroup{name: $name, displayName: $displayName, description: $description, members: $members, tags: $tags, createdBy: $createdBy, createdOn: $createdOn}';
  }
}

class AtGroupBasicInfo {
  String atGroupName;
  String atGroupKey;

  AtGroupBasicInfo(this.atGroupName, this.atGroupKey);

  Map<String, dynamic> toJson() {
    return {
      'atGroupName': atGroupName,
      'atGroupKey': atGroupKey,
    };
  }

  AtGroupBasicInfo.fromJson(Map json) {
    atGroupName = json['atGroupName'];
    atGroupKey = json['atGroupKey'];
  }

  @override
  String toString() {
    return 'AtGroupBasicInfo{atGroupName: $atGroupName, atGroupKey: $atGroupKey';
  }
}

class AlreadyExistsException implements Exception {
  String message;
  AlreadyExistsException(this.message);
}

class GroupNotExistsException implements Exception {
  String message;
  GroupNotExistsException(this.message);
}
