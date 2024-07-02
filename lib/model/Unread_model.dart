class Un_Thread {
  String? name;
  String? directthreadmsg;
  String? created_at;
  Un_Thread({this.directthreadmsg, this.name, this.created_at});
  Un_Thread.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    directthreadmsg = json['directthreadmsg'];
    created_at = json['created_at'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['created_at'] = this.created_at;
    data['directthreadmsg'] = this.directthreadmsg;
    data['name'] = this.name;
    return data;
  }
}

class Un_G_Thread {
  int? id;
  String? name;
  String? channel_name;
  String? groupthreadmsg;
  String? created_at;
  Un_G_Thread(
      {this.id,
      this.groupthreadmsg,
      this.channel_name,
      this.name,
      this.created_at});
  Un_G_Thread.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    channel_name = json['channel_name'];
    groupthreadmsg = json['groupthreadmsg'];
    created_at = json['created_at'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['created_at'] = this.created_at;
    data['groupthreadmsg'] = this.groupthreadmsg;
    data['name'] = this.name;
    data['channel_name'] = this.channel_name;
    return data;
  }
}

class Un_DirectMsg {
  String? created_at;
  String? directmsg;
  String? name;
  Un_DirectMsg({this.created_at, this.directmsg, this.name});
  Un_DirectMsg.fromJson(Map<String, dynamic> json) {
    created_at = json['created_at'];
    directmsg = json['directmsg'];
    name = json['name'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['created_at'] = this.created_at;
    data['directmsg'] = this.directmsg;
    data['name'] = this.name;
    return data;
  }
}

class Un_G_message {
  int? id;
  String? name;
  String? channel_name;
  String? groupmsg;
  String? created_at;
  Un_G_message(
      {this.id, this.channel_name, this.created_at, this.groupmsg, this.name});
  Un_G_message.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    groupmsg = json['groupmsg'];
    created_at = json['created_at'];
    channel_name = json['channel_name'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['groupmsg'] = this.groupmsg;
    data['created_at'] = this.created_at;
    data['channel_name'] = this.channel_name;
    return data;
  }
}
