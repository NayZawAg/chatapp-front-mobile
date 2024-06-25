import 'package:flutter_frontend/model/Unread_model.dart';

class UnreadMsg {
  List<Un_DirectMsg>? unreadDirectMsg;
  List<Un_G_message>? unreadGpMsg;
  List<Un_Thread>? unreadThreads;
  List<Un_G_Thread>? unreadGpThreads;
  List<dynamic>? t_user_channel_ids;
  List<dynamic>? t_user_channel_thread_ids;
  UnreadMsg({this.unreadDirectMsg, this.unreadGpMsg, this.unreadThreads, this.unreadGpThreads, this.t_user_channel_ids, this.t_user_channel_thread_ids});
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
    return data;
  }
}
