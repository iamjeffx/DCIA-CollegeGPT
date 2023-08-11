// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'env.dart';

import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;

final GoogleSignIn _googleSignIn = GoogleSignIn(
  // Optional clientId
  clientId: Env.googleAPIKey,
  scopes: <String>[CalendarApi.calendarScope],
);

void main() {
  runApp(
    const MaterialApp(
      title: 'Google Sign In + googleapis',
      home: SignInDemo(),
    ),
  );
}

/// The main widget of this demo.
class SignInDemo extends StatefulWidget {
  /// Creates the main widget of this demo.
  const SignInDemo({super.key});

  @override
  State createState() => SignInDemoState();
}

/// The state of the main widget.
class SignInDemoState extends State<SignInDemo> {
  GoogleSignInAccount? _currentUser;
  String _eventName = '';
  CalendarApi? calendarAPI;
  String? calendarID;
  final eventName = TextEditingController();

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _handleGetCalendar();
      }
    });
    _googleSignIn.signInSilently();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    eventName.dispose();
    super.dispose();
  }

  Future<void> _handleGetCalendar() async {
    setState(() {
      _eventName = "Getting Event";
    });

    // Retrieve an [auth.AuthClient] from the current [GoogleSignIn] instance.
    final auth.AuthClient? client = await _googleSignIn.authenticatedClient();
    final bool isAuthorized = await _googleSignIn
        .canAccessScopes(<String>[CalendarApi.calendarScope]);
    assert(client != null, 'Authenticated client missing!');
    assert(isAuthorized, 'Necessary scopes not granted');
    calendarAPI = CalendarApi(client!);
    const String calendarSummary = "CollegeGPT";

    Calendar collegeGPTCalendar;
    CalendarList calendarList = await calendarAPI!.calendarList.list();

    if (calendarList.items != null) {
      for (var listElement in calendarList.items!) {
        if (listElement.summary == calendarSummary) {
          calendarID = listElement.id;
        }
      }
    }

    if (calendarID != null) {
      collegeGPTCalendar = await calendarAPI!.calendars.get(calendarID!);
    } else {
      collegeGPTCalendar =
          await calendarAPI!.calendars.insert(Calendar(summary: "CollegeGPT"));
      calendarID = collegeGPTCalendar.id;
    }
    final Events calendarEvents = await calendarAPI!.events.list(calendarID!);
    setState(() {
      if (calendarEvents.items?.isNotEmpty ?? false) {
        _eventName = calendarEvents.items!.first.summary ?? "No Events";
      } else {
        _eventName = "No Events";
      }
    });
  }

  void _handleAddEvent() {
    calendarAPI?.events.insert(
        Event(
            summary: eventName.text,
            end: EventDateTime(date: DateTime.now()),
            start: EventDateTime(date: DateTime.now())),
        calendarID!);
    eventName.clear();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error); // ignore: avoid_print
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Widget _buildBody() {
    final GoogleSignInAccount? user = _currentUser;
    if (user != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ListTile(
            leading: GoogleUserCircleAvatar(
              identity: user,
            ),
            title: Text(user.displayName ?? ''),
            subtitle: Text(user.email),
          ),
          const Text('Signed in successfully.'),
          Text(_eventName),
          ElevatedButton(
            onPressed: _handleSignOut,
            child: const Text('SIGN OUT'),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: TextField(
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "Enter Event Name"),
              controller: eventName,
            ),
          ),
          ElevatedButton(
              onPressed: _handleAddEvent, child: const Text("ADD EVENT")),
          ElevatedButton(
            onPressed: _handleGetCalendar,
            child: const Text('REFRESH'),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text('You are not currently signed in.'),
          ElevatedButton(
            onPressed: _handleSignIn,
            child: const Text('SIGN IN'),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Google Sign In + googleapis'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}
