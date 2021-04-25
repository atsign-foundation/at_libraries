Provides methods to encode/decode utf-7 strings or adapt the modified base64 for custom methods.

## Usage

A simple usage example:

```dart
import 'package:utf7/utf7.dart';

main() {
  // encode/decode strings
  print(Utf7.encode("ûtf-8 chäräctérs")); // +APs-tf-8 ch+AOQ-r+AOQ-ct+AOk-rs
  print(Utf7.decode("+APs-tf-8 ch+AOQ-r+AOQ-ct+AOk-rs")); // ûtf-8 chäräctérs
  // encodeAll additionally encodes characters that could be control characters
  // wherever the encoded string is used
  print(Utf7.encodeAll("A b\r\nc\$")); // A+ACA-b+AA0ACg-c+ACQ-

  // encode/decode modified base64 sequences (the part between + and -)
  print(Utf7.encodeModifiedBase64("û")); // AOQ
  print(Utf7.decodeModifiedBase64("AOQ")); // û
}
```
