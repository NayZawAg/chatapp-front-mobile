import 'package:flutter_frontend/model/groupMessage.dart';
import 'package:flutter_frontend/model/group_thread_list.dart';

class MentionLists {
  List<GroupMessage>? groupMessage;
  List<GroupThread>? groupThread;
  List<int>? groupStar;
  List<int>? groupThreadStar;

  List<EmojiCountsforGpMsg>? tGroupEmojiCounts;
  List<dynamic>? tGroupReactMsgIds;
  List<ReactUserDataForGpMsg>? reactUsernamesForGroupMsg;

  List<EmojiCountsforGpThread>? tGroupThreadEmojiCounts;
  List<dynamic>? tGroupThreadReactMsgIds;
  List<ReactUserDataForGpThread>? reactUsernamesForGroupThreadMsg;

  MentionLists(
      {this.groupMessage,
      this.groupThread,
      this.groupStar,
      this.groupThreadStar,
      this.tGroupEmojiCounts,
      this.tGroupReactMsgIds,
      this.reactUsernamesForGroupMsg,
      this.tGroupThreadEmojiCounts,
      this.tGroupThreadReactMsgIds,
      this.reactUsernamesForGroupThreadMsg});

  MentionLists.fromJson(Map<String, dynamic> json) {
    if (json['t_group_messages'] != null) {
      groupMessage = <GroupMessage>[];
      json['t_group_messages'].forEach((e) {
        groupMessage!.add(new GroupMessage.fromJson(e));
      });
    }
    if (json['t_group_threads'] != null) {
      groupThread = <GroupThread>[];
      json['t_group_threads'].forEach((e) {
        groupThread!.add(new GroupThread.fromJson(e));
      });
    }
    groupStar = json['t_group_star_msgids'].cast<int>();
    groupThreadStar = json['t_group_star_thread_msgids'].cast<int>();

    if (json["group_emoji_counts"] != null) {
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

    if (json["group_thread_emoji_counts"] != null) {
      tGroupThreadEmojiCounts = <EmojiCountsforGpThread>[];
      json["group_thread_emoji_counts"].forEach((v) {
        tGroupThreadEmojiCounts!.add(new EmojiCountsforGpThread.fromJson(v));
      });
    }
    if (json["group_thread_react_usernames"] != null) {
      reactUsernamesForGroupThreadMsg = <ReactUserDataForGpThread>[];
      json["group_thread_react_usernames"].forEach((v) {
        reactUsernamesForGroupThreadMsg!
            .add(new ReactUserDataForGpThread.fromJson(v));
      });
    }
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.groupMessage != null) {
      data['t_group_messages'] =
          this.groupMessage!.map((e) => e.toJson()).toList();
    }
    if (this.groupThread != null) {
      data['t_group_threads'] =
          this.groupThread!.map((e) => e.toJson()).toList();
    }
    data['t_group_star_msgids'] = this.groupStar;
    data['t_group_star_thread_msgids'] = this.groupThreadStar;

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
      data["group_thread_emoji_counts"] =
          tGroupThreadEmojiCounts!.map((v) => v.toJson()).toList();
    } else {
      data["group_thread_emoji_counts"] = <Map<String, dynamic>>[];
    }
    if (reactUsernamesForGroupThreadMsg != null) {
      data["group_thread_react_usernames"] =
          reactUsernamesForGroupThreadMsg!.map((v) => v.toJson()).toList();
    } else {
      data["group_thread_react_usernames"] = <Map<String, dynamic>>[];
    }
    return data;
  }
}

class GroupMessage {
  int? id;
  String? groupmsg;
  DateTime? createdAt;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;
  String? name;
  String? channelName;

  GroupMessage(
      {this.id,
      this.groupmsg,
      this.createdAt,
      this.name,
      this.channelName,
      this.files,
      this.fileNames,
      this.profileImage});

  GroupMessage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupmsg = json['groupmsg'];
    createdAt = DateTime.parse(json['created_at']);
    name = json['name'];
    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];
    channelName = json['channel_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['groupmsg'] = this.groupmsg;
    data['created_at'] = createdAt;
    data['name'] = this.name;
    data['channel_name'] = this.channelName;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}

class GroupThread {
  int? id;
  String? groupthreadmsg;
  DateTime? createdAt;
  List<dynamic>? files;
  List<dynamic>? fileNames;
  String? profileImage;
  String? name;
  String? channelName;

  GroupThread(
      {this.id,
      this.groupthreadmsg,
      this.createdAt,
      this.name,
      this.channelName,
      this.files,
      this.fileNames,
      this.profileImage});

  GroupThread.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupthreadmsg = json['groupthreadmsg'];
    createdAt = DateTime.parse(json['created_at']);
    name = json['name'];

    files = json['file_urls'] as List<dynamic>?;
    fileNames = json['file_names'] as List<dynamic>?;
    profileImage = json['profile_image'];

    channelName = json['channel_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['groupthreadmsg'] = this.groupthreadmsg;
    data['created_at'] = createdAt;
    data['name'] = this.name;
    data['channel_name'] = this.channelName;
    data['file_urls'] = this.files;
    data['profile_image'] = this.profileImage;
    data['file_names'] = this.fileNames;
    return data;
  }
}
