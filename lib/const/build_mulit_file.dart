import 'package:flutter/material.dart';
import 'package:flutter_frontend/const/build_fileContainer.dart';
import 'package:flutter_frontend/const/file_upload/download_file_web.dart';
import 'package:flutter_frontend/dotenv.dart';

class BuildMulitFile {
  Widget buildMultipleFiles(List<dynamic> files, TargetPlatform? platform,
      BuildContext context, List<dynamic>? fileName) {
    String replaceMinioWithIP(String url) {
      return url.replaceAll(
          "http://minio:9000", "http://$ipAddressForMinio:9000");
    }

    List<dynamic> images = files.where((file) => _isImage(file!)).toList();
    List<dynamic> others = files.where((file) => !_isImage(file!)).toList();

    return Column(
      children: [
        const SizedBox(
          height: 8,
        ),
        if (images.isNotEmpty)
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                String modifiedUrl;

                if (platform == TargetPlatform.android) {
                  modifiedUrl = replaceMinioWithIP(images[index]!);
                } else {
                  modifiedUrl = images[index]!;
                  print("====================");
                  print("TF ${files!.length}");
                  print("tt ${fileName!.length}");
                  print("==========================");
                }
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.9,
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.9,
                              ),
                              child: Stack(children: [
                                Image.network(modifiedUrl, fit: BoxFit.contain),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: Image.network(modifiedUrl, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () async {
                          try {
                            await DownloadFile.downloadFile(
                                modifiedUrl, context, fileName?[index]);
                          } catch (e) {
                            rethrow;
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
        const SizedBox(
          height: 8,
        ),
        if (others.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: others.length,
            itemBuilder: (context, index) {
              String? fileUrl = others[index];
              String modifiedUrl;
              String? filename = fileName![index];
              if (platform == TargetPlatform.android) {
                modifiedUrl = replaceMinioWithIP(fileUrl!);
              } else {
                modifiedUrl = fileUrl!;
              }
              final isExcel = _isExcel(modifiedUrl);
              final isTxt = _isTxt(modifiedUrl);
              final isPdf = _isPdf(modifiedUrl);
              return BuildFilecontainer.buildFileContainer(
                  modifiedUrl, isExcel, isTxt, filename, isPdf, context);
            },
          ),
      ],
    );
  }

  bool _isImage(String fileUrl) {
    return fileUrl.endsWith('.png') ||
        fileUrl.endsWith('.jpg') ||
        fileUrl.endsWith('.jpeg') ||
        fileUrl.endsWith('.gif') ||
        fileUrl.endsWith('.bmp');
  }

  bool _isExcel(String fileUrl) {
    return fileUrl.endsWith('.xlsx') || fileUrl.endsWith('.xls');
  }

  bool _isTxt(String fileUrl) {
    return fileUrl.endsWith('.txt');
  }

  bool _isPdf(String fileUrl) {
    return fileUrl.endsWith('.pdf');
  }
}
