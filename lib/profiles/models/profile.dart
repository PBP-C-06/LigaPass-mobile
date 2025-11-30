// To parse this JSON data, do
//
//     final profile = profileFromJson(jsonString);

import 'dart:convert';

List<Profile> profileFromJson(String str) => List<Profile>.from(json.decode(str).map((x) => Profile.fromJson(x)));

String profileToJson(List<Profile> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Profile {
    String id;
    String username;
    String email;
    String fullName;
    String phone;
    String? profilePicture;
    DateTime dateOfBirth;
    String status;

    Profile({
        required this.id,
        required this.username,
        required this.email,
        required this.fullName,
        required this.phone,
        required this.profilePicture,
        required this.dateOfBirth,
        required this.status,
    });

    factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json["id"],
        username: json["username"],
        email: json["email"],
        fullName: json["full_name"],
        phone: json["phone"],
        profilePicture: json["profile_picture"],
        dateOfBirth: DateTime.parse(json["date_of_birth"]),
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "full_name": fullName,
        "phone": phone,
        "profile_picture": profilePicture,
        "date_of_birth": "${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}",
        "status": status,
    };
}
