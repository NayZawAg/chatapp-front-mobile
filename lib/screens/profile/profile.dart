import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/profileImage.dart';
import 'package:flutter_frontend/screens/Navigation/changePw.dart';
import 'package:flutter_frontend/screens/userEdit/user_edit.dart';
import 'package:flutter_frontend/services/userservice/profile_upload/profile_upload_api.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class Profile extends StatefulWidget {
  final String currentUserWorkspace;
  const Profile({super.key, required this.currentUserWorkspace});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late String currentUserName;
  late String currentUserEmail;
  String? currentUserProfileImage;
  bool isLoading = false;
  int? currentUserId = SessionStore.sessionData!.currentUser!.id;
  int? imageWidth;
  int? imageHeight;

  final ProfileUploadApi profileUploadApi = ProfileUploadApi();

  @override
  void initState() {
    super.initState();
    currentUserName = SessionStore.sessionData?.currentUser?.name ?? '';
    currentUserEmail = SessionStore.sessionData?.currentUser?.email ?? '';
    currentUserProfileImage =
        SessionStore.sessionData?.currentUser?.imageUrl ?? '';
    if (currentUserProfileImage != null && !kIsWeb) {
      currentUserProfileImage = MinioToIP.replaceMinioWithIP(
          currentUserProfileImage!, ipAddressForMinio);
    }
  }

  Future<void> _uploadProfileImage() async {
    if (!kIsWeb) {
      PermissionStatus status = await Permission.storage.status;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
      status = await Permission.storage.request();
      if (status.isDenied) return;
    }

    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      if (kIsWeb) {
        setState(() {
          isLoading = true;
        });
        ProfileImage profileImage =
            await profileUploadApi.uploadProfileImage(result.files.first);
        await Future.delayed(const Duration(seconds: 5));

        setState(() {
          currentUserProfileImage = profileImage.profileImage;

          if (kIsWeb) {
            SessionStore.sessionData?.currentUser?.imageUrl =
                profileImage.profileImage;
            currentUserProfileImage = profileImage.profileImage;
          } else {
            currentUserProfileImage = MinioToIP.replaceMinioWithIP(
                currentUserProfileImage!, ipAddressForMinio);
            SessionStore.sessionData?.currentUser?.imageUrl =
                currentUserProfileImage;
          }
          isLoading = false;
        });
      } else {
        File? croppedFile = await _cropImage(result.files.first);
        if (croppedFile != null) {
          File secfile = File(croppedFile.path);
          final resizedBytes = await _resizeImageIfNeeded(secfile);

          if (resizedBytes != null) {
            // Write the resized bytes to a new file
            final tempDir = await getTemporaryDirectory();
            final resizedFile =
                File('${tempDir.path}/${result.files.first.name}');
            await resizedFile.writeAsBytes(resizedBytes);

            setState(() {
              isLoading = true;
            });
            PlatformFile file = PlatformFile(
              path: resizedFile.path,
              name: result.files.first.name,
              size: resizedFile.lengthSync(),
            );
            ProfileImage profileImage =
                await profileUploadApi.uploadProfileImage(file);
            await Future.delayed(const Duration(seconds: 5));

            setState(() {
              currentUserProfileImage = profileImage.profileImage;
              if (kIsWeb) {
                currentUserProfileImage = profileImage.profileImage;
              } else {
                currentUserProfileImage = MinioToIP.replaceMinioWithIP(
                    currentUserProfileImage!, ipAddressForMinio);
                SessionStore.sessionData?.currentUser?.imageUrl =
                    currentUserProfileImage;
              }
              isLoading = false;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                'The uploaded file likely exceeded the maximum width(500px) and height(500px) that this server supports.',
              ),
              backgroundColor: Color.fromARGB(255, 216, 40, 28),
              duration: Duration(seconds: 5),
            ));
          }
        }
      }
    }
  }

  Future<Uint8List?> _resizeImageIfNeeded(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image != null) {
      if (image.width > 500 || image.height > 500) {
        final aspectRatio = image.width / image.height;
        int newWidth;
        int newHeight;

        if (aspectRatio > 1) {
          newWidth = 500;
          newHeight = (500 / aspectRatio).round();
        } else {
          newHeight = 500;
          newWidth = (500 * aspectRatio).round();
        }

        final resizedImage =
            img.copyResize(image, width: newWidth, height: newHeight);
        return Uint8List.fromList(img.encodePng(resizedImage));
      } else {
        return Uint8List.fromList(bytes);
      }
    }
    return null;
  }

  Future<File?> _cropImage(PlatformFile file) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path!,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );
    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_ios_new)),
        title: const Text(
          "Profile",
        ),
        toolbarHeight: 50,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Card(
                  color: Colors.grey[300],
                  elevation: 5,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 30,
                      ),
                      Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: 80,
                            child: ClipOval(
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white)))
                                  : currentUserProfileImage == ""
                                      ? const Icon(
                                          Icons.person_outline_rounded,
                                          size: 50,
                                        )
                                      : Image.network(
                                          currentUserProfileImage!,
                                          fit: BoxFit.cover,
                                          width: 160,
                                          height: 160,
                                        ),
                            ),
                          ),
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade800,
                                ),
                                child: InkWell(
                                  onTap: _uploadProfileImage,
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  ),
                                ),
                              ))
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        currentUserName,
                        style: const TextStyle(fontSize: 25),
                      ),
                      Text(
                        "Active Now",
                        style: TextStyle(color: Colors.green[900]),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      ListTile(
                        leading: const Icon(Icons.verified_user),
                        title: const Text("Username",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w100)),
                        titleAlignment: ListTileTitleAlignment.center,
                        trailing: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(currentUserName,
                                  style: const TextStyle(fontSize: 17)),
                              GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => UserEdit(
                                                  username: currentUserName,
                                                  email: currentUserEmail,
                                                  workspaceName: widget
                                                      .currentUserWorkspace,
                                                )));
                                  },
                                  child: const Icon(Icons.edit))
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text("Email",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w100)),
                        titleAlignment: ListTileTitleAlignment.center,
                        trailing: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(currentUserEmail,
                                style: const TextStyle(fontSize: 17)),
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.workspace_premium),
                        title: const Text("Workspace",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w100)),
                        titleAlignment: ListTileTitleAlignment.center,
                        trailing: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(widget.currentUserWorkspace,
                                style: const TextStyle(fontSize: 17)),
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.key_off),
                        title: const Text("Change password",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w100)),
                        titleAlignment: ListTileTitleAlignment.center,
                        trailing: IconButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ChangePassword(
                                          email: currentUserEmail)));
                            },
                            icon: const Icon(Icons.arrow_forward_ios)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
