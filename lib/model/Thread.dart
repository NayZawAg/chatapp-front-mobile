// import 'dart:js_util';
import 'package:flutter_frontend/model/direct_message.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:flutter_frontend/model/groupMessage.dart';
import 'package:flutter_frontend/model/group_thread_list.dart';
import 'package:flutter_frontend/model/thread_model.dart';

class Threads {
  List<DirectMsg>? directMsg;
  List<dThread>? d_thread;
  List<G_message>? groupMessage;
  List<G_thread>? groupThread;
  List<int>? groupThreadStar;
  List<int>? directMsgstar;

  List<TDirectMsgEmojiCounts>? tDirectMsgEmojiCounts;
  List<ReactUserDataForDirectMsg>? reactUsernames;
  List<EmojiCountsforDirectThread>? emojiCounts;
  List<ReactUserDataForDirectThread>? reactUserDatas;

  List<EmojiCountsforGpMsg>? tGroupEmojiCounts;
  List<dynamic>? tGroupReactMsgIds;
  List<ReactUserDataForGpMsg>? reactUsernamesForGroupMsg;

  List<EmojiCountsforGpThread>? tGroupThreadEmojiCounts;
  List<dynamic>? tGroupThreadReactMsgIds;
  List<ReactUserDataForGpThread>? reactUsernamesForGroupThreadMsg;
  Threads(
      {this.d_thread,
      this.directMsg,
      this.groupMessage,
      this.groupThread,
      this.groupThreadStar,
      this.tDirectMsgEmojiCounts,
      this.reactUsernames,
      this.emojiCounts,
      this.reactUserDatas,
      this.tGroupEmojiCounts,
      this.tGroupReactMsgIds,
      this.reactUsernamesForGroupMsg,
      this.tGroupThreadEmojiCounts,
      this.tGroupThreadReactMsgIds,
      this.reactUsernamesForGroupThreadMsg});
  Threads.fromJson(Map<String, dynamic> json) {
    if (json['t_direct_messages'] != null) {
      directMsg = <DirectMsg>[];
      json['t_direct_messages'].forEach((v) {
        directMsg!.add(new DirectMsg.fromJson(v));
      });
    }
    if (json['t_direct_threads'] != null) {
      d_thread = <dThread>[];
      json['t_direct_threads'].forEach((v) {
        d_thread!.add(new dThread.fromJson(v));
      });
    }
    if (json['t_group_messages'] != null) {
      groupMessage = <G_message>[];
      json['t_group_messages'].forEach((v) {
        groupMessage!.add(new G_message.fromJson(v));
      });
    }
    if (json['t_group_threads'] != null) {
      groupThread = <G_thread>[];
      json['t_group_threads'].forEach((e) {
        groupThread!.add(new G_thread.fromJson(e));
      });
    }
    groupThreadStar = json['t_group_star_thread_msgids'].cast<int>();
    directMsgstar = json['t_group_star_msgids'].cast<int>();
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
      emojiCounts = <EmojiCountsforDirectThread>[];
      json["t_direct_thread_emojiscounts"].forEach((v) {
        emojiCounts!.add(new EmojiCountsforDirectThread.fromJson(v));
      });
    }

    if (json["t_direct_thread_react_usernames"] != null) {
      reactUserDatas = <ReactUserDataForDirectThread>[];
      json["t_direct_thread_react_usernames"].forEach((v) {
        reactUserDatas!.add(new ReactUserDataForDirectThread.fromJson(v));
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
    if (this.directMsg != null) {
      data['t_direct_messages'] =
          this.directMsg!.map((e) => e.toJson()).toList();
    }
    if (this.d_thread != null) {
      data['t_direct_threads'] = this.d_thread!.map((e) => e.toJson()).toList();
    }
    if (this.groupMessage != null) {
      data['t_group_messages'] =
          this.groupMessage!.map((e) => e.toJson()).toList();
    }
    if (this.groupThread != null) {
      data['t_group_threads'] =
          this.groupThread!.map((e) => e.toJson()).toList();
    }
    data['t_group_star_thread_msgids'] = this.groupThreadStar;
    data['t_group_star_msgids'] = this.directMsgstar;

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
    if (emojiCounts != null) {
      data['emoji_counts'] = emojiCounts!.map((e) => e.toJson()).toList();
    }
    if (reactUserDatas != null) {
      data['t_direct_thread_react_usernames'] =
          reactUserDatas!.map((e) => e.toJson()).toList();
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
