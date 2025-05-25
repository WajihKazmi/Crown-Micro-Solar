class SignUpModel {
  String email;
  String password;
  String firstName;
  String lastName;
  String gender;
  String dateOfBirth;
  String phone;
  String interest;

  SignUpModel({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    required this.phone,
    required this.interest,
  });

  factory SignUpModel.fromJson(Map<String, dynamic> json) {
    return SignUpModel(
      email: json['email'],
      password: json['password'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'],
      phone: json['phone'],
      interest: json['interest'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['email'] = email;
    data['password'] = password;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['gender'] = gender;
    data['dateOfBirth'] = dateOfBirth;
    data['phone'] = phone;
    data['interest'] = interest;
    return data;
  }
}
