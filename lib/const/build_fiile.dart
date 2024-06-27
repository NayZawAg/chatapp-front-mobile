import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileDisplayWidget extends StatefulWidget {
  final List<PlatformFile> files;
  final TargetPlatform? platform;

  const FileDisplayWidget({
    Key? key,
    required this.files,
    required this.platform,
  }) : super(key: key);

  @override
  _FileDisplayWidgetState createState() => _FileDisplayWidgetState();
}

class _FileDisplayWidgetState extends State<FileDisplayWidget> {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: true,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: calculateGridHeight(widget.files.length),
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(13),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 3,
              mainAxisExtent: 40,
            ),
            itemCount: widget.files.length,
            itemBuilder: (context, index) {
              final file = widget.files[index];
              return buildFile(file);
            },
          ),
        ),
      ),
    );
  }

  Widget buildFile(PlatformFile file) {
    final kb = file.size / 1024;
    final mb = kb / 1024;
    final filesize =
        mb >= 1 ? '${mb.toStringAsFixed(2)} MB' : '${kb.toStringAsFixed(2)} KB';
    final extension = file.extension?.toLowerCase() ?? 'none';
    final isImage = ['png', 'jpg', 'jpeg', 'gif', 'bmp'].contains(extension);
    final isExcel = extension == 'xlsx' || extension == 'xls';
    final isTxt = extension == 'txt';
    final isPdf = extension == 'pdf';

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isImage && !kIsWeb)
                Image.file(
                  File(file.path!),
                  fit: BoxFit.cover,
                )
              else if (isImage)
                Image.memory(file.bytes!)
              else if (isExcel || isTxt || isPdf)
                Container(
                  padding: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  height: 20,
                  width: 15,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isExcel
                        ? Colors.green
                        : isTxt
                            ? Colors.blue
                            : Colors.red,
                  ),
                  child: Text(
                    isExcel
                        ? 'E'
                        : isTxt
                            ? 'T'
                            : 'P',
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                )
              else
                const Icon(Icons.description),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      filesize,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                widget.files.remove(file);
              });
            },
            child: const Icon(
              Icons.close,
              size: 13,
            ),
          ),
        ),
      ],
    );
  }

  double calculateGridHeight(int itemCount) {
    const double itemHeight = 40.0;
    const int itemsPerRow = 3;
    const double spacing = 15.0;
    int numRows = (itemCount / itemsPerRow).ceil();
    double totalHeight = (itemHeight + spacing) * numRows;
    return totalHeight;
  }
}
