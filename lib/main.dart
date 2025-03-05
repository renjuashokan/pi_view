import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'route_generator.dart';
import 'viewmodels/login_viewmodel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        // Add other providers here if needed
      ],
      child: MaterialApp(
        title: 'FilePi Client',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
