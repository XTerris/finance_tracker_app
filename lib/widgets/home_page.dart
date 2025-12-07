import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tabs/dashboard.dart';
import 'tabs/history.dart';
import 'tabs/accounts.dart';
import 'tabs/reports.dart';

// Главная страница приложения с вкладками навигации
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  // Список вкладок приложения (используем PageStorageKey для сохранения состояния)
  final List<Widget> _tabs = [
    DashboardTab(key: PageStorageKey('dashboard_tab')),
    HistoryTab(key: PageStorageKey('history_tab')),
    AccountsAndGoalsTab(key: PageStorageKey('accounts_and_goals_tab')),
    ReportsTab(key: PageStorageKey('reports_tab')),
  ];

  void _setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack сохраняет состояние неактивных вкладок
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _tabs),
      ),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        elevation: 0.0,
        toolbarHeight: 0.0,
      ),
      bottomNavigationBar: NavigationBar(
        currentIndex: _currentIndex,
        onTap: _setCurrentIndex,
      ),
    );
  }
}

// Кастомная панель навигации внизу экрана
class NavigationBar extends StatelessWidget {
  const NavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  final ValueChanged<int> onTap;

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => onTap(index),
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 14,
      unselectedFontSize: 14,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Обзор'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'История'),
        BottomNavigationBarItem(
          icon: Icon(Icons.monetization_on_outlined),
          label: 'Цели и накопления',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Отчёты'),
      ],
    );
  }
}

// Настройка поведения скролла для всех типов устройств ввода
class NoThumbScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}
