import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'widgets/home_page.dart';
import 'widgets/login_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create:
          (context) =>
              UserProvider()
                ..init()
                ..updateUser(),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      scrollBehavior: NoThumbScrollBehavior().copyWith(scrollbars: false),
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoggedIn == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (userProvider.isLoggedIn!) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
