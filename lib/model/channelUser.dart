class channelUserModel{
  List<cUser>? c_User;
  channelUserModel({this.c_User});
  channelUserModel.fromJson(Map<String,dynamic> json){
    if(json['c_users'] != null){
      c_User = <cUser>[];
      json['c_users'].forEach((e){
        c_User!.add(new cUser.fromJson(e));
      });
    }
  }
  Map<String,dynamic> toJson(){
    final Map<String,dynamic> data = new Map<String,dynamic>();
    if(this.c_User != null){
      data['c_users'] = this.c_User!.map((e) => e.toJson()).toList();
    }
    return data;
  }
}


class cUser{
  String? name,email;
  bool? admin;
  cUser({this.admin,this.email,this.name});
  cUser.fromJson(Map<String,dynamic> json){
    name = json['name'];
    email = json['email'];
    admin = json['created_admin'];

  }
  Map<String,dynamic> toJson(){
    final Map<String,dynamic> data = new Map<String,dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['created_admin'] = this.admin;
    return data;
  }
}