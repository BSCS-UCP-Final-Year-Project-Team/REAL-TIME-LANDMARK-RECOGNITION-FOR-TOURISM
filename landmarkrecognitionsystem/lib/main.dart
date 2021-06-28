import 'package:flutter/material.dart';
import 'package:landmarkrecognitionsystem/splashscreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Landmark Recognition System',
      home: MySplash(),
      debugShowCheckedModeBanner: false,
    );
  }
}
