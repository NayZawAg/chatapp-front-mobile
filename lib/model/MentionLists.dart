class MentionLists {
  List<GroupMessage>? groupMessage;
  List<GroupThread>? groupThread;
  List<int>? groupStar;
  List<int>? groupThreadStar;

  MentionLists(
      {this.groupMessage,
      this.groupThread,
      this.groupStar,
      this.groupThreadStar});

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
