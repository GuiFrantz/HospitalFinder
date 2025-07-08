import 'package:flutter/material.dart';
import 'package:prjectcm/screens/dashboard.dart';
import 'package:prjectcm/screens/evaluate.dart';
import 'package:prjectcm/screens/hospitals_list.dart';
import 'package:prjectcm/screens/hospitals_map.dart';

import 'main.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(),
      HospitalsList(),
      HospitalsMap(),
      EvaluateHospital(),
    ];
    // Title for page's AppBar
    final List<String> titles = [
      "Dashboard",
      "Lista de Hospitais",
      "Mapa de Hospitais",
      "Avaliar",
    ];

    return Scaffold(
      appBar: buildAppBar(titles),
      body: screens[_selectedIndex],
      bottomNavigationBar: buildNavigationBar(),
    );
  }

  AppBar buildAppBar(List<String> titles) {
    return AppBar(
      backgroundColor: AppColors.mainAppColor,
      centerTitle: true,
      title: Text(
        titles[_selectedIndex],
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  NavigationBar buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      destinations: [
        NavigationDestination(
          key: const Key('dashboard-bottom-bar-item'),
          icon: Icon(Icons.dashboard),
          label: "Dashboard",
        ),
        NavigationDestination(
          key: const Key('lista-bottom-bar-item'),
          icon: Icon(Icons.list),
          label: "Lista",
        ),
        NavigationDestination(
          key: const Key('mapa-bottom-bar-item'),
          icon: Icon(Icons.map),
          label: "Mapa",
        ),
        NavigationDestination(
          key: const Key('avaliacoes-bottom-bar-item'),
          icon: Icon(Icons.star),
          label: "Avaliar",
        ),
      ],
    );
  }
}
