class dThread {
  int? id;
  String? name;
  String? directthreadmsg;
  List<dynamic>? fileUrls;
  List<dynamic>? fileNames;
  String? profileImage;
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
      this.senderId,
      this.fileNames,
      this.profileImage});
  dThread.fromJson(Map<String, dynamic> json) {
    directMsgId = json['t_direct_message_id'];
    fileUrls = json['file_urls'];
    id = json['id'];
    name = json['name'];
    directthreadmsg = json['directthreadmsg'];
    created_at = json['created_at'];
    senderId = json['sender_id'];
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
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
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}

class DirectMsg {
  int? id;
  int? receiverId;
  int? senderId;
  String? created_at;
  List<dynamic>? fileUrls;
  List<dynamic>? fileName;
  String? profileName;
  String? directmsg;
  bool? activeStatus;
  bool? senderActiveStatus;
  String? name;
  String? receiverName;

  DirectMsg(
      {this.created_at,
      this.directmsg,
      this.name,
      this.id,
      this.fileUrls,
      this.senderId,
      this.receiverId,
      this.profileName,
      this.fileName,
      this.receiverName,
      this.activeStatus,
      this.senderActiveStatus});
  DirectMsg.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    receiverId = json['receiver_id'];
    fileUrls = json['file_urls'];
    senderId = json['sender_id'];
    created_at = json['created_at'];
    receiverName = json['receiver_name'];
    activeStatus = json['active_status'];
    senderActiveStatus = json['sender_active_status'];
    fileName = json['file_names'] as List<dynamic>?;
    profileName = json['profile_image'];
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
    data['file_names'] = this.fileName;
    data['profile_image'] = this.profileName;
    data['receiver_name'] = this.receiverName;
    data['sender_active_status'] = this.senderActiveStatus;
    data['active_status'] = this.activeStatus;
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
  String? profileName;
  List<dynamic>? fileName;
  String? created_at;
  int? senderId;
  G_message(
      {this.created_at,
      this.groupmsg,
      this.name,
      this.id,
      this.fileUrls,
      this.senderId,
      this.profileName,
      this.fileName});
  G_message.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    channelId = json['channel_id'];
    channelStatus = json['channel_status'];
    channelName = json['channel_name'];
    fileUrls = json['file_urls'];
    groupmsg = json['groupmsg'];
    profileName = json['profile_image'];
    fileName = json['file_names'] as List<dynamic>?;
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
    data['profile_image'] = this.profileName;
    data['file_names'] = this.fileName;
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
  String? profileName;
  List<dynamic>? fileName;
  int? groupMessageId;
  String? created_at;
  int? senderId;
  G_thread(
      {this.created_at,
      this.groupthreadmsg,
      this.name,
      this.channelName,
      this.fileUrls,
      this.senderId,
      this.profileName,
      this.fileName});
  G_thread.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupMessageId = json['t_group_message_id'];
    name = json['name'];
    fileUrls = json['file_urls'];
    channelName = json['channel_name'];
    groupthreadmsg = json['groupthreadmsg'];
    created_at = json['created_at'];
    profileName = json['profile_image'];
    fileName = json['file_names'] as List<dynamic>?;
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
    data['profile_image'] = this.profileName;
    data['file_names'] = this.fileName;
    return data;
  }
}
