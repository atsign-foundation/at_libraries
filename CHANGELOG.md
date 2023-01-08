## 3.0.34
- feat: New server-side exception ServerIsPausedException, error code AT0024
## 3.0.33
- fix: Deprecate AtCompactionConfig class
## 3.0.32
- fix: Enable deletion of a local key
## 3.0.31
- feat: Added AtTelemetryService. Marked @experimental while the feature is in early stages.
## 3.0.30
* fix: Add key validations to Update and llookup verb builders
## 3.0.29
* fix: AtKey.fromString() sets incorrect value in sharedWith attribute for public keys.
## 3.0.28
* feat: Introduce the local key type
## 3.0.27
* feat: Implement the `==` and `hashCode` methods for AtKey, AtValue and Metadata classes
## 3.0.26
* feat: Introduce notifyFetch verb
* fix: bug in at_exception_stack.dart
## 3.0.25
* fix: update regex to correctly parse negative values in ttl and ttb
* feat: add clientConfig to from verb syntax
## 3.0.24
* fix:  add error code for InvalidAtKeyException
## 3.0.23
* fix: bug fixes to AtKey.fromString static method and various toString instance methods
* feat: When validating AtKeys, allow _namespace_ to be optional, for legacy app code which depends on keys without namespaces
* feat: Added _getKeyType_ to AtKey

## 3.0.22
- Add ENCODING to update verb regex, update verb builder and Metadata to support encoding of new line character
- Add AtKeyNotFoundException for non-existent keys in secondary
- Add documentation around the Metadata fields
## 3.0.21
- Add constant for stats notification id
## 3.0.20
- Enhance notify verb to include the isEncrypted field
- Add intent and exception scenario to AtException sub-classes
- Introducing class SecureSocketConfig to store config params to create security context for secure sockets.
## 3.0.19
- Rename byPassCache to bypassCache in lookup, plookup verb builders and at_constants
## 3.0.18
- Add 'showHidden' to scan regex to display hidden keys when set to true
## 3.0.17
- Introduce exception hierarchy and new AtException subclasses
## 3.0.16
- Hide at_client_exceptions.dart to prevent at_client_exception being referred from at_commons
## 3.0.15
- FEAT: support to bypass cache in lookup and plookup verbs
## 3.0.14
- Remove unnecessary print statements
## 3.0.13
- Generate default notification id
## 3.0.12
- Added optional parameter to info verb. Valid syntax is now either 'info' or 'info:brief'
## 3.0.11
- Rename 'NotifyDelete' to 'NotifyRemove' since 'notify:delete' is already in use.
## 3.0.10
- Added syntax regex for 'notifyDelete' verb
## 3.0.9
- Bug fix in notify verb syntax
## 3.0.8
- Support for encryption shared key and public key in notify verb
## 3.0.7
- Added encryption shared key and public key checksum to metadata
## 3.0.6
- Added syntax regexes for new verbs 'info' and 'noop'
## 3.0.5
- Rename TimeoutException to AtTimeoutException to prevent confusion with Dart async's TimeoutException
## 3.0.4
- Add TimeoutException
## 3.0.3
- Add static factor methods for AtKey creation
## 3.0.2
- added constants for compaction and notification expiry
## 3.0.1
- Add AtKey validations
## 3.0.0
- sync pagination changes
## 2.0.5
- version 2.0.4 update issue
## 2.0.4
- Shared key status in metadata
- Add last notification time to Monitor
## 2.0.3
- Syntax change in stream verb to support resume
## 2.0.2
- Fix regex issue in Notify verb
## 2.0.1
- Remove trailing space in StatsVerbBuilder
## 2.0.0
- Null safety upgrade
## 1.0.1+8
- Refactor code with dart lint rules
## 1.0.1+7
- Third party package dependency upgrade
## 1.0.1+6
- Replace ByteBuffer with ByteBuilder
## 1.0.1+5
- Notification sub system changes
## 1.0.1+4
- added createdAt and updatedAt to metadata
  Introduced batch verb for sync
## 1.0.1+3
- Notify verb builder and update verb syntax changes
## 1.0.1+2
- Update verb builder changes
## 1.0.1+1
- Stream verb syntax changes
## 1.0.1
- Initial version, created by Stagehand