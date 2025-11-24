import 'dart:convert';

List<User> userFromJson(String str) => List<User>.from(json.decode(str).map((x) => User.fromJson(x)));

String userToJson(List<User> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class User {
    String id;
    String username;
    String email;
    String firstName;
    String lastName;
    String role;
    String? phone;
    bool profileCompleted;
    bool isGoogleAccount;

    User({
        required this.id,
        required this.username,
        required this.email,
        required this.firstName,
        required this.lastName,
        required this.role,
        required this.phone,
        required this.profileCompleted,
        required this.isGoogleAccount,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        username: json["username"],
        email: json["email"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        role: json["role"],
        phone: json["phone"],
        profileCompleted: json["profile_completed"],
        isGoogleAccount: json["is_google_account"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "first_name": firstName,
        "last_name": lastName,
        "role": role,
        "phone": phone,
        "profile_completed": profileCompleted,
        "is_google_account": isGoogleAccount,
    };
}
