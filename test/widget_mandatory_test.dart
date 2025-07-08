import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:prjectcm/connectivity_module.dart';
import 'package:prjectcm/data/http_sns_datasource.dart';
import 'package:prjectcm/data/sqflite_sns_datasource.dart';
import 'package:prjectcm/location_module.dart';
import 'package:prjectcm/main.dart';
import 'package:prjectcm/models/hospital.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:testable_form_field/testable_form_field.dart';

import 'fake_connectivity_module.dart';
import 'fake_http_sns_datasource.dart';
import 'fake_location_module.dart';
import 'fake_sqflite_sns_datasource.dart';

void main() {
  runWidgetTests();
}

void runWidgetTests() {

  testWidgets('Has navigation bar with 4 options', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<HttpSnsDataSource>.value(value: FakeHttpSnsDataSource()),
        Provider<SqfliteSnsDataSource>.value(value: FakeSqfliteSnsDataSource()),
        Provider<LocationModule>.value(value: FakeLocationModule()),
        Provider<ConnectivityModule>.value(value: FakeConnectivityModule()),
      ],
      child: const MyApp(),
    ));

    // have to wait for async initializations
    await tester.pumpAndSettle(Duration(milliseconds: 200));

    expect(find.byType(NavigationBar), findsOneWidget,
        reason: "Deveria existir uma NavigationBar (atenção que a BottomNavigationBar deve deixar de ser usada)");
    expect(find.byType(NavigationDestination), findsNWidgets(4),
        reason: "Deveriam existir 4 NavigationDestination dentro da NavigationBar");

    for (String key in ['dashboard-bottom-bar-item', 'lista-bottom-bar-item', 'mapa-bottom-bar-item', 'avaliacoes-bottom-bar-item']) {
      expect(find.byKey(Key(key)), findsOneWidget,
          reason: "Deveria existir um NavigationDestination com a key '$key'");
    }
  });

  testWidgets('Show hospitals list', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<HttpSnsDataSource>.value(value: FakeHttpSnsDataSource()),
        Provider<SqfliteSnsDataSource>.value(value: FakeSqfliteSnsDataSource()),
        Provider<LocationModule>.value(value: FakeLocationModule()),
        Provider<ConnectivityModule>.value(value: FakeConnectivityModule()),
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

    final Finder listViewFinder = find.byKey(Key('list-view'));
    expect(listViewFinder, findsOneWidget,
        reason: "Depois de saltar para o ecrã com a lista, deveria existir um ListView com a key 'list-view'");
    expect(tester.widget(listViewFinder), isA<ListView>(),
        reason: "O widget com a key 'list-view' deveria ser um ListView");

    final Finder listTilesFinder = find.descendant(of: listViewFinder, matching: find.byType(ListTile));
    final tiles = List.from(tester.widgetList<ListTile>(listTilesFinder));
    expect(tiles.length, 2, reason: "Deveriam existir 2 ListTiles dentro do ListView dos hospitais");

    // Ensure the first ListTile contains a Text widget with "Hospital 1"
    final Finder firstTileTextFinder = find.descendant(of: listTilesFinder.first, matching: find.text("hospital 1"));
    expect(firstTileTextFinder, findsOneWidget,
        reason: "O primeiro ListTile deveria conter um Text com o texto 'hospital 1'");

    // Ensure the second ListTile contains a Text widget with "Hospital 2"
    final Finder secondTileTextFinder = find.descendant(of: listTilesFinder.last, matching: find.text("hospital 2"));
    expect(secondTileTextFinder, findsOneWidget,
        reason: "O segundo ListTile deveria conter um Text com o texto 'hospital 2'");

  });


  // check if it shows a circularprogressindicator while it doesn't receive an answer from the server
  testWidgets('Show hospitals list with delay', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<HttpSnsDataSource>.value(value: FakeHttpSnsDataSource(delay: 1)),
        Provider<SqfliteSnsDataSource>.value(value: FakeSqfliteSnsDataSource()),
        Provider<LocationModule>.value(value: FakeLocationModule()),
        Provider<ConnectivityModule>.value(value: FakeConnectivityModule()),
      ],
      child: const MyApp(),
    ));

    // have to wait for async initializations
    await tester.pumpAndSettle(Duration(milliseconds: 200));

    var listBottomBarItemFinder = find.byKey(Key('lista-bottom-bar-item'));
    expect(listBottomBarItemFinder, findsOneWidget,
        reason: "Deveria existir um NavigationDestination com a key 'lista-bottom-bar-item'");
    await tester.tap(listBottomBarItemFinder);
    await tester.pump();    // one pump for circular progress indicator
    await tester.pump(Duration(milliseconds: 100));  // another pump should still show circular progress indicator

    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: "Enquanto carrega a lista de hospitais, devia mostrar um CircularProgressIndicator");

    // wait for the response
    await tester.pumpAndSettle(Duration(seconds: 1));

    final Finder listViewFinder = find.byKey(Key('list-view'));
    expect(listViewFinder, findsOneWidget,
        reason: "Após mostrar o CircularProgressIndicator, deveria existir um ListView com a key 'list-view'");
    expect(tester.widget(listViewFinder), isA<ListView>(),
        reason: "O widget com a key 'list-view' deveria ser um ListView");
  });


  testWidgets('Show hospitals map', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<HttpSnsDataSource>.value(value: FakeHttpSnsDataSource()),
        Provider<SqfliteSnsDataSource>.value(value: FakeSqfliteSnsDataSource()),
        Provider<LocationModule>.value(value: FakeLocationModule()),
        Provider<ConnectivityModule>.value(value: FakeConnectivityModule()),
      ],
      child: const MyApp(),
    ));

    // have to wait for async initializations
    await tester.pumpAndSettle(Duration(milliseconds: 200));

    var mapBottomBarItemFinder = find.byKey(Key('mapa-bottom-bar-item'));
    expect(mapBottomBarItemFinder, findsOneWidget,
        reason: "Deveria existir um NavigationDestination com a key 'mapa-bottom-bar-item'");
    await tester.tap(mapBottomBarItemFinder);
    await tester.pumpAndSettle();

    // Find the GoogleMap widget
    final Finder mapFinder = find.byType(GoogleMap);
    expect(mapFinder, findsOneWidget,
        reason: "Depois de saltar para o ecrã com o mapa, deveria existir um widget do tipo GoogleMap");

    // Extract the GoogleMap widget
    final GoogleMap googleMap = tester.widget<GoogleMap>(mapFinder);
    // Ensure the map contains exactly two markers
    expect(googleMap.markers.length, 2, reason: "O mapa deve conter exatamente 2 marcadores");
  });

  testWidgets('Show hospitals list and detail', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<HttpSnsDataSource>.value(value: FakeHttpSnsDataSource()),
        Provider<SqfliteSnsDataSource>.value(value: FakeSqfliteSnsDataSource()),
        Provider<LocationModule>.value(value: FakeLocationModule()),
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

    // go back
    await tester.pageBack();
    await tester.pumpAndSettle();

    final Finder listTilesFinder2 = find.descendant(of: find.byKey(Key('list-view')), matching: find.byType(ListTile));
    await tester.tap(listTilesFinder2.at(1));
    await tester.pumpAndSettle();

    // find if the text 'hospital2' is present
    final Finder hospital2Finder = find.text('hospital 2');
    expect(hospital2Finder, findsAtLeastNWidgets(1), reason: "Deveria existir pelo menos um Text com o texto 'hospital 2' (segundo elemento da lista)");
  });

  testWidgets('Insert evaluation and show detail', (WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<HttpSnsDataSource>.value(value: FakeHttpSnsDataSource()),
        Provider<SqfliteSnsDataSource>.value(value: FakeSqfliteSnsDataSource()),
        Provider<LocationModule>.value(value: FakeLocationModule()),
        Provider<ConnectivityModule>.value(value: FakeConnectivityModule()),
      ],
      child: const MyApp(),
    ));

    // have to wait for async initializations
    await tester.pumpAndSettle(Duration(milliseconds: 200));

    var avaliacoesBottomBarItemFinder = find.byKey(Key('avaliacoes-bottom-bar-item'));
    expect(avaliacoesBottomBarItemFinder, findsOneWidget,
        reason: "Deveria existir um NavigationDestination com a key 'avaliacoes-bottom-bar-item'");
    await tester.tap(avaliacoesBottomBarItemFinder);
    await tester.pumpAndSettle();

    final Finder hospitalSelectionViewFinder = find.byKey(Key('evaluation-hospital-selection-field'));
    expect(hospitalSelectionViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'evaluation-hospital-selection-field'");
    expect(tester.widget(hospitalSelectionViewFinder), isA<TestableFormField<Hospital>>(),
        reason: "O widget com a key 'evaluation-hospital-selection-field' deveria ser um TestableFormField<Hospital>");
    TestableFormField<Hospital> hospitalSelectionFormField = tester.widget(hospitalSelectionViewFinder);

    final Finder ratingViewFinder = find.byKey(Key('evaluation-rating-field'));
    expect(ratingViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'evaluation-rating-field'");
    expect(tester.widget(ratingViewFinder), isA<TestableFormField<int>>(),
        reason: "O widget com a key 'evaluation-rating-field' deveria ser um TestableFormField<int>");
    TestableFormField<int> ratingFormField = tester.widget(ratingViewFinder);

    final Finder dateTimeViewFinder = find.byKey(Key('evaluation-datetime-field'));
    expect(dateTimeViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'evaluation-datetime-field'");
    expect(tester.widget(dateTimeViewFinder), isA<TestableFormField<DateTime>>(),
        reason: "O widget com a key 'evaluation-datetime-field' deveria ser um TestableFormField<DateTime>");
    TestableFormField<DateTime> dateTimeFormField = tester.widget(dateTimeViewFinder);

    final Finder commentViewFinder = find.byKey(Key('evaluation-comment-field'));
    expect(commentViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'evaluation-comment-field'");
    expect(tester.widget(commentViewFinder), isA<TestableFormField<String>>(),
        reason: "O widget com a key 'evaluation-comment-field' deveria ser um TestableFormField<String>");
    TestableFormField<String> commentFormField = tester.widget(commentViewFinder);

    // using "an hour ago" instead of current time since probably the form field will have its default value set to now
    final aHourAgo = DateTime.now().subtract(Duration(hours: 1));
    hospitalSelectionFormField.setValue(FakeHttpSnsDataSource().hospitals[0]);
    // ratingFormField.setValue(4);  // don't set the value for now
    dateTimeFormField.setValue(aHourAgo);
    commentFormField.setValue("No comments");

    final Finder submitButtonViewFinder = find.byKey(Key('evaluation-form-submit-button'));
    expect(submitButtonViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'evaluation-form-submit-button'");
    await tester.tap(submitButtonViewFinder);
    await tester.pumpAndSettle();

    // it should show a text near the field explaining the error
    expect(find.textContaining('Preencha a avaliação'), findsOneWidget);

    // it should show a snackbar telling a field is missing
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pumpAndSettle(Duration(seconds: 5));

    ratingFormField.setValue(5);  // set the missing value now

    final Finder submitButtonViewFinder2 = find.byKey(Key('evaluation-form-submit-button'));
    expect(submitButtonViewFinder2, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'evaluation-form-submit-button'");
    await tester.ensureVisible(submitButtonViewFinder2);
    await tester.tap(submitButtonViewFinder2);
    await tester.pumpAndSettle();

    // go to list
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

    // find if the text 'hospital1' is present
    expect(find.text('hospital 1'), findsAtLeastNWidgets(1),
        reason: "Deveria existir pelo menos um Text com o texto 'hospital 1' (primeiro elemento da lista)");

    // find if the text with the current date is present
    final nowStr = DateFormat("dd/MM/yyyy HH:mm").format(aHourAgo);
    expect(find.text(nowStr), findsAtLeastNWidgets(1),
        reason: "Deveria existir pelo menos um Text com o texto '$nowStr' (data de uma das avaliações)");

    // find if the text 'No comments' is present
    expect(find.text('No comments'), findsAtLeastNWidgets(1),
        reason: "Deveria existir pelo menos um Text com o texto 'No comments' (texto de uma das avaliações)");

  });

}