import 'dart:io' as io;
import 'package:prjectcm/data/http_sns_datasource.dart';
import 'package:prjectcm/data/sqflite_sns_datasource.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'connectivity_module.dart';
import 'location_module.dart';
import 'main_screen.dart';

class AppColors {
  // Main Color (same from Interação Humano-Máquina)
  static const Color mainAppColor = Color.fromARGB(255, 204, 134, 19);
}

void main() {
  io.HttpOverrides.global = _HttpOverrides();
  final httpSnsDataSource = HttpSnsDataSource();
  final sqfliteSnsDataSource = SqfliteSnsDataSource();
  final locationModule = LocationModule();
  final connectivityModule = ConnectivityModule();

  runApp(
    MultiProvider(
      providers: [
        Provider<HttpSnsDataSource>(create: (_) => httpSnsDataSource),
        Provider<SqfliteSnsDataSource>(create: (_) => sqfliteSnsDataSource),
        Provider<LocationModule>(create: (_) => locationModule),
        Provider<ConnectivityModule>(create: (_) => connectivityModule),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _HttpOverrides extends io.HttpOverrides {
  @override
  io.HttpClient createHttpClient(io.SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (io.X509Certificate cert, String host, int port) => true;
  }
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final sqfliteSnsDataSource = SqfliteSnsDataSource();

    return FutureBuilder(
      future: sqfliteSnsDataSource.init(),
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
              home: Center(
            child: CircularProgressIndicator(),
          ));
        } else {
          return MaterialApp(
            title: 'SNS Hospitais',
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: AppColors.mainAppColor),
            ),
            home: const MyHomePage(title: 'SNS Hospitais'),
          );
        }
      },
    );
  }
}
