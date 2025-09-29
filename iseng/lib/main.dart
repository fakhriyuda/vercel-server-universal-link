import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iseng/deeplink_manager.dart';
import 'package:iseng/firebase_set.dart';
import 'package:iseng/page2.dart';
import 'package:iseng/page3.dart';
import 'package:iseng/product_page.dart';
import 'package:iseng/route_observer.dart';

final navKey = GlobalKey<NavigatorState>();

late final DeepLinkManager _dlm;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // await PushMessaging.I.init(
  //   onTap: (msg) async {
  //     debugPrint('🔔 [onTap] messageId=${msg.messageId} data=${msg.data}');
  //     // Route the user on notification tap
  //     // final route = msg.data['route'];
  //     // // Navigator.of(navigatorKey.currentContext!).pushNamed(route ?? '/');
  //   },
  // );
  _dlm = DeepLinkManager();
  runApp(Bootstrap(child: MyApp()));
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key, required this.child});
  final Widget child;
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  @override
  void initState() {
    super.initState();
    _dlm.start(); // mulai dengar deep links
  }

  @override
  void dispose() {
    _dlm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iseng',
      navigatorKey: navKey, // <-- pasang navigatorKey
      navigatorObservers: [
        // routeObserver, // <-- pasang routeObserver
        routeTracker, // <-- pasang routeTracker
      ],
      routes: {
        '/': (_) => MyHomePage(title: 'Flutter Demo Home Page'),
        '/2': (_) => const PageTwo(),
        '/3': (_) => const PageThree(),
        '/product': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as ProductArgs;
          debugPrint('navigasi ke ProductPage id=${args.id} ref=${args.ref}');
          return ProductPage(id: args.id, ref: args.ref);
        },
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? token;

  @override
  void initState() {
    // getToken();
    super.initState();
  }

  getToken() async {
    String? token = await PushMessaging.I.getToken();
    debugPrint('Token: $token');
    setState(() {
      this.token = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Your Token is here:'),
            Text(token ?? 'No Token'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token ?? 'No Token'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
          ],
        ),
      ),
    );
  }
}
