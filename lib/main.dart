import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sisyphus/screen/main_screen.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Wakelock.enable();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark
        ),
          primarySwatch: Colors.pink,
          fontFamily: 'Jamsil'
      ),
      home: const MainScreen(),
    );
  }
}
