import 'dart:convert';

class MyData {
  final String key;
  final int myNumber;

  MyData(this.key, this.myNumber);

  factory MyData.fromJson(String json) {
    Map<String, dynamic> data = jsonDecode(json);
    return MyData(
      data['key'] ?? '',
      data['myNumber'] ?? 0,
    );
  }

  String toJson() => jsonEncode({'key': key, 'myNumber': myNumber});

  @override
  String toString() {
    return 'MyData{key: $key, myNumber: $myNumber}';
  }
}