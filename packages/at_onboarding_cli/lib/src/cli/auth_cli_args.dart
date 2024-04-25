import 'dart:io';

import 'package:args/args.dart';
import 'package:at_commons/at_commons.dart';
import 'package:meta/meta.dart';

enum AuthCliCommand {
  help(usage: 'Show help'),
  onboard(usage: '"onboard" is used when first authenticating to an atServer.'
      ' It generates "atKeys" (stored to filesystem or keychain) which'
      ' may be used for authentication thereafter.'
      '\n\n'
      'When another program'
      ' needs to be able to authenticate, it may use the atKeys file if it is'
      ' available - however when the program is on a different device, or on '
      ' the same device but in a different, sandboxed app, the recommended'
      ' approach is to use the "enroll" command.'),
  otp(usage: 'Generate a one-time passcode which may be used by a single'
      ' enrollment request.'
      '\n\n'
      'Note that the passcode is used only to allow the'
      ' atServer to identify that an enrollment request is not'
      ' spurious / malicious / spam - i.e. enrollment requests which have a valid'
      ' passcode will be accepted.'),
  spp(usage: 'Set a semi-permanent passcode which may be used by multiple'
      ' enrollment requests. This is particularly useful when programs will '
      ' need to be run on many different devices.'
      '\n\n'
      'Note that the passcode is used only to allow the'
      ' atServer to identify that an enrollment request is not'
      ' spurious / malicious / spam - i.e. enrollment requests which have a valid'
      ' passcode will be accepted.'),
  interactive(usage: 'Run in interactive mode'),
  list(usage: 'List enrollment requests'),
  fetch(usage: 'Fetch a specific enrollment request'),
  approve(usage: 'Approve a pending enrollment request'),
  deny(usage: 'Deny a pending enrollment request'),
  denyAllPending(usage: 'Deny all pending enrollment requests'),
  revoke(usage: 'Revoke approval of a previously-approved enrollment'),
  enroll(usage: 'Enroll is used when a program needs to authenticate and'
      ' "atKeys" are not available, and "onboard" has already been run'
      ' by another program.'
      '\n\n'
      'Enrollment requests require a valid passcode in order'
      ' for them to be accepted by the atServer; accepted requests will then'
      ' be delivered to some other program(s) which have'
      ' permission to approve or deny the requests. Typically that will be'
      ' the program which first onboarded; however it can also be an enrolled'
      ' program which has "rw" access to the "__manage" namespace.');

  const AuthCliCommand({this.usage = ''});
  final String usage;
}

main() {
  print(AuthCliCommand.values);
}

class AuthCliArgs {
  static const defaultAtDirectoryFqdn = 'root.atsign.org';
  static const defaultAtRegistrarFqdn = 'my.atsign.com';
  late final ArgParser _aap;
  late final ArgParser _sap;

  final String atDirectoryFqdn;
  final String atRegistrarFqdn;

  static const argNameHelp = 'help';
  static const argNameVerbose = 'verbose';
  static const argNameDebug = 'debug';
  static const argNameAtSign = 'atsign';
  static const argNameCramSecret = 'cramkey';
  static const argNameAtKeys = 'keys';
  static const argNameAtDirectoryFqdn = 'rootServer';
  static const argNameRegistrarFqdn = 'registrarUrl';
  static const argNameSpp = 'spp';
  static const argNameAppName = 'app';
  static const argNameDeviceName = 'device';
  static const argNamePasscode = 'passcode';
  static const argAbbrPasscode = 's';
  static const argNameNamespaceAccessList = 'namespaces';
  static const argNameEnrollmentId = 'enrollmentId';
  static const argNameEnrollmentStatus = 'enrollmentStatus';

  ArgParser get parser {
    return _aap;
  }

  ArgParser get sharedArgsParser {
    return _sap;
  }

  AuthCliArgs(
      {this.atDirectoryFqdn = defaultAtDirectoryFqdn,
      this.atRegistrarFqdn = defaultAtRegistrarFqdn}) {
    _aap = createMainParser();
    _sap = createSharedArgParser(hide: false);
  }

  /// Creates an ArgParser with commands for each of AuthCliCommand
  @visibleForTesting
  ArgParser createMainParser() {
    final p = ArgParser(
        usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null);

    p.addFlag(
      argNameHelp,
      abbr: 'h',
      negatable: false,
      hide: true,
    );

    for (final c in AuthCliCommand.values) {
      p.addCommand(c.name, createParserForCommand(c));
    }

    return p;
  }

  @visibleForTesting
  ArgParser createParserForCommand(AuthCliCommand c) {
    switch (c) {
      case AuthCliCommand.help:
        return createHelpCommandParser();

      case AuthCliCommand.onboard:
        return createOnboardCommandParser();

      case AuthCliCommand.enroll:
        return createEnrollCommandParser();

      case AuthCliCommand.interactive:
        return createInteractiveCommandParser();

      case AuthCliCommand.spp:
        return createSppCommandParser();

      case AuthCliCommand.otp:
        return createOtpCommandParser();

      case AuthCliCommand.list:
        return createListCommandParser();

      case AuthCliCommand.fetch:
        return createFetchCommandParser();

      case AuthCliCommand.approve:
        return createApproveCommandParser();

      case AuthCliCommand.deny:
        return createDenyCommandParser();

      case AuthCliCommand.denyAllPending:
        return createDenyAllPendingCommandParser();

      case AuthCliCommand.revoke:
        return createRevokeCommandParser();
    }
  }

  /// Make an ArgParser with the args which are common to every command
  @visibleForTesting
  ArgParser createSharedArgParser({required bool hide, bool forOnboard=false}) {
    ArgParser p = ArgParser(
        usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null);
    p.addOption(
      argNameAtSign,
      abbr: 'a',
      help: 'The atSign',
      mandatory: true,
      hide: hide,
    );
    p.addOption(
      argNameAtDirectoryFqdn,
      abbr: 'r',
      help: 'atDirectory (aka root) server\'s domain name',
      defaultsTo: atDirectoryFqdn,
      mandatory: false,
      hide: hide,
    );
    p.addOption(
      argNameAtKeys,
      abbr: 'k',
      help: 'Path to atKeys file to create (onboard / enroll) or use (approve / deny / etc)',
      mandatory: false,
      hide: hide,
    );
    p.addFlag(
      argNameHelp,
      abbr: 'h',
      negatable: false,
      hide: hide,
    );
    p.addFlag(
      argNameVerbose,
      abbr: 'v',
      help: 'INFO-level logging',
      negatable: false,
      hide: hide,
    );
    p.addFlag(
      argNameDebug,
      help: 'FINEST-level logging',
      negatable: false,
      hide: true,
    );
    p.addOption(
      argNameRegistrarFqdn,
      abbr: 'g',
      help: 'url to the registrar api',
      mandatory: false,
      defaultsTo: atRegistrarFqdn,
      hide: !forOnboard,
    );
    p.addOption(
      argNameCramSecret,
      abbr: 'c',
      help: 'CRAM key',
      mandatory: false,
      hide: !forOnboard,
    );

    return p;
  }

  @visibleForTesting
  ArgParser createHelpCommandParser() {
    ArgParser p = createSharedArgParser(hide: true, forOnboard: false);

    return p;
  }

  @visibleForTesting
  ArgParser createOnboardCommandParser() {
    ArgParser p = createSharedArgParser(hide: true, forOnboard: true);

    return p;
  }

  ArgParser createInteractiveCommandParser() {
    ArgParser p = createSharedArgParser(hide: true);
    return p;
  }

  /// auth spp : require atSign, spp [, atKeys path] [, atDirectory]
  @visibleForTesting
  ArgParser createSppCommandParser() {
    ArgParser p = createSharedArgParser(hide: true);
    p.addOption(
      argNameSpp,
      abbr: argAbbrPasscode,
      help: 'The semi-permanent enrollment passcode to set for this atSign',
      mandatory: true,
    );
    return p;
  }

  /// auth otp : require atSign [, atKeys path] [, atDirectory]
  @visibleForTesting
  ArgParser createOtpCommandParser() {
    ArgParser p = createSharedArgParser(hide: true);
    return p;
  }

  /// auth enroll : require atSign, app name, device name, namespaces, otp [, atKeys path]
  ///     If atKeys file doesn't exist, then this is a new enrollment
  ///     If it does exist, then the enrollment request has been made and we need
  ///         to try to auth, and act appropriately on the atServer response
  @visibleForTesting
  ArgParser createEnrollCommandParser() {
    ArgParser p = createSharedArgParser(hide: true);
    p.addOption(
      argNamePasscode,
      abbr: argAbbrPasscode,
      help: 'The passcode to present with this enrollment request.',
      mandatory: true,
    );
    p.addOption(
      argNameAppName,
      abbr: 'p',
      help: 'The name of the app being enrolled',
      mandatory: true,
    );
    p.addOption(
      argNameDeviceName,
      abbr: 'd',
      help: 'A name for the device on which this app is running',
      mandatory: true,
    );
    p.addOption(
      argNameNamespaceAccessList,
      abbr: 'n',
      help:
          'The namespace access list as comma-separated list of name:value pairs'
          ' e.g. "buzz:rw,contacts:rw,__manage:rw"',
      mandatory: true,
    );
    return p;
  }

  /// auth list-enroll-requests
  @visibleForTesting
  ArgParser createListCommandParser() {
    ArgParser p = createSharedArgParser(hide: true);
    p.addOption(
      argNameEnrollmentStatus,
      abbr: 's',
      help:
          'A specific status to filter by; if not supplied, all enrollments will be listed',
      allowed: EnrollmentStatus.values.map((c) => c.name).toList(),
      mandatory: false,
    );
    return p;
  }

  /// auth list-enroll-requests
  @visibleForTesting
  ArgParser createFetchCommandParser() {
    ArgParser p = createSharedArgParser(hide: true);
    _addEnrollmentIdOption(p);
    return p;
  }

  void _addEnrollmentIdOption(ArgParser p) {
    p.addOption(
      argNameEnrollmentId,
      abbr: 'i',
      help: 'The ID of the enrollment request',
      mandatory: true,
    );
  }

  /// auth approve
  @visibleForTesting
  ArgParser createApproveCommandParser() {
    ArgParser p = createSharedArgParser(hide: true);
    _addEnrollmentIdOption(p);
    return p;
  }

  /// auth deny
  @visibleForTesting
  ArgParser createDenyCommandParser() {
    ArgParser p = createSharedArgParser(hide: true);
    _addEnrollmentIdOption(p);
    return p;
  }

  /// auth deny all pending
  @visibleForTesting
  ArgParser createDenyAllPendingCommandParser() {
    ArgParser p = createSharedArgParser(hide: true);
    return p;
  }

  /// auth revoke
  @visibleForTesting
  ArgParser createRevokeCommandParser() {
    ArgParser p = createSharedArgParser(hide: true);
    _addEnrollmentIdOption(p);
    return p;
  }
}
