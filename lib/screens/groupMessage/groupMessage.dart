import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/const/build_fiile.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/constants.dart';

import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/screens/groupMessage/Drawer/drawer.dart';
import 'package:flutter_frontend/services/groupMessageService/group_message_service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/groupMessage.dart';

import 'package:flutter_frontend/screens/groupMessage/groupThread.dart';
import 'package:flutter_frontend/services/groupMessageService/gropMessage/groupMessage_Services.dart';
import 'package:intl/intl.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_html/flutter_html.dart' as flutter_html;
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
  final quill.QuillController _quilcontroller = quill.QuillController.basic();
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

    loadMessage();
    connectWebSocket();
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
    _quilcontroller.removeListener(_onSelectionChanged);
    _focusNode.removeListener(_focusChange);
    _quilcontroller.removeListener(_onTextChanged);

    _channel!.sink.close();
    _scrollController.dispose();
  }

  void connectWebSocket() {
    var url =
        'ws://localhost:3000/cable?channel_id=${widget.workspace_id}&user_id=$currentUserId';
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

  void getMchannelUsers() {
    for (var i = 0; i < retrieveGroupMessage!.mChannelUsers!.length; i++) {
      setState(() {
        _userList.add(retrieveGroupMessage!.mChannelUsers![i].name!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
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
                                                              widget.channelID);
                                                    }
                                                  },
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  color: Colors.red,
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
                                                                    .channelID);
                                                      }
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                          bottomLeft: Radius.circular(10),
                                          bottomRight: Radius.zero,
                                        ),
                                        color:
                                            Color.fromARGB(110, 121, 120, 124),
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
                                                  ".bq": flutter_html.Style(
                                                    border: const Border(
                                                        left: BorderSide(
                                                            color: Colors.grey,
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
                                                    margin: flutter_html.Margins
                                                        .all(0),
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
                                                    margin: flutter_html.Margins
                                                        .all(0),
                                                  ),
                                                  ".code-block": flutter_html
                                                      .Style(
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .all(10),
                                                          backgroundColor:
                                                              Colors.grey[200],
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
                                                  files[0], context, platform),
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
                                                      padding: EdgeInsets.only(
                                                          left: 4.0),
                                                      child: Icon(Icons.reply),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                          bottomRight: Radius.circular(10),
                                          bottomLeft: Radius.zero,
                                        ),
                                        color:
                                            Color.fromARGB(111, 113, 81, 228),
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
                                                  ".bq": flutter_html.Style(
                                                    border: const Border(
                                                        left: BorderSide(
                                                            color: Colors.grey,
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
                                                    margin: flutter_html.Margins
                                                        .all(0),
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
                                                    margin: flutter_html.Margins
                                                        .all(0),
                                                  ),
                                                  ".code-block": flutter_html
                                                      .Style(
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .all(10),
                                                          backgroundColor:
                                                              Colors.grey[200],
                                                          color: Colors.black,
                                                          width: flutter_html
                                                              .Width(150)),
                                                  ".code-block code":
                                                      flutter_html.Style(
                                                          color: Colors.black)
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
                                                      padding: EdgeInsets.only(
                                                          left: 4.0),
                                                      child: Icon(Icons.reply),
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
                                    String plaintext =
                                        _quilcontroller.document.toPlainText();
                                    List<String> currentMentions = [];
                                    for (var i = 0;
                                        i < uniqueList.length;
                                        i++) {
                                      if (plaintext.contains(uniqueList[i])) {
                                        currentMentions
                                            .add("@${uniqueList[i]}");
                                      }
                                    }

                                    // for editor
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
                                    setState(() {
                                      mentionnames.clear();
                                      mentionnames.addAll(currentMentions);
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
                                    int channelId = widget.channelID;
                                    // for mention name
                                    String plaintext =
                                        _quilcontroller.document.toPlainText();
                                    List<String> currentMentions = [];
                                    for (var i = 0;
                                        i < uniqueList.length;
                                        i++) {
                                      if (plaintext.contains(uniqueList[i])) {
                                        currentMentions
                                            .add("@${uniqueList[i]}");
                                      }
                                    }
                                    // for editor
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

                                    setState(() {
                                      mentionnames.clear();
                                      mentionnames.addAll(currentMentions);
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
