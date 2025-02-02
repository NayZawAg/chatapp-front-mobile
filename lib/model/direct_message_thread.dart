class DirectMessageThread {
  TDirectMessage? tDirectMessage;
  List<TDirectThreads>? tDirectThreads;
  List<int>? tDirectStarThreadMsgids;
  String? senderName;
  List<EmojiCountsforDirectThread>? emojiCounts;
  List<ReactUserDataForDirectThread>? reactUserDatas;
  List<ReactUserDataForDirectMessage>? directReactUserDatas;
  List<EmojiCountsforDirectMessage>? directEmojiCounts;
  DirectMessageThread(
      {this.tDirectMessage,
      this.tDirectThreads,
      this.tDirectStarThreadMsgids,
      this.emojiCounts,
      this.reactUserDatas});

  DirectMessageThread.fromJson(Map<String, dynamic> json) {
    tDirectMessage = json['t_direct_message'] != null
        ? new TDirectMessage.fromJson(json['t_direct_message'])
        : null;
    if (json['t_direct_threads'] != null) {
      tDirectThreads = <TDirectThreads>[];
      json['t_direct_threads'].forEach((v) {
        tDirectThreads!.add(new TDirectThreads.fromJson(v));
      });
    }
    tDirectStarThreadMsgids = json['t_direct_star_thread_msgids'].cast<int>();

    senderName = json['sender_name'];

    if (json["t_direct_thread_emojiscounts"] != null) {
      emojiCounts = <EmojiCountsforDirectThread>[];
      json["t_direct_thread_emojiscounts"].forEach((v) {
        emojiCounts!.add(new EmojiCountsforDirectThread.fromJson(v));
      });
    }

    if (json["react_usernames"] != null) {
      reactUserDatas = <ReactUserDataForDirectThread>[];
      json["react_usernames"].forEach((v) {
        reactUserDatas!.add(new ReactUserDataForDirectThread.fromJson(v));
      });
    }

    if (json["t_direct_msg_emojiscounts"] != null) {
      directEmojiCounts = <EmojiCountsforDirectMessage>[];
      json["t_direct_msg_emojiscounts"].forEach((v) {
        directEmojiCounts!.add(new EmojiCountsforDirectMessage.fromJson(v));
      });
    }

    if (json["direct_react_usernames"] != null) {
      directReactUserDatas = <ReactUserDataForDirectMessage>[];
      json["direct_react_usernames"].forEach((v) {
        directReactUserDatas!
            .add(new ReactUserDataForDirectMessage.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.tDirectMessage != null) {
      data['t_direct_message'] = this.tDirectMessage!.toJson();
    }
    if (this.tDirectThreads != null) {
      data['t_direct_threads'] =
          this.tDirectThreads!.map((v) => v.toJson()).toList();
    }
    if (this.tDirectStarThreadMsgids != null) {
      data['t_direct_star_thread_msgids'] = this.tDirectStarThreadMsgids;
      return data;
    }
    data['sender_name'] = this.senderName;

    if (emojiCounts != null) {
      data['emoji_counts'] = emojiCounts!.map((e) => e.toJson()).toList();
    }
    if (reactUserDatas != null) {
      data['react_usernames'] = reactUserDatas!.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class TDirectMessage {
  int? id;
  String? directmsg;
  bool? readStatus;
  int? sendUserId;
  int? receiveUserId;
  String? createdAt;
  String? updatedAt;

  TDirectMessage(
      {this.id,
      this.directmsg,
      this.readStatus,
      this.sendUserId,
      this.receiveUserId,
      this.createdAt,
      this.updatedAt});

  TDirectMessage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    directmsg = json['directmsg'];
    readStatus = json['read_status'];
    sendUserId = json['send_user_id'];
    receiveUserId = json['receive_user_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['directmsg'] = this.directmsg;
    data['read_status'] = this.readStatus;
    data['send_user_id'] = this.sendUserId;
    data['receive_user_id'] = this.receiveUserId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class TDirectThreads {
  String? name;
  String? directthreadmsg;
  List<dynamic>? fileUrls;
  List<dynamic>? fileName;
  String? profileName;
  int? id;
  String? createdAt;

  TDirectThreads(
      {this.name,
      this.directthreadmsg,
      this.id,
      this.createdAt,
      this.fileUrls,
      this.fileName,
      this.profileName});

  TDirectThreads.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    directthreadmsg = json['directthreadmsg'];
    fileUrls = json['file_urls'] as List<dynamic>?;
    fileName = json['file_names'] as List<dynamic>?;
    profileName = json['image_url'];
    id = json['id'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['directthreadmsg'] = this.directthreadmsg;
    data['file_names'] = this.fileName;
    data['image_url'] = this.profileName;
    data['id'] = this.id;
    data['file_urls'] = this.fileUrls;
    data['created_at'] = this.createdAt;
    return data;
  }
}

class EmojiCountsforDirectThread {
  int? directThreadId;
  String? emoji;
  int? emojiCount;

  EmojiCountsforDirectThread(
      {this.directThreadId, this.emoji, this.emojiCount});

  EmojiCountsforDirectThread.fromJson(Map<String, dynamic> json) {
    directThreadId = json['directthreadid'];
    emoji = json['emoji'];
    emojiCount = json['emoji_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['directthreadid'] = directThreadId;
    data['emoji'] = emoji;
    data['emoji_count'] = emojiCount;
    return data;
  }
}

class ReactUserDataForDirectThread {
  String? name;
  int? directThreadId;
  String? emoji;
  int? userId;

  ReactUserDataForDirectThread(
      {this.name, this.directThreadId, this.emoji, this.userId});

  ReactUserDataForDirectThread.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    directThreadId = json['directthreadid'];
    emoji = json['emoji'];
    userId = json['userid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['directthreadid'] = directThreadId;
    data['emoji'] = emoji;
    data['userid'] = userId;
    return data;
  }
}

class EmojiCountsforDirectMessage {
  int? directmsgid;
  String? directemoji;
  int? directemojiCounts;

  EmojiCountsforDirectMessage(
      {this.directmsgid, this.directemoji, this.directemojiCounts});

  EmojiCountsforDirectMessage.fromJson(Map<String, dynamic> json) {
    directmsgid = json['directmsgid'];
    directemoji = json['emoji'];
    directemojiCounts = json['emoji_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['directmsgid'] = directmsgid;
    data['emoji'] = directemoji;
    data['emoji_count'] = directemojiCounts;
    return data;
  }
}

class ReactUserDataForDirectMessage {
  String? name;
  int? directMessageId;
  String? emoji;
  int? userId;

  ReactUserDataForDirectMessage(
      {this.name, this.directMessageId, this.emoji, this.userId});

  ReactUserDataForDirectMessage.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    directMessageId = json['directmsgid'];
    emoji = json['emoji'];
    userId = json['userid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['directmsgid'] = directMessageId;
    data['emoji'] = emoji;
    data['userid'] = userId;
    return data;
  }
}
