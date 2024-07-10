import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/const/build_fiile.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/constants.dart';

import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/screens/groupMessage/Drawer/drawer.dart';
import 'package:flutter_frontend/services/groupMessageService/group_message_service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/groupMessage.dart';

import 'package:flutter_frontend/screens/groupMessage/groupThread.dart';
import 'package:flutter_frontend/services/groupMessageService/gropMessage/groupMessage_Services.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:intl/intl.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import "package:http/http.dart" as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
// ignore_for_file: prefer_const_constructors, must_be_immutable

// ignore: depend_on_referenced_packages

class GroupMessage extends StatefulWidget {
  final channelID, channelName, workspace_id, memberName;
  final channelStatus;
  final member;
  GroupMessage(
      {super.key,
      this.channelID,
      this.channelStatus,
      this.channelName,
      this.member,
      this.workspace_id,
      this.memberName});

  @override
  State<GroupMessage> createState() => _GroupMessage();
}

class _GroupMessage extends State<GroupMessage> with RouteAware {
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  final groupMessageService = GroupMessageServices(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  late ScrollController _scrollController;
  RetrieveGroupMessage? retrieveGroupMessage;
  Retrievehome? retrievehome;
  GroupMessgeModel? groupdata;
  String currentUserName =
      SessionStore.sessionData!.currentUser!.name.toString();
  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();

  List<int>? tGroupStarMsgids = [];

  List<TGroupMessages>? tGroupMessages = [];
  List<EmojiCountsforGpMsg>? emojiCounts = [];
  List<ReactUserDataForGpMsg>? reactUserData = [];

  WebSocketChannel? _channel;
  String? groupMessageName;
  bool isloading = false;
  bool isButtom = false;

  bool isLoading = false;
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

  BuildSingleFile singleFile = BuildSingleFile();
  BuildMulitFile mulitFile = BuildMulitFile();
  final _apiSerive = GroupMessageServiceImpl();
  late List<Map<String, Object?>> mention;

  bool isCursor = false;
  bool isSelectText = false;
  bool isfirstField = true;
  bool isClickedTextFormat = false;
  String htmlContent = "";
  quill.QuillController _quilcontroller = quill.QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  List<String> uniqueList = [];
  OverlayEntry? _overlayEntry;
  final List<String> _userList = []; // Example user list
  List<String> _filteredUsers = [];
  List<String> mentionnames = [];

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

  String selectedEmoji = "";
  String _seletedEmojiName = "";
  bool _isEmojiSelected = false;
  bool emojiBorderColor = false;
  @override
  void initState() {
    super.initState();
    loadMessage();
    connectWebSocket();
    _quilcontroller.addListener(_onSelectionChanged);
    _focusNode.addListener(_focusChange);
    _quilcontroller.addListener(_onTextChanged);

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
    _scrollController = ScrollController();

    _scrollToBottom();
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
    _quilcontroller.removeListener(_onSelectionChanged);
    _focusNode.removeListener(_focusChange);
    _quilcontroller.removeListener(_onTextChanged);
    _scrollController.dispose();
  }

  void connectWebSocket() {
    var url =
        'ws://$wsUrl/cable?channel_id=${widget.workspace_id}&user_id=$currentUserId';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'GroupChannel'}),
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
                  msg.containsKey('groupmsg') &&
                  msg['m_channel_id'] == widget.channelID) {
                var groupMessage = msg['groupmsg'];
                int id = msg['id'];
                var date = msg['created_at'];
                int mUserId = msg['m_user_id'];
                List<dynamic> fileUrls = [];
                String senduser = messageContent['sender_name'];

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileUrls = files.map((file) => file['file']).toList();
                  }
                }

                setState(() {
                  tGroupMessages!.add(TGroupMessages(
                      createdAt: date,
                      fileUrls: fileUrls,
                      groupmsg: groupMessage,
                      id: id,
                      sendUserId: mUserId,
                      name: senduser));
                });
              } else {}
            } else if (messageContent.containsKey('messaged_star') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var messageStarData = messageContent['messaged_star'];

              if (messageStarData != null &&
                  messageStarData['userid'] == currentUserId) {
                int groupmsgid = messageStarData['groupmsgid'];

                setState(() {
                  tGroupStarMsgids!.add(groupmsgid);
                });
              } else {}
            } else if (messageContent.containsKey('unstared_message') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var unstaredMsg = messageContent['unstared_message'];

              if (unstaredMsg != null &&
                  unstaredMsg['userid'] == currentUserId) {
                int unstaredMsgId = unstaredMsg['groupmsgid'];
                setState(() {
                  tGroupStarMsgids!.removeWhere(
                    (element) => element == unstaredMsgId,
                  );
                });
              }
            } else {
              var deletemsg = messageContent['delete_msg'];

              int id = deletemsg['id'];

              setState(() {
                tGroupMessages?.removeWhere((element) => element.id == id);
              });
            }
          } else {}
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

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() {
      files.addAll(result.files);
      hasFileToSEnd = true;
    });
  }

  void loadMessage() async {
    var token = await AuthController().getToken();
    GroupMessgeModel data =
        await groupMessageService.getAllGpMsg(widget.channelID, token!);

    setState(() {
      retrieveGroupMessage = data.retrieveGroupMessage;
      retrievehome = data.retrievehome;
      groupdata = data;
      tGroupStarMsgids = data.retrieveGroupMessage!.tGroupStarMsgids;
      emojiCounts = data.retrieveGroupMessage!.emojiCounts;
      reactUserData = data.retrieveGroupMessage!.reactUserData;
      tGroupMessages = data.retrieveGroupMessage!.tGroupMessages;
      isLoading = true;
    });
    mention = retrieveGroupMessage!.mChannelUsers!.map((e) {
      return {'display': e.name, 'name': e.name};
    }).toList();
  }

  void _scrollToBottom() {
    if (isButtom) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendGroupMessageData(
      String groupMessage, int channelId, List<String> mentionName) async {
    if (groupMessage.isNotEmpty || files.isNotEmpty) {
      try {
        await _apiSerive.sendGroupMessageData(
            groupMessage, channelId, mentionName, files);
        files.clear();
      } catch (e) {
        rethrow;
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  String? channelName;
  int? memberCount;

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

  void _onTextChanged() {
    final text = _quilcontroller.document.toPlainText();
    final selection = _quilcontroller.selection;

    getMchannelUsers();
    // remove duplicated name
    uniqueList = _userList.toSet().toList();

    if (selection.baseOffset == selection.extentOffset) {
      final offset = selection.baseOffset;
      if (selection.baseOffset > 0 && text[offset - 1] == '@') {
        // userlist won't show when String@
        List txts = text.split(" ");
        String str = "";
        for (var i = 0; i < txts.length; i++) {
          str = txts[i];
        }
        if (str.startsWith("@")) {
          setState(() {
            _filteredUsers = uniqueList;
          });
          _showUserList();
        }
      } else {
        // filtering users
        final atPos = text.lastIndexOf('@', selection.baseOffset);
        if (atPos != -1) {
          final query =
              text.substring(atPos + 1, selection.baseOffset).toLowerCase();
          _filteredUsers = uniqueList
              .where((user) => user.toLowerCase().startsWith(query))
              .toList();
          if (_filteredUsers.isEmpty) {
            _hideUserList();
          }
        } else {
          _hideUserList();
        }
      }
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
    final checkLastCodeBlock = _isWordCodeBlock(wordRange);

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

  void _showUserList() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideUserList() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    ScrollController scrollmention = ScrollController();

    return OverlayEntry(
      builder: (context) => Positioned(
        left: 60,
        top: 150,
        width: 300,
        height: 250,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(10.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 300,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                    ),
                  ),
                ),
                ListView(
                  controller: scrollmention,
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: _filteredUsers.map((user) {
                    return ListTile(
                      leading: Icon(
                        Icons.person,
                        color: Colors.grey[300],
                      ),
                      title: Text(user),
                      onTap: () {
                        _insertUser(user);
                        _hideUserList();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _insertUser(String user) {
    final selection = _quilcontroller.selection;
    final text = _quilcontroller.document.toPlainText();
    // final start = selection.baseOffset - 1;
    int cursorPosition = _quilcontroller.selection.baseOffset;

    int start = text.substring(0, cursorPosition).lastIndexOf(' ');
    int end = cursorPosition;

    if (start == -1) {
      start = 0;
    } else {
      start += 1;
    }

    final newText = text.replaceRange(start, selection.baseOffset, '@$user ');
    _quilcontroller.replaceText(
      start,
      end - start,
      '@$user ',
      _quilcontroller.selection,
    );

    _quilcontroller.updateSelection(
      TextSelection.collapsed(offset: start + user.length + 2),
      quill.ChangeSource.local,
    );
  }

  void insertMention(String text) {
    final index = _quilcontroller.selection.baseOffset;
    if (index >= 0) {
      _quilcontroller.document.insert(index, text);
    } else {
      _quilcontroller.document.insert(0, text);
    }
    _quilcontroller.updateSelection(
      TextSelection.collapsed(offset: index + text.length),
      ChangeSource.local,
    );
  }

  void insertEditText(msg) {
    Delta delta = convertHtmlToDelta(msg);
    _quilcontroller = quill.QuillController(
      document: quill.Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    // final int len = delta.length - 2;
    // if (delta[len].attributes!.containsKey("code")) {
    //   setState(() {
    //     isCode = true;
    //   });
    // } else {
    //   setState(() {
    //     isCode = false;
    //   });
    // }
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
          case 'p':
            if (node.nodes.isNotEmpty && node.nodes.last is html_dom.Text) {
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
      // if (node.toString().contains('"')) {
      //   parseNode(node, {});
      //   delta.insert("\n");
      // } else {
      parseNode(node, {});
      // }
    }

    // Ensure the last block ends with a newline
    if (delta.length > 0 && !(delta.last.data as String).endsWith('\n')) {
      delta.insert('\n');
    }
    return delta;
  }

  Future<void> editGroupMessage(
      String message, int msgId, List<String> mentionnames) async {
    var token = await AuthController().getToken();
    http.post(Uri.parse("http://10.0.2.2:3000/update_groupmsg"),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'id': msgId,
          'message': message,
          'mention_name': mentionnames
        }));
  }

  void getMchannelUsers() {
    for (var i = 0; i < retrieveGroupMessage!.mChannelUsers!.length; i++) {
      setState(() {
        _userList.add(retrieveGroupMessage!.mChannelUsers![i].name!);
      });
    }
  }

  Future<void> giveMsgReaction(
      {required String emoji,
      required int msgId,
      required int sChannelId}) async {
    var token = await AuthController().getToken();
    try {
      final response =
          await http.post(Uri.parse("http://10.0.2.2:3000/groupreact"),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, dynamic>{
                "message_id": msgId,
                "s_channel_id": sChannelId,
                "emoji": emoji,
              }));
    } catch (e) {
      print("error===> $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    int? groupMessageID;
    return isLoading == false
        ? ProgressionBar(imageName: 'loading.json', height: 200, size: 200)
        : Scaffold(
            backgroundColor: kPriamrybackground,
            resizeToAvoidBottomInset: true,
            key: _scaffoldKey,
            drawer: Drawer(
              child: DrawerPage(
                  channelId: widget.channelID,
                  channelName: widget.channelName,
                  channelStatus: widget.channelStatus,
                  memberCount: memberCount,
                  memberName: widget.memberName,
                  member: retrieveGroupMessage!.mChannelUsers,
                  adminID: retrieveGroupMessage!.create_admin),
            ),
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {
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
                  Container(
                    child: widget.channelStatus
                        ? Icon(
                            Icons.tag,
                            color: Colors.white,
                          )
                        : Icon(
                            Icons.lock,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      GestureDetector(
                          onTap: () {
                            _openDrawer();
                          },
                          child: Text(
                            widget.channelName,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )),
                    ],
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                    child: ListView.builder(
                  itemCount: retrieveGroupMessage!.tGroupMessages!.length,
                  itemBuilder: (context, index) {
                    var channelStar = tGroupMessages!;

                    List<dynamic>? files = [];
                    files = tGroupMessages![index].fileUrls;

                    List<int> tempStar = tGroupStarMsgids?.toList() ?? [];
                    bool isStared = tempStar.contains(channelStar[index].id);

                    String message = channelStar[index].groupmsg ?? "";
                    String sendername = tGroupMessages![index].name.toString();

                    int count = channelStar[index].count ?? 0;
                    String time = channelStar[index].createdAt.toString();
                    DateTime date = DateTime.parse(time).toLocal();

                    String created_at =
                        DateFormat('MMM d, yyyy hh:mm a').format(date);
                    bool isMessageFromCurrentUser =
                        currentUserName == channelStar[index].name;
                    int sendUserId = tGroupMessages![index].sendUserId!.toInt();
                    int messageId = tGroupMessages![index].id!.toInt();

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
                                          padding: const EdgeInsets.all(3.0),
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
                                                          await _apiSerive
                                                              .deleteGroupMessage(
                                                                  tGroupMessages![
                                                                          index]
                                                                      .id!,
                                                                  widget
                                                                      .channelID);
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
                                                                builder: (_) => GpThreadMessage(
                                                                    channelID:
                                                                        widget
                                                                            .channelID,
                                                                    channelStatus:
                                                                        widget
                                                                            .channelStatus,
                                                                    channelName:
                                                                        widget
                                                                            .channelName,
                                                                    messageID:
                                                                        tGroupMessages![index]
                                                                            .id,
                                                                    message:
                                                                        message,
                                                                    name: retrieveGroupMessage!
                                                                        .tGroupMessages![
                                                                            index]
                                                                        .name
                                                                        .toString(),
                                                                    time:
                                                                        created_at,
                                                                    fname: retrieveGroupMessage!
                                                                        .tGroupMessages![
                                                                            index]
                                                                        .name
                                                                        .toString())));
                                                      },
                                                      icon: const Icon(
                                                          Icons.reply),
                                                      color:
                                                          const Color.fromARGB(
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
                                                            await _apiSerive
                                                                .deleteGroupStarMessage(
                                                                    tGroupMessages![
                                                                            index]
                                                                        .id!,
                                                                    widget
                                                                        .channelID!);
                                                          } else {
                                                            await _apiSerive
                                                                .getMessageStar(
                                                                    tGroupMessages![
                                                                            index]
                                                                        .id!,
                                                                    widget
                                                                        .channelID);
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
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
                                                                  setState(() {
                                                                    groupMessageID =
                                                                        tGroupMessages![index]
                                                                            .id!
                                                                            .toInt();
                                                                    selectedEmoji =
                                                                        emoji
                                                                            .emoji;
                                                                    _seletedEmojiName =
                                                                        emoji
                                                                            .name;
                                                                    _isEmojiSelected =
                                                                        true;
                                                                  });

                                                                  await giveMsgReaction(
                                                                      sChannelId:
                                                                          widget
                                                                              .channelID,
                                                                      emoji:
                                                                          selectedEmoji,
                                                                      msgId:
                                                                          groupMessageID!);

                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                config: Config(
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
                                                                      const SkinToneConfig(),
                                                                  categoryViewConfig:
                                                                      const CategoryViewConfig(),
                                                                  bottomActionBarConfig:
                                                                      const BottomActionBarConfig(),
                                                                  searchViewConfig:
                                                                      const SearchViewConfig(),
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                        icon: Icon(Icons
                                                            .add_reaction_outlined)),
                                                    IconButton(
                                                        onPressed: () {
                                                          _clearEditor();
                                                          setState(() {
                                                            isEdit = true;
                                                          });
                                                          editMsg = message;

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
                                                                    _onTextChanged);
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
                                                            Icons.edit))
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
                                              bottomLeft: Radius.circular(10),
                                              bottomRight: Radius.zero,
                                            ),
                                            color: Color.fromARGB(
                                                110, 121, 120, 124),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (sendername.isNotEmpty)
                                                  Text(
                                                    sendername,
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                if (message.isNotEmpty)
                                                  flutter_html.Html(
                                                    data: message,
                                                    style: {
                                                      "blockquote":
                                                          flutter_html.Style(
                                                        border: const Border(
                                                            left: BorderSide(
                                                                color:
                                                                    Colors.grey,
                                                                width: 5.0)),
                                                        margin: flutter_html
                                                            .Margins.all(0),
                                                        padding: flutter_html
                                                                .HtmlPaddings
                                                            .only(left: 10),
                                                      ),
                                                      "ol": flutter_html.Style(
                                                        margin: flutter_html
                                                                .Margins
                                                            .symmetric(
                                                                horizontal: 10),
                                                        padding: flutter_html
                                                                .HtmlPaddings
                                                            .symmetric(
                                                                horizontal: 10),
                                                      ),
                                                      "ul": flutter_html.Style(
                                                        display: flutter_html
                                                            .Display
                                                            .inlineBlock,
                                                        padding: flutter_html
                                                                .HtmlPaddings
                                                            .symmetric(
                                                                horizontal: 10),
                                                        margin: flutter_html
                                                            .Margins.all(0),
                                                      ),
                                                      "pre": flutter_html.Style(
                                                        backgroundColor:
                                                            Colors.grey[300],
                                                        padding: flutter_html
                                                                .HtmlPaddings
                                                            .symmetric(
                                                                horizontal: 10,
                                                                vertical: 5),
                                                      ),
                                                      "code":
                                                          flutter_html.Style(
                                                        display: flutter_html
                                                            .Display
                                                            .inlineBlock,
                                                        backgroundColor:
                                                            Colors.grey[300],
                                                        color: Colors.red,
                                                        padding: flutter_html
                                                                .HtmlPaddings
                                                            .symmetric(
                                                                horizontal: 10,
                                                                vertical: 5),
                                                      )
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
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 4.0),
                                                          child:
                                                              Icon(Icons.reply),
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
                                                  emojiCounts!.length, (index) {
                                                bool show = false;
                                                List userIds = [];
                                                List reactUsernames = [];

                                                if (emojiCounts![index]
                                                        .groupmsgid ==
                                                    messageId) {
                                                  for (dynamic reactUser
                                                      in reactUserData!) {
                                                    if (reactUser.groupmsgid ==
                                                            emojiCounts![index]
                                                                .groupmsgid &&
                                                        emojiCounts![index]
                                                                .emoji ==
                                                            reactUser.emoji) {
                                                      userIds.add(
                                                          reactUser.userid);
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
                                                          .groupmsgid ==
                                                      messageId) {
                                                    for (int j = 0;
                                                        j <
                                                            reactUserData!
                                                                .length;
                                                        j++) {
                                                      if (userIds.contains(
                                                          reactUserData![j]
                                                              .userid)) {
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
                                                                // groupMessageID =
                                                                //     groupMessageList
                                                                //         .retrieveGroupMessage!
                                                                //         .tGroupMessages![
                                                                //             index]
                                                                //         .id!
                                                                //         .toInt();
                                                              });
                                                              HapticFeedback
                                                                  .vibrate();
                                                              await giveMsgReaction(
                                                                emoji:
                                                                    emojiCounts![
                                                                            index]
                                                                        .emoji!,
                                                                msgId: emojiCounts![
                                                                        index]
                                                                    .groupmsgid!,
                                                                sChannelId: widget
                                                                    .channelID,
                                                              );
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
                                                                          Center(
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
                                                                                    "${reactUsernames[index]}さん",
                                                                                    style: TextStyle(fontSize: 18, letterSpacing: 0.1),
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
                                                                  WidgetStateProperty
                                                                      .all(Size(
                                                                          50,
                                                                          25)),
                                                            ),
                                                            child: Text(
                                                              '${emojiCounts![index].emoji} ${emojiCounts![index].emojiCount}',
                                                              style: TextStyle(
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
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Column(
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
                                              bottomRight: Radius.circular(10),
                                              bottomLeft: Radius.zero,
                                            ),
                                            color: Color.fromARGB(
                                                111, 113, 81, 228),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (sendername.isNotEmpty)
                                                  Text(
                                                    sendername,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                if (message.isNotEmpty)
                                                  flutter_html.Html(
                                                    data: message,
                                                    style: {
                                                      "blockquote":
                                                          flutter_html.Style(
                                                        border: const Border(
                                                            left: BorderSide(
                                                                color:
                                                                    Colors.grey,
                                                                width: 5.0)),
                                                        margin: flutter_html
                                                            .Margins.all(0),
                                                        padding: flutter_html
                                                                .HtmlPaddings
                                                            .only(left: 10),
                                                      ),
                                                      "ol": flutter_html.Style(
                                                        margin: flutter_html
                                                                .Margins
                                                            .symmetric(
                                                                horizontal: 10),
                                                        padding: flutter_html
                                                                .HtmlPaddings
                                                            .symmetric(
                                                                horizontal: 10),
                                                      ),
                                                      "ul": flutter_html.Style(
                                                        display: flutter_html
                                                            .Display
                                                            .inlineBlock,
                                                        padding: flutter_html
                                                                .HtmlPaddings
                                                            .symmetric(
                                                                horizontal: 10),
                                                        margin: flutter_html
                                                            .Margins.all(0),
                                                      ),
                                                      "pre": flutter_html.Style(
                                                        backgroundColor:
                                                            Colors.grey[300],
                                                        padding: flutter_html
                                                                .HtmlPaddings
                                                            .symmetric(
                                                                horizontal: 10,
                                                                vertical: 5),
                                                      ),
                                                      "code":
                                                          flutter_html.Style(
                                                        display: flutter_html
                                                            .Display
                                                            .inlineBlock,
                                                        backgroundColor:
                                                            Colors.grey[300],
                                                        color: Colors.red,
                                                        padding: flutter_html
                                                                .HtmlPaddings
                                                            .symmetric(
                                                                horizontal: 10,
                                                                vertical: 5),
                                                      )
                                                    },
                                                  ),
                                                if (files != null &&
                                                    files.isNotEmpty)
                                                  ...files.length == 1
                                                      ? [
                                                          singleFile
                                                              .buildSingleFile(
                                                                  files.first,
                                                                  context,
                                                                  platform)
                                                        ]
                                                      : [
                                                          mulitFile
                                                              .buildMultipleFiles(
                                                                  files,
                                                                  platform,
                                                                  context)
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
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 4.0),
                                                          child:
                                                              Icon(Icons.reply),
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
                                                  emojiCounts!.length, (index) {
                                                bool show = false;
                                                List userIds = [];
                                                List reactUsernames = [];

                                                if (emojiCounts![index]
                                                        .groupmsgid ==
                                                    messageId) {
                                                  for (dynamic reactUser
                                                      in reactUserData!) {
                                                    if (reactUser.groupmsgid ==
                                                            emojiCounts![index]
                                                                .groupmsgid &&
                                                        emojiCounts![index]
                                                                .emoji ==
                                                            reactUser.emoji) {
                                                      userIds.add(
                                                          reactUser.userid);
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
                                                          .groupmsgid ==
                                                      messageId) {
                                                    for (int j = 0;
                                                        j <
                                                            reactUserData!
                                                                .length;
                                                        j++) {
                                                      if (userIds.contains(
                                                          reactUserData![j]
                                                              .userid)) {
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
                                                                // groupMessageID =
                                                                //     groupMessageList
                                                                //         .retrieveGroupMessage!
                                                                //         .tGroupMessages![
                                                                //             index]
                                                                //         .id!
                                                                //         .toInt();
                                                              });
                                                              HapticFeedback
                                                                  .vibrate();
                                                              await giveMsgReaction(
                                                                emoji:
                                                                    emojiCounts![
                                                                            index]
                                                                        .emoji!,
                                                                msgId: emojiCounts![
                                                                        index]
                                                                    .groupmsgid!,
                                                                sChannelId: widget
                                                                    .channelID,
                                                              );
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
                                                                          Center(
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
                                                                                    "${reactUsernames[index]}さん",
                                                                                    style: TextStyle(fontSize: 18, letterSpacing: 0.1),
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
                                                                  WidgetStateProperty
                                                                      .all(Size(
                                                                          50,
                                                                          25)),
                                                            ),
                                                            child: Text(
                                                              '${emojiCounts![index].emoji} ${emojiCounts![index].emojiCount}',
                                                              style: TextStyle(
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
                                    if (_selectedMessageIndex ==
                                            channelStar[index].id &&
                                        !isSelected)
                                      Align(
                                        child: Container(
                                          padding: const EdgeInsets.all(3.0),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
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
                                                        await _apiSerive.deleteGroupStarMessage(
                                                            tGroupMessages![
                                                                    index]
                                                                .id!,
                                                            widget.channelID!);
                                                      } else {
                                                        await _apiSerive
                                                            .getMessageStar(
                                                                tGroupMessages![
                                                                        index]
                                                                    .id!,
                                                                widget
                                                                    .channelID!);
                                                      }
                                                    }
                                                  },
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (_) => GpThreadMessage(
                                                                channelID: widget
                                                                    .channelID,
                                                                channelStatus:
                                                                    widget
                                                                        .channelStatus,
                                                                channelName: widget
                                                                    .channelName,
                                                                messageID:
                                                                    tGroupMessages![index]
                                                                        .id,
                                                                message:
                                                                    message,
                                                                name: retrieveGroupMessage!
                                                                    .tGroupMessages![
                                                                        index]
                                                                    .name
                                                                    .toString(),
                                                                time:
                                                                    created_at,
                                                                fname: retrieveGroupMessage!
                                                                    .tGroupMessages![
                                                                        index]
                                                                    .name
                                                                    .toString())));
                                                  },
                                                  icon: const Icon(Icons.reply),
                                                  color: const Color.fromARGB(
                                                      255, 15, 15, 15),
                                                ),
                                                IconButton(
                                                    onPressed: () async {
                                                      showModalBottomSheet(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return EmojiPicker(
                                                            onEmojiSelected:
                                                                (category,
                                                                    Emoji
                                                                        emoji) async {
                                                              setState(() {
                                                                groupMessageID =
                                                                    tGroupMessages![
                                                                            index]
                                                                        .id!
                                                                        .toInt();
                                                                selectedEmoji =
                                                                    emoji.emoji;
                                                                _seletedEmojiName =
                                                                    emoji.name;
                                                                _isEmojiSelected =
                                                                    true;
                                                              });

                                                              await giveMsgReaction(
                                                                  sChannelId: widget
                                                                      .channelID,
                                                                  emoji:
                                                                      selectedEmoji,
                                                                  msgId:
                                                                      groupMessageID!);

                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            config: Config(
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
                                                                  const SkinToneConfig(),
                                                              categoryViewConfig:
                                                                  const CategoryViewConfig(),
                                                              bottomActionBarConfig:
                                                                  const BottomActionBarConfig(),
                                                              searchViewConfig:
                                                                  const SearchViewConfig(),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                    icon: Icon(Icons
                                                        .add_reaction_outlined)),
                                                if (sendUserId == currentUserId)
                                                  IconButton(
                                                    onPressed: () async {
                                                      if (_selectedMessageIndex !=
                                                          null) {
                                                        await _apiSerive.deleteGroupMessage(
                                                            tGroupMessages![
                                                                    index]
                                                                .id!,
                                                            widget.channelID!);
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete),
                                                    color: Colors.red,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
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
                                    margin:
                                        const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(5)),
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
                                    margin:
                                        const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: IconButton(
                                        color: Colors.white,
                                        onPressed: () {
                                          // for mention name
                                          String plaintext = _quilcontroller
                                              .document
                                              .toPlainText();
                                          List<String> currentMentions = [];
                                          for (var i = 0;
                                              i < uniqueList.length;
                                              i++) {
                                            if (plaintext
                                                .contains(uniqueList[i])) {
                                              currentMentions
                                                  .add("@${uniqueList[i]}");
                                            }
                                          }

                                          htmlContent = detectStyles();

                                          if (htmlContent.contains("<p>")) {
                                            htmlContent = htmlContent
                                                .replaceAll("<p>", "");
                                            htmlContent = htmlContent
                                                .replaceAll("</p>", "");
                                          }

                                          setState(() {
                                            mentionnames.clear();
                                            mentionnames
                                                .addAll(currentMentions);
                                            isEdit = false;
                                          });

                                          editGroupMessage(
                                              htmlContent,
                                              _selectedMessageIndex!,
                                              mentionnames);
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
                                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 24, 103, 167),
                                    borderRadius: BorderRadius.circular(5)),
                                child: IconButton(
                                    onPressed: () {
                                      int channelId = widget.channelID;
                                      // for mention name
                                      String plaintext = _quilcontroller
                                          .document
                                          .toPlainText();
                                      List<String> currentMentions = [];
                                      for (var i = 0;
                                          i < uniqueList.length;
                                          i++) {
                                        if (plaintext.contains(uniqueList[i])) {
                                          currentMentions
                                              .add("@${uniqueList[i]}");
                                        }
                                      }

                                      htmlContent = detectStyles();

                                      if (htmlContent.contains("<p>")) {
                                        htmlContent =
                                            htmlContent.replaceAll("<p>", "");
                                        htmlContent =
                                            htmlContent.replaceAll("</p>", "");
                                      }

                                      setState(() {
                                        mentionnames.clear();
                                        mentionnames.addAll(currentMentions);
                                        isClickedTextFormat = false;
                                      });
                                      _clearEditor();

                                      sendGroupMessageData(
                                          htmlContent, channelId, mentionnames);
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
                                        borderRadius: BorderRadius.circular(6),
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
                                        borderRadius: BorderRadius.circular(6),
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
                                        borderRadius: BorderRadius.circular(6),
                                        color: isStrike
                                            ? Colors.grey[400]
                                            : Colors.grey[300],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.strikethrough_s),
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
                                                quill.Attribute.strikeThrough);
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
                                        borderRadius: BorderRadius.circular(6),
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
                                        borderRadius: BorderRadius.circular(6),
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
                                                    quill.Attribute.ol, null));
                                          }
                                        },
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
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
                                                    quill.Attribute.ul, null));
                                          }
                                        },
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
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
                                                    quill.Attribute.blockQuote,
                                                    null));
                                          }
                                        },
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
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
                                                    quill.Attribute.inlineCode,
                                                    null));
                                          }
                                        },
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
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
                                                    quill.Attribute.inlineCode,
                                                    null));
                                            _quilcontroller.formatSelection(
                                                quill.Attribute.clone(
                                                    quill.Attribute
                                                        .strikeThrough,
                                                    null));
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
                            if (isEdit)
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    margin:
                                        const EdgeInsets.fromLTRB(15, 0, 10, 0),
                                    decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(5)),
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
                                    margin:
                                        const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: IconButton(
                                        color: Colors.white,
                                        onPressed: () {
                                          // for mention name
                                          String plaintext = _quilcontroller
                                              .document
                                              .toPlainText();
                                          List<String> currentMentions = [];
                                          for (var i = 0;
                                              i < uniqueList.length;
                                              i++) {
                                            if (plaintext
                                                .contains(uniqueList[i])) {
                                              currentMentions
                                                  .add("@${uniqueList[i]}");
                                            }
                                          }

                                          htmlContent = detectStyles();

                                          if (htmlContent.contains("<p>")) {
                                            htmlContent = htmlContent
                                                .replaceAll("<p>", "");
                                            htmlContent = htmlContent
                                                .replaceAll("</p>", "");
                                          }

                                          setState(() {
                                            mentionnames.clear();
                                            mentionnames
                                                .addAll(currentMentions);
                                            isEdit = false;
                                          });

                                          editGroupMessage(
                                              htmlContent,
                                              _selectedMessageIndex!,
                                              mentionnames);
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
                                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 24, 103, 167),
                                    borderRadius: BorderRadius.circular(5)),
                                child: IconButton(
                                    onPressed: () {
                                      int channelId = widget.channelID;
                                      // for mention name
                                      String plaintext = _quilcontroller
                                          .document
                                          .toPlainText();
                                      List<String> currentMentions = [];
                                      for (var i = 0;
                                          i < uniqueList.length;
                                          i++) {
                                        if (plaintext.contains(uniqueList[i])) {
                                          currentMentions
                                              .add("@${uniqueList[i]}");
                                        }
                                      }

                                      htmlContent = detectStyles();

                                      if (htmlContent.contains("<p>")) {
                                        htmlContent =
                                            htmlContent.replaceAll("<p>", "");
                                        htmlContent =
                                            htmlContent.replaceAll("</p>", "");
                                      }

                                      setState(() {
                                        mentionnames.clear();
                                        mentionnames.addAll(currentMentions);
                                        isClickedTextFormat = false;
                                      });
                                      _clearEditor();

                                      sendGroupMessageData(
                                          htmlContent, channelId, mentionnames);
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

                // Padding(
                //   padding: const EdgeInsets.only(left: 10, right: 10),
                //   child: FlutterMentions(
                //     key: key,
                //     suggestionPosition: SuggestionPosition.Top,
                //     maxLines: 3,
                //     minLines: 1,
                //     decoration: InputDecoration(
                //         hintText: 'send messages',
                //         suffixIcon: Row(
                //           mainAxisSize: MainAxisSize.min,
                //           children: [
                //             GestureDetector(
                //               onTap: () {
                //                 pickFiles();
                //               },
                //               child: const Icon(
                //                 Icons.attach_file_outlined,
                //                 size: 35,
                //               ),
                //             ),
                //             GestureDetector(
                //                 onTap: () {
                //                   String message = key
                //                       .currentState!.controller!.text
                //                       .trimRight();
                //                   int? channelId = widget.channelID;

                //                   String mentionName = " ";
                //                   List<String> userSearchItems = [];

                //                   mention.forEach((data) {
                //                     if (message
                //                         .contains('@${data['display']}')) {
                //                       mentionName = '@${data['display']}';

                //                       userSearchItems.add(mentionName);
                //                     }
                //                   });

                //                   sendGroupMessageData(
                //                       message, channelId!, userSearchItems);
                //                   key.currentState!.controller!.text = " ";
                //                 },
                //                 child: Icon(Icons.telegram,
                //                     color: Colors.blue, size: 35))
                //           ],
                //         )),
                //     mentions: [
                //       Mention(
                //           trigger: '@',
                //           style: TextStyle(
                //             color: Colors.blue,
                //           ),
                //           data: mention,
                //           matchAll: false,
                //           suggestionBuilder: (data) {
                //             return Container(
                //               color: Colors.grey.shade200,
                //               padding: EdgeInsets.all(10.0),
                //               child: Row(
                //                 children: <Widget>[
                //                   SizedBox(
                //                     width: 20.0,
                //                   ),
                //                   Column(
                //                     children: <Widget>[
                //                       //  Text(data['display']),
                //                       Text('@${data['display']}'),
                //                     ],
                //                   )
                //                 ],
                //               ),
                //             );
                //           }),
                //     ],
                //   ),
                // ),
              ],
            ),
          );
  }
}
