class AccountInfo {
  final int uid;
  final String usr;
  final int role;
  final String mobile;
  final String email;
  final String qname;
  final bool enable;
  final DateTime gts;
  final String? photo;

  AccountInfo({
    required this.uid,
    required this.usr,
    required this.role,
    required this.mobile,
    required this.email,
    required this.qname,
    required this.enable,
    required this.gts,
    this.photo,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      uid: json['uid'] ?? 0,
      usr: json['usr'] ?? '',
      role: json['role'] ?? 0,
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      qname: json['qname'] ?? '',
      enable: json['enable'] ?? false,
      gts: json['gts'] != null ? DateTime.parse(json['gts']) : DateTime.now(),
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'usr': usr,
      'role': role,
      'mobile': mobile,
      'email': email,
      'qname': qname,
      'enable': enable,
      'gts': gts.toIso8601String(),
      'photo': photo,
    };
  }
} 