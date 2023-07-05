class Criminal {
  String uid;
  String? image;
  String name;
  int age;
  int pincode;
  final DateTime timestamp;

  Criminal({
    required this.uid,
    this.image,
    required this.name,
    required this.age,
    required this.pincode,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'image': image,
      'name': name,
      'age': age,
      'pincode': pincode,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Criminal.fromMap(Map<dynamic, dynamic> map) {
    return Criminal(
      uid: map['uid'],
      image: map['image'],
      name: map['name'],
      age: map['age'] ?? 0,
      pincode: map['pincode'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}
