import 'package:flutter/material.dart';
import 'package:flutter_frontend/const/file_upload/download_file_web.dart';

class BuildFilecontainer {
  static Widget buildFileContainer(String fileUrl, bool isExcel, bool isTxt,
      String? fileName, bool isPdf, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isExcel
                  ? Container(
                      padding: const EdgeInsets.all(5),
                      alignment: Alignment.center,
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.green),
                      child: const Text(
                        "E",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    )
                  : isTxt
                      ? Container(
                          padding: const EdgeInsets.all(5),
                          alignment: Alignment.center,
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.blue),
                          child: const Text(
                            "T",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        )
                      : isPdf
                          ? Container(
                              padding: const EdgeInsets.all(5),
                              alignment: Alignment.center,
                              height: 20,
                              width: 20,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.red),
                              child: const Text(
                                "P",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            )
                          : const Icon(Icons.description),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName ?? '',
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Download to get file",
                      style: TextStyle(fontSize: 10),
                    )
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.download,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () async {
                  await DownloadFile.downloadFile(
                      fileUrl, context, fileName ?? '');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
