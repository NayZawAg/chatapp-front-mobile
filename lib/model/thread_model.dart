class dThread {
  int? id;
  String? name;
  String? directthreadmsg;
  List<dynamic>? fileUrls;
  int? directMsgId;
  String? created_at;
  int? senderId;
  dThread(
      {this.id,
      this.directthreadmsg,
      this.name,
      this.created_at,
      this.directMsgId,
      this.fileUrls,
      this.senderId});
  dThread.fromJson(Map<String, dynamic> json) {
    directMsgId = json['t_direct_message_id'];
    fileUrls = json['file_urls'];
    id = json['id'];
    name = json['name'];
    directthreadmsg = json['directthreadmsg'];
    created_at = json['created_at'];
    senderId = json['sender_id'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['t_direct_message_id'] = this.directMsgId;
    data['file_urls'] = this.fileUrls;
    data['created_at'] = this.created_at;
    data['directthreadmsg'] = this.directthreadmsg;
    data['name'] = this.name;
    data['id'] = this.id;
    data['sender_id'] = this.senderId;
    return data;
  }
}

class DirectMsg {
  int? id;
  int? receiverId;
  int? senderId;
  String? created_at;
  List<dynamic>? fileUrls;
  String? directmsg;
  String? name;
  DirectMsg(
      {this.created_at,
      this.directmsg,
      this.name,
      this.id,
      this.fileUrls,
      this.senderId,
      this.receiverId});
  DirectMsg.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    receiverId = json['receiver_id'];
    fileUrls = json['file_urls'];
    senderId = json['sender_id'];
    created_at = json['created_at'];
    directmsg = json['directmsg'];
    name = json['name'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['receiver_id'] = this.receiverId;
    data['file_urls'] = this.fileUrls;
    data['sender_id'] = this.senderId;
    data['created_at'] = this.created_at;
    data['directmsg'] = this.directmsg;
    data['name'] = this.name;
    data['id'] = this.id;
    return data;
  }
}

class G_message {
  int? id;
  String? name;
  String? groupmsg;
  bool? channelStatus;
  String? channelName;
  int? channelId;
  List<dynamic>? fileUrls;
  String? created_at;
  int? senderId;
  G_message(
      {this.created_at,
      this.groupmsg,
      this.name,
      this.id,
      this.fileUrls,
      this.senderId});
  G_message.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    channelId = json['channel_id'];
    channelStatus = json['channel_status'];
    channelName = json['channel_name'];
    fileUrls = json['file_urls'];
    groupmsg = json['groupmsg'];
    created_at = json['created_at'];
    senderId = json['m_user_id'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['file_urls'] = this.fileUrls;
    data['channel_id'] = this.channelId;
    data['channel_name'] = this.channelName;
    data['channel_status'] = this.channelStatus;
    data['groupmsg'] = this.groupmsg;
    data['created_at'] = this.created_at;
    data['m_user_id'] = this.senderId;
    return data;
  }
}

class G_thread {
  int? id;
  String? name;
  String? channelName;
  List<dynamic>? fileUrls;
  String? groupthreadmsg;
  int? groupMessageId;
  String? created_at;
  int? senderId;
  G_thread(
      {this.created_at,
      this.groupthreadmsg,
      this.name,
      this.channelName,
      this.fileUrls,
      this.senderId});
  G_thread.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupMessageId = json['t_group_message_id'];
    name = json['name'];
    fileUrls = json['file_urls'];
    channelName = json['channel_name'];
    groupthreadmsg = json['groupthreadmsg'];
    created_at = json['created_at'];
    senderId = json['m_user_id'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['file_urls'] = this.fileUrls;
    data['t_group_message_id'] = this.groupMessageId;
    data['channel_name'] = this.channelName;
    data['groupthreadmsg'] = this.groupthreadmsg;
    data['created_at'] = this.created_at;
    data['m_user_id'] = this.senderId;
    return data;
  }
}
