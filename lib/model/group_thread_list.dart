class GroupThreadMessage {
  List<gpThreads>? GpThreads;
  List<dynamic>? GpThreadStar;
  List<mChannelUser>? TChannelUsers;
  List<mUsers>? MUsers;
  List<EmojiCountsforGpThread>? emojiCounts;
  List<ReactUserDataForGpThread>? reactUserDatas;
  GroupThreadMessage(
      {this.GpThreads,
      this.GpThreadStar,
      this.TChannelUsers,
      this.emojiCounts,
      this.reactUserDatas});

  GroupThreadMessage.fromJson(Map<String, dynamic> json) {
    if (json['retrieveGroupThread']['t_group_threads'] != null) {
      GpThreads = <gpThreads>[];
      json['retrieveGroupThread']['t_group_threads'].forEach((v) {
        GpThreads!.add(new gpThreads.fromJson(v));
      });
    }
    if (json['retrieveGroupThread']['m_channel_users'] != null) {
      TChannelUsers = <mChannelUser>[];
      json['retrieveGroupThread']['m_channel_users'].forEach((v) {
        TChannelUsers!.add(new mChannelUser.fromJson(v));
      });
    }
    if (json['retrievehome']['m_users'] != null) {
      MUsers = <mUsers>[];
      json['retrievehome']['m_users'].forEach((v) {
        MUsers!.add(new mUsers.fromJson(v));
      });
    }
    GpThreadStar = json['retrieveGroupThread']['t_group_star_thread_msgids'];

    if (json['retrieveGroupThread']['emoji_counts'] != null) {
      emojiCounts = <EmojiCountsforGpThread>[];
      json['retrieveGroupThread']['emoji_counts'].forEach((v) {
        emojiCounts!.add(EmojiCountsforGpThread.fromJson(v));
      });
    }
    if (json['retrieveGroupThread']['react_usernames'] != null) {
      reactUserDatas = <ReactUserDataForGpThread>[];
      json['retrieveGroupThread']['react_usernames'].forEach((v) {
        reactUserDatas!.add(ReactUserDataForGpThread.fromJson(v));
      });
    }
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.GpThreads != null) {
      data['retrieveGroupThread']['t_group_threads'] =
          this.GpThreads!.map((e) => e.toJson()).toList();
    }
    if (this.MUsers != null) {
      data['retrievehome']['m_users'] =
          this.MUsers!.map((e) => e.toJson()).toList();
    }
    data['retrieveGroupThread']['t_group_star_thread_msgids'] =
        this.GpThreadStar;

    if (emojiCounts != null) {
      data['retrieveGroupThread']['emoji_counts'] =
          emojiCounts!.map((e) => e.toJson()).toList();
    }
    if (reactUserDatas != null) {
      data['retrieveGroupThread']['react_userNames'] =
          reactUserDatas!.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class mUsers {
  bool? user_status;
  String? name;
  String? email;
  mUsers({this.email, this.name, this.user_status});
  mUsers.fromJson(Map<String, dynamic> json) {
    user_status = json['active_status'];
    name = json['name'];
    email = json['email'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['active_status'] = this.user_status;
    data['email'] = this.email;
    return data;
  }
}

class gpThreads {
  int? id;
  String? name;
  int? sendUserId;
  String? groupthreadmsg;
  List<dynamic>? fileUrls;
  String? profileName;
  List<dynamic>? fileName;
  String? created_at;
  gpThreads(
      {this.id,
      this.groupthreadmsg,
      this.name,
      this.created_at,
      this.fileUrls,
      this.sendUserId,
      this.profileName,
      this.fileName});
  gpThreads.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    sendUserId = json['send_user_id'];
    fileUrls = json['file_url'] as List<dynamic>;
    fileName = json['file_name'] as List<dynamic>?;
    profileName = json['image_url'];
    groupthreadmsg = json['groupthreadmsg'];
    created_at = json['created_at'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['created_at'] = this.created_at;
    data['groupthreadmsg'] = this.groupthreadmsg;
    data['name'] = this.name;
    data['id'] = this.id;
    data['image_url'] = this.profileName;
    data['file_name'] = this.fileName;
    data['file_url'] = this.fileUrls;
    data['send_user_id'] = this.sendUserId;
    return data;
  }
}

class mChannelUser {
  String? name;
  String? email;
  bool? activeStatus;

  mChannelUser({this.email, this.name, this.activeStatus});
  mChannelUser.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    activeStatus = json['active_status'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['active_status'] = this.activeStatus;
    return data;
  }
}

class EmojiCountsforGpThread {
  int? groupThreadId;
  String? emoji;
  int? emojiCount;

  EmojiCountsforGpThread({this.groupThreadId, this.emoji, this.emojiCount});

  EmojiCountsforGpThread.fromJson(Map<String, dynamic> json) {
    groupThreadId = json['groupthreadid'];
    emoji = json['emoji'];
    emojiCount = json['emoji_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['groupthreadid'] = groupThreadId;
    data['emoji'] = emoji;
    data['emoji_count'] = emojiCount;
    return data;
  }
}

class ReactUserDataForGpThread {
  String? name;
  int? groupThreadId;
  String? emoji;
  int? userId;

  ReactUserDataForGpThread(
      {this.name, this.groupThreadId, this.emoji, this.userId});

  ReactUserDataForGpThread.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    groupThreadId = json['groupthreadid'];
    emoji = json['emoji'];
    userId = json['userid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['groupthreadid'] = groupThreadId;
    data['emoji'] = emoji;
    data['userid'] = userId;
    return data;
  }
}
