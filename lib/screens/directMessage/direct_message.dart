import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/const/build_fiile.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/customLoadingForMesaging.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:flutter_quill/quill_delta.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';

import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/direct_message.dart';
import 'package:flutter_frontend/services/directMessage/direct_message_api.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/screens/directThreadMessage/direct_message_thread.dart';
import 'package:flutter_frontend/services/directMessage/directMessage/direct_meessages.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum SampleItem { itemOne, itemTwo, itemThree }

class DirectMessageWidget extends StatefulWidget {
  final int userId;
  final String receiverName;
  final user_status;
  final String? profileImage;
  final bool? activeStatus;

  const DirectMessageWidget(
      {Key? key,
      required this.userId,
      this.user_status,
      required this.receiverName,
      this.profileImage,
      this.activeStatus})
      : super(key: key);

  @override
  State<DirectMessageWidget> createState() => _DirectMessageWidgetState();
}

class _DirectMessageWidgetState extends State<DirectMessageWidget> {
  final DirectMessageService directMessageService = DirectMessageService();
  final TextEditingController messageTextController = TextEditingController();
  String currentUserName =
      SessionStore.sessionData!.currentUser!.name.toString();
  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
  List<TDirectMessages>? tDirectMessages = [];
  List<TempDirectStarMsgids>? tempDirectStarMsgids = [];
// ---------
  List<TDirectMsgEmojiCounts>? emojiCounts = [];
  List<ReactUserDataForDirectMsg>? reactUserData = [];
// -------------
  List<int>? tempStarMsgids = [];
  WebSocketChannel? _channel;
  late ScrollController _scrollController;
  BuildMulitFile mulitFile = BuildMulitFile();
  BuildSingleFile singleFile = BuildSingleFile();

  String selectedEmoji = "";
  final String _seletedEmojiName = "";
  bool _isEmojiSelected = false;
  bool emojiBorderColor = false;
  bool showScrollButton = false;
  bool isScrolling = false;
  bool isMessaging = false;
  bool isLoading = false;
  final _apiService = ApiService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  bool isreading = false;
  bool isSelected = false;
  bool isStarred = false;
  int? _selectedMessageIndex;
  int? selectUserId;
  bool hasFileToSEnd = false;
  List<PlatformFile> files = [];
  late String localpath;
  late bool permissionReady;
  TargetPlatform? platform;
  final PermissionClass permissions = PermissionClass();
  String? fileText;

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
  List _previousOps = [];
  String editMsg = "";
  bool? currentUserActiveStatus =
      SessionStore.sessionData!.currentUser!.activeStatus;

  @override
  void initState() {
    super.initState();
    loadMessages();
    connectWebSocket();
    _scrollController = ScrollController();
    _scrollController.addListener(scrollListener);
    _quilcontroller.addListener(_onSelectionChanged);
    _focusNode.addListener(_focusChange);
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
    _quilcontroller.removeListener(_onSelectionChanged);
    _focusNode.removeListener(_focusChange);
    _channel!.sink.close();
    _scrollController.dispose();
    _scrollController.removeListener(scrollListener);
  }

  void connectWebSocket() {
    var url =
        'ws://$wsUrl/cable?user_id=$currentUserId&s_user_id=${widget.userId}';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ChatChannel'}),
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
                  msg.containsKey('directmsg') &&
                  ((msg['send_user_id'] == currentUserId &&
                          msg['receive_user_id'] == widget.userId) ||
                      (msg['send_user_id'] == widget.userId &&
                          msg['receive_user_id'] == currentUserId))) {
                var directmsg = msg['directmsg'];
                int id = msg['id'];
                var date = msg['created_at'];
                String send = messageContent['sender_name'];
                List<dynamic> fileUrls = [];

                List<dynamic> fileName = [];

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
                  tDirectMessages!.add(TDirectMessages(
                      id: id,
                      directmsg: directmsg,
                      createdAt: date,
                      name: send,
                      fileUrls: fileUrls,
                      fileName: fileName));
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
                var starId = messageStarData['id'];
                var directMsgId = messageStarData['directmsgid'];

                setState(() {
                  tempDirectStarMsgids!.add(TempDirectStarMsgids(
                      directmsgid: directMsgId, id: starId));
                  tempStarMsgids!.add(directMsgId);
                });
              } else {}
            } else if (messageContent.containsKey('unstared_message') &&
                messageContent['unstared_message']['userid'] == currentUserId) {
              var unstaredMsg = messageContent['unstared_message'];
              var directmsgid = unstaredMsg['directmsgid'];

              setState(() {
                tempStarMsgids
                    ?.removeWhere((element) => element == directmsgid);
                tempDirectStarMsgids?.removeWhere(
                    (element) => element.directmsgid == directmsgid);
              });
            } else if (messageContent.containsKey('react_message')) {
              var reactmsg = messageContent['react_message'];
              var userId = reactmsg['userid'];
              var directmsgid = reactmsg['directmsgid'];
              var emoji = reactmsg['emoji'];
              var emojiCount;
              bool emojiExists = false;
              for (var element in emojiCounts!) {
                if (element.emoji == emoji &&
                    element.directmsgid == directmsgid) {
                  emojiCount = element.emojiCount! + 1;
                  element.emojiCount = emojiCount;
                  emojiExists = true;
                  break;
                }
              }
              if (!emojiExists) {
                emojiCount = 1;
                emojiCounts!.add(TDirectMsgEmojiCounts(
                    directmsgid: directmsgid,
                    emoji: emoji,
                    emojiCount: emojiCount));
              }

              var reactUserInfo = messageContent['reacted_user_info'];

              setState(() {
                if (emojiExists) {
                  emojiCounts!.add(TDirectMsgEmojiCounts(
                      directmsgid: directmsgid, emojiCount: emojiCount));
                }
                reactUserData!.add(ReactUserDataForDirectMsg(
                    directmsgid: directmsgid,
                    emoji: emoji,
                    name: reactUserInfo,
                    userId: userId));
              });
            } else if (messageContent.containsKey('remove_reaction')) {
              var deleteRection = messageContent['remove_reaction'];
              var directmsgid = deleteRection['directmsgid'];
              var emoji = deleteRection['emoji'];
              var reactUserInfo = messageContent['reacted_user_info'];
              setState(() {
                for (var element in emojiCounts!) {
                  if (element.emoji == emoji &&
                      element.directmsgid == directmsgid) {
                    element.emojiCount = element.emojiCount! - 1;
                    break;
                  }
                }
                reactUserData!.removeWhere((user) =>
                    user.emoji == emoji &&
                    user.directmsgid == directmsgid &&
                    user.name == reactUserInfo);
              });
            } else if (messageContent.containsKey('update_message')) {
              var updatemsg = messageContent['update_message'];
              var directmsg = updatemsg['directmsg'];

              int id = updatemsg['id'];
              var date = updatemsg['created_at'];
              String send = messageContent['sender_name'];
              List<dynamic> fileUrls = [];
              List<dynamic> fileName = [];

              tDirectMessages!.removeWhere((e) => e.id == updatemsg['id']);
              setState(() {
                tDirectMessages!.add(TDirectMessages(
                    id: id,
                    directmsg: directmsg,
                    createdAt: date,
                    name: send,
                    fileUrls: fileUrls,
                    fileName: fileName));
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (isMessaging == false) {
                    _scrollToBottom();
                  }
                });
              });
            } else {
              var deletemsg = messageContent['delete_msg'];
              var id = deletemsg['id'];
              var directmsg = deletemsg['directmsg'];
              setState(() {
                tDirectMessages?.removeWhere((element) => element.id == id);
              });
            }
          }
        } catch (e) {
          rethrow;
        }
      },
      onDone: () {
        _channel!.sink.close();
      },
      onError: (error) {},
    );
  }

  Future<void> loadMessages() async {
    var token = await getToken();
    try {
      DirectMessages messagess = await _apiService.getAllDirectMessages(
          widget.userId, token.toString());

      setState(() {
        tDirectMessages = messagess.tDirectMessages;
        tempDirectStarMsgids = messagess.tempDirectStarMsgids;
        tempStarMsgids = messagess.tDirectStarMsgids;
        emojiCounts = messagess.tDirectMsgEmojiCounts;
        reactUserData = messagess.reactUsernames;
        isLoading = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      });
    } catch (e) {
      rethrow;
    }
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

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 300,
      duration: const Duration(milliseconds: 100),
      curve: Curves.ease,
    );
  }

  Future<void> sendMessage(htmlContent) async {
    if (htmlContent.isNotEmpty || files.isNotEmpty) {
      try {
        await directMessageService.sendDirectMessage(
            widget.userId, htmlContent.trimRight(), files);
        files.clear();
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<String?> getToken() async {
    return await AuthController().getToken();
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
    if (cursorPosition == 0) {
      return;
    }

    final doc = _quilcontroller.document;
    final text = doc.toPlainText();
    final wordRange = _getWordRangeAtCursor(text, cursorPosition);
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
    return Scaffold(
      backgroundColor: kPriamrybackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            setState(() {
              isreading = !isreading;
            });
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const Nav()));
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        backgroundColor: navColor,
        title: Row(
          children: [
            Stack(children: [
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
                          borderRadius: BorderRadius.circular(10),
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
                    color: widget.activeStatus == true
                        ? Colors.green
                        : Colors.black,
                  ),
                ),
              ),
            ]),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.receiverName.toUpperCase()}",
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
      body: isLoading == false
          ? const Shimmers()
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                        child: ListView.builder(
                      controller: _scrollController,
                      itemCount: tDirectMessages!.length,
                      itemBuilder: (context, index) {
                        if (tDirectMessages == null ||
                            tDirectMessages!.isEmpty) {
                          return Container();
                        }

                        var channelStar = tDirectMessages!;

                        List<dynamic>? files = [];
                        files = tDirectMessages![index].fileUrls;

                        List<dynamic>? fileNames = [];
                        fileNames = tDirectMessages![index].fileName;

                        String? profileImage =
                            tDirectMessages![index].profileName;

                        if (profileImage != null && !kIsWeb) {
                          profileImage = MinioToIP.replaceMinioWithIP(
                              profileImage, ipAddressForMinio);
                        }

                        bool? activeStatus;
                        for (var user in SessionStore.sessionData!.mUsers!) {
                          if (user.name == channelStar[index].name) {
                            activeStatus = user.activeStatus;
                          }
                        }

                        List<int> tempStar = tempStarMsgids?.toList() ?? [];
                        bool isStared =
                            tempStar.contains(channelStar[index].id);

                        String message = channelStar[index].directmsg ?? "";

                        int count = channelStar[index].count ?? 0;
                        String time = channelStar[index].createdAt.toString();
                        DateTime date = DateTime.parse(time).toLocal();

                        String created_at =
                            DateFormat('MMM d, yyyy hh:mm a').format(date);
                        bool isMessageFromCurrentUser =
                            currentUserName == channelStar[index].name;
                        int directMsgIds = channelStar[index].id ?? 0;

                        return SingleChildScrollView(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedMessageIndex = channelStar[index].id;
                                isSelected = !isSelected;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isMessageFromCurrentUser)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (_selectedMessageIndex ==
                                                channelStar[index].id &&
                                            !isSelected)
                                          Align(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        IconButton(
                                                          onPressed: () async {
                                                            if (_selectedMessageIndex !=
                                                                null) {
                                                              await directMessageService
                                                                  .deleteMsg(
                                                                      _selectedMessageIndex!);
                                                            }
                                                          },
                                                          icon: const Icon(
                                                              Icons.delete),
                                                          color: Colors.red,
                                                        ),
                                                        IconButton(
                                                          onPressed: () async {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder: (_) =>
                                                                        DirectMessageThreadWidget(
                                                                          userstatus:
                                                                              currentUserActiveStatus,
                                                                          receiverId:
                                                                              widget.userId,
                                                                          directMsgId:
                                                                              directMsgIds,
                                                                          receiverName:
                                                                              widget.receiverName,
                                                                          files:
                                                                              files,
                                                                          profileImage:
                                                                              profileImage,
                                                                          filesName:
                                                                              fileNames,
                                                                        )));
                                                          },
                                                          icon: const Icon(
                                                              Icons.reply),
                                                          color: const Color
                                                              .fromARGB(
                                                              255, 15, 15, 15),
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.star,
                                                            color: isStared
                                                                ? Colors.yellow
                                                                : Colors.grey,
                                                          ),
                                                          onPressed: () async {
                                                            if (_selectedMessageIndex !=
                                                                null) {
                                                              if (isStared) {
                                                                await directMessageService
                                                                    .directUnStarMsg(
                                                                        _selectedMessageIndex!);
                                                              } else {
                                                                await directMessageService
                                                                    .directStarMsg(
                                                                        widget
                                                                            .userId,
                                                                        _selectedMessageIndex!);
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                            onPressed:
                                                                () async {
                                                              showModalBottomSheet(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
                                                                  return EmojiPicker(
                                                                    onEmojiSelected:
                                                                        (category,
                                                                            Emoji
                                                                                emoji) {
                                                                      setState(
                                                                          () {
                                                                        selectedEmoji =
                                                                            emoji.emoji;

                                                                        _isEmojiSelected =
                                                                            true;
                                                                      });

                                                                      directMessageService.directReactMsg(
                                                                          selectedEmoji,
                                                                          directMsgIds,
                                                                          widget
                                                                              .userId,
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
                                                                },
                                                              );
                                                            },
                                                            icon: const Icon(
                                                              Icons
                                                                  .add_reaction_outlined,
                                                            )),
                                                        IconButton(
                                                            onPressed: () {
                                                              _clearEditor();
                                                              setState(() {
                                                                isEdit = true;
                                                              });
                                                              editMsg = message;

                                                              if (!(editMsg
                                                                  .contains(
                                                                      "<br/><div class='ql-code-block'>"))) {
                                                                if (editMsg
                                                                    .contains(
                                                                        "<div class='ql-code-block'>")) {
                                                                  editMsg = editMsg
                                                                      .replaceAll(
                                                                          "<div class='ql-code-block'>",
                                                                          "<br/><div class='ql-code-block'>");
                                                                }
                                                              }

                                                              if (!(editMsg
                                                                  .contains(
                                                                      "<br/><blockquote>"))) {
                                                                if (editMsg
                                                                    .contains(
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
                                                ),
                                              ),
                                            ),
                                          ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                  bottomLeft:
                                                      Radius.circular(10),
                                                  bottomRight: Radius.zero,
                                                ),
                                                color: Color.fromARGB(
                                                    110, 121, 120, 124),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    if (message.isNotEmpty)
                                                      flutter_html.Html(
                                                        data: message,
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
                                                                .Margins.all(0),
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
                                                              fileNames
                                                                      ?.first ??
                                                                  ''),
                                                    if (files.length >= 2)
                                                      mulitFile
                                                          .buildMultipleFiles(
                                                              files,
                                                              platform,
                                                              context,
                                                              fileNames ?? []),
                                                    const SizedBox(height: 8),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      created_at,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Color.fromARGB(
                                                            255, 15, 15, 15),
                                                      ),
                                                    ),
                                                    RichText(
                                                      text: TextSpan(
                                                        text: '$count',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color.fromARGB(
                                                              255, 15, 15, 15),
                                                        ),
                                                        children: const [
                                                          WidgetSpan(
                                                            child: Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      left:
                                                                          4.0),
                                                              child: Icon(
                                                                  Icons.reply),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              child: Wrap(
                                                  direction: Axis.horizontal,
                                                  spacing: 7,
                                                  children: List.generate(
                                                      emojiCounts!.length,
                                                      (index) {
                                                    bool show = false;
                                                    List userIds = [];
                                                    List reactUsernames = [];

                                                    if (emojiCounts![index]
                                                            .directmsgid ==
                                                        directMsgIds) {
                                                      for (dynamic reactUser
                                                          in reactUserData!) {
                                                        if (reactUser
                                                                    .directmsgid ==
                                                                emojiCounts![
                                                                        index]
                                                                    .directmsgid &&
                                                            emojiCounts![index]
                                                                    .emoji ==
                                                                reactUser
                                                                    .emoji) {
                                                          userIds.add(
                                                              reactUser.userId);
                                                          reactUsernames.add(
                                                              reactUser.name);
                                                        }
                                                      } //reactUser for loop end

                                                      if (userIds.contains(
                                                          currentUserId)) {
                                                        Container();
                                                      }
                                                    }
                                                    for (int i = 0;
                                                        i < emojiCounts!.length;
                                                        i++) {
                                                      if (emojiCounts![i]
                                                              .directmsgid ==
                                                          directMsgIds) {
                                                        for (int j = 0;
                                                            j <
                                                                reactUserData!
                                                                    .length;
                                                            j++) {
                                                          if (userIds.contains(
                                                              reactUserData![j]
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
                                                                border:
                                                                    Border.all(
                                                                  color: userIds
                                                                          .contains(
                                                                              currentUserId)
                                                                      ? Colors
                                                                          .green
                                                                      : Colors
                                                                          .red, // Use emojiBorderColor here
                                                                  width: 1,
                                                                ),
                                                                color: const Color
                                                                    .fromARGB(
                                                                    226,
                                                                    212,
                                                                    234,
                                                                    250),
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              child: TextButton(
                                                                onPressed:
                                                                    () async {
                                                                  setState(() {
                                                                    _isEmojiSelected =
                                                                        false;
                                                                  });
                                                                  HapticFeedback
                                                                      .vibrate();
                                                                  directMessageService.directReactMsg(
                                                                      emojiCounts![
                                                                              index]
                                                                          .emoji!,
                                                                      directMsgIds,
                                                                      widget
                                                                          .userId,
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
                                                                              style: TextStyle(fontSize: 20),
                                                                            ),
                                                                          ),
                                                                          children: [
                                                                            SizedBox(
                                                                              width: MediaQuery.of(context).size.width,
                                                                              child: ListView.builder(
                                                                                shrinkWrap: true,
                                                                                itemCount: reactUsernames.length,
                                                                                itemBuilder: (context, index) {
                                                                                  return SingleChildScrollView(
                                                                                      child: SimpleDialogOption(
                                                                                    onPressed: () => Navigator.pop(context),
                                                                                    child: Center(
                                                                                      child: Text(
                                                                                        "${reactUsernames[index]}",
                                                                                        style: const TextStyle(fontSize: 18, letterSpacing: 0.1),
                                                                                      ),
                                                                                    ),
                                                                                  ));
                                                                                },
                                                                              ),
                                                                            )
                                                                          ],
                                                                        );
                                                                      });
                                                                },
                                                                style:
                                                                    ButtonStyle(
                                                                  padding: WidgetStateProperty.all(
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
                                                                    fontSize:
                                                                        14,
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
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                  bottomRight:
                                                      Radius.circular(10),
                                                  bottomLeft: Radius.zero,
                                                ),
                                                color: Color.fromARGB(
                                                    111, 113, 81, 228),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (message.isNotEmpty)
                                                      flutter_html.Html(
                                                        data: message,
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
                                                                .Margins.all(0),
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
                                                    if (files != null &&
                                                        files.isNotEmpty)
                                                      ...files.length == 1
                                                          ? [
                                                              singleFile
                                                                  .buildSingleFile(
                                                                      files
                                                                          .first,
                                                                      context,
                                                                      platform,
                                                                      fileNames
                                                                              ?.first ??
                                                                          '')
                                                            ]
                                                          : [
                                                              mulitFile
                                                                  .buildMultipleFiles(
                                                                      files,
                                                                      platform,
                                                                      context,
                                                                      fileNames ??
                                                                          [])
                                                            ],
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      created_at,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    RichText(
                                                      text: TextSpan(
                                                        text: '$count',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color.fromARGB(
                                                              255, 15, 15, 15),
                                                        ),
                                                        children: const [
                                                          WidgetSpan(
                                                            child: Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      left:
                                                                          4.0),
                                                              child: Icon(
                                                                  Icons.reply),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (_selectedMessageIndex ==
                                                    channelStar[index].id &&
                                                !isSelected)
                                              Align(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(3.0),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 8),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.star,
                                                            color: isStared
                                                                ? Colors.yellow
                                                                : Colors.grey,
                                                          ),
                                                          onPressed: () async {
                                                            if (_selectedMessageIndex !=
                                                                null) {
                                                              if (isStared) {
                                                                await directMessageService
                                                                    .directUnStarMsg(
                                                                        _selectedMessageIndex!);
                                                              } else {
                                                                await directMessageService
                                                                    .directStarMsg(
                                                                        widget
                                                                            .userId,
                                                                        _selectedMessageIndex!);
                                                              }
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          onPressed: () async {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder: (_) =>
                                                                        DirectMessageThreadWidget(
                                                                          userstatus:
                                                                              widget.user_status,
                                                                          receiverId:
                                                                              widget.userId,
                                                                          directMsgId:
                                                                              directMsgIds,
                                                                          receiverName:
                                                                              widget.receiverName,
                                                                          files:
                                                                              files,
                                                                          profileImage:
                                                                              profileImage,
                                                                          filesName:
                                                                              fileNames,
                                                                        )));
                                                          },
                                                          icon: const Icon(
                                                              Icons.reply),
                                                          color: const Color
                                                              .fromARGB(
                                                              255, 15, 15, 15),
                                                        ),
                                                        IconButton(
                                                            onPressed:
                                                                () async {
                                                              showModalBottomSheet(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
                                                                  return EmojiPicker(
                                                                    onEmojiSelected:
                                                                        (category,
                                                                            Emoji
                                                                                emoji) {
                                                                      setState(
                                                                          () {
                                                                        selectedEmoji =
                                                                            emoji.emoji;

                                                                        _isEmojiSelected =
                                                                            true;
                                                                      });

                                                                      directMessageService.directReactMsg(
                                                                          selectedEmoji,
                                                                          directMsgIds,
                                                                          widget
                                                                              .userId,
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
                                                                },
                                                              );
                                                            },
                                                            icon: const Icon(Icons
                                                                .add_reaction_outlined))
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          child: Wrap(
                                              direction: Axis.horizontal,
                                              spacing: 7,
                                              children: List.generate(
                                                  emojiCounts!.length, (index) {
                                                bool show = false;
                                                List userIds = [];
                                                List reactUsernames = [];

                                                if (emojiCounts![index]
                                                        .directmsgid ==
                                                    directMsgIds) {
                                                  for (dynamic reactUser
                                                      in reactUserData!) {
                                                    if (reactUser.directmsgid ==
                                                            emojiCounts![index]
                                                                .directmsgid &&
                                                        emojiCounts![index]
                                                                .emoji ==
                                                            reactUser.emoji) {
                                                      userIds.add(
                                                          reactUser.userId);
                                                      reactUsernames
                                                          .add(reactUser.name);
                                                    }
                                                  } //reactUser for loop end

                                                  if (userIds.contains(
                                                      currentUserId)) {
                                                    Container();
                                                  }
                                                }
                                                for (int i = 0;
                                                    i < emojiCounts!.length;
                                                    i++) {
                                                  if (emojiCounts![i]
                                                          .directmsgid ==
                                                      directMsgIds) {
                                                    for (int j = 0;
                                                        j <
                                                            reactUserData!
                                                                .length;
                                                        j++) {
                                                      if (userIds.contains(
                                                          reactUserData![j]
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
                                                            color: const Color
                                                                .fromARGB(226,
                                                                212, 234, 250),
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
                                                              directMessageService.directReactMsg(
                                                                  emojiCounts![
                                                                          index]
                                                                      .emoji!,
                                                                  directMsgIds,
                                                                  widget.userId,
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
                                                                          style:
                                                                              TextStyle(fontSize: 20),
                                                                        ),
                                                                      ),
                                                                      children: [
                                                                        SizedBox(
                                                                          width: MediaQuery.of(context)
                                                                              .size
                                                                              .width,
                                                                          child:
                                                                              ListView.builder(
                                                                            shrinkWrap:
                                                                                true,
                                                                            itemCount:
                                                                                reactUsernames.length,
                                                                            itemBuilder:
                                                                                (context, index) {
                                                                              return SingleChildScrollView(
                                                                                  child: SimpleDialogOption(
                                                                                onPressed: () => Navigator.pop(context),
                                                                                child: Center(
                                                                                  child: Text(
                                                                                    "${reactUsernames[index]}",
                                                                                    style: const TextStyle(fontSize: 18, letterSpacing: 0.1),
                                                                                  ),
                                                                                ),
                                                                              ));
                                                                            },
                                                                          ),
                                                                        )
                                                                      ],
                                                                    );
                                                                  });
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
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )),
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
                                                isClickedTextFormat = false;
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

                                              setState(() {
                                                isEdit = false;
                                                isClickedTextFormat = false;
                                              });

                                              directMessageService
                                                  .editDirectMessge(htmlContent,
                                                      _selectedMessageIndex!);
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
                                            isreading = !isreading;
                                            isClickedTextFormat = false;
                                          }

                                          sendMessage(htmlContent);
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
                                          child: discode
                                              ? const IconButton(
                                                  onPressed: null,
                                                  icon: Icon(Icons.format_bold))
                                              : IconButton(
                                                  icon: const Icon(
                                                      Icons.format_bold),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (isBold) {
                                                        isBold = false;
                                                      } else {
                                                        isBold = true;
                                                      }
                                                    });
                                                    if (isBold) {
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                              .Attribute.bold);
                                                    } else {
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                                  .Attribute
                                                              .clone(
                                                                  quill
                                                                      .Attribute
                                                                      .bold,
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
                                          child: discode
                                              ? const IconButton(
                                                  onPressed: null,
                                                  icon:
                                                      Icon(Icons.format_italic))
                                              : IconButton(
                                                  icon: const Icon(
                                                      Icons.format_italic),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (isItalic) {
                                                        isItalic = false;
                                                      } else {
                                                        isItalic = true;
                                                      }
                                                    });
                                                    if (isItalic) {
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                              .Attribute
                                                              .italic);
                                                    } else {
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                                  .Attribute
                                                              .clone(
                                                                  quill
                                                                      .Attribute
                                                                      .italic,
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
                                          child: discode
                                              ? const IconButton(
                                                  onPressed: null,
                                                  icon: Icon(
                                                      Icons.strikethrough_s))
                                              : IconButton(
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
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                              .Attribute
                                                              .strikeThrough);
                                                    } else {
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                                  .Attribute
                                                              .clone(
                                                                  quill
                                                                      .Attribute
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
                                          child: discode
                                              ? const IconButton(
                                                  onPressed: null,
                                                  icon: Icon(Icons.link))
                                              : IconButton(
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
                                                    _quilcontroller
                                                        .formatSelection(quill
                                                                .Attribute
                                                            .clone(
                                                                quill.Attribute
                                                                    .bold,
                                                                null));
                                                    _quilcontroller
                                                        .formatSelection(quill
                                                                .Attribute
                                                            .clone(
                                                                quill.Attribute
                                                                    .italic,
                                                                null));
                                                    _quilcontroller
                                                        .formatSelection(quill
                                                                .Attribute
                                                            .clone(
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
                                                    discode = false;
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
                                                    discode = false;
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
                                                isClickedTextFormat = false;
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

                                              setState(() {
                                                isEdit = false;
                                                isClickedTextFormat = false;
                                              });

                                              directMessageService
                                                  .editDirectMessge(htmlContent,
                                                      _selectedMessageIndex!);
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
                                            isreading = !isreading;
                                            isClickedTextFormat = false;
                                          }

                                          sendMessage(htmlContent);
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
                  ],
                ),
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
              ],
            ),
    );
  }
}
