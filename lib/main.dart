import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/theme/theme_data.dart';
import 'package:chatapp/service/authentication.dart';

import 'model/root_page.dart';

const title = "Zeft Chat";

void main() {
  runApp(new FriendlyChatApp());
}

class FriendlyChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: defaultTargetPlatform == TargetPlatform.android
          ? kIOSTheme
          : kDefaultTheme,
      home: RootPage(title: title, auth: Auth()),
    );
  }
}