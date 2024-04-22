import 'package:args/args.dart';
import 'package:meta/meta.dart';

enum AuthCliCommand {
  onboard,
  spp,
  interactive,
  listen,
  listEnrollRequests,
  approve,
  deny,
  revoke,
  enroll,
}

class AuthCliArgs {
  static const defaultAtDirectoryFqdn = 'root.atsign.org';
  static const defaultAtRegistrarFqdn = 'my.atsign.com';
  late final ArgParser _aap;

  final String atDirectoryFqdn;
  final String atRegistrarFqdn;

  static const argNameHelp = 'help';
  static const argNameVerbose = 'verbose';
  static const argNameDebug = 'debug';
  static const argNameAtSign = 'atsign';
  static const argNameCramSecret = 'cramkey';
  static const argNameAtDirectoryFqdn  = 'rootServer';
  static const argNameRegistrarFqdn  = 'registrarUrl';
  static const argNameSpp  = 'spp';
  static const argNameAppName  = 'app';
  static const argNameDeviceName  = 'device';
  static const argNamePasscode  = 'passcode';
  static const argNameNamespaceAccessList  = 'namespaces';
  static const argNameEnrollmentId  = 'enrollmentId';

  ArgParser get parser {
    return _aap;
  }

  AuthCliArgs(
      {this.atDirectoryFqdn = defaultAtDirectoryFqdn,
      this.atRegistrarFqdn = defaultAtRegistrarFqdn}) {
    _aap = createMainParser();
  }

  /// Creates an ArgParser with commands for
  /// - onboard
  /// - spp
  /// - enroll
  /// - listEnrollRequests
  /// - approve
  /// - deny
  /// - listEnrollments
  /// - revoke
  @visibleForTesting
  ArgParser createMainParser() {
    final p = ArgParser();

    for (final c in AuthCliCommand.values) {
      p.addCommand(c.name, createParserForCommand(c));
    }

    p.addFlag(
      argNameHelp,
      abbr: 'h',
      help: 'Usage instructions',
      negatable: false,
    );
    p.addFlag(
      argNameVerbose,
      abbr: 'v',
      help: 'INFO-level logging',
      negatable: false,
    );
    p.addFlag(
      argNameDebug,
      help: 'FINEST-level logging',
      negatable: false,
    );

    return p;
  }

  @visibleForTesting
  ArgParser createParserForCommand(AuthCliCommand c) {
    switch (c) {
      case AuthCliCommand.onboard:
        return createOnboardCommandParser();

      case AuthCliCommand.enroll:
        return createEnrollCommandParser();

      case AuthCliCommand.interactive:
        return createInteractiveCommandParser();

      case AuthCliCommand.listen:
        return createListenCommandParser();

      case AuthCliCommand.spp:
        return createSppCommandParser();

      case AuthCliCommand.listEnrollRequests:
        return createListEnrollRequestsCommandParser();

      case AuthCliCommand.approve:
        return createApproveCommandParser();

      case AuthCliCommand.deny:
        return createDenyCommandParser();

      case AuthCliCommand.revoke:
        return createRevokeCommandParser();
    }
  }

  /// auth onboard : require atSign, [, cram, atDirectory, atRegistrar]
  /// When the cram arg is not supplied, we first use the registrar API
  /// to send an OTP to the user and then use that OTP to obtain the cram
  /// secret from the registrar.
  @visibleForTesting
  ArgParser createOnboardCommandParser() {
    ArgParser p = ArgParser();
    p.addOption(
      argNameAtSign,
      abbr: 'a',
      help: 'atSign to activate',
      mandatory: true,
    );
    p.addOption(
      argNameCramSecret,
      abbr: 'c',
      help: 'CRAM key',
      mandatory: false,
    );
    p.addOption(
      argNameAtDirectoryFqdn,
      abbr: 'r',
      help: 'atDirectory (root) server\'s domain name',
      defaultsTo: atDirectoryFqdn,
      mandatory: false,
    );
    p.addOption(
      argNameRegistrarFqdn,
      abbr: 'g',
      help: 'url to the registrar api',
      mandatory: false,
      defaultsTo: atRegistrarFqdn,
    );
    p.addFlag(
      argNameHelp,
      abbr: 'h',
      help: 'Usage instructions',
      negatable: false,
    );

    return p;
  }

  ArgParser createInteractiveCommandParser() {
    final p = ArgParser();

    p.addOption(
      argNameAtSign,
      abbr: 'a',
      help: 'The atSign',
      mandatory: true,
    );
    p.addOption(
      argNameAtDirectoryFqdn,
      abbr: 'r',
      help: 'root server\'s domain name',
      defaultsTo: atDirectoryFqdn,
      mandatory: false,
    );
    return p;
  }

  ArgParser createListenCommandParser() {
    final p = ArgParser();

    p.addOption(
      argNameAtSign,
      abbr: 'a',
      help: 'The atSign',
      mandatory: true,
    );
    p.addOption(
      argNameAtDirectoryFqdn,
      abbr: 'r',
      help: 'root server\'s domain name',
      defaultsTo: atDirectoryFqdn,
      mandatory: false,
    );
    return p;
  }

  /// auth spp : require atSign, spp [, atKeys path] [, atDirectory]
  @visibleForTesting
  ArgParser createSppCommandParser() {
    final p = ArgParser();
    p.addOption(
      argNameAtSign,
      abbr: 'a',
      help: 'The atSign for which we are setting the spp (semi-permanent-pin)',
      mandatory: true,
    );
    p.addOption(
      argNameSpp,
      abbr: 's',
      help: 'The semi-permanent enrollment pin to set for this atSign',
      mandatory: true,
    );
    p.addOption(
      argNameAtDirectoryFqdn,
      abbr: 'r',
      help: 'root server\'s domain name',
      defaultsTo: atDirectoryFqdn,
      mandatory: false,
    );
    return p;
  }

  /// auth enroll : require atSign, app name, device name, otp [, atKeys path]
  ///     If atKeys file doesn't exist, then this is a new enrollment
  ///     If it does exist, then the enrollment request has been made and we need
  ///         to try to auth, and act appropriately on the atServer response
  @visibleForTesting
  ArgParser createEnrollCommandParser() {
    final p = ArgParser();
    p.addOption(
      argNameAtSign,
      abbr: 'a',
      help: 'The atSign for which we are setting the spp (semi-permanent-pin)',
      mandatory: true,
    );
    p.addOption(
      argNamePasscode,
      abbr: 'p',
      help: 'The passcode to present with this enrollment request.',
      mandatory: true,
    );
    p.addOption(
      argNameAppName,
      help: 'The name of the app being enrolled',
      mandatory: true,
    );
    p.addOption(
      argNameDeviceName,
      help: 'A name for the device on which this app is running',
      mandatory: true,
    );
    p.addOption(
      argNameAtDirectoryFqdn,
      abbr: 'r',
      help: 'atDirectory (root) server\'s domain name',
      defaultsTo: atDirectoryFqdn,
      mandatory: false,
    );
    p.addOption(
      argNameRegistrarFqdn,
      abbr: 'g',
      help: 'url to the registrar api',
      mandatory: false,
      defaultsTo: atRegistrarFqdn,
    );
    p.addFlag(
      argNameHelp,
      abbr: 'h',
      help: 'Usage instructions',
      negatable: false,
    );
    return p;
  }

  /// auth list-enroll-requests
  @visibleForTesting
  ArgParser createListEnrollRequestsCommandParser() {
    final p = ArgParser();
    return p;
  }

  /// auth approve
  @visibleForTesting
  ArgParser createApproveCommandParser() {
    final p = ArgParser();
    return p;
  }

  /// auth deny
  @visibleForTesting
  ArgParser createDenyCommandParser() {
    final p = ArgParser();
    return p;
  }

  /// auth revoke
  @visibleForTesting
  ArgParser createRevokeCommandParser() {
    final p = ArgParser();
    return p;
  }
}
