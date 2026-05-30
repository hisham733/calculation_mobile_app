import 'package:flutter/material.dart';

class UserProfile {
  final int? id;
  String name;
  int colorValue;

  UserProfile({this.id, required this.name, this.colorValue = 0xFF007AFF});

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'color_value': colorValue,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as int,
        name: map['name'] as String,
        colorValue: map['color_value'] as int,
      );
}
