class DirectMessages {
  MUser? mUser;
  MUser? sUser;
  List<TDirectMessages>? tDirectMessages;
  List<TempDirectStarMsgids>? tempDirectStarMsgids;
  List<int>? tDirectStarMsgids;
  List<TDirectMsgEmojiCounts>? tDirectMsgEmojiCounts;
  List<ReactUserDataForDirectMsg>? reactUsernames;

  DirectMessages(
      {this.mUser,
      this.sUser,
      this.tDirectMessages,
      this.tempDirectStarMsgids,
      this.tDirectStarMsgids,
      this.tDirectMsgEmojiCounts,
      this.reactUsernames});
  DirectMessages.fromJson(Map<String, dynamic> json) {
    mUser = json['m_user'] != null ? MUser.fromJson(json['m_user']) : null;
    sUser = json['s_user'] != null ? MUser.fromJson(json['s_user']) : null;
    if (json['t_direct_messages'] != null) {
      tDirectMessages = <TDirectMessages>[];
      json['t_direct_messages'].forEach((v) {
        tDirectMessages!.add(TDirectMessages.fromJson(v));
      });
    }
    if (json['temp_direct_star_msgids'] != null) {
      tempDirectStarMsgids = <TempDirectStarMsgids>[];
      json['temp_direct_star_msgids'].forEach((v) {
        tempDirectStarMsgids!.add(TempDirectStarMsgids.fromJson(v));
      });
    }
    // Initialize tDirectStarMsgids to an empty list if it is null
    tDirectStarMsgids = json['t_direct_star_msgids'] != null
        ? List<int>.from(json['t_direct_star_msgids'])
        : [];
    if (json['t_direct_msg_emojiscounts'] != null) {
      tDirectMsgEmojiCounts = <TDirectMsgEmojiCounts>[];
      json['t_direct_msg_emojiscounts'].forEach((v) {
        tDirectMsgEmojiCounts!.add(TDirectMsgEmojiCounts.fromJson(v));
      });
    } else {
      tDirectMsgEmojiCounts = <TDirectMsgEmojiCounts>[];
    }
    if (json['react_usernames'] != null) {
      reactUsernames = <ReactUserDataForDirectMsg>[];
      json['react_usernames'].forEach((v) {
        reactUsernames!.add(ReactUserDataForDirectMsg.fromJson(v));
      });
    } else {
      reactUsernames = <ReactUserDataForDirectMsg>[];
    }
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (mUser != null) {
      data['m_user'] = mUser!.toJson();
    }
    if (sUser != null) {
      data['s_user'] = sUser!.toJson();
    }
    if (tDirectMessages != null) {
      data['t_direct_messages'] =
          tDirectMessages!.map((v) => v.toJson()).toList();
    }
    if (tempDirectStarMsgids != null) {
      data['temp_direct_star_msgids'] =
          tempDirectStarMsgids!.map((v) => v.toJson()).toList();
    }
    data['t_direct_star_msgids'] = tDirectStarMsgids;

    if (tDirectMsgEmojiCounts != null) {
      data['t_direct_msg_emojiscounts'] =
          tDirectMsgEmojiCounts!.map((v) => v.toJson()).toList();
    } else {
      data['t_direct_msg_emojiscounts'] = <Map<String, dynamic>>[];
    }

    if (reactUsernames != null) {
      data['t_direct_msg_emoji_userNames'] =
          reactUsernames!.map((v) => v.toJson()).toList();
    } else {
      data['t_direct_msg_emoji_userNames'] = <Map<String, dynamic>>[];
    }
    return data;
  }
}

class MUser {
  int? id;
  String? name;
  String? email;
  String? passwordDigest;
  String? profileImage;
  String? rememberDigest;
  bool? activeStatus;
  bool? admin;
  bool? memberStatus;
  String? createdAt;
  String? updatedAt;
  MUser(
      {this.id,
      this.name,
      this.email,
      this.passwordDigest,
      this.profileImage,
      this.rememberDigest,
      this.activeStatus,
      this.admin,
      this.memberStatus,
      this.createdAt,
      this.updatedAt});
  MUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    passwordDigest = json['password_digest'];
    profileImage = json['profile_image'];
    rememberDigest = json['remember_digest'];
    activeStatus = json['active_status'];
    admin = json['admin'];
    memberStatus = json['member_status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['email'] = this.email;
    data['password_digest'] = this.passwordDigest;
    data['profile_image'] = this.profileImage;
    data['remember_digest'] = this.rememberDigest;
    data['active_status'] = this.activeStatus;
    data['admin'] = this.admin;
    data['member_status'] = this.memberStatus;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class TDirectMessages {
  String? name;
  String? directmsg;
  List<dynamic>? fileUrls;
  int? id;
  String? createdAt;
  int? count;
  TDirectMessages(
      {this.name,
      this.directmsg,
      this.id,
      this.createdAt,
      this.count,
      this.fileUrls});
  TDirectMessages.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    directmsg = json['directmsg'];
    fileUrls = json['file_urls'] as List<dynamic>?;
    id = json['id'];
    createdAt = json['created_at'];
    count = json['count'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['directmsg'] = this.directmsg;
    data['file_urls'] = this.fileUrls;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    data['count'] = this.count;
    return data;
  }
}

class TempDirectStarMsgids {
  int? directmsgid;
  int? id;
  TempDirectStarMsgids({this.directmsgid, this.id});
  TempDirectStarMsgids.fromJson(Map<String, dynamic> json) {
    directmsgid = json['directmsgid'];
    id = json['id'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['directmsgid'] = this.directmsgid;
    data['id'] = this.id;
    return data;
  }
}

class TDirectMessageDates {
  String? createdDate;
  int? id;
  TDirectMessageDates({this.createdDate, this.id});
  TDirectMessageDates.fromJson(Map<String, dynamic> json) {
    createdDate = json['created_date'];
    id = json['id'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['created_date'] = this.createdDate;
    data['id'] = this.id;
    return data;
  }
}

class TDirectMsgEmojiCounts {
  int? directmsgid;
  String? emoji;
  int? emojiCount;

  TDirectMsgEmojiCounts({this.directmsgid, this.emoji, this.emojiCount});

  TDirectMsgEmojiCounts.fromJson(Map<String, dynamic> json) {
    directmsgid = json['directmsgid'];
    emoji = json['emoji'];
    emojiCount = json['emoji_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['directmsgid'] = directmsgid;
    data['emoji'] = emoji;
    data['emoji_count'] = emojiCount;
    return data;
  }
}

class ReactUserDataForDirectMsg {
  String? name;
  int? directmsgid;
  String? emoji;
  int? userId;

  ReactUserDataForDirectMsg({this.directmsgid, this.emoji, this.name, this.userId});

  ReactUserDataForDirectMsg.fromJson(Map<String, dynamic> json) {
    userId = json['userid'];
    directmsgid = json['directmsgid'];
    emoji = json['emoji'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userid'] = userId;
    data['directmsgid'] = directmsgid;
    data['emoji'] = emoji;
    data['name'] = name;
    return data;
  }
}
