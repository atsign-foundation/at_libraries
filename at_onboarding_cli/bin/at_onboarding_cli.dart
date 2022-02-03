import 'dart:io';

import 'package:at_onboarding_cli/at_onboarding_cli.dart' as at_onboarding_cli;
import 'package:at_onboarding_cli/src/at_onboarding_service.dart';
import 'package:at_onboarding_cli/src/config_utils/config_util.dart';
import 'package:yaml/yaml.dart';

Future<void> main(List<String> arguments) async {
  String atSign = arguments[0];
  OnboardingService onboardingService = OnboardingService(atSign);
  String? filePath = getStringValueFromYaml(['auth', 'atKeysPath']);
  String jsonData = await getAuthData(filePath!);
  onboardingService.authenticate(atSign, jsonData);
}

dynamic getConfigValueFromYaml(List<String> args) {
  YamlMap? yamlMap = ConfigUtil.getConfigYaml();
  var value;
  if (yamlMap != null) {
    for (int i = 0; i < args.length; i++) {
      if (i == 0) {
        value = yamlMap[args[0]];
      } else {
        value = value[args[i]];
      }
    }
  }
  if (value == null || value == Null) {
    throw Exception('Specified config not found');
  }
  return value;
}

String? getStringValueFromYaml(List<String> keyParts) {
  var yamlMap = ConfigUtil.getConfigYaml();
  var value;
  if (yamlMap != null) {
    for (int i = 0; i < keyParts.length; i++) {
      if (i == 0) {
        value = yamlMap[keyParts[i]];
      } else {
        if (value != null) {
          value = value[keyParts[i]];
        }
      }
    }
  }

  if (value == Null || value == null) {
    return null;
  } else {
    return value.toString();
  }
}

Future<String> getAuthData(String atKeysFilePath) async {
  File atKeysFile = File(atKeysFilePath);
  final String atAuthData = await atKeysFile.readAsString();
  return atAuthData;
}

Future<dynamic> getRootServerUrl() {
  return getConfigValueFromYaml(['root_server', 'url']);
}

Future<dynamic> getRootServerPort() {
  return getConfigValueFromYaml(['root_server', 'port']);
}
