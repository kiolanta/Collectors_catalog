import 'package:collectors_catalog/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget get _subject => const MaterialApp(home: LoginPage());

void main() {
  group('LoginPage – renders key elements', () {
    testWidgets('shows Log in heading', (tester) async {
      await tester.pumpWidget(_subject);
      await tester.pump();

      expect(find.text('Log in'), findsWidgets);
    });

    testWidgets('shows Artefacto title', (tester) async {
      await tester.pumpWidget(_subject);
      await tester.pump();

      expect(find.text('Artefacto'), findsOneWidget);
    });

    testWidgets('renders email and password TextFormFields', (tester) async {
      await tester.pumpWidget(_subject);
      await tester.pump();

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('renders Log in submit button', (tester) async {
      await tester.pumpWidget(_subject);
      await tester.pump();

      expect(find.widgetWithText(ElevatedButton, 'Log in'), findsOneWidget);
    });
  });

  group('LoginPage – form validation', () {
    testWidgets('shows email error when submitting empty form', (tester) async {
      await tester.pumpWidget(_subject);
      await tester.pump();

      // Tap Log in with no input — validate() fires, _authService is never accessed
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows password error when submitting empty form', (
      tester,
    ) async {
      await tester.pumpWidget(_subject);
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows invalid email error after typing bad email', (
      tester,
    ) async {
      await tester.pumpWidget(_subject);
      await tester.pump();

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'not-an-email');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('password toggle changes visibility icon', (tester) async {
      await tester.pumpWidget(_subject);
      await tester.pump();

      // Initially hidden → visibility_off icon shown
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // After toggle → visibility icon shown
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
