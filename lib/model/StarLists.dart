import 'package:flutter_frontend/model/direct_message.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:flutter_frontend/model/groupMessage.dart';
import 'package:flutter_frontend/model/group_thread_list.dart';

class StarLists {
  List<DirectStar>? directStar;
  List<DirectStarThread>? directStarThread;
  List<GroupStar>? groupStar;
  List<GroupStarThread>? groupStarThread;
  
  List<TDirectMsgEmojiCounts>? tDirectMsgEmojiCounts;
  List<dynamic>? tDirectReactMsgIds;
  List<ReactUserDataForDirectMsg>? reactUsernames;

  List<EmojiCountsforDirectThread>? tDirectThreadEmojiCounts;
  List<dynamic>? tDirectReactThreadMsgIds;
  List<ReactUserDataForDirectThread>? reactUsernamesForDirectThread;

  List<EmojiCountsforGpMsg>? tGroupEmojiCounts;
  List<dynamic>? tGroupReactMsgIds;
  List<ReactUserDataForGpMsg>? reactUsernamesForGroupMsg;

  List<EmojiCountsforGpThread>? tGroupThreadEmojiCounts;
  List<dynamic>? tGroupThreadReactMsgIds;
  List<ReactUserDataForGpThread>? reactUsernamesForGroupThreadMsg;

  StarLists(
      {this.directStar,
      this.directStarThread,
      this.groupStar,
      this.groupStarThread,
      this.tDirectMsgEmojiCounts,
      this.tDirectReactMsgIds,
      this.reactUsernames,
      this.tDirectThreadEmojiCounts,
      this.tDirectReactThreadMsgIds,
      this.reactUsernamesForDirectThread,
      this.tGroupEmojiCounts,
      this.tGroupReactMsgIds,
      this.reactUsernamesForGroupMsg,
      this.tGroupThreadEmojiCounts,
      this.tGroupThreadReactMsgIds,
      this.reactUsernamesForGroupThreadMsg});

  StarLists.fromJson(Map<String, dynamic> json) {
    if (json['direct_Star'] != null) {
      directStar = <DirectStar>[];
      json['direct_Star'].forEach((v) {
        directStar!.add(new DirectStar.fromJson(v));
      });
    }
    if (json['direct_star_thread'] != null) {
      directStarThread = <DirectStarThread>[];
      json['direct_star_thread'].forEach((v) {
        directStarThread!.add(new DirectStarThread.fromJson(v));
      });
    }
    if (json['group_star'] != null) {
      groupStar = <GroupStar>[];
      json['group_star'].forEach((v) {
        groupStar!.add(new GroupStar.fromJson(v));
      });
    }
    if (json['group_star_thread'] != null) {
      groupStarThread = <GroupStarThread>[];
      json['group_star_thread'].forEach((v) {
        groupStarThread!.add(new GroupStarThread.fromJson(v));
      });
    }
    tDirectReactMsgIds = json['t_direct_react_msgids'];
    tDirectReactThreadMsgIds = json["t_direct_react_thread_msgids"];
    tGroupReactMsgIds = json["t_group_react_msgids"];
    tGroupThreadReactMsgIds = json["t_group_react_thread_msgids"];

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
    if (json["t_direct_thread_emojiscounts"] != null) {
      tDirectThreadEmojiCounts = <EmojiCountsforDirectThread>[];
      json["t_direct_thread_emojiscounts"].forEach((v) {
        tDirectThreadEmojiCounts!
            .add(new EmojiCountsforDirectThread.fromJson(v));
      });
    }

    if (json["t_direct_thread_react_usernames"] != null) {
      reactUsernamesForDirectThread = <ReactUserDataForDirectThread>[];
      json["t_direct_thread_react_usernames"].forEach((v) {
        reactUsernamesForDirectThread!
            .add(new ReactUserDataForDirectThread.fromJson(v));
      });
    }    if (json["group_emoji_counts"] != null) {
      tGroupEmojiCounts = <EmojiCountsforGpMsg>[];
      json["group_emoji_counts"].forEach((v) {
        tGroupEmojiCounts!.add(new EmojiCountsforGpMsg.fromJson(v));
      });
    }
    if (json["group_react_usernames"] != null) {
      reactUsernamesForGroupMsg = <ReactUserDataForGpMsg>[];
      json["group_react_usernames"].forEach((v) {
        reactUsernamesForGroupMsg!.add(new ReactUserDataForGpMsg.fromJson(v));
      });
    }
    if (json["t_group_thread_emoji_counts"] != null) {
      tGroupThreadEmojiCounts = <EmojiCountsforGpThread>[];
      json["t_group_thread_emoji_counts"].forEach((v) {
        tGroupThreadEmojiCounts!.add(new EmojiCountsforGpThread.fromJson(v));
      });
    }
    if (json["t_group_thread_react_usernames"] != null) {
      reactUsernamesForGroupThreadMsg = <ReactUserDataForGpThread>[];
      json["t_group_thread_react_usernames"].forEach((v) {
        reactUsernamesForGroupThreadMsg!
            .add(new ReactUserDataForGpThread.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.directStar != null) {
      data['direct_Star'] = this.directStar!.map((v) => v.toJson()).toList();
    }
    if (this.directStarThread != null) {
      data['direct_star_thread'] =
          this.directStarThread!.map((v) => v.toJson()).toList();
    }
    if (this.groupStar != null) {
      data['group_star'] = this.groupStar!.map((v) => v.toJson()).toList();
    }
    if (this.groupStarThread != null) {
      data['group_star_thread'] =
          this.groupStarThread!.map((v) => v.toJson()).toList();
    }
    data['t_direct_react_msgids'] = this.tDirectReactMsgIds;
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
    data["t_direct_react_thread_msgids"] = this.tDirectReactThreadMsgIds;
    if (tDirectThreadEmojiCounts != null) {
      data["t_direct_thread_emojiscounts"] =
          tDirectThreadEmojiCounts!.map((v) => v.toJson()).toList();
    } else {
      data["t_direct_thread_emojiscounts"] = <Map<String, dynamic>>[];
    }
    if (reactUsernamesForDirectThread != null) {
      data["t_direct_thread_react_usernames"] =
          reactUsernamesForDirectThread!.map((v) => v.toJson()).toList();
    } else {
      data["t_direct_thread_react_usernames"] = <Map<String, dynamic>>[];
    }

    data["t_group_react_msgids"] = this.tGroupEmojiCounts;
    if (tGroupEmojiCounts != null) {
      data["group_emoji_counts"] =
          tGroupEmojiCounts!.map((v) => v.toJson()).toList();
    } else {
      data["group_emoji_counts"] = <Map<String, dynamic>>[];
    }
    if (reactUsernamesForGroupMsg != null) {
      data["group_react_usernames"] =
          reactUsernamesForGroupMsg!.map((v) => v.toJson()).toList();
    } else {
      data["group_react_usernames"] = <Map<String, dynamic>>[];
    }
    data["t_group_react_thread_msgids"] = this.tGroupThreadReactMsgIds;

    if (tGroupThreadEmojiCounts != null) {
      data["t_group_thread_emoji_counts"] =
          tGroupThreadEmojiCounts!.map((v) => v.toJson()).toList();
    } else {
      data["t_group_thread_emoji_counts"] = <Map<String, dynamic>>[];
    }
    if (reactUsernamesForGroupThreadMsg != null) {
      data["t_group_thread_react_usernames"] =
          reactUsernamesForGroupThreadMsg!.map((v) => v.toJson()).toList();
    } else {
      data["t_group_thread_react_usernames"] = <Map<String, dynamic>>[];
    }
    return data;
  }
}

class DirectStar {
  int? id;
  String? directmsg;
  DateTime? createdAt;
  String? name;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;

  DirectStar(
      {this.id,
      this.directmsg,
      this.createdAt,
      this.name,
      this.files,
      this.fileNames,
      this.profileImage});

  DirectStar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    directmsg = json['directmsg'];
    createdAt = DateTime.parse(json['created_at']);
    name = json['name'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['directmsg'] = this.directmsg;
    data['created_at'] = this.createdAt;
    data['name'] = this.name;

    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}

class DirectStarThread {
  int? id;
  String? directthreadmsg;
  DateTime? createdAt;
  String? name;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;

  DirectStarThread(
      {this.id,
      this.directthreadmsg,
      this.files,
      this.fileNames,
      this.profileImage,
      this.createdAt,
      this.name});

  DirectStarThread.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    directthreadmsg = json['directthreadmsg'];
    createdAt = DateTime.parse(json['created_at']);
    name = json['name'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['directthreadmsg'] = this.directthreadmsg;
    data['created_at'] = this.createdAt;
    data['name'] = this.name;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}

class GroupStar {
  int? id;
  String? groupmsg;
  DateTime? createdAt;
  String? name;
  String? channelName;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;

  GroupStar(
      {this.id, this.groupmsg, this.createdAt, this.name, this.channelName});

  GroupStar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupmsg = json['groupmsg'];
    createdAt = DateTime.parse(json['created_at']);
    name = json['name'];
    channelName = json['channel_name'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['groupmsg'] = this.groupmsg;
    data['created_at'] = this.createdAt;
    data['name'] = this.name;
    data['channel_name'] = this.channelName;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}

class GroupStarThread {
  int? id;
  String? groupthreadmsg;
  DateTime? createdAt;
  String? name;
  String? channelName;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;

  GroupStarThread(
      {this.id,
      this.groupthreadmsg,
      this.createdAt,
      this.name,
      this.channelName,
      this.files,
      this.fileNames,
      this.profileImage});

  GroupStarThread.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupthreadmsg = json['groupthreadmsg'];
    createdAt = DateTime.parse(json['created_at']);
    name = json['name'];
    channelName = json['channel_name'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['groupthreadmsg'] = this.groupthreadmsg;
    data['created_at'] = this.createdAt;
    data['name'] = this.name;
    data['channel_name'] = this.channelName;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}
