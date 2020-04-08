import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/model/chat_message.dart';
import 'package:chatapp/service/authentication.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

//const String _name = "Nhan Nguyen";

class ChatScreen extends StatefulWidget {
  ChatScreen(String title, String id,
      {Key key, this.auth, this.userId, this.onSignedOut})
      : _title = title,
        _uid = id,
        super(key: key);

  final _title;
  final _uid;
  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State createState() => ChatScreenState(_title, _uid);
}

const List<Choice> choices = const <Choice>[
  const Choice('Sign out'),
  const Choice('Settings')
];

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _title;
  final _uid;
  final List<ChatMessage> _messages;
  final TextEditingController _textController;
  final DatabaseReference _messageDatabaseReference;
  final StorageReference _photoStorageReference;

  bool _isComposing = false;

  ChatScreenState(String title, String id)
      : _title = title,
        _uid = id,
        _isComposing = false,
        _messages = <ChatMessage>[],
        _textController = TextEditingController(),
        _messageDatabaseReference =
            FirebaseDatabase.instance.reference().child("messages"),
        _photoStorageReference =
            FirebaseStorage.instance.ref().child("chat_photos") {
    _messageDatabaseReference.onChildAdded.listen(_onMessageAdded);
  }

  Widget _buildTextComposer() {
    return IconTheme(
        data: IconThemeData(color: Theme.of(context).accentColor),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  controller: _textController,
                  onChanged: (String text) {
                    setState(() {
                      _isComposing = text.length > 0;
                    });
                  },
                  onSubmitted: _handleSubmitted,
                  decoration:
                      InputDecoration.collapsed(hintText: "Send a message"),
                ),
              ),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: _sendImageFromCamera,
                      ),
                      IconButton(
                        icon: Icon(Icons.image),
                        onPressed: _sendImageFromGallery,
                      ),
                      Theme.of(context).platform == TargetPlatform.iOS
                          ? CupertinoButton(
                              child: Text("Send"),
                              onPressed: _isComposing
                                  ? () => _handleSubmitted(_textController.text)
                                  : null,
                            )
                          : IconButton(
                              icon: Icon(Icons.send),
                              onPressed: _isComposing
                                  ? () => _handleSubmitted(_textController.text)
                                  : null,
                            ),
                    ],
                  ))
            ],
          ),
        ));
  }

  void _onMessageAdded(Event event) {
    final text = event.snapshot.value["text"];
    final imageUrl = event.snapshot.value["imageUrl"];
    final user = event.snapshot.value['username'];
    print("User: " + user);

    if (user == _uid) {
      ChatMessage message = imageUrl == null
          ? _createMessageFromText(text)
          : _createMessageFromImage(imageUrl);

      setState(() {
        _messages.insert(0, message);
      });

      message.animationController.forward();
    }
    /*List<ChatMessage> _ClearMessages;
    for(int i=0; i<_messages.length; i++){
      //if(_messages.)
    }*/
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });

    final ChatMessage message = _createMessageFromText(text);
    _messageDatabaseReference.push().set(message.toMap());
  }

  void _sendImage(ImageSource imageSource) async {
    File image = await ImagePicker.pickImage(source: imageSource);
    final String fileName = Uuid().v4();
    StorageReference photoRef = _photoStorageReference.child(fileName);
    final StorageUploadTask uploadTask = photoRef.putFile(image);
    final StorageTaskSnapshot downloadUrl = await uploadTask.onComplete;
    final ChatMessage message = _createMessageFromImage(
      await downloadUrl.ref.getDownloadURL(),
    );
    _messageDatabaseReference.push().set(message.toMap());
  }

  void _sendImageFromCamera() async {
    _sendImage(ImageSource.camera);
  }

  void _sendImageFromGallery() async {
    _sendImage(ImageSource.gallery);
  }

  ChatMessage _createMessageFromText(String text) => ChatMessage(
        text: text,
        username: _uid,
        animationController: AnimationController(
          duration: Duration(milliseconds: 180),
          vsync: this,
        ),
        dt: DateTime.now().toString(),
      );

  ChatMessage _createMessageFromImage(String imageUrl) => ChatMessage(
        imageUrl: imageUrl,
        username: _uid,
        animationController: AnimationController(
          duration: Duration(milliseconds: 90),
          vsync: this,
        ),
      );
  var recentJobsRef = FirebaseDatabase.instance.reference().child('messages');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
          ),
        ],
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            StreamBuilder(
                stream: recentJobsRef.onValue,
                builder: (context, snap) {
                  if (snap.hasData &&
                      !snap.hasError &&
                      snap.data.value != null) {
                    DataSnapshot snapshot = snap.data.snapshot;
                    List item = [];
                    List _list = [];
                    _list = snapshot.value;

                    _list.forEach((f) {
                      if (f != null) {
                        item.add(f);
                      }
                    });

                    return snap.data.snapshot.value == null
                        ? SizedBox()
                        : Flexible(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: item.length,
                              itemBuilder: (context, index) {
                                return _messages[index];
                              },
                            ),
                          );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                }),
            // Flexible(
            //   child: ListView.builder(
            //     padding: EdgeInsets.all(8.0),
            //     reverse: true,
            //     itemBuilder: (_, int index) => _messages[index],
            //     itemCount: _messages.length,
            //   ),
            // ),
            Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer(),
            ),
          ],
        ),
        decoration: Theme.of(context).platform == TargetPlatform.iOS
            ? BoxDecoration(
                border: Border(
                top: BorderSide(color: Colors.grey[200]),
              ))
            : null,
      ),
    );
  }

  @override
  void dispose() {
    for (ChatMessage message in _messages)
      message.animationController.dispose();
    super.dispose();
  }

  void _select(Choice choice) {
    switch (choice.title) {
      case 'Sign out':
        _signOut();
        break;
    }
  }

  void _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }
}

class Choice {
  const Choice(this.title);

  final String title;
}
