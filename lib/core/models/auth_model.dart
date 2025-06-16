import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

@JsonSerializable()
class AuthModel {
  final String usr;
  final String pwd;
  final String? token;
  final String? secret;
  final int? err;
  final String? desc;

  AuthModel({
    required this.usr,
    required this.pwd,
    this.token,
    this.secret,
    this.err,
    this.desc,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) => _$AuthModelFromJson(json);
  Map<String, dynamic> toJson() => _$AuthModelToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final int err;
  final String desc;
  final LoginData? dat;

  LoginResponse({
    required this.err,
    required this.desc,
    this.dat,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class LoginData {
  final String token;
  final String secret;

  LoginData({
    required this.token,
    required this.secret,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) => _$LoginDataFromJson(json);
  Map<String, dynamic> toJson() => _$LoginDataToJson(this);
} 