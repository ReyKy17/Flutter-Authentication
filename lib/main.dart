import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

//1
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
//

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
//2
    return MaterialApp(
      title: 'Flutter Firebase Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
//
//3
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
//
        builder: (context, snapshot) {
//4
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
//
//5
          if (snapshot.hasData) {
            // Pengguna sudah login
            return const HomeScreen();
          }

          // Pengguna belum login
          return const AuthScreen();
//
        },
      ),
    );
  }
}