class ProfileImage {
  String? message;
  int? userId;
  String? profileImage;

  ProfileImage({this.message, this.userId, this.profileImage});

  ProfileImage.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    userId = json['user_id'];
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    data['user_id'] = this.userId;
    data['profile_image'] = this.profileImage;
    return data;
  }
}