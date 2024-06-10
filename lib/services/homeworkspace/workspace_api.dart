
import 'dart:convert';
import 'package:http/http.dart' as http;


 Future<Map<String, dynamic>> getUser(int id) async {
  
  final url = 'https://cmmteam3-backend-api.onrender.com/m_users';
  final response = await http.get(Uri.parse('$url/$id'));
  if (response.statusCode == 200) {
    Map<String, dynamic> data = jsonDecode(response.body);
    String name = data['name'];
    String remember_digest = data['remember_digest'];
    return {'name':name , 'remember_digest':remember_digest};
    
  } else {
  throw Exception('Failed to load data');
  }
}

Future<Map<String, dynamic>> getChannel(int id) async {
  final url = 'https://cmmteam3-backend-deploy-1.onrender.com/m_channels';
  final response = await http.get(Uri.parse('$url/$id'));
  if (response.statusCode == 200) {
    Map<String, dynamic> data = jsonDecode(response.body);
    String name = data['channel_name'];
    
    return {'channel_name':name};
    
  } else {
  throw Exception('Failed to load data');
  }
}
