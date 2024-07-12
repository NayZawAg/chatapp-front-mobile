class Un_Thread {
  String? name;
  String? directthreadmsg;
  String? created_at;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;
  Un_Thread(
      {this.directthreadmsg,
      this.name,
      this.created_at,
      this.files,
      this.fileNames,
      this.profileImage});
  Un_Thread.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    directthreadmsg = json['directthreadmsg'];
    created_at = json['created_at'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['created_at'] = this.created_at;
    data['directthreadmsg'] = this.directthreadmsg;
    data['name'] = this.name;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}

class Un_G_Thread {
  int? id;
  String? name;
  String? channel_name;
  String? groupthreadmsg;
  String? created_at;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;

  Un_G_Thread(
      {this.id,
      this.groupthreadmsg,
      this.channel_name,
      this.name,
      this.created_at,
      this.files,
      this.fileNames,
      this.profileImage});
  Un_G_Thread.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    channel_name = json['channel_name'];
    groupthreadmsg = json['groupthreadmsg'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
    created_at = json['created_at'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['created_at'] = this.created_at;
    data['groupthreadmsg'] = this.groupthreadmsg;
    data['name'] = this.name;
    data['channel_name'] = this.channel_name;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}

class Un_DirectMsg {
  String? created_at;
  String? directmsg;
  String? name;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;
  Un_DirectMsg(
      {this.created_at,
      this.directmsg,
      this.name,
      this.files,
      this.fileNames,
      this.profileImage});
  Un_DirectMsg.fromJson(Map<String, dynamic> json) {
    created_at = json['created_at'];
    directmsg = json['directmsg'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
    name = json['name'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['created_at'] = this.created_at;
    data['directmsg'] = this.directmsg;
    data['name'] = this.name;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}

class Un_G_message {
  int? id;
  String? name;
  String? channel_name;
  String? groupmsg;
  String? created_at;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;

  Un_G_message(
      {this.id,
      this.channel_name,
      this.created_at,
      this.groupmsg,
      this.name,
      this.files,
      this.fileNames,
      this.profileImage});
  Un_G_message.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    groupmsg = json['groupmsg'];
    created_at = json['created_at'];
    channel_name = json['channel_name'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['groupmsg'] = this.groupmsg;
    data['created_at'] = this.created_at;
    data['channel_name'] = this.channel_name;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}
