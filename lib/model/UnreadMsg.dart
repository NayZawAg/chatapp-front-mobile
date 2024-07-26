import 'package:dio/dio.dart';
import 'package:flutter_frontend/model/Unread_model.dart';
import 'package:flutter_frontend/model/direct_message.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:flutter_frontend/model/groupMessage.dart';
import 'package:flutter_frontend/model/group_thread_list.dart';

class UnreadMsg {
  List<Un_DirectMsg>? unreadDirectMsg;
  List<Un_G_message>? unreadGpMsg;
  List<Un_Thread>? unreadThreads;
  List<Un_G_Thread>? unreadGpThreads;
  List<dynamic>? t_user_channel_ids;
  List<dynamic>? t_user_channel_thread_ids;
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
  UnreadMsg(
      {this.unreadDirectMsg,
      this.unreadGpMsg,
      this.unreadThreads,
      this.unreadGpThreads,
      this.t_user_channel_ids,
      this.t_user_channel_thread_ids,
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
  UnreadMsg.fromJson(Map<String, dynamic> json) {
    if (json['t_direct_messages'] != null) {
      unreadDirectMsg = <Un_DirectMsg>[];
      json['t_direct_messages'].forEach((v) {
        unreadDirectMsg!.add(new Un_DirectMsg.fromJson(v));
      });
    }
    if (json['t_direct_threads'] != null) {
      unreadThreads = <Un_Thread>[];
      json['t_direct_threads'].forEach((v) {
        unreadThreads!.add(new Un_Thread.fromJson(v));
      });
    }
    if (json['t_group_messages'] != null) {
      unreadGpMsg = <Un_G_message>[];
      json['t_group_messages'].forEach((v) {
        unreadGpMsg!.add(new Un_G_message.fromJson(v));
      });
    }
    if (json['t_group_threads'] != null) {
      unreadGpThreads = <Un_G_Thread>[];
      json['t_group_threads'].forEach((v) {
        unreadGpThreads!.add(new Un_G_Thread.fromJson(v));
      });
    }
    t_user_channel_ids = json['t_user_channelids'];
    t_user_channel_thread_ids = json['t_user_channelthreadids'];

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

    if (json["threads_react_usernames"] != null) {
      reactUsernamesForDirectThread = <ReactUserDataForDirectThread>[];
      json["threads_react_usernames"].forEach((v) {
        reactUsernamesForDirectThread!
            .add(new ReactUserDataForDirectThread.fromJson(v));
      });
    }
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
    if (json["group_threads_emoji_counts"] != null) {
      tGroupThreadEmojiCounts = <EmojiCountsforGpThread>[];
      json["group_threads_emoji_counts"].forEach((v) {
        tGroupThreadEmojiCounts!.add(new EmojiCountsforGpThread.fromJson(v));
      });
    }
    if (json["group_threads_react_usernames"] != null) {
      reactUsernamesForGroupThreadMsg = <ReactUserDataForGpThread>[];
      json["group_threads_react_usernames"].forEach((v) {
        reactUsernamesForGroupThreadMsg!
            .add(new ReactUserDataForGpThread.fromJson(v));
      });
    }
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.unreadDirectMsg != null) {
      data['t_direct_messages'] =
          this.unreadDirectMsg!.map((e) => e.toJson()).toList();
    }
    if (this.unreadThreads != null) {
      data['t_direct_threads'] =
          this.unreadThreads!.map((e) => e.toJson()).toList();
    }
    if (this.unreadGpMsg != null) {
      data['t_group_messages'] =
          this.unreadGpMsg!.map((e) => e.toJson()).toList();
    }
    if (this.unreadGpThreads != null) {
      data['t_group_threads'] =
          this.unreadGpThreads!.map((e) => e.toJson()).toList();
    }
    data['t_user_channelids'] = this.t_user_channel_ids;
    data['t_user_channelthreadids'] = this.t_user_channel_thread_ids;

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
      data["threads_react_usernames"] =
          reactUsernamesForDirectThread!.map((v) => v.toJson()).toList();
    } else {
      data["threads_react_usernames"] = <Map<String, dynamic>>[];
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
      data["group_threads_emoji_counts"] =
          tGroupThreadEmojiCounts!.map((v) => v.toJson()).toList();
    } else {
      data["group_threads_emoji_counts"] = <Map<String, dynamic>>[];
    }
    if (reactUsernamesForGroupThreadMsg != null) {
      data["group_threads_react_usernames"] =
          reactUsernamesForGroupThreadMsg!.map((v) => v.toJson()).toList();
    } else {
      data["group_threads_react_usernames"] = <Map<String, dynamic>>[];
    }
    return data;
  }
}
