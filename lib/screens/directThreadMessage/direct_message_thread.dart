import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/const/build_fiile.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/loadingScreenForThread.dart';
import 'package:flutter_frontend/services/directMessage/direct_message_api.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/directMessage/directMessageThread/direct_message_thread.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:flutter_quill/quill_delta.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
// ignore_for_file: public_member_api_docs, sort_constructors_first

class DirectMessageThreadWidget extends StatefulWidget {
  final int directMsgId;
  final String? receiverName;
  final int receiverId;
  final userstatus;
  final String? profileImage;
  final List<dynamic>? files;
  final List<dynamic>? filesName;
  const DirectMessageThreadWidget(
      {Key? key,
      required this.directMsgId,
      this.receiverName,
      required this.receiverId,
      this.userstatus,
      this.profileImage,
      this.files,
      this.filesName})
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

//　-----------------
  List<EmojiCountsforDirectThread>? emojiCounts = [];
  List<ReactUserDataForDirectThread>? reactUserDatas = [];
  String selectedEmoji = "";
  String _seletedEmojiName = "";
  bool _isEmojiSelected = false;
// ----------------
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
  quill.QuillController _quilcontroller = quill.QuillController.basic();
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
  bool isEnter = false;
  bool discode = false;
  bool isEdit = false;
  bool showScrollButton = false;
  bool isScrolling = false;
  bool isMessaging = false;
  List _previousOps = [];
  String editMsg = "";
  int? editMsgId;

  @override
  void initState() {
    super.initState();
    loadMessages();
    connectWebSocket();
    _quilcontroller.addListener(_onSelectionChanged);
    _focusNode.addListener(_focusChange);
    _scrollController = ScrollController();
    _scrollController.addListener(scrollListener);

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
              discode = false;
            });
          }
          if (!(attributes.containsKey("italic"))) {
            setState(() {
              isItalic = false;
              discode = false;
            });
          }
          if (!(attributes.containsKey("strike"))) {
            setState(() {
              isStrike = false;
              discode = false;
            });
          }
          if (!(attributes.containsKey("code"))) {
            setState(() {
              isCode = false;
              discode = false;
            });
          }
          if (attributes.containsKey("list")) {
            final int start = _quilcontroller.selection.baseOffset - 2;
            final int end = _quilcontroller.selection.baseOffset;
            _quilcontroller.replaceText(
                start, end - start, '', TextSelection.collapsed(offset: start));
            setState(() {
              discode = false;
            });
          }
        }
      }
      // Update the previous text and operations to the new state after handling changes
      _previousOps = _quilcontroller.document.toDelta().toList();
    });

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
    _channel!.sink.close();
    _scrollController.dispose();
    _quilcontroller.removeListener(_onSelectionChanged);
    _focusNode.removeListener(_focusChange);
    _scrollController.removeListener(scrollListener);
  }

  void scrollListener() {
    if (_scrollController.position.pixels <
            _scrollController.position.maxScrollExtent - 100 ||
        isMessaging == false) {
      setState(() {
        isMessaging = true;
        showScrollButton = true;
      });
    } else {
      setState(() {
        isMessaging = false;
        showScrollButton = false;
      });
    }
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
                List<dynamic>? fileName = [];
                String? profileImage = messageContent['profile_image'];

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileUrls = files.map((file) => file['file']).toList();
                  }
                }

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileName = files.map((file) => file['file_name']).toList();
                  }
                }

                setState(() {
                  tDirectThreads!.add(TDirectThreads(
                    id: id,
                    directthreadmsg: directThreadMsg,
                    fileUrls: fileUrls,
                    createdAt: date,
                    name: send,
                    fileName: fileName,
                    profileName: profileImage,
                  ));
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (isMessaging == false) {
                      _scrollToBottom();
                    }
                  });
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
            } else if (messageContent.containsKey('react_message')) {
              var reactmsg = messageContent['react_message'];
              var userId = reactmsg['userid'];
              var directthreadid = reactmsg['directthreadid'];
              var emoji = reactmsg['emoji'];
              var reactUserInfo = messageContent['reacted_user_info'];
              var emojiCount;
              bool emojiExists = false;
              for (var element in emojiCounts!) {
                if (element.emoji == emoji &&
                    element.directThreadId == directthreadid) {
                  emojiCount = element.emojiCount! + 1;
                  element.emojiCount = emojiCount;
                  emojiExists = true;
                  break;
                }
              }
              if (!emojiExists) {
                emojiCount = 1;
                emojiCounts!.add(EmojiCountsforDirectThread(
                    directThreadId: directthreadid,
                    emoji: emoji,
                    emojiCount: emojiCount));
              }

              setState(() {
                if (emojiExists) {
                  emojiCounts!.add(EmojiCountsforDirectThread(
                      directThreadId: directthreadid, emojiCount: emojiCount));
                }
                reactUserDatas!.add(ReactUserDataForDirectThread(
                    directThreadId: directthreadid,
                    emoji: emoji,
                    name: reactUserInfo,
                    userId: userId));
              });
            } else if (messageContent.containsKey('remove_reaction')) {
              var deleteRection = messageContent['remove_reaction'];
              var directthreadid = deleteRection['directthreadid'];
              var emoji = deleteRection['emoji'];
              var reactUserInfo = messageContent['reacted_user_info'];
              setState(() {
                for (var element in emojiCounts!) {
                  if (element.emoji == emoji &&
                      element.directThreadId == directthreadid) {
                    element.emojiCount = element.emojiCount! - 1;
                    break;
                  }
                }
                reactUserDatas!.removeWhere((user) =>
                    user.emoji == emoji &&
                    user.directThreadId == directthreadid &&
                    user.name == reactUserInfo);
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
        emojiCounts = thread.emojiCounts!;
        reactUserDatas = thread.reactUserDatas!;
        isLoading = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
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

  Future<void> giveThreadMsgReaction(
      {required int threadId,
      required String emoji,
      required int selectedDirectMsgId,
      required int selectedUserId,
      required int userId}) async {
    var token = await getToken();
    Map<String, dynamic> requestBody = {
      "s_direct_message_id": selectedDirectMsgId,
      "s_user_id": selectedUserId,
      "thread_id": threadId,
      "user_id": userId,
      "emoji": emoji
    };
    await _apiService.directThreadMessageReaction(requestBody, token!);
  }

  Future<void> editdirectThreadMessage(String thmessage, int thmsgId) async {
    var token = await getToken();
    Map<String, dynamic> requestBody = {
      'id': thmsgId,
      'message': thmessage,
    };
    await _apiService.editdirectThreadMessage(requestBody, token!);
    setState(() {
      isEdit = false;
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 300,
      duration: const Duration(milliseconds: 100),
      curve: Curves.ease,
    );
  }

  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  String detectStyles() {
    var delta = _quilcontroller.document.toDelta();
    final Delta updatedDelta = Delta();

    for (final op in delta.toList()) {
      if (op.attributes != null &&
          op.attributes!.containsKey("list") &&
          op.value != null &&
          op.value != "\n" &&
          op.attributes!.length == 1) {
        final newAttributes = Map<String, dynamic>.from(op.attributes!);
        newAttributes.remove('list');

        // Add the modified operation to the updated delta
        updatedDelta.insert(op.data);
      } else if (op.attributes != null &&
          op.attributes!.containsKey("list") &&
          op.value != null &&
          op.value != "\n") {
        final newAttributes = Map<String, dynamic>.from(op.attributes!);
        if (newAttributes.containsKey('list')) {
          newAttributes.remove('list');
        }
        updatedDelta.insert(op.data, newAttributes);
      } else {
        // Add the original operation to the updated delta
        updatedDelta.push(op);
      }
    }

    var converter = QuillDeltaToHtmlConverter(updatedDelta.toJson());

    String html = converter.convert();

    return html;
  }

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
    final checkLastCodeBlock = _isWordCodeBlock(wordRange);

    if (checkLastBold) {
      setState(() {
        isBold = true;
        discode = false;
      });
    } else {
      setState(() {
        isBold = false;
      });
    }

    if (checkLastItalic) {
      setState(() {
        isItalic = true;
        discode = false;
      });
    } else {
      setState(() {
        isItalic = false;
      });
    }

    if (checkLastStrikethrough) {
      setState(() {
        isStrike = true;
        discode = false;
      });
    } else {
      setState(() {
        isStrike = false;
      });
    }

    if (checkLastCode) {
      setState(() {
        isCode = true;
        discode = false;
      });
    } else {
      setState(() {
        isCode = false;
      });
    }

    if (checkLastCodeBlock) {
      setState(() {
        isCodeblock = true;
        discode = true;
      });
    } else {
      setState(() {
        isCodeblock = false;
        discode = false;
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

  bool _isWordCodeBlock(TextRange wordRange) {
    for (int i = wordRange.start; i < wordRange.end; i++) {
      final style = _quilcontroller.getSelectionStyle().attributes;
      if (style.containsKey(quill.Attribute.codeBlock.key)) {
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
      discode = false;
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

  void insertEditText(msg) {
    Delta delta = convertHtmlToDelta(msg);
    _quilcontroller = quill.QuillController(
      document: quill.Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Delta convertHtmlToDelta(String html) {
    if (html.contains("<ol>") || html.contains("<ul>")) {
      html = "<p>$html</p>";
    }
    final document = html_parser.parse(html);
    final delta = Delta();

    void parseNode(html_dom.Node node, Map<String, dynamic> attributes) {
      if (node is html_dom.Element) {
        var newAttributes = Map<String, dynamic>.from(attributes);

        switch (node.localName) {
          case 'strong':
            newAttributes['bold'] = true;
            break;
          case 'em':
            newAttributes['italic'] = true;
            break;
          case 's':
            newAttributes['strike'] = true;
            break;
          case 'a':
            newAttributes['link'] = node.attributes['href'];
            break;
          case 'code':
            newAttributes['code'] = true;
            break;
          case 'span':
            newAttributes['code'] = true;
            break;
          case 'p':
            if (node.nodes.isNotEmpty) {
              node.append(html_dom.Element.tag('br'));
            }
            for (var child in node.nodes) {
              parseNode(child, newAttributes);
            }
            return;
          case 'ol':
            for (var child in node.children) {
              if (child.localName == 'li') {
                parseNode(child, {});
                delta.insert("\n", {'list': 'ordered'});
              }
            }
            setState(() {
              isOrderList = true;
            });
            return;
          case 'ul':
            for (var child in node.children) {
              if (child.localName == 'li') {
                parseNode(child, {});
                delta.insert("\n", {'list': 'bullet'});
              }
            }
            setState(() {
              isUnorderList = true;
            });
            return;
          case 'blockquote':
            for (var child in node.nodes) {
              if (child.text!.isNotEmpty) {
                parseNode(child, {});
                delta.insert("\n", {'blockquote': true});
              }
            }
            setState(() {
              isBlockquote = true;
            });
            return;
          case "pre":
            for (var child in node.nodes) {
              if (child.text!.isNotEmpty) {
                if (child.text!.contains("\n")) {
                  List txtlist = child.text!.split("\n");
                  for (var txt in txtlist) {
                    delta.insert(txt, {});
                    delta.insert("\n", {'code-block': true});
                  }
                } else {
                  delta.insert(child.text, {});
                  delta.insert("\n", {'code-block': true});
                }
              }
            }
            setState(() {
              isCodeblock = true;
              discode = true;
            });
            return;
          case "div":
            for (var child in node.nodes) {
              if (child.text!.isNotEmpty) {
                if (child.text!.contains("\n")) {
                  List txtlist = child.text!.split("\n");
                  for (var txt in txtlist) {
                    delta.insert(txt, {});
                    delta.insert("\n", {'code-block': true});
                  }
                } else {
                  delta.insert(child.text, {});
                  delta.insert("\n", {'code-block': true});
                }
              }
            }
            setState(() {
              isCodeblock = true;
              discode = true;
            });
            return;
          case 'br':
            delta.insert('\n');
            return;
          default:
            for (var child in node.nodes) {
              parseNode(child, newAttributes);
            }
            return;
        }
        for (var child in node.nodes) {
          parseNode(child, newAttributes);
        }
      } else if (node is html_dom.Text) {
        final text = node.text;
        if (text.trim().isNotEmpty) {
          delta.insert(text, attributes);
        }
      }
    }

    for (var node in document.body!.nodes) {
      parseNode(node, {});
    }

    // Ensure the last block ends with a newline
    if (delta.length > 0 && !(delta.last.data as String).endsWith('\n')) {
      delta.insert('\n');
    }

    return delta;
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
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Thread",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.receiverName!,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: isLoading == false
              ? const ShimmerThread()
              : Stack(children: [
                  Column(children: [
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
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: Center(
                                      child: widget.profileImage == null ||
                                              widget.profileImage!.isEmpty
                                          ? const Icon(Icons.person)
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                widget.profileImage!,
                                                fit: BoxFit.cover,
                                                width: 40,
                                                height: 40,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      height: 10,
                                      width: 10,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                        color: widget.userstatus == true
                                            ? Colors.green
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
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
                                            style:
                                                const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            createdAt,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
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
                                        ".ql-code-block": flutter_html.Style(
                                            backgroundColor: Colors.grey[300],
                                            padding: flutter_html.HtmlPaddings
                                                .symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                            margin:
                                                flutter_html.Margins.symmetric(
                                                    vertical: 7)),
                                        ".highlight": flutter_html.Style(
                                          display:
                                              flutter_html.Display.inlineBlock,
                                          backgroundColor: Colors.grey[300],
                                          color: Colors.red,
                                          padding: flutter_html.HtmlPaddings
                                              .symmetric(
                                                  horizontal: 10, vertical: 5),
                                        ),
                                        "blockquote": flutter_html.Style(
                                          border: const Border(
                                              left: BorderSide(
                                                  color: Colors.grey,
                                                  width: 5.0)),
                                          margin:
                                              flutter_html.Margins.symmetric(
                                                  vertical: 10.0),
                                          padding:
                                              flutter_html.HtmlPaddings.only(
                                                  left: 10),
                                        ),
                                        "ol": flutter_html.Style(
                                          margin:
                                              flutter_html.Margins.symmetric(
                                                  horizontal: 10),
                                          padding: flutter_html.HtmlPaddings
                                              .symmetric(horizontal: 10),
                                        ),
                                        "ul": flutter_html.Style(
                                          display:
                                              flutter_html.Display.inlineBlock,
                                          padding: flutter_html.HtmlPaddings
                                              .symmetric(horizontal: 10),
                                          margin: flutter_html.Margins.all(0),
                                        ),
                                        "pre": flutter_html.Style(
                                          backgroundColor: Colors.grey[300],
                                          padding: flutter_html.HtmlPaddings
                                              .symmetric(
                                                  horizontal: 10, vertical: 5),
                                        ),
                                        "code": flutter_html.Style(
                                          display:
                                              flutter_html.Display.inlineBlock,
                                          backgroundColor: Colors.grey[300],
                                          color: Colors.red,
                                          padding: flutter_html.HtmlPaddings
                                              .symmetric(
                                                  horizontal: 10, vertical: 5),
                                        )
                                      },
                                    ),
                                    widget.files!.length == 1
                                        ? singleFile.buildSingleFile(
                                            widget.files?.first ?? '',
                                            context,
                                            platform,
                                            widget.filesName?.first ?? '')
                                        : mulitFile.buildMultipleFiles(
                                            widget.files ?? [],
                                            platform,
                                            context,
                                            widget.filesName ?? [])
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
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
                            String replyMessages = tDirectThreads![index]
                                .directthreadmsg
                                .toString();
                            String name =
                                tDirectThreads![index].name.toString();

                            List<dynamic>? files = [];
                            files = tDirectThreads![index].fileUrls;

                            List<dynamic>? fileName = [];
                            fileName = tDirectThreads![index].fileName;

                            String? profileName =
                                tDirectThreads![index].profileName;

                            if (profileName != null && !kIsWeb) {
                              profileName = MinioToIP.replaceMinioWithIP(
                                  profileName, ipAddressForMinio);
                            }

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
                            int currentUserId =
                                SessionStore.sessionData!.currentUser!.id!;

                            bool? userstatus;
                            for (var user
                                in SessionStore.sessionData!.mUsers!) {
                              if (user.name == name) {
                                userstatus = user.activeStatus;
                              }
                            }

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
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors.grey[300],
                                          ),
                                          child: Center(
                                            child: profileName == null ||
                                                    profileName.isEmpty
                                                ? const Icon(Icons.person)
                                                : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: Image.network(
                                                      profileName,
                                                      fit: BoxFit.cover,
                                                      width: 40,
                                                      height: 40,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            height: 10,
                                            width: 10,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1,
                                              ),
                                              color: userstatus == true
                                                  ? Colors.green
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(13),
                                                      bottomRight:
                                                          Radius.circular(13),
                                                      topRight:
                                                          Radius.circular(13))),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(name,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black,
                                                        )),
                                                    if (replyMessages
                                                        .isNotEmpty)
                                                      flutter_html.Html(
                                                        data: replyMessages,
                                                        style: {
                                                          ".ql-code-block": flutter_html.Style(
                                                              backgroundColor:
                                                                  Colors.grey[
                                                                      300],
                                                              padding: flutter_html
                                                                      .HtmlPaddings
                                                                  .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          5),
                                                              margin: flutter_html
                                                                      .Margins
                                                                  .symmetric(
                                                                      vertical:
                                                                          7)),
                                                          ".highlight":
                                                              flutter_html
                                                                  .Style(
                                                            display: flutter_html
                                                                .Display
                                                                .inlineBlock,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                            color: Colors.red,
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        5),
                                                          ),
                                                          "blockquote":
                                                              flutter_html
                                                                  .Style(
                                                            border: const Border(
                                                                left: BorderSide(
                                                                    color: Colors
                                                                        .grey,
                                                                    width:
                                                                        5.0)),
                                                            margin: flutter_html
                                                                    .Margins
                                                                .symmetric(
                                                                    vertical:
                                                                        10.0),
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .only(left: 10),
                                                          ),
                                                          "ol": flutter_html
                                                              .Style(
                                                            margin: flutter_html
                                                                    .Margins
                                                                .symmetric(
                                                                    horizontal:
                                                                        10),
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .symmetric(
                                                                    horizontal:
                                                                        10),
                                                          ),
                                                          "ul": flutter_html
                                                              .Style(
                                                            display: flutter_html
                                                                .Display
                                                                .inlineBlock,
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .symmetric(
                                                                    horizontal:
                                                                        10),
                                                            margin: flutter_html
                                                                .Margins.all(0),
                                                          ),
                                                          "pre": flutter_html
                                                              .Style(
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        5),
                                                          ),
                                                          "code": flutter_html
                                                              .Style(
                                                            display: flutter_html
                                                                .Display
                                                                .inlineBlock,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                            color: Colors.red,
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        5),
                                                          )
                                                        },
                                                      ),
                                                    if (files!.length == 1)
                                                      singleFile
                                                          .buildSingleFile(
                                                              files[0],
                                                              context,
                                                              platform,
                                                              fileName?.first ??
                                                                  ''),
                                                    if (files.length >= 2)
                                                      mulitFile
                                                          .buildMultipleFiles(
                                                              files,
                                                              platform,
                                                              context,
                                                              fileName ?? []),
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
                                              Column(
                                                children: [
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
                                                      IconButton(
                                                        icon: const Icon(Icons
                                                            .add_reaction_outlined),
                                                        onPressed: () async {
                                                          await showModalBottomSheet(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return EmojiPicker(
                                                                  onEmojiSelected:
                                                                      (category,
                                                                          Emoji
                                                                              emoji) async {
                                                                    setState(
                                                                        () {
                                                                      selectedEmoji =
                                                                          emoji
                                                                              .emoji;
                                                                      _seletedEmojiName =
                                                                          emoji
                                                                              .name;
                                                                      _isEmojiSelected =
                                                                          true;
                                                                    });

                                                                    await giveThreadMsgReaction(
                                                                        emoji:
                                                                            selectedEmoji,
                                                                        threadId:
                                                                            replyMessagesIds,
                                                                        selectedDirectMsgId:
                                                                            widget
                                                                                .directMsgId,
                                                                        selectedUserId:
                                                                            widget
                                                                                .receiverId,
                                                                        userId:
                                                                            currentUserId);

                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  config:
                                                                      const Config(
                                                                    height: double
                                                                        .maxFinite,
                                                                    checkPlatformCompatibility:
                                                                        true,
                                                                    emojiViewConfig:
                                                                        EmojiViewConfig(
                                                                      emojiSizeMax:
                                                                          23,
                                                                    ),
                                                                    swapCategoryAndBottomBar:
                                                                        false,
                                                                    skinToneConfig:
                                                                        SkinToneConfig(),
                                                                    categoryViewConfig:
                                                                        CategoryViewConfig(),
                                                                    bottomActionBarConfig:
                                                                        BottomActionBarConfig(),
                                                                    searchViewConfig:
                                                                        SearchViewConfig(),
                                                                  ),
                                                                );
                                                              });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      if (currentUserName ==
                                                          name)
                                                        IconButton(
                                                          onPressed: () async {
                                                            await deleteReply(
                                                                replyMessagesIds);
                                                          },
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            size: 20,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      IconButton(
                                                          onPressed: () {
                                                            _clearEditor();
                                                            setState(() {
                                                              isEdit = true;
                                                            });
                                                            editMsg =
                                                                replyMessages;
                                                            editMsgId =
                                                                replyMessagesIds;

                                                            if (!(editMsg.contains(
                                                                "<br/><div class='ql-code-block'>"))) {
                                                              if (editMsg.contains(
                                                                  "<div class='ql-code-block'>")) {
                                                                editMsg = editMsg
                                                                    .replaceAll(
                                                                        "<div class='ql-code-block'>",
                                                                        "<br/><div class='ql-code-block'>");
                                                              }
                                                            }

                                                            if (!(editMsg.contains(
                                                                "<br/><blockquote>"))) {
                                                              if (editMsg.contains(
                                                                  "<blockquote>")) {
                                                                editMsg = editMsg
                                                                    .replaceAll(
                                                                        "<blockquote>",
                                                                        "<br/><blockquote>");
                                                              }
                                                            }

                                                            insertEditText(
                                                                editMsg);
                                                            // Request focusr
                                                            WidgetsBinding
                                                                .instance
                                                                .addPostFrameCallback(
                                                                    (_) {
                                                              _focusNode
                                                                  .requestFocus();
                                                              _quilcontroller
                                                                  .addListener(
                                                                      _onSelectionChanged);
                                                              // move cursor to end
                                                              final length =
                                                                  _quilcontroller
                                                                      .document
                                                                      .length;
                                                              _quilcontroller
                                                                  .updateSelection(
                                                                TextSelection
                                                                    .collapsed(
                                                                        offset:
                                                                            length),
                                                                ChangeSource
                                                                    .local,
                                                              );
                                                            });
                                                          },
                                                          icon: const Icon(
                                                              Icons.edit)),
                                                    ],
                                                  )
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 300,
                                          child: Wrap(
                                              direction: Axis.horizontal,
                                              spacing: 7,
                                              children: List.generate(
                                                  emojiCounts!.length, (index) {
                                                List userIds = [];
                                                List userNames = [];

                                                if (emojiCounts![index]
                                                        .directThreadId ==
                                                    replyMessagesIds) {
                                                  for (dynamic reactUser
                                                      in reactUserDatas!) {
                                                    if (reactUser
                                                                .directThreadId ==
                                                            emojiCounts![index]
                                                                .directThreadId &&
                                                        emojiCounts![index]
                                                                .emoji ==
                                                            reactUser.emoji) {
                                                      userIds.add(
                                                          reactUser.userId);
                                                      userNames
                                                          .add(reactUser.name);
                                                    }
                                                  } //reactUser for loop end
                                                }
                                                for (int i = 0;
                                                    i < emojiCounts!.length;
                                                    i++) {
                                                  if (emojiCounts![i]
                                                          .directThreadId ==
                                                      replyMessagesIds) {
                                                    for (int j = 0;
                                                        j <
                                                            reactUserDatas!
                                                                .length;
                                                        j++) {
                                                      if (userIds.contains(
                                                          reactUserDatas![j]
                                                              .userId)) {
                                                        return Container(
                                                          width: 50,
                                                          height: 25,
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        16),
                                                            border: Border.all(
                                                              color: userIds
                                                                      .contains(
                                                                          currentUserId)
                                                                  ? Colors.green
                                                                  : Colors
                                                                      .red, // Use emojiBorderColor here
                                                              width: 1,
                                                            ),
                                                            color:
                                                                Color.fromARGB(
                                                                    226,
                                                                    212,
                                                                    234,
                                                                    250),
                                                          ),
                                                          padding:
                                                              EdgeInsets.zero,
                                                          child: TextButton(
                                                            onPressed:
                                                                () async {
                                                              setState(() {
                                                                _isEmojiSelected =
                                                                    false;
                                                              });
                                                              HapticFeedback
                                                                  .vibrate();

                                                              await giveThreadMsgReaction(
                                                                  emoji: emojiCounts![
                                                                          index]
                                                                      .emoji!,
                                                                  threadId:
                                                                      replyMessagesIds,
                                                                  selectedDirectMsgId:
                                                                      widget
                                                                          .directMsgId,
                                                                  selectedUserId:
                                                                      widget
                                                                          .receiverId,
                                                                  userId:
                                                                      currentUserId);
                                                            },
                                                            onLongPress:
                                                                () async {
                                                              HapticFeedback
                                                                  .heavyImpact();
                                                              await showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
                                                                  return SimpleDialog(
                                                                    title:
                                                                        const Center(
                                                                      child:
                                                                          Text(
                                                                        "People Who React",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                20),
                                                                      ),
                                                                    ),
                                                                    children: [
                                                                      SizedBox(
                                                                        width: MediaQuery.of(context)
                                                                            .size
                                                                            .width,
                                                                        child: ListView
                                                                            .builder(
                                                                          shrinkWrap:
                                                                              true,
                                                                          itemBuilder:
                                                                              (ctx, index) {
                                                                            return SingleChildScrollView(
                                                                              child: SimpleDialogOption(
                                                                                onPressed: () => Navigator.pop(context),
                                                                                child: Center(
                                                                                  child: Text(
                                                                                    "${userNames[index]}",
                                                                                    style: const TextStyle(fontSize: 18, letterSpacing: 0.1),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                          itemCount:
                                                                              userNames.length,
                                                                        ),
                                                                      )
                                                                    ],
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            style: ButtonStyle(
                                                              padding:
                                                                  WidgetStateProperty.all(
                                                                      EdgeInsets
                                                                          .zero),
                                                              minimumSize:
                                                                  WidgetStateProperty.all(
                                                                      const Size(
                                                                          50,
                                                                          25)),
                                                            ),
                                                            child: Text(
                                                              '${emojiCounts![index].emoji} ${emojiCounts![index].emojiCount}',
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .blueAccent,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  }
                                                }
                                                return Container();
                                              })),
                                        )
                                      ],
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
                                if (isEdit)
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        margin: const EdgeInsets.fromLTRB(
                                            0, 0, 10, 0),
                                        decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        child: IconButton(
                                            color: Colors.white,
                                            onPressed: () {
                                              // _quilcontroller.clear();
                                              _clearEditor();
                                              SystemChannels.textInput.invokeMethod(
                                                  'TextInput.hide'); // Hide the keyboard
                                              setState(() {
                                                isEdit = false;
                                              });
                                            },
                                            icon: const Icon(Icons.close)),
                                      ),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        margin: const EdgeInsets.fromLTRB(
                                            0, 0, 10, 0),
                                        decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        child: IconButton(
                                            color: Colors.white,
                                            onPressed: () {
                                              htmlContent = detectStyles();

                                              if (htmlContent.contains("<p>")) {
                                                htmlContent = htmlContent
                                                    .replaceAll("<p>", "");
                                                htmlContent = htmlContent
                                                    .replaceAll("</p>", "");
                                              }

                                              if (htmlContent
                                                  .contains("<code>")) {
                                                htmlContent =
                                                    htmlContent.replaceAll(
                                                        "<code>",
                                                        "<span class='highlight'>");
                                                htmlContent =
                                                    htmlContent.replaceAll(
                                                        "</code>", "</span>");
                                              }

                                              if (htmlContent
                                                  .contains("<pre>")) {
                                                htmlContent =
                                                    htmlContent.replaceAll(
                                                        "<pre>",
                                                        "<div class='ql-code-block'>");
                                                htmlContent =
                                                    htmlContent.replaceAll(
                                                        "</pre>", "</div>");
                                                htmlContent = htmlContent
                                                    .replaceAll("\n", "<br/>");
                                              }

                                              editdirectThreadMessage(
                                                  htmlContent, editMsgId!);
                                              _clearEditor();
                                              SystemChannels.textInput.invokeMethod(
                                                  'TextInput.hide'); // Hide the keyboard
                                            },
                                            icon: const Icon(Icons.check)),
                                      ),
                                    ],
                                  )
                                else
                                  Container(
                                    width: 40,
                                    height: 40,
                                    margin:
                                        const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 24, 103, 167),
                                        borderRadius: BorderRadius.circular(5)),
                                    child: IconButton(
                                        onPressed: () {
                                          htmlContent = detectStyles();

                                          if (htmlContent.contains("<p>")) {
                                            htmlContent = htmlContent
                                                .replaceAll("<p>", "");
                                            htmlContent = htmlContent
                                                .replaceAll("</p>", "");
                                          }

                                          if (htmlContent.contains("<code>")) {
                                            htmlContent =
                                                htmlContent.replaceAll("<code>",
                                                    "<span class='highlight'>");
                                            htmlContent =
                                                htmlContent.replaceAll(
                                                    "</code>", "</span>");
                                          }

                                          if (htmlContent.contains("<pre>")) {
                                            htmlContent = htmlContent.replaceAll(
                                                "<pre>",
                                                "<div class='ql-code-block'>");
                                            htmlContent = htmlContent
                                                .replaceAll("</pre>", "</div>");
                                            htmlContent = htmlContent
                                                .replaceAll("\n", "<br/>");
                                          }

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
                          visible: isSelectText || isClickedTextFormat
                              ? true
                              : false,
                          child: Container(
                            color: Colors.grey[300],
                            padding:
                                const EdgeInsets.fromLTRB(8.0, 0, 8.0, 10.0),
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
                                            icon:
                                                const Icon(Icons.format_italic),
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
                                            icon: const Icon(
                                                Icons.strikethrough_s),
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
                                                    quill.Attribute
                                                        .strikeThrough);
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
                                                  discode = false;
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
                                                        quill.Attribute
                                                            .blockQuote,
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
                                          child: discode
                                              ? const IconButton(
                                                  onPressed: null,
                                                  icon: Icon(Icons.code))
                                              : IconButton(
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
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                              .Attribute
                                                              .inlineCode);
                                                    } else {
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                                  .Attribute
                                                              .clone(
                                                                  quill
                                                                      .Attribute
                                                                      .inlineCode,
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
                                                  discode = false;
                                                } else {
                                                  isBlockquote = false;
                                                  isOrderList = false;
                                                  isUnorderList = false;
                                                  isCodeblock = true;
                                                  isCode = false;
                                                  discode = true;
                                                }
                                              });
                                              if (isCodeblock) {
                                                _quilcontroller.formatSelection(
                                                    quill.Attribute.codeBlock);
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
                                                            .inlineCode,
                                                        null));
                                                _quilcontroller.formatSelection(
                                                    quill.Attribute.clone(
                                                        quill.Attribute
                                                            .strikeThrough,
                                                        null));
                                              } else {
                                                _quilcontroller.formatSelection(
                                                    quill.Attribute.clone(
                                                        quill.Attribute
                                                            .codeBlock,
                                                        null));
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isEdit)
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        margin: const EdgeInsets.fromLTRB(
                                            15, 0, 10, 0),
                                        decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        child: IconButton(
                                            color: Colors.white,
                                            onPressed: () {
                                              // _quilcontroller.clear();
                                              _clearEditor();
                                              SystemChannels.textInput.invokeMethod(
                                                  'TextInput.hide'); // Hide the keyboard
                                              setState(() {
                                                isEdit = false;
                                              });
                                            },
                                            icon: const Icon(Icons.close)),
                                      ),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        margin: const EdgeInsets.fromLTRB(
                                            0, 0, 10, 0),
                                        decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        child: IconButton(
                                            color: Colors.white,
                                            onPressed: () {
                                              htmlContent = detectStyles();

                                              if (htmlContent.contains("<p>")) {
                                                htmlContent = htmlContent
                                                    .replaceAll("<p>", "");
                                                htmlContent = htmlContent
                                                    .replaceAll("</p>", "");
                                              }

                                              if (htmlContent
                                                  .contains("<code>")) {
                                                htmlContent =
                                                    htmlContent.replaceAll(
                                                        "<code>",
                                                        "<span class='highlight'>");
                                                htmlContent =
                                                    htmlContent.replaceAll(
                                                        "</code>", "</span>");
                                              }

                                              if (htmlContent
                                                  .contains("<pre>")) {
                                                htmlContent =
                                                    htmlContent.replaceAll(
                                                        "<pre>",
                                                        "<div class='ql-code-block'>");
                                                htmlContent =
                                                    htmlContent.replaceAll(
                                                        "</pre>", "</div>");
                                                htmlContent = htmlContent
                                                    .replaceAll("\n", "<br/>");
                                              }

                                              editdirectThreadMessage(
                                                  htmlContent, editMsgId!);
                                              _clearEditor();
                                              SystemChannels.textInput.invokeMethod(
                                                  'TextInput.hide'); // Hide the keyboard
                                            },
                                            icon: const Icon(Icons.check)),
                                      ),
                                    ],
                                  )
                                else
                                  Container(
                                    width: 40,
                                    height: 40,
                                    margin:
                                        const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 24, 103, 167),
                                        borderRadius: BorderRadius.circular(5)),
                                    child: IconButton(
                                        onPressed: () {
                                          htmlContent = detectStyles();

                                          if (htmlContent.contains("<p>")) {
                                            htmlContent = htmlContent
                                                .replaceAll("<p>", "");
                                            htmlContent = htmlContent
                                                .replaceAll("</p>", "");
                                          }

                                          if (htmlContent.contains("<code>")) {
                                            htmlContent =
                                                htmlContent.replaceAll("<code>",
                                                    "<span class='highlight'>");
                                            htmlContent =
                                                htmlContent.replaceAll(
                                                    "</code>", "</span>");
                                          }

                                          if (htmlContent.contains("<pre>")) {
                                            htmlContent = htmlContent.replaceAll(
                                                "<pre>",
                                                "<div class='ql-code-block'>");
                                            htmlContent = htmlContent
                                                .replaceAll("</pre>", "</div>");
                                            htmlContent = htmlContent
                                                .replaceAll("\n", "<br/>");
                                          }

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
                  ]),
                  if (showScrollButton)
                    Positioned(
                      bottom: isCursor ? 120 : 60,
                      left: 145,
                      child: IconButton(
                        onPressed: () {
                          _scrollToBottom();
                          setState(() {
                            showScrollButton = false;
                          });
                        },
                        icon: const CircleAvatar(
                          backgroundColor: Color.fromARGB(117, 0, 0, 0),
                          radius: 25,
                          child: Icon(
                            Icons.arrow_downward,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                ]));
    }
  }
}
