import 'package:flutter/material.dart';
import 'dart:io';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:pediatko/preslikave.dart';

/// Third window of the homepage screen
/// contains a body with webview custom page
///
/// TODO: Edges of bars are smooth, so white background leaks into the window
class Webview extends StatefulWidget {
  const Webview({Key? key}) : super(key: key);

  @override
  WebviewState createState() => WebviewState();
}

class WebviewState extends State<Webview> {
  @override
  void initState() {
    super.initState();
    // Enable virtual display.
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      //padding: EdgeInsets.all(8.0),
      child: ClipRRect(
        //borderRadius: BorderRadius.all(Radius.circular(20)),
        child: FutureBuilder<Preslikave>(
            future: preslikava,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const WebView(
                    initialUrl: 'https://ars.rtvslo.si/b-air/');
              }
              if (snapshot.hasData) {
                return WebView(initialUrl: snapshot.data!.infoPageUrl);
              } else {
                return Container(
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator());
              }
            }),
      ),
    );
  }
}
