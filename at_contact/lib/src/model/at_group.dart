import 'package:at_contact/src/model/at_contact.dart';
import 'package:at_contact/src/service/util_service.dart';

class AtGroup {
  //Group name
  String name;

  // Group description
  String description;

  // Group picture
  dynamic groupPicture;

  //Group members set
  Set<AtContact> members;

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
      {this.description,
      this.groupPicture,
      this.members,
      this.tags,
      this.createdOn,
      this.updatedOn,
      this.createdBy,
      this.updatedBy}) {
    createdOn ??= DateTime.now();
    updatedOn ??= DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'groupPicture': groupPicture,
      'members': members,
      'tags': tags,
      'createdOn': UtilServices.dateToString(createdOn),
      'updatedOn': UtilServices.dateToString(updatedOn),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  AtGroup.fromJson(Map json) {
    name = json['name'];
    description = json['description'];
    groupPicture = json['groupPicture'];
    members = (json['members'] as Set<dynamic>)?.cast<AtContact>();
    tags = json['tags'];
    createdOn = UtilServices.stringToDate(json['createdOn']);
    updatedOn = UtilServices.stringToDate(json['updatedOn']);
    createdBy = json['createdBy'];
    updatedBy = json['updatedBy'];
  }

  @override
  String toString() {
    return 'AtGroup{name: $name, description: $description, members: $members, tags: $tags, createdBy: $createdBy, createdOn: $createdOn}';
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
