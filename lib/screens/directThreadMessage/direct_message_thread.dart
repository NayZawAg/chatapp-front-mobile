import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/build_fiile.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/services/directMessage/direct_message_api.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/directMessage/directMessageThread/direct_message_thread.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_html/flutter_html.dart' as flutter_html;
// ignore_for_file: public_member_api_docs, sort_constructors_first

class DirectMessageThreadWidget extends StatefulWidget {
  final int directMsgId;
  final String receiverName;
  final int receiverId;
  final userstatus;
  const DirectMessageThreadWidget(
      {Key? key,
      required this.directMsgId,
      required this.receiverName,
      required this.receiverId,
      this.userstatus})
      : super(key: key);

  @override
  State<DirectMessageThreadWidget> createState() => _DirectMessageThreadState();
}

class _DirectMessageThreadState extends State<DirectMessageThreadWidget> {
  final DirectMsgThreadService _apiService = DirectMsgThreadService(Dio(
      BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  final TextEditingController replyTextController = TextEditingController();
  final DirectMessageService _directMessageService = DirectMessageService();
  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
  late ScrollController _scrollController;

  int? selectedIndex;

  bool isLoading = false;
  List<TDirectThreads>? tDirectThreads = [];
  List<int>? tDirectStarThreadMsgIds = [];
  String senderName = "";
  String directMessage = "";
  String times = DateTime.now().toString();
  List<PlatformFile> files = [];
  bool hasFileToSEnd = false;
  late String localpath;
  late bool permissionReady;
  TargetPlatform? platform;
  WebSocketChannel? _channel;
  final PermissionClass permissions = PermissionClass();
  String? fileText;
  BuildMulitFile mulitFile = BuildMulitFile();
  BuildSingleFile singleFile = BuildSingleFile();

  bool isCursor = false;
  bool isSelectText = false;
  bool isfirstField = true;
  bool isClickedTextFormat = false;
  String htmlContent = "";
  final quill.QuillController _quilcontroller = quill.QuillController.basic();
  final FocusNode _focusNode = FocusNode();

  bool isBlockquote = false;
  bool isOrderList = false;
  bool isBold = false;
  bool isItalic = false;
  bool isStrike = false;
  bool isLink = false;
  bool isUnorderList = false;
  bool isCode = false;
  bool isCodeblock = false;
  bool playBool = false;
  bool isEnter = false;
  List<String> check = [];
  List _previousOps = [];
  List<String>? lastStyle = [];

  @override
  void initState() {
    super.initState();
    _quilcontroller.addListener(_onSelectionChanged);
    _focusNode.addListener(_focusChange);
    _scrollController = ScrollController();

    _previousOps = _quilcontroller.document.toDelta().toList();
    // To remove background color when format was remove
    _quilcontroller.document.changes.listen((change) {
      final delta = change.change; // Get the delta change

      for (final op in delta.toList()) {
        if (op.isDelete) {
          // Find the range of deleted text in the previous operations
          final start = _quilcontroller.selection.baseOffset - op.length!;
          final end = _quilcontroller.selection.baseOffset;

          // Check attributes in the range of deleted text
          final attributes = _getAttributesInRange(start, end);

          if (!(attributes.containsKey("bold"))) {
            setState(() {
              isBold = false;
            });
          }
          if (!(attributes.containsKey("italic"))) {
            setState(() {
              isItalic = false;
            });
          }
          if (!(attributes.containsKey("strike"))) {
            setState(() {
              isStrike = false;
            });
          }
          if (!(attributes.containsKey("code"))) {
            setState(() {
              isCode = false;
            });
          }
          if (attributes.containsKey("list")) {
            final int start = _quilcontroller.selection.baseOffset - 2;
            final int end = _quilcontroller.selection.baseOffset;
            _quilcontroller.replaceText(
                start, end - start, '', TextSelection.collapsed(offset: start));
          }
        }
      }
      // Update the previous text and operations to the new state after handling changes
      _previousOps = _quilcontroller.document.toDelta().toList();
    });

    loadMessages();
    connectWebSocket();
    if (kIsWeb) {
      return;
    } else if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
  }

  Map<String, dynamic> _getAttributesInRange(int start, int end) {
    Map<String, dynamic> combinedAttributes = {};
    int currentPosition = 0;

    for (final op in _previousOps) {
      if (op.isInsert) {
        final text = op.data as String;
        final length = text.length;

        if (currentPosition + length >= start && currentPosition < end) {
          combinedAttributes.addAll(op.attributes ?? {});
        }
        currentPosition += length;
      } else if (op.isRetain) {
        currentPosition += op.length! as int;
      }
    }
    return combinedAttributes;
  }

  @override
  void dispose() {
    super.dispose();

    _scrollController.dispose();
    _quilcontroller.removeListener(_onSelectionChanged);
    _focusNode.removeListener(_focusChange);
  }

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() {
      files.addAll(result.files);
      hasFileToSEnd = true;
    });
  }

  void connectWebSocket() {
    var url =
        'ws://$wsUrl/cable?user_id=$currentUserId&s_user_id=${widget.receiverId}';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ThreadChannel'}),
    });

    _channel!.sink.add(subscriptionMessage);

    _channel!.stream.listen(
      (message) {
        try {
          var parsedMessage = jsonDecode(message) as Map<String, dynamic>;

          if (parsedMessage.containsKey('type') &&
              parsedMessage['type'] == 'ping') {
            return;
          }

          if (parsedMessage.containsKey('message')) {
            var messageContent = parsedMessage['message'];

            // Handling chat message
            if (messageContent != null &&
                messageContent.containsKey('message')) {
              var msg = messageContent['message'];

              if (msg != null &&
                  msg.containsKey('directthreadmsg') &&
                  msg['t_direct_message_id'] == widget.directMsgId) {
                var directThreadMsg = msg['directthreadmsg'];
                int id = msg['id'];
                var date = msg['created_at'];
                String send = messageContent['sender_name'];
                List<dynamic> fileUrls = [];

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileUrls = files.map((file) => file['file']).toList();
                  }
                }
                setState(() {
                  tDirectThreads!.add(TDirectThreads(
                    id: id,
                    directthreadmsg: directThreadMsg,
                    fileUrls: fileUrls,
                    createdAt: date,
                    name: send,
                  ));
                });
              } else {}
            } else if (messageContent.containsKey('messaged_star')) {
              var messageStarData = messageContent['messaged_star'];

              if (messageStarData != null &&
                  messageStarData['userid'] == currentUserId) {
                var directThreadID = messageStarData['directthreadid'];

                setState(() {
                  tDirectStarThreadMsgIds!.add(directThreadID);
                });
              } else {}
            } else if (messageContent.containsKey('unstared_message') &&
                messageContent['unstared_message']['userid'] == currentUserId) {
              var unstaredMsg = messageContent['unstared_message'];

              var directmsgid = unstaredMsg['directthreadid'];

              setState(() {
                tDirectStarThreadMsgIds!.remove(directmsgid);
              });
            } else {
              var deletemsg = messageContent['delete_msg_thread'];

              var threadId = deletemsg['id'];

              setState(() {
                tDirectThreads!.removeWhere((thread) {
                  return thread.id == threadId;
                });
              });
            }
          } else {}
        } catch (e) {
          rethrow;
        }
      },
      onDone: () {},
      onError: (error) {},
    );
  }

  Future<void> loadMessages() async {
    var token = await getToken();
    try {
      DirectMessageThread thread =
          await _apiService.getAllThread(widget.directMsgId, token!);

      setState(() {
        tDirectThreads = thread.tDirectThreads;
        tDirectStarThreadMsgIds = thread.tDirectStarThreadMsgids;
        senderName = thread.senderName!;
        directMessage = thread.tDirectMessage!.directmsg!;
        times = thread.tDirectMessage!.createdAt!;
        isLoading = true;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendReplyMessage(htmlcontent) async {
    if (htmlcontent.isNotEmpty || files.isNotEmpty) {
      await _directMessageService.sendDirectMessageThread(
          widget.directMsgId, widget.receiverId, htmlcontent, files);
      files.clear();
    }
  }

  Future<void> starMsgReply(int threadId) async {
    var token = await getToken();
    await _apiService.starThread(
        widget.receiverId, currentUserId, threadId, widget.directMsgId, token!);
  }

  Future<void> unStarReply(int threadId) async {
    var token = await getToken();
    await _apiService.unStarThread(
        widget.directMsgId, widget.receiverId, threadId, currentUserId, token!);
  }

  Future<void> deleteReply(int threadId) async {
    var token = await getToken();
    await _apiService.deleteThread(
        widget.directMsgId, widget.receiverId, threadId, token!);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  // -------------------------------------------------------

  void _onSelectionChanged() {
    if (_quilcontroller.selection.extentOffset !=
        _quilcontroller.selection.baseOffset) {
      setState(() {
        isSelectText = true;
        isfirstField = false;
      });
      _checkSelectedWordFormatting();
    } else {
      setState(() {
        isSelectText = false;
        isfirstField = true;
      });
    }

    _checkWordFormatting();
  }

  void _focusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        isCursor = true;
      });
    } else {
      setState(() {
        isCursor = false;
      });
    }
  }

  void _checkSelectedWordFormatting() {
    final selection = _quilcontroller.selection;

    if (selection.isCollapsed) {
      return;
    }
    // final doc = _quilcontroller.document;
    // final text = doc.toPlainText();
    // final selectedText = text.substring(selection.start, selection.end).trim();

    final checkSelectedBold = _isSelectedTextFormatted(
        selection.start, selection.end, quill.Attribute.bold);
    final checkSelectedItalic = _isSelectedTextFormatted(
        selection.start, selection.end, quill.Attribute.italic);
    final checkSelectedStrike = _isSelectedTextFormatted(
        selection.start, selection.end, quill.Attribute.strikeThrough);
    final checkSelectedCode = _isSelectedTextFormatted(
        selection.start, selection.end, quill.Attribute.inlineCode);

    if (checkSelectedBold) {
      setState(() {
        isBold = true;
      });
    } else {
      setState(() {
        isBold = false;
      });
    }

    if (checkSelectedItalic) {
      setState(() {
        isItalic = true;
      });
    } else {
      setState(() {
        isItalic = false;
      });
    }

    if (checkSelectedStrike) {
      setState(() {
        isStrike = true;
      });
    } else {
      setState(() {
        isStrike = false;
      });
    }

    if (checkSelectedCode) {
      setState(() {
        isCode = true;
      });
    } else {
      setState(() {
        isCode = false;
      });
    }
  }

  bool _isSelectedTextFormatted(int start, int end, quill.Attribute attribute) {
    final styles = _quilcontroller.getAllSelectionStyles();
    for (var style in styles) {
      if (style.attributes.containsKey(attribute.key)) {
        return true;
      }
    }
    return false;
  }

  void _checkWordFormatting() {
    final int cursorPosition = _quilcontroller.selection.baseOffset;
    // To avoid first word not working
    if (cursorPosition == 0) {
      return;
    }

    final doc = _quilcontroller.document;
    final text = doc.toPlainText();
    final wordRange = _getWordRangeAtCursor(text, cursorPosition);
    // final word = text.substring(wordRange.start, wordRange.end).trim();

    final checkLastBold = _isWordBold(wordRange);
    final checkLastItalic = _isWordItalic(wordRange);
    final checkLastStrikethrough = _isWordStrikethrough(wordRange);
    final checkLastCode = _isWordCode(wordRange);

    if (checkLastBold) {
      setState(() {
        isBold = true;
      });
    } else {
      setState(() {
        isBold = false;
      });
    }

    if (checkLastItalic) {
      setState(() {
        isItalic = true;
      });
    } else {
      setState(() {
        isItalic = false;
      });
    }

    if (checkLastStrikethrough) {
      setState(() {
        isStrike = true;
      });
    } else {
      setState(() {
        isStrike = false;
      });
    }

    if (checkLastCode) {
      setState(() {
        isCode = true;
      });
    } else {
      setState(() {
        isCode = false;
      });
    }
  }

  TextRange _getWordRangeAtCursor(String text, int cursorPosition) {
    if (cursorPosition <= 0 || cursorPosition >= text.length) {
      return TextRange(start: cursorPosition, end: cursorPosition);
    }

    int start = cursorPosition - 1;
    int end = cursorPosition;

    // Find the start of the word
    while (start > 0 && !_isWordBoundary(text[start - 1])) {
      start--;
    }

    // Find the end of the word
    while (end < text.length && !_isWordBoundary(text[end])) {
      end++;
    }

    return TextRange(start: start, end: end);
  }

  bool _isWordBold(TextRange wordRange) {
    for (int i = wordRange.start; i < wordRange.end; i++) {
      final style = _quilcontroller.getSelectionStyle().attributes;
      if (style.containsKey(quill.Attribute.bold.key)) {
        return true;
      }
    }
    return false;
  }

  bool _isWordItalic(TextRange wordRange) {
    for (int i = wordRange.start; i < wordRange.end; i++) {
      final style = _quilcontroller.getSelectionStyle().attributes;
      if (style.containsKey(quill.Attribute.italic.key)) {
        return true;
      }
    }
    return false;
  }

  bool _isWordStrikethrough(TextRange wordRange) {
    for (int i = wordRange.start; i < wordRange.end; i++) {
      final style = _quilcontroller.getSelectionStyle().attributes;
      if (style.containsKey(quill.Attribute.strikeThrough.key)) {
        return true;
      }
    }
    return false;
  }

  bool _isWordCode(TextRange wordRange) {
    for (int i = wordRange.start; i < wordRange.end; i++) {
      final style = _quilcontroller.getSelectionStyle().attributes;
      if (style.containsKey(quill.Attribute.inlineCode.key)) {
        return true;
      }
    }
    return false;
  }

  bool _isWordBoundary(String char) {
    return char == ' ' ||
        char == '\n' ||
        char == '\t' ||
        char == '.' ||
        char == ',' ||
        char == '!' ||
        char == '?';
  }

  String convertDocumentToHtml(quill.Document doc) {
    final StringBuffer buffer = StringBuffer();
    List list = [];

    for (final leaf in doc.toDelta().toList()) {
      final insert = leaf.data;
      final attributes = leaf.attributes ?? {};

      if (insert is String) {
        String text = insert.replaceAll('\n', '<br>');

        if (attributes.containsKey('bold')) {
          text = '<strong>$text</strong>';
        }
        if (attributes.containsKey('italic')) {
          text = '<em>$text</em>';
        }
        if (attributes.containsKey('underline')) {
          text = '<u>$text</u>';
        }
        if (attributes.containsKey('strike')) {
          text = '<s>$text</s>';
        }
        if (attributes.containsKey("link")) {
          text = '<a href="${attributes["link"]}">$text</a>';
        }
        if (attributes.containsKey("code")) {
          text =
              '<code style="border: 1px solid #A9A9A9; padding:10px; display:inline-block">$text</code>';
        }
        if (isBlockquote) {
          text = '<blockquote>$text</blockquote>';
        }
        if (isOrderList || isUnorderList) {
          list += [text];
          if (list[0].contains("<br>")) {
            list[0] = "${list[0]}<a>";
            for (int i = 0; i < list.length; i++) {
              text = list[i];
            }
          }
        }
        buffer.write(text);
      }
    }
    return buffer.toString();
  }

  void _clearEditor() {
    final length = _quilcontroller.document.length;
    _quilcontroller.replaceText(
        0, length, '', const TextSelection.collapsed(offset: 0));
    // Clear bg color
    setState(() {
      isBlockquote = false;
      isOrderList = false;
      isBold = false;
      isItalic = false;
      isStrike = false;
      isLink = false;
      isUnorderList = false;
      isCode = false;
      isCodeblock = false;
    });
    // Clear format
    _quilcontroller
        .formatSelection(quill.Attribute.clone(quill.Attribute.ol, null));
    _quilcontroller
        .formatSelection(quill.Attribute.clone(quill.Attribute.ul, null));
    _quilcontroller.formatSelection(
        quill.Attribute.clone(quill.Attribute.blockQuote, null));
    _quilcontroller.formatSelection(
        quill.Attribute.clone(quill.Attribute.codeBlock, null));
  }

  void _insertLink() async {
    String selectedLinkText = "";
    final selection = _quilcontroller.selection;
    if (!selection.isCollapsed) {
      final startIndex = selection.baseOffset;
      final endIndex = selection.extentOffset;
      selectedLinkText = _quilcontroller.document
          .toPlainText()
          .substring(startIndex, endIndex);
    }

    final TextEditingController linktextController = selectedLinkText.isNotEmpty
        ? TextEditingController(text: selectedLinkText)
        : TextEditingController();
    final TextEditingController linkController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          elevation: 5.0,
          title: const Text('Insert Link'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the text";
                    }
                    return null;
                  },
                  controller: linktextController,
                  decoration: const InputDecoration(labelText: 'Text'),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the URL";
                    }
                    return null;
                  },
                  controller: linkController,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  isLink = false;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Insert'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final text = linktextController.text;
                  final link = linkController.text;
                  if (text.isNotEmpty && link.isNotEmpty) {
                    final selection = _quilcontroller.selection;
                    final start = selection.baseOffset;
                    final length =
                        selection.extentOffset - selection.baseOffset;

                    _quilcontroller.replaceText(
                      start,
                      length,
                      text,
                      selection,
                    );

                    _quilcontroller.formatText(
                      start,
                      text.length,
                      quill.LinkAttribute(link),
                    );

                    // Move the cursor to the end of the inserted text
                    _quilcontroller.updateSelection(
                      TextSelection.collapsed(offset: start + text.length),
                      quill.ChangeSource.local,
                    );
                  }
                  setState(() {
                    isLink = false;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    ).then((value) async {
      if (value == null) {
        setState(() {
          isLink = false;
        });
      } else {
        setState(() {
          isLink = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (SessionStore.sessionData!.currentUser!.memberStatus == false) {
      return const CustomLogOut();
    } else {
      DateTime dates = DateTime.parse(times).toLocal();
      String createdAt = DateFormat('MMM d, yyyy hh:mm a').format(dates);
      int maxLines = (directMessage.length / 25).ceil();
      int replyLength = tDirectThreads?.length ?? 0;

      return Scaffold(
          backgroundColor: kPriamrybackground,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: navColor,
            leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                )),
            title: const Text(
              'Thread',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: isLoading == false
              ? const ProgressionBar(
                  imageName: 'loading.json',
                  height: 200,
                  size: 200,
                  color: Colors.white)
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      height: 100,
                      width: 500,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(20)),
                                  height: 50,
                                  width: 50,
                                  child: Center(
                                    child: Text(
                                      senderName.characters.first.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: widget.userstatus == true
                                        ? Container(
                                            height: 14,
                                            width: 14,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 1),
                                                color: Colors.green),
                                          )
                                        : Container())
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Row(children: [
                                        Text(
                                          senderName,
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          createdAt,
                                          style: const TextStyle(
                                              fontSize: 10, color: Colors.grey),
                                        )
                                      ]),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  flutter_html.Html(
                                    data: directMessage.isNotEmpty
                                        ? directMessage
                                        : "",
                                    style: {
                                      ".bq": flutter_html.Style(
                                        // backgroundColor: Colors.purple
                                        border: const Border(
                                            left: BorderSide(
                                                color: Colors.grey,
                                                width: 5.0)),
                                        padding: flutter_html.HtmlPaddings.only(
                                            left: 10),
                                      ),
                                      "blockquote": flutter_html.Style(
                                        display: flutter_html.Display.inline,
                                      ),
                                      "code": flutter_html.Style(
                                        backgroundColor: Colors.grey[200],
                                        color: Colors.red,
                                      ),
                                      "ol": flutter_html.Style(
                                        margin: flutter_html.Margins.all(0),
                                        padding:
                                            flutter_html.HtmlPaddings.all(0),
                                      ),
                                      "ol li": flutter_html.Style(
                                        display:
                                            flutter_html.Display.inlineBlock,
                                      ),
                                      "ul": flutter_html.Style(
                                        display:
                                            flutter_html.Display.inlineBlock,
                                        padding:
                                            flutter_html.HtmlPaddings.symmetric(
                                                horizontal: 10),
                                        margin: flutter_html.Margins.all(0),
                                      ),
                                      ".code-block": flutter_html.Style(
                                          padding:
                                              flutter_html.HtmlPaddings.all(10),
                                          backgroundColor: Colors.grey[200],
                                          color: Colors.black,
                                          width: flutter_html.Width(150)),
                                      ".code-block code": flutter_html.Style(
                                          color: Colors.black)
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              '$replyLength reply',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Divider(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: replyLength,
                        itemBuilder: (context, index) {
                          String replyMessages =
                              tDirectThreads![index].directthreadmsg.toString();
                          String name = tDirectThreads![index].name.toString();

                          List<dynamic>? files = [];
                          files = tDirectThreads![index].fileUrls;

                          int replyMessagesIds =
                              tDirectThreads![index].id!.toInt();
                          List<int> replyStarMsgId =
                              tDirectStarThreadMsgIds!.toList();
                          bool isStar =
                              replyStarMsgId.contains(replyMessagesIds);
                          String time =
                              tDirectThreads![index].createdAt.toString();

                          DateTime date = DateTime.parse(time).toLocal();
                          String createdAt =
                              DateFormat('MMM d, yyyy hh:mm a').format(date);

                          String currentUserName =
                              SessionStore.sessionData!.currentUser!.name!;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        height: 50,
                                        width: 50,
                                        child: Center(
                                          child: Text(
                                            name.characters.first.toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: widget.userstatus == true
                                              ? Container(
                                                  height: 14,
                                                  width: 14,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7),
                                                      border: Border.all(
                                                          color: Colors.white,
                                                          width: 1),
                                                      color: Colors.green),
                                                )
                                              : Container())
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(13),
                                            bottomRight: Radius.circular(13),
                                            topRight: Radius.circular(13))),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (replyMessages.isNotEmpty)
                                                flutter_html.Html(
                                                  data: replyMessages,
                                                  style: {
                                                    ".bq": flutter_html.Style(
                                                      // backgroundColor: Colors.purple
                                                      border: const Border(
                                                          left: BorderSide(
                                                              color:
                                                                  Colors.grey,
                                                              width: 5.0)),
                                                      padding: flutter_html
                                                              .HtmlPaddings
                                                          .only(left: 10),
                                                    ),
                                                    "blockquote":
                                                        flutter_html.Style(
                                                      display: flutter_html
                                                          .Display.inline,
                                                    ),
                                                    "code": flutter_html.Style(
                                                      backgroundColor:
                                                          Colors.grey[200],
                                                      color: Colors.red,
                                                    ),
                                                    "ol": flutter_html.Style(
                                                      margin: flutter_html
                                                          .Margins.all(0),
                                                      padding: flutter_html
                                                          .HtmlPaddings.all(0),
                                                    ),
                                                    "ol li": flutter_html.Style(
                                                      display: flutter_html
                                                          .Display.inlineBlock,
                                                    ),
                                                    "ul": flutter_html.Style(
                                                      display: flutter_html
                                                          .Display.inlineBlock,
                                                      padding: flutter_html
                                                              .HtmlPaddings
                                                          .symmetric(
                                                              horizontal: 10),
                                                      margin: flutter_html
                                                          .Margins.all(0),
                                                    ),
                                                    ".code-block": flutter_html
                                                        .Style(
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .all(10),
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[200],
                                                            color: Colors.black,
                                                            width: flutter_html
                                                                .Width(150)),
                                                    ".code-block code":
                                                        flutter_html.Style(
                                                            color: Colors.black)
                                                  },
                                                ),
                                              if (files!.length == 1)
                                                singleFile.buildSingleFile(
                                                    files[0],
                                                    context,
                                                    platform),
                                              if (files.length > 2)
                                                mulitFile.buildMultipleFiles(
                                                    files, platform, context),
                                              const SizedBox(height: 8),
                                              const SizedBox(height: 8),
                                              Text(
                                                createdAt,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color.fromARGB(
                                                      255, 15, 15, 15),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          // crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () async {
                                                if (isStar) {
                                                  await unStarReply(
                                                      replyMessagesIds);
                                                } else {
                                                  await starMsgReply(
                                                      replyMessagesIds);
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.star,
                                                size: 20,
                                              ),
                                              color: isStar
                                                  ? Colors.yellow
                                                  : Colors.grey,
                                            ),
                                            if (currentUserName == name)
                                              IconButton(
                                                onPressed: () async {
                                                  await deleteReply(
                                                      replyMessagesIds);
                                                  print(
                                                      "This is a corona ${replyMessagesIds}");
                                                },
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 20,
                                                  color: Colors.red,
                                                ),
                                              ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (hasFileToSEnd && files.isNotEmpty)
                    FileDisplayWidget(files: files, platform: platform),

                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(25),
                                topRight: Radius.circular(25))),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20)),
                          child: QuillEditor.basic(
                            focusNode: _focusNode,
                            configurations: QuillEditorConfigurations(
                              minHeight: 20,
                              maxHeight: 100,
                              controller: _quilcontroller,
                              placeholder: "send messages...",
                              // readOnly: false,
                              sharedConfigurations:
                                  const QuillSharedConfigurations(
                                locale: Locale('de'),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isCursor &&
                          isfirstField &&
                          isClickedTextFormat == false)
                        Container(
                          color: Colors.grey[300],
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: IconButton(
                                          onPressed: () {
                                            pickFiles();
                                          },
                                          icon: const Icon(
                                              Icons.attach_file_outlined))),
                                  IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isfirstField = false;
                                          isSelectText = true;
                                          isClickedTextFormat = true;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.text_format,
                                        size: 30,
                                        color: Colors.grey[800],
                                      )),
                                ],
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 24, 103, 167),
                                    borderRadius: BorderRadius.circular(5)),
                                child: IconButton(
                                    onPressed: () {
                                      final doc = _quilcontroller.document;
                                      htmlContent = convertDocumentToHtml(doc);
                                      // for blockquote
                                      if (isBlockquote) {
                                        htmlContent =
                                            "<div class='bq'>$htmlContent</div>";
                                      }
                                      // for codeblock
                                      if (isCodeblock) {
                                        htmlContent =
                                            htmlContent.replaceAll('<br>', ' ');
                                        htmlContent =
                                            '<div class="code-block" style="border:1px solid #A9A9A9;">$htmlContent</div>';
                                      }
                                      // for order list
                                      if (isOrderList) {
                                        String separateText = "";
                                        String orderText = "";
                                        List<String> combinedList = [];

                                        if (htmlContent.contains("<a>")) {
                                          final separate =
                                              htmlContent.split("<a>");
                                          orderText = separate[1].toString();
                                          separateText = separate[0].toString();
                                          final orderList =
                                              orderText.split("<br>");
                                          for (int i = 0;
                                              i < orderList.length;
                                              i++) {
                                            if (orderList[i].isNotEmpty) {
                                              combinedList.add(
                                                  "<ol><li>${i + 1}.  ${orderList[i]}</li></ol><br>");
                                            }
                                          }
                                          String finalcontent =
                                              combinedList.join(" ");
                                          htmlContent =
                                              "$separateText $finalcontent";
                                        } else {
                                          final orderList =
                                              htmlContent.split("<br>");
                                          for (int i = 0;
                                              i < orderList.length;
                                              i++) {
                                            if (orderList[i].isNotEmpty) {
                                              combinedList.add(
                                                  "<ol><li>${i + 1}.  ${orderList[i]}</li></ol><br>");
                                            }
                                          }
                                          htmlContent = combinedList.join(" ");
                                        }
                                      }
                                      // for unorder list
                                      if (isUnorderList) {
                                        String separateText = "";
                                        String orderText = "";
                                        List<String> combinedList = [];

                                        if (htmlContent.contains("<a>")) {
                                          final separate =
                                              htmlContent.split("<a>");
                                          orderText = separate[1].toString();
                                          separateText = separate[0].toString();
                                          final orderList =
                                              orderText.split("<br>");
                                          for (int i = 0;
                                              i < orderList.length;
                                              i++) {
                                            if (orderList[i].isNotEmpty) {
                                              combinedList.add(
                                                  "<ul><li>${orderList[i]}</li></ul><br>");
                                            }
                                          }
                                          String finalcontent =
                                              combinedList.join(" ");
                                          htmlContent =
                                              "$separateText $finalcontent";
                                        } else {
                                          final orderList =
                                              htmlContent.split("<br>");
                                          for (int i = 0;
                                              i < orderList.length;
                                              i++) {
                                            if (orderList[i].isNotEmpty) {
                                              combinedList.add(
                                                  "<ul><li>${orderList[i]}</li></ul><br>");
                                            }
                                          }
                                          htmlContent = combinedList.join(" ");
                                        }
                                      }
                                      htmlContent =
                                          htmlContent.replaceAll("<br>", "");

                                      setState() {
                                        isLoading = !isLoading;
                                      }

                                      sendReplyMessage(htmlContent);
                                      _clearEditor();
                                    },
                                    icon: const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      Visibility(
                        visible:
                            isSelectText || isClickedTextFormat ? true : false,
                        child: Container(
                          color: Colors.grey[300],
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 10.0),
                          child: Row(
                            children: [
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isClickedTextFormat = false;
                                      isSelectText = false;
                                      isfirstField = true;
                                    });
                                  },
                                  icon: const Icon(Icons.close)),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: isBold
                                              ? Colors.grey[400]
                                              : Colors.grey[300],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.format_bold),
                                          onPressed: () {
                                            setState(() {
                                              if (isBold) {
                                                isBold = false;
                                              } else {
                                                isBold = true;
                                              }
                                            });
                                            if (isBold) {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.bold);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.bold,
                                                      null));
                                            }
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: isItalic
                                              ? Colors.grey[400]
                                              : Colors.grey[300],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.format_italic),
                                          onPressed: () {
                                            setState(() {
                                              if (isItalic) {
                                                isItalic = false;
                                              } else {
                                                isItalic = true;
                                              }
                                            });
                                            if (isItalic) {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.italic);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.italic,
                                                      null));
                                            }
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: isStrike
                                              ? Colors.grey[400]
                                              : Colors.grey[300],
                                        ),
                                        child: IconButton(
                                          icon:
                                              const Icon(Icons.strikethrough_s),
                                          onPressed: () {
                                            setState(() {
                                              if (isStrike) {
                                                isStrike = false;
                                              } else {
                                                isStrike = true;
                                              }
                                            });
                                            if (isStrike) {
                                              _quilcontroller.formatSelection(
                                                  quill
                                                      .Attribute.strikeThrough);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute
                                                          .strikeThrough,
                                                      null));
                                            }
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: isLink
                                              ? Colors.grey[400]
                                              : Colors.grey[300],
                                        ),
                                        child: IconButton(
                                            icon: const Icon(Icons.link),
                                            onPressed: () {
                                              setState(() {
                                                if (isLink) {
                                                  isLink = false;
                                                } else {
                                                  isLink = true;
                                                  isBold = false;
                                                  isItalic = false;
                                                  isStrike = false;
                                                }
                                              });
                                              if (isLink) {
                                                _insertLink();
                                              }
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.bold,
                                                      null));
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.italic,
                                                      null));
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute
                                                          .strikeThrough,
                                                      null));
                                            }),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: isOrderList
                                              ? Colors.grey[400]
                                              : Colors.grey[300],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                              Icons.format_list_numbered),
                                          onPressed: () {
                                            setState(() {
                                              setState(() {
                                                if (isOrderList) {
                                                  isBlockquote = false;
                                                  isOrderList = false;
                                                  isUnorderList = false;
                                                  isCodeblock = false;
                                                } else {
                                                  isBlockquote = false;
                                                  isOrderList = true;
                                                  isUnorderList = false;
                                                  isCodeblock = false;
                                                }
                                              });
                                            });

                                            if (isOrderList) {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.ol);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.ol,
                                                      null));
                                            }
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: isUnorderList
                                              ? Colors.grey[400]
                                              : Colors.grey[300],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                              Icons.format_list_bulleted),
                                          onPressed: () {
                                            setState(() {
                                              if (isUnorderList) {
                                                isBlockquote = false;
                                                isOrderList = false;
                                                isUnorderList = false;
                                                isCodeblock = false;
                                              } else {
                                                isBlockquote = false;
                                                isOrderList = false;
                                                isUnorderList = true;
                                                isCodeblock = false;
                                              }
                                            });
                                            if (isUnorderList) {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.ul);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.ul,
                                                      null));
                                            }
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: isBlockquote
                                              ? Colors.grey[400]
                                              : Colors.grey[300],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                              Icons.align_horizontal_left),
                                          onPressed: () {
                                            setState(() {
                                              setState(() {
                                                if (isBlockquote) {
                                                  isBlockquote = false;
                                                  isOrderList = false;
                                                  isUnorderList = false;
                                                  isCodeblock = false;
                                                } else {
                                                  isBlockquote = true;
                                                  isOrderList = false;
                                                  isUnorderList = false;
                                                  isCodeblock = false;
                                                }
                                              });
                                            });
                                            if (isBlockquote) {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.blockQuote);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill
                                                          .Attribute.blockQuote,
                                                      null));
                                            }
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: isCode
                                              ? Colors.grey[400]
                                              : Colors.grey[300],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.code),
                                          onPressed: () {
                                            setState(() {
                                              if (isCode) {
                                                isCode = false;
                                              } else {
                                                isCode = true;
                                              }
                                            });
                                            if (isCode) {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.inlineCode);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill
                                                          .Attribute.inlineCode,
                                                      null));
                                            }
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: isCodeblock
                                              ? Colors.grey[400]
                                              : Colors.grey[300],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.article),
                                          onPressed: () {
                                            setState(() {
                                              if (isCodeblock) {
                                                isBlockquote = false;
                                                isOrderList = false;
                                                isUnorderList = false;
                                                isCodeblock = false;
                                                isCode = false;
                                              } else {
                                                isBlockquote = false;
                                                isOrderList = false;
                                                isUnorderList = false;
                                                isCodeblock = true;
                                                isCode = false;
                                              }
                                            });
                                            if (isCodeblock) {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.codeBlock);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.codeBlock,
                                                      null));
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 24, 103, 167),
                                    borderRadius: BorderRadius.circular(5)),
                                child: IconButton(
                                    onPressed: () {
                                      final doc = _quilcontroller.document;
                                      htmlContent = convertDocumentToHtml(doc);
                                      // for blockquote
                                      if (isBlockquote) {
                                        htmlContent =
                                            "<div class='bq'>$htmlContent</div>";
                                      }
                                      // for codeblock
                                      if (isCodeblock) {
                                        htmlContent =
                                            htmlContent.replaceAll('<br>', ' ');
                                        htmlContent =
                                            '<div class="code-block" style="border:1px solid #A9A9A9;">$htmlContent</div>';
                                      }
                                      // for order list
                                      if (isOrderList) {
                                        String separateText = "";
                                        String orderText = "";
                                        List<String> combinedList = [];

                                        if (htmlContent.contains("<a>")) {
                                          final separate =
                                              htmlContent.split("<a>");
                                          orderText = separate[1].toString();
                                          separateText = separate[0].toString();
                                          final orderList =
                                              orderText.split("<br>");
                                          for (int i = 0;
                                              i < orderList.length;
                                              i++) {
                                            if (orderList[i].isNotEmpty) {
                                              combinedList.add(
                                                  "<ol><li>${i + 1}.  ${orderList[i]}</li></ol><br>");
                                            }
                                          }
                                          String finalcontent =
                                              combinedList.join(" ");
                                          htmlContent =
                                              "$separateText $finalcontent";
                                        } else {
                                          final orderList =
                                              htmlContent.split("<br>");
                                          for (int i = 0;
                                              i < orderList.length;
                                              i++) {
                                            if (orderList[i].isNotEmpty) {
                                              combinedList.add(
                                                  "<ol><li>${i + 1}.  ${orderList[i]}</li></ol><br>");
                                            }
                                          }
                                          htmlContent = combinedList.join(" ");
                                        }
                                      }
                                      // for unorder list
                                      if (isUnorderList) {
                                        String separateText = "";
                                        String orderText = "";
                                        List<String> combinedList = [];

                                        if (htmlContent.contains("<a>")) {
                                          final separate =
                                              htmlContent.split("<a>");
                                          orderText = separate[1].toString();
                                          separateText = separate[0].toString();
                                          final orderList =
                                              orderText.split("<br>");
                                          for (int i = 0;
                                              i < orderList.length;
                                              i++) {
                                            if (orderList[i].isNotEmpty) {
                                              combinedList.add(
                                                  "<ul><li>${orderList[i]}</li></ul><br>");
                                            }
                                          }
                                          String finalcontent =
                                              combinedList.join(" ");
                                          htmlContent =
                                              "$separateText $finalcontent";
                                        } else {
                                          final orderList =
                                              htmlContent.split("<br>");
                                          for (int i = 0;
                                              i < orderList.length;
                                              i++) {
                                            if (orderList[i].isNotEmpty) {
                                              combinedList.add(
                                                  "<ul><li>${orderList[i]}</li></ul><br>");
                                            }
                                          }
                                          htmlContent = combinedList.join(" ");
                                        }
                                      }

                                      htmlContent =
                                          htmlContent.replaceAll("<br>", "");

                                      setState() {
                                        isLoading = !isLoading;
                                      }

                                      sendReplyMessage(htmlContent);
                                      _clearEditor();
                                    },
                                    icon: const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // TextFormField(
                  //   controller: replyTextController,
                  //   keyboardType: TextInputType.text,
                  //   textInputAction: TextInputAction.send,
                  //   maxLines: null,
                  //   cursorColor: kPrimaryColor,
                  //   decoration: InputDecoration(
                  //     hintText: "Sends Messages",
                  //     suffixIcon: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         GestureDetector(
                  //             onTap: () {
                  //               pickFiles();
                  //             },
                  //             child: const Icon(
                  //               Icons.attach_file_outlined,
                  //               size: 30,
                  //             )),
                  //         const SizedBox(
                  //           width: 5,
                  //         ),
                  //         GestureDetector(
                  //           onTap: () {
                  //             sendReplyMessage();
                  //             setState(() {
                  //               hasFileToSEnd = false;
                  //             });
                  //           },
                  //           child: const Icon(
                  //             Icons.telegram_outlined,
                  //             size: 35,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ]));
    }
  }
}
