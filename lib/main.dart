import 'package:finance_tracker_app/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/account_provider.dart';
import 'providers/goal_provider.dart';
import 'widgets/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServiceLocator.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TransactionProvider>(
          create: (context) => TransactionProvider()..init(),
        ),
        ChangeNotifierProvider<CategoryProvider>(
          create: (context) => CategoryProvider()..init(),
        ),
        ChangeNotifierProvider<AccountProvider>(
          create: (context) => AccountProvider()..init(),
        ),
        ChangeNotifierProvider<GoalProvider>(
          create: (context) => GoalProvider()..init(),
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('ru', 'RU')],
      scrollBehavior: NoThumbScrollBehavior().copyWith(scrollbars: false),
      home: const HomePage(),
    );
  }
}
