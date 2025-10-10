import 'package:finance_tracker_app/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/account_provider.dart';
import 'widgets/home_page.dart';
import 'widgets/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServiceLocator.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider()..init(),
        ),
        ChangeNotifierProvider<TransactionProvider>(
          create: (context) => TransactionProvider()..init(),
        ),
        ChangeNotifierProvider<CategoryProvider>(
          create: (context) => CategoryProvider()..init(),
        ),
        ChangeNotifierProvider<AccountProvider>(
          create: (context) => AccountProvider()..init(),
        ),
      ],
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
          if (!userProvider.isReady) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (userProvider.isLoggedIn) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
