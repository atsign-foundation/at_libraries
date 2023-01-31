class VerbSyntax {
  // Adding \{ and \} to regex to ensure the JSON encoded String is Map.
  static const from =
      r'^from:(?<atSign>@?[^@:\s]+)(:clientConfig:(?<clientConfig>\{.+\}))?$';
  static const pol = r'^pol$';
  static const cram = r'^cram:(?<digest>.+$)';
  static const pkam = r'^pkam:(?<signature>.+$)';
  static const llookup =
      r'^llookup:((?<operation>meta|all):)?(?:cached:)?((?:public:)|(@(?<forAtSign>[^@:\s]*):))?(?<atKey>[^:]((?!:{2})[^@])+)@(?<atSign>[^@\s]+)$';
  static const plookup =
      r'^plookup:(bypassCache:(?<bypassCache>true|false):)?((?<operation>meta|all):)?(?<atKey>[^@\s]+)@(?<atSign>[^@\s]+)$';
  static const lookup =
      r'^lookup:(bypassCache:(?<bypassCache>true|false):)?((?<operation>meta|all):)?(?<atKey>(?:[^:]).+)@(?<atSign>[^@\s]+)$';
  static const scan =
      r'^scan$|scan(:showhidden:(?<showhidden>true|false))?(:(?<forAtSign>@[^:@\s]+))?(:page:(?<page>\d+))?( (?<regex>\S+))?$';
  static const config =
      r'^config:(?:(?<=config:)block:(?<operation>add|remove|show)(?:(?<=show)\s?$|(?:(?<=add|remove):(?<atSign>(?:@[^\s@]+)( (?:@[^\s@]+))*$))))|(?:(?<=config:)(?<setOperation>set|reset|print):(?<configNew>.+)$)';
  static const stats =
      r'^stats(?<statId>:((?!0)\d+)?(,(\d+))*)?(:(?<regex>(?<=:3:).+))?$';
  static const sync = r'^sync:(?<from_commit_seq>[0-9]+|-1)(:(?<regex>.+))?$';
  static const syncFrom =
      r'^sync:from:(?<from_commit_seq>[0-9]+|-1)(:limit:(?<limit>\d+))(:(?<regex>.+))?$';

  // NB: When adding metadata, you must add it to both the [update] and [update_meta] regexes,
  // and the order must be the same.
  static const update =
      r'^update:json:(?<json>.+)$'
      r'|'
      r'^update'
      r'(:ttl:(?<ttl>(-?)\d+))?'
      r'(:ttb:(?<ttb>(-?)\d+))?'
      r'(:ttr:(?<ttr>(-?)\d+))?'
      r'(:ccd:(?<ccd>true|false))?'
      r'(:dataSignature:(?<dataSignature>[^:@\s]+))?'
      r'(:sharedKeyStatus:(?<sharedKeyStatus>[^:@\s]+))?'
      r'(:isBinary:(?<isBinary>true|false))?'
      r'(:isEncrypted:(?<isEncrypted>true|false))?'
      r'(:sharedKeyEnc:(?<sharedKeyEnc>[^:@\s]+))?'
      r'(:pubKeyCS:(?<pubKeyCS>[^:@\s]+))?'
      r'(:encoding:(?<encoding>[^:@\s]+))?'
      r'(:priority:(?<priority>low|medium|high))?'
      r'(:encKeyName:(?<encKeyName>[^:@\s]+))?'
      r'(:encAlgo:(?<encAlgo>[^:@\s]+))?'
      r'(:ivNonce:(?<ivNonce>[^:@\s]+))?'
      r'(:skeEncKeyName:(?<skeEncKeyName>[^:@\s]+))?'
      r'(:skeEncAlgo:(?<skeEncAlgo>[^:@\s]+))?'
      r':((public:)|(@(?<forAtSign>[^@:\s]*):))?(?<atKey>[^:@]((?!:{2})[^@])+)(@(?<atSign>[^@:\s]*))? (?<value>.+$)';

  // NB: When adding metadata, you must add it to both the [update] and [update_meta] regexes,
  // and the order must be the same.
  // ignore: constant_identifier_names
  static const update_meta =
      r'^update:meta:((public:)|(@(?<forAtSign>[^@:\s]*):))?'
      r'(?<atKey>[^:@]((?!:{2})[^@])+)@(?<atSign>[^@:\s]*)'
      r'(:ttl:(?<ttl>(-?)\d+))?'
      r'(:ttb:(?<ttb>(-?)\d+))?'
      r'(:ttr:(?<ttr>(-?)\d+))?'
      r'(:ccd:(?<ccd>true|false))?'
      r'(:dataSignature:(?<dataSignature>[^:@\s]+))?'
      r'(:sharedKeyStatus:(?<sharedKeyStatus>[^:@\s]+))?'
      r'(:isBinary:(?<isBinary>true|false))?'
      r'(:isEncrypted:(?<isEncrypted>true|false))?'
      r'(:sharedKeyEnc:(?<sharedKeyEnc>[^:@\s]+))?'
      r'(:pubKeyCS:(?<pubKeyCS>[^:@\s]+))?'
      r'(:encoding:(?<encoding>[^:@\s]+))?'
      r'(:priority:(?<priority>low|medium|high))?'
      r'(:encKeyName:(?<encKeyName>[^:@\s]+))?'
      r'(:encAlgo:(?<encAlgo>[^:@\s]+))?'
      r'(:ivNonce:(?<ivNonce>[^:@\s]+))?'
      r'(:skeEncKeyName:(?<skeEncKeyName>[^:@\s]+))?'
      r'(:skeEncAlgo:(?<skeEncAlgo>[^:@\s]+))?'
      r'$';
  static const delete =
      r'^delete:(priority:(?<priority>low|medium|high):)?(?:cached:)?((?:public:)|(@(?<forAtSign>[^@:\s]*):))?(?<atKey>[^:]((?!:{2})[^@])+)(@(?<atSign>[^@\s]+))?$';
  static const monitor = r'^monitor(:(?<epochMillis>\d+))?( (?<regex>.+))?$';
  static const stream =
      r'^stream:((?<operation>init|send|receive|done|resume))?((@(?<receiver>[^@:\s]+)))?( ?namespace:(?<namespace>[\w-]+))?( ?startByte:(?<startByte>\d+))?( (?<streamId>[\w-]*))?( (?<fileName>.* ))?((?<length>\d*))?$';
  static const notify =
      r'^notify:(id:(?<id>[\w\d\-\_]+):)?((?<operation>update|delete):)?(messageType:(?<messageType>key|text):)?(priority:(?<priority>low|medium|high):)?(strategy:(?<strategy>all|latest):)?(latestN:(?<latestN>\d+):)?(notifier:(?<notifier>[^\s:]+):)?(ttln:(?<ttln>\d+):)?(ttl:(?<ttl>\d+):)?(ttb:(?<ttb>\d+):)?(ttr:(?<ttr>(-)?\d+):)?(ccd:(?<ccd>true|false):)?(isEncrypted:(?<isEncrypted>true|false):)?(sharedKeyEnc:(?<sharedKeyEnc>[^:@]+):)?(pubKeyCS:(?<pubKeyCS>[^:@]+):)?(@(?<forAtSign>[^@:\s]*)):(?<atKey>[^:@]((?!:{2})[^@])+)(@(?<atSign>[^@:\s]+))?(:(?<value>.+))?$';
  static const notifyList =
      r'^notify:list(:(?<fromDate>\d{4}-[01]?\d?-[0123]?\d?))?(:(?<toDate>\d{4}-[01]?\d?-[0123]?\d?))?(:(?<regex>[^:]+))?';
  static const notifyStatus = r'^notify:status:(?<notificationId>\S+)$';
  static const notifyFetch = r'^notify:fetch:(?<notificationId>\S+)$';
  static const notifyAll =
      r'^notify:all:((?<operation>update|delete):)?(messageType:((?<messageType>key|text):))?(?:ttl:(?<ttl>\d+):)?(?:ttb:(?<ttb>\d+):)?(?:ttr:(?<ttr>-?\d+):)?(?:ccd:(?<ccd>true|false+):)?(?<forAtSign>(([^:\s])+)?(,([^:\s]+))*)(:(?<atKey>[^@:\s]+))(@(?<atSign>[^@:\s]+))?(:(?<value>.+))?$';
  static const batch = r'^batch:(?<json>.+)$';
  static const info = r'^info(:brief)?$';
  static const noOp = r'^noop:(?<delayMillis>\d+)$';
  static const notifyRemove = r'notify:remove:(?<id>[\w\d\-\_]+)';
}
