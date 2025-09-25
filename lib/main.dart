import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:provider/provider.dart';
import 'callscreen/call_service.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'profile_setup_page.dart';
import 'pages/home_screen.dart';
import 'CallScreen/incoming_call_screen.dart';
import 'CallScreen/VideoCallScreen.dart';
import 'CallScreen/AudioCallScreen.dart';


final GlobalKey<NavigatorState> navigatorkey = GlobalKey<NavigatorState>();

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    await FirebaseFirestore.instance.collection('notifications').add({
      'receiverId': user.uid,
      'title': message.notification?.title ?? "New Notification",
      'body': message.notification?.body ?? "",
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  final data = message.data;
  if (data['type'] == 'call' && data['callId'] != null) {
    await FlutterCallkitIncoming.showCallkitIncoming(
      CallKitParams(
        id: data['callId'],
        nameCaller: data['callerName'] ?? 'Unknown',
        appName: 'MatchCall',
        avatar: data['callerAvatar'] ?? '',
        handle: data['callerId'],
        type: data['callType'] == 'video' ? 1:0,
        duration: 30000,
        extra: data,
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: 'https://i.pravatar.cc/500',
          actionColor: '#4CAF50',
        ),
      ),
    );
  }
}

  void main()  async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
       create: (_) => ThemeProvider(),
       child: const MyApp(),
      ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ///get FCM token
  void getFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint("FCM Token: $token");

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
    }
  }
  @override
  void initState() {
    super.initState();
    getFCMToken();

FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  final data = message.data;

  ///save notification to firestore
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance.collection('notifications').add({
      'receiverId': user.uid,
      'title': message.notification?.title ?? "New Notification",
      'body': message.notification?.body ?? "",
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  ///handle incoming call
  if (data['type'] == 'call' && data['callId'] != null) {
    FlutterCallkitIncoming.showCallkitIncoming(
      CallKitParams(
        id: data['callId'],
        nameCaller: data['callerName'] ?? 'Unknown',
        appName: 'MatchCall',
        avatar: data['callerAvatar'] ?? '',
        handle: data['callerId'],
        type: data['callType'] == 'video' ? 1 : 0,
        duration: 30000,
        extra: data,
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          actionColor: '#4CAF50',
        ),
      ),
    );
  }
 });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;
      if (data['type'] == 'call' && data['callId'] != null){
        _openIncomingScreen(data['callId']);
      }
    });

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;
      final ev = event.event;
      final body = event.body ?? {};
      final callId = body['id'] ?? body['callId'] ?? body['callID'] ?? '';
      final callType = body['callType'] ?? 'audio';
      final callService = CallService();

      switch (ev) {
        case Event.actionCallAccept:
          await callService.acceptCall(callId);
          _openIncomingScreen(callId, callType); // this will push your IncomingCallPage which will navigate to call screen
          break;
        case Event.actionCallDecline:
          await callService.rejectCall(callId);
          break;
        case Event.actionCallEnded:
          await callService.endCall(
            channelName: callId,
            receiverId: '',
            receiverName: '',
            callType: callType,
            startTime: DateTime.now(),
          );
          break;
        default:
          break;
      }
    });
  }

  void _openIncomingScreen(String callId, [String callType = 'audio']) async {
    final doc = await FirebaseFirestore.instance.collection('calls').doc(callId).get();
      if (doc.exists) {
        navigatorkey.currentState?.push(
            MaterialPageRoute(
          builder: (_) => IncomingCallPage(callData: doc.data()!),
         )
        );
      }
  }

  void _openCallScreen(String callId, String callType) async {
    final doc = await FirebaseFirestore.instance.collection('calls').doc(callId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final channelName = data['channelName'];
      final receiverId = data['receiverId'];
      final receiverName = data['receiverName'];
      final token = data['callerToken'] ?? data['receiverToken'] ?? '';

      navigatorkey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => callType == 'video'
              ? VideoCallScreen(
            channelName: channelName,
            receiverId: receiverId,
            receiverName: receiverName,
            token: token,
          )
              : AudioCallScreen(
            channelName: channelName,
            receiverId: receiverId,
            receiverName: receiverName,
            token: token,
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorkey,
      title: 'MatchCall',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      home: const EntryPoint(),
    );
  }
}


class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  bool _isLoading = true;
  Widget _landingPage = const LoginPage();

  @override
  void initState() {
    super.initState();
    _determineLandingPage();
  }

  Future<void> _determineLandingPage() async {
    final prefs = await SharedPreferences.getInstance();
    final signedUp = prefs.getBool("hasSignedUp") ?? false;
    final loggedIn = FirebaseAuth.instance.currentUser != null;

    if(!signedUp) {
      _landingPage = const SignUpPage();
    } else if(!loggedIn) {
        _landingPage = const LoginPage();
      } else {

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
    final profileCompleted = userDoc.data()?['profileCompleted'] ?? false;
    _landingPage = profileCompleted ? const HomeScreen() : const ProfileSetupPage();
        }

    setState(() {
      _isLoading = false;
    });
  }

 @override
    Widget build(BuildContext context) {
    return _isLoading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _landingPage;
    }
 }




 // 9b638404a3e04fc19c515994acbeb358 - primary certificate
// 143e70ab953f419ca6bdadd36f09d111 - secondary certificate
// af6296faa12444958370d9655380d002 - appId
//{"token":"006af6296faa12444958370d9655380d002IAD89gvr3UmpYccVFzIQGlDYLgFjbpX/yO22ZqHcwbJe7LuiVPCBkyDDIgBz0wO8ND+vaAQAAQA0IY9qAgA0IY9qAwA0IY9qBAA0IY9q","expiresAt":1787765044}
//FCM Token: f6MDCz5mQOyGpyqzfMvCUi:APA91bGRLxuyAbTkTTRDLXsS43tW1trQCQ-VJXLZ0eVpoDKP1ouV0UAFlcTDo0uW001RD9cuA7LqJQ4qVVfkuuU3lJEgypVpyRXvqCV1RxwXZNUoLbgfMss
