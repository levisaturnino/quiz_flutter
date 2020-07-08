import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

void main() => runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: WikipediaExplorer()));

class WikipediaExplorer extends StatefulWidget {
  @override
  _WikipediaExplorerState createState() => _WikipediaExplorerState();
}

class _WikipediaExplorerState extends State<WikipediaExplorer> {
  Completer<WebViewController> _controller = Completer<WebViewController>();
  final Set<String> _favorites = Set<String>();
  final _key = UniqueKey();
  bool _isLoadingPage;

  @override
  void initState() {
    super.initState();
    _isLoadingPage = true;
  }

  @override
  Widget build(BuildContext context) {
    const PrimaryColor = const Color(0xFF000000);
    _launchURL(url) async {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    }

    return new WillPopScope(
      // ignore: missing_return
      onWillPop: () {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text('Deseja realmente saí do Toritama Jeans?'),
                actions: [
                  // ignore: missing_return, missing_return, missing_return
                  FlatButton(
                    onPressed: () =>
                        Navigator.pop(context, false), // passing false
                    child: Text('Não'),
                  ),
                  FlatButton(
                    onPressed: () =>
                        Navigator.pop(context, true), // passing true
                    child: Text('Sim'),
                  ),
                ],
              );
              // ignore: missing_return
            }).then((exit) {
          if (exit == null) return;

          if (exit) {
            // user pressed Yes button
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          } else {
            // user pressed No button
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Oficial'),
          backgroundColor: PrimaryColor,
          // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
          actions: <Widget>[
            NavigationControls(_controller.future),
            Menu(_controller.future, () => _favorites),
          ],
        ),
        body: Stack(
          children: <Widget>[
            WebView(
              key: _key,
              initialUrl: 'https://www.toritama-jeans.com/webview/',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller.complete(webViewController);
              },
              onPageFinished: (finish) {
                setState(() {
                  _isLoadingPage = false;
                });
              },
              navigationDelegate: (NavigationRequest request) {
                setState(() {
                  _isLoadingPage = true;
                });
                if (request.url.contains("mailto:")) {
                  _launchURL(request.url);
                  return NavigationDecision.prevent;
                } else if (request.url.contains("tel:")) {
                  _launchURL(request.url);
                  return NavigationDecision.prevent;
                }else if (request.url.contains("whatsapp:")) {
                  _launchURL(request.url);
                  return NavigationDecision.prevent;
                  }
                else if (request.url.contains("whatsapp:")) {
                  _launchURL(request.url);
                  return NavigationDecision.prevent;
                }
                else if (request.url.contains("intent:")) {
                  _launchURL(request.url);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
            _isLoadingPage
                ? Container(
                    alignment: FractionalOffset.center,
                    child: CircularProgressIndicator(
                      valueColor: new AlwaysStoppedAnimation<Color>(Colors.yellow),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  _bookmarkButton() {
    return FutureBuilder<WebViewController>(
      future: _controller.future,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        if (controller.hasData) {
          return FloatingActionButton(
            onPressed: () async {
              var url = await controller.data.currentUrl();
              _favorites.add(url);
              Scaffold.of(context).showSnackBar(
                SnackBar(content: Text('Saved $url for later reading.')),
              );
            },
            child: Icon(Icons.favorite),
          );
        }
        return Container();
      },
    );
  }
}

class Menu extends StatelessWidget {
  Menu(this._webViewControllerFuture, this.favoritesAccessor);
  final Future<WebViewController> _webViewControllerFuture;
  // TODO(efortuna): Come up with a more elegant solution for an accessor to this than a callback.
  final Function favoritesAccessor;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        if (!controller.hasData) return Container();
        return PopupMenuButton<String>(
          onSelected: (String value) async {
            if (value == 'Email link') {
              var url = await controller.data.currentUrl();
              await launch(
                  'mailto:?subject=Check out this cool Wikipedia page&body=$url');
            } else {
              var newUrl = await Navigator.push(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return FavoritesPage(favoritesAccessor());
              }));
              Scaffold.of(context).removeCurrentSnackBar();
              if (newUrl != null) controller.data.loadUrl(newUrl);
            }
          },
         itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        /*    const PopupMenuItem<String>(
              value: 'Email link',
              child: Text('Email link'),
            ),
            const PopupMenuItem<String>(
              value: 'See Favorites',
              child: Text('See Favorites'),
            ),*/
          ],
        );
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  FavoritesPage(this.favorites);
  final Set<String> favorites;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favorite pages')),
      body: ListView(
          children: favorites
              .map((url) => ListTile(
                  title: Text(url), onTap: () => Navigator.pop(context, url)))
              .toList()),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture)
      : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: !webViewReady
                  ? null
                  : () => navigate(context, controller, goBack: true),

            ),
            IconButton(

              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: !webViewReady
                  ? null
                  : () => {
                navigate(context, controller, goBack: false)},
            ),
          ],
        );
      },
    );
  }



  navigate(BuildContext context, WebViewController controller,

      {bool goBack: false}) async {

    bool canNavigate =
        goBack ? await controller.canGoBack() : await controller.canGoForward();
    if (canNavigate) {

      goBack ? controller.goBack() : controller.goForward();
    } else {
      Scaffold.of(context).showSnackBar(
        SnackBar(
            content: Text("No ${goBack ? 'back' : 'forward'} history item")),
      );
    }
  }

}
