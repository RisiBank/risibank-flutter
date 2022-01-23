import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share/share.dart';
import 'package:path_provider/path_provider.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    return Scaffold(
      body: InAppWebView(
        initialUrlRequest: URLRequest(
            url: Uri.parse(
                "https://risibank.fr/embed?"
                "theme=light"
                "&mediaSize=lg"
                "&navbarSize=lg"
                "&showCopyButton=true"
                "&allowUsernameSelection=false"
            )),
        initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              mediaPlaybackRequiresUserGesture: false,
            ),
            android: AndroidInAppWebViewOptions(useHybridComposition: true)),
        onLoadStop: (controller, url) async {
          await controller.evaluateJavascript(source: """
            // message event listener
            window.addEventListener("message", (event) => {
              console.log(JSON.stringify(event.data));
            }, false);
          """);
        },
        onConsoleMessage: (controller, consoleMessage) async {
          Map<String, dynamic> eventData = jsonDecode(consoleMessage.message);
          if (eventData['type'] == 'risibank-media-selected') {
            dynamic media = eventData['media'];
            String mediaUrl = media['cache_url'];
            String mediaExtension = media['cache_url'].split('.').last;
            String mediaMimeType = 'image/' + mediaExtension;
            final response = await get(Uri.parse(mediaUrl));
            final Directory temp = await getTemporaryDirectory();
            String mediaTempFilePath =
                '${temp.path}/${media['id']}.$mediaExtension';
            final File imageFile = File(mediaTempFilePath);
            imageFile.writeAsBytesSync(response.bodyBytes);
            Share.shareFiles(
              [mediaTempFilePath],
              mimeTypes: [mediaMimeType]
            );
          } else if (eventData['type'] == 'risibank-media-copy') {
            dynamic media = eventData['media'];
            // Actually share the URL to the clipboard
            Clipboard.setData(ClipboardData(text: media['source_url']));
            // Share URL? -> Share.share(media['source_url']);
            // Show confirmation:
            final snackBar = SnackBar(
              content: const Text('Lien noelshack copié'),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () { },
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
      ),
    );
  }
}
