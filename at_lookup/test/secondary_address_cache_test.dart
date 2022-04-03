import 'package:at_lookup/src/cache/secondary_address_cache.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() async {
  test(' test create a group', () async {
    var secondaryAddress = await SecondaryAddressCacheImpl.getInstance()
        .getAddress('@colin', 'root.atsign.org', 64);
    expect(secondaryAddress.port, isNotNull);
    expect(secondaryAddress.host, isNotNull);
    print(secondaryAddress.toString());
  });
}
