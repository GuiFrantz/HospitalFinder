import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prjectcm/connectivity_module.dart';
import 'package:prjectcm/data/http_sns_datasource.dart';
import 'package:prjectcm/data/sqflite_sns_datasource.dart';
import 'package:prjectcm/location_module.dart';
import 'package:prjectcm/main.dart';
import 'package:prjectcm/models/hospital.dart';
import 'package:provider/provider.dart';

import 'fake_connectivity_module.dart';
import 'fake_http_sns_datasource.dart';
import 'fake_location_module.dart';
import 'fake_sqflite_sns_datasource.dart';

void main() {
  runWidgetTests();
}

void runWidgetTests() {


  testWidgets('Show error message when starting offline (hospitals list)', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<HttpSnsDataSource>.value(value: FakeHttpSnsDataSource()),
        Provider<SqfliteSnsDataSource>.value(value: FakeSqfliteSnsDataSource()),
        Provider<LocationModule>.value(value: FakeLocationModule()),
        Provider<ConnectivityModule>.value(value: FakeConnectivityModule(online: false)),
      ],
      child: const MyApp(),
    ));

    // have to wait for async initializations
    await tester.pumpAndSettle(Duration(milliseconds: 200));

    var listBottomBarItemFinder = find.byKey(Key('lista-bottom-bar-item'));
    expect(listBottomBarItemFinder, findsOneWidget,
        reason: "Deveria existir um NavigationDestination com a key 'lista-bottom-bar-item'");
    await tester.tap(listBottomBarItemFinder);
    await tester.pumpAndSettle();

    expect(find.text("Não foi possível obter os hospitais. Verifique a conectividade e volte a tentar"), findsOneWidget,
        reason: "Deveria existir pelo menos um Text com o texto 'Não foi possível obter os hospitais. "
            "Verifique a conectividade e volte a tentar' quando se arranca a app em offline e ela nunca"
            "obteve previamente os hospitais");
  });


  testWidgets('Start online, get hospitals list, then go offline and refresh hospitals list',
          (WidgetTester tester) async {
        final fakeConnectivityModule = FakeConnectivityModule();
        final fakeHttpSnsDataSource = FakeHttpSnsDataSource();

        await tester.pumpWidget(MultiProvider(
          providers: [
            Provider<HttpSnsDataSource>.value(value: fakeHttpSnsDataSource),
            Provider<SqfliteSnsDataSource>.value(value: FakeSqfliteSnsDataSource()),
            Provider<LocationModule>.value(value: FakeLocationModule()),
            Provider<ConnectivityModule>.value(value: fakeConnectivityModule),
          ],
          child: const MyApp(),
        ));

        // have to wait for async initializations
        await tester.pumpAndSettle(Duration(milliseconds: 200));

        // go to hospitals list
        var listBottomBarItemFinder = find.byKey(Key('lista-bottom-bar-item'));
        expect(listBottomBarItemFinder, findsOneWidget,
            reason: "Deveria existir um NavigationDestination com a key 'lista-bottom-bar-item'");
        await tester.tap(listBottomBarItemFinder);
        await tester.pumpAndSettle();

        final Finder listViewFinder = find.byKey(Key('list-view'));
        expect(listViewFinder, findsOneWidget);
        final Finder listTilesFinder = find.descendant(of: listViewFinder, matching: find.byType(ListTile));
        final tiles = List.from(tester.widgetList<ListTile>(listTilesFinder));
        expect(tiles.length, 2);

        // go to dashboard
        var dashboardBottomBarItemFinder = find.byKey(Key('dashboard-bottom-bar-item'));
        expect(dashboardBottomBarItemFinder, findsOneWidget,
            reason: "Deveria existir um NavigationDestination com a key 'dashboard-bottom-bar-item'");
        await tester.tap(dashboardBottomBarItemFinder);
        await tester.pumpAndSettle();


        // go offline
        fakeConnectivityModule.online = false;

        // inject another hospital in the online version
        fakeHttpSnsDataSource.hospitals.add(
          Hospital(
            id: 3,
            name: 'hospital 3',
            latitude: 0.0,
            longitude: 0.0,
            address: 'address3',
            phoneNumber: 456,
            email: 'hospital2@sns.pt',
            district: 'Porto',
            hasEmergency: false,
          ),
        );

        // go to hospitals list again
        await tester.tap(listBottomBarItemFinder);
        await tester.pumpAndSettle();

        final Finder listViewFinder2 = find.byKey(Key('list-view'));
        expect(listViewFinder2, findsOneWidget);
        final Finder listTilesFinder2 = find.descendant(of: listViewFinder, matching: find.byType(ListTile));
        final tiles2 = List.from(tester.widgetList<ListTile>(listTilesFinder2));
        expect(tiles2.length, 2, reason: "Devia ter mostrado 2 hospitais vindos da BD pois está offline");

        // go to dashboard
        await tester.tap(dashboardBottomBarItemFinder);
        await tester.pumpAndSettle();

        // go online
        fakeConnectivityModule.online = true;

        // go to hospitals list again
        await tester.tap(listBottomBarItemFinder);
        await tester.pumpAndSettle();

        final Finder listViewFinder3 = find.byKey(Key('list-view'));
        expect(listViewFinder3, findsOneWidget);
        final Finder listTilesFinder3 = find.descendant(of: listViewFinder, matching: find.byType(ListTile));
        final tiles3 = List.from(tester.widgetList<ListTile>(listTilesFinder3));
        expect(tiles3.length, 3, reason: "Devia ter mostrado 3 hospitais vindos do servidor pois está online");
      });

  testWidgets('Show hospitals list and detail with distance', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<HttpSnsDataSource>.value(value: FakeHttpSnsDataSource()),
        Provider<SqfliteSnsDataSource>.value(value: FakeSqfliteSnsDataSource()),
        Provider<LocationModule>.value(value: FakeLocationModule(latitude: 38.7580, longitude: -9.1531)),
        Provider<ConnectivityModule>.value(value: FakeConnectivityModule()),
      ],
      child: const MyApp(),
    ));

    // have to wait for async initializations
    await tester.pumpAndSettle(Duration(milliseconds: 200));

    var listBottomBarItemFinder = find.byKey(Key('lista-bottom-bar-item'));
    expect(listBottomBarItemFinder, findsOneWidget);
    await tester.tap(listBottomBarItemFinder);
    await tester.pumpAndSettle();

    final Finder listViewFinder = find.byKey(Key('list-view'));
    expect(listViewFinder, findsOneWidget);
    final Finder listTilesFinder = find.descendant(of: listViewFinder, matching: find.byType(ListTile));
    final tiles = List.from(tester.widgetList<ListTile>(listTilesFinder));
    expect(tiles.length, 2);

    await tester.tap(listTilesFinder.first);
    await tester.pumpAndSettle();

    // // just for demo purposes
    // await Future.delayed(Duration(seconds: 10));

    // find if the text 'hospital1' is present
    final Finder hospital1Finder = find.text('hospital 1');
    expect(hospital1Finder, findsAtLeastNWidgets(1), reason: "Deveria existir pelo menos um Text com o texto 'hospital 1' (primeiro elemento da lista)");
    expect(find.textContaining('559'), findsAtLeastNWidgets(1), reason: "Deveria existir pelo menos um Text contendo o texto '559' (representando a distância em metros entre"
        "a localização atual e a localização deste hospital)");
  });
}