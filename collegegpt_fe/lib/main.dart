// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:provider/provider.dart';

import 'env.dart';

import 'dart:async';
import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' hide Colors;
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:mdi/mdi.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final GoogleSignIn _googleSignIn = GoogleSignIn(
  // Optional clientId
  clientId: kIsWeb ? Env.googleAPIKey : Env.googleAndroidClientKey,
  scopes: <String>[CalendarApi.calendarScope],
);

void main() {
  runApp(
    ChangeNotifierProvider(
        create: (context) => AppState(),
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          title: 'CollegeGPT',
          home: const HomePage(),
        )),
  );
}

Future<void> _handleSignOut() => _googleSignIn.disconnect();

/// The main widget of this demo.
class HomePage extends StatefulWidget {
  /// Creates the main widget of this demo.
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class AppState extends ChangeNotifier {
  GoogleSignInAccount? _currentUser;
  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  List<String> courses = [];
  TextEditingController courseName = TextEditingController();
  final _controller = SidebarXController(selectedIndex: -1, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  void initializeCourses() async {
    final SharedPreferences prefs = await this.prefs;
    courses = prefs.getStringList('courses') ?? [];
    notifyListeners();
  }

  void attachSubscription() async {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      notifyListeners();
    });
    _currentUser = await _googleSignIn.signInSilently();
  }

  void addCourse() {
    if (courseName.text.isEmpty) {
      return;
    }
    courses.add(courseName.text);
    notifyListeners();
  }

  void setCourseIndex(int index) {
    _controller.selectIndex(index);
    notifyListeners();
  }
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appstate, child) {
      Widget page;
      if (appstate._currentUser == null) {
        page = const SignInScreen();
      } else {
        page = ChatScreen(courseIndex: appstate._controller.selectedIndex);
      }
      return page;
    });
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

/// The state of the main widget.
class _SignInScreenState extends State<SignInScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<AppState>(context, listen: false).attachSubscription();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error); // ignore: avoid_print
    }
  }

  Widget _buildBody() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('CollegeGPT'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}

class CourseSidebar extends StatelessWidget {
  CourseSidebar({Key? key}) : super(key: key);

  final Map<String, MdiIconData> letterToIcon = {
    'a': Mdi.alphaABox,
    'b': Mdi.alphaBBox,
    'c': Mdi.alphaCBox,
    'd': Mdi.alphaDBox,
    'e': Mdi.alphaEBox,
    'f': Mdi.alphaFBox,
    'g': Mdi.alphaGBox,
    'h': Mdi.alphaHBox,
    'i': Mdi.alphaIBox,
    'j': Mdi.alphaJBox,
    'k': Mdi.alphaKBox,
    'l': Mdi.alphaLBox,
    'm': Mdi.alphaMBox,
    'n': Mdi.alphaNBox,
    'o': Mdi.alphaOBox,
    'p': Mdi.alphaPBox,
    'q': Mdi.alphaQBox,
    'r': Mdi.alphaRBox,
    's': Mdi.alphaSBox,
    't': Mdi.alphaTBox,
    'u': Mdi.alphaUBox,
    'v': Mdi.alphaVBox,
    'w': Mdi.alphaWBox,
    'x': Mdi.alphaXBox,
    'y': Mdi.alphaYBox,
    'z': Mdi.alphaZBox
  };

  final Duration animationTime = const Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appstate, child) {
        return SidebarX(
          controller: appstate._controller,
          items: [
            for (int courseIndex = 0;
                courseIndex < appstate.courses.length;
                courseIndex++)
              SidebarXItem(
                  icon: letterToIcon[
                      appstate.courses[courseIndex][0].toLowerCase()]!,
                  label: appstate.courses[courseIndex],
                  onTap: () {
                    appstate.setCourseIndex(courseIndex);
                  }),
            SidebarXItem(
              icon: Icons.add,
              label: 'Add Course',
              onTap: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) => _AddCourseDialog());
              },
            )
          ],
          theme: const SidebarXTheme(
              margin: EdgeInsets.all(10),
              itemTextPadding: EdgeInsets.only(left: 30),
              selectedItemTextPadding: EdgeInsets.only(left: 30)),
          extendedTheme: const SidebarXTheme(
              width: 300,
              margin: EdgeInsets.all(10),
              itemTextPadding: EdgeInsets.only(left: 30),
              selectedItemTextPadding: EdgeInsets.only(left: 30)),
          headerBuilder: (context, extended) {
            final GoogleSignInAccount? user = appstate._currentUser;
            return Row(children: [
              GoogleUserCircleAvatar(
                identity: user!,
              ),
              Column(
                children: [
                  FutureBuilder(
                    future: Future.delayed(animationTime, () {
                      return Text(user.displayName ?? '',
                          overflow: TextOverflow.fade);
                    }),
                    builder: (context, snapshot) {
                      if (extended) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox();
                        }
                        return snapshot.data ?? const SizedBox();
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                  FutureBuilder(
                    future: Future.delayed(animationTime, () {
                      return Text(user.email,
                          style: DefaultTextStyle.of(context)
                              .style
                              .apply(fontSizeFactor: 0.8),
                          overflow: TextOverflow.fade);
                    }),
                    builder: (context, snapshot) {
                      if (extended) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox();
                        }
                        return snapshot.data ?? const SizedBox();
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ],
              )
            ]);
          },
          animationDuration: animationTime,
        );
      },
    );
  }
}

class _AddCourseDialog extends Dialog {
  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.2,
                maxWidth: MediaQuery.of(context).size.width * 0.5),
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Consumer<AppState>(builder: (context, appstate, child) {
                  appstate.courseName.clear();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, right: 8.0, left: 8.0),
                        child: TextField(
                          controller: appstate.courseName,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Course Name',
                          ),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    appstate.addCourse();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Add Course'),
                                ),
                              ]))
                    ],
                  );
                }))));
  }
}

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  Widget _buildBody() {
    return Consumer<AppState>(builder: (context, appstate, child) {
      if (appstate.courses.isEmpty) {
        return const Center(child: Text('No courses'));
      } else {
        return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.count(crossAxisCount: 2, children: <Widget>[
              for (int courseIndex = 0;
                  courseIndex < appstate.courses.length;
                  courseIndex++)
                ElevatedButton(
                    onPressed: () {
                      appstate.setCourseIndex(courseIndex);
                    },
                    child: Text(appstate.courses[courseIndex]))
            ]));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final isSmallScreen = MediaQuery.of(context).size.width < 600;
      final key = Provider.of<AppState>(context)._key;
      return Scaffold(
          key: key,
          appBar: AppBar(
            title: const Text('CollegeGPT'),
            leading: isSmallScreen
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => key.currentState?.openDrawer(),
                  )
                : null,
            actions: const <Widget>[
              IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: _handleSignOut,
                tooltip: "Sign out",
              ),
            ],
          ),
          drawer: isSmallScreen ? CourseSidebar() : null,
          body: Row(children: [
            if (!isSmallScreen) CourseSidebar(),
            Expanded(
              child: Center(child: _buildBody()),
            )
          ]),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) => _AddCourseDialog()),
            tooltip: "New course",
            child: const Icon(Icons.add),
          ));
    });
  }
}

class ChatScreen extends StatefulWidget {
  ChatScreen({required this.courseIndex})
      : super(key: ValueKey("chat_$courseIndex"));
  final int courseIndex;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<types.Message> _messages = [];
  late String _id;
  late types.User _user;

  Widget _buildBody() {
    if (Provider.of<AppState>(context)._controller.selectedIndex == -1) {
      return const Text('No courses');
    }
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Chat(
          messages: _messages,
          onSendPressed: _handleSendPressed,
          user: _user,
        ));
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _id,
      text: message.text,
    );

    _addMessage(textMessage);
  }

  @override
  Widget build(BuildContext context) {
    _id = Provider.of<AppState>(context)._currentUser!.id;
    _user = types.User(id: _id);

    return Builder(builder: (context) {
      final isSmallScreen = MediaQuery.of(context).size.width < 600;
      final key = Provider.of<AppState>(context)._key;

      return Scaffold(
          key: key,
          appBar: AppBar(
            title: const Text('CollegeGPT'),
            leading: isSmallScreen
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => key.currentState?.openDrawer(),
                  )
                : null,
            actions: <Widget>[
              if (widget.courseIndex != -1)
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              UploadScreen(courseIndex: widget.courseIndex)),
                    );
                  },
                  tooltip: "Upload Files",
                ),
              if (widget.courseIndex != -1)
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FileListScreen(courseIndex: widget.courseIndex)),
                    );
                  },
                  tooltip: "View Uploaded Files",
                ),
              if (widget.courseIndex != -1)
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CalendarScreen(courseIndex: widget.courseIndex)),
                    );
                  },
                  tooltip: "Extract Events",
                ),
              const IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: _handleSignOut,
                tooltip: "Sign out",
              ),
            ],
          ),
          drawer: isSmallScreen ? CourseSidebar() : null,
          body: Row(children: [
            if (!isSmallScreen) CourseSidebar(),
            Expanded(
              child: Center(child: _buildBody()),
            )
          ]));
    });
  }
}

class CalendarScreen extends StatefulWidget {
  CalendarScreen({required this.courseIndex})
      : super(key: ValueKey("calendar_$courseIndex"));
  final int courseIndex;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarApi? calendarAPI;
  String? calendarID;
  final List<TextEditingController> eventsControllers = [];
  List<Event> events = [];
  bool _notLoading = true;
  bool _importSuccessful = false;

  Future<void> _handleGetCalendar() async {
    // Retrieve an [auth.AuthClient] from the current [GoogleSignIn] instance.
    debugger();
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
    setState(() {
      events = [];
      _importSuccessful = true;
    });
  }

  Future<void> _fetchEventsFromSyllabus() async {
    setState(() {
      _notLoading = false;
      _importSuccessful = false;
    });
    final response = await http.post(
      Uri.parse("http://localhost:8000/syllabus/"),
      body: {
        "courseName": Provider.of<AppState>(context, listen: false)
            .courses[widget.courseIndex]
      },
    );
    if (response.statusCode == 200) {
      final List fileNames =
          jsonDecode(jsonDecode(response.body))["event_list"];
      setState(() {
        for (Map event in fileNames) {
          events.add(Event(
              summary: event["event_name"],
              start: EventDateTime(
                dateTime: Function.apply(
                    DateTime.new,
                    event["start_time"]
                        .values
                        .toList()
                        .map((e) => e.toInt())
                        .toList()),
              ),
              end: EventDateTime(
                  dateTime: Function.apply(
                      DateTime.new,
                      event["end_time"]
                          .values
                          .toList()
                          .map((e) => e.toInt())
                          .toList()))));
        }
      });
    } else {
      throw Exception('Failed to load file names');
    }
    setState(() {
      _notLoading = true;
    });
  }

  void _handleAddEvents() {
    if (calendarAPI == null) {
      _handleGetCalendar();
    }
    setState(() {
      for (Event event in events) {
        calendarAPI?.events.insert(event, calendarID!);
      }
    });
  }

  Widget _buildBody() {
    return Container(
        padding: const EdgeInsets.only(left: 100, right: 100, bottom: 8),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              const Text('Import events from syllabus into Google Calendar'),
              if (events.isNotEmpty)
                SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: ListView.builder(
                      itemBuilder: (context, index) {
                        if (index >= eventsControllers.length) {
                          eventsControllers.add(TextEditingController.fromValue(
                              TextEditingValue(
                                  text: events[index].summary.toString())));
                        } else {
                          eventsControllers[index].text =
                              events[index].summary.toString();
                        }
                        return ListTile(
                            visualDensity: const VisualDensity(vertical: 2),
                            title:
                                TextField(controller: eventsControllers[index]),
                            subtitle: const Text(""),
                            trailing: Column(children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                      onPressed: () async {
                                        final DateTime? chosenDate =
                                            await showDatePicker(
                                                context: context,
                                                initialDate: events[index]
                                                        .start
                                                        ?.dateTime ??
                                                    DateTime.now(),
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2100));
                                        setState(() {
                                          events[index].start?.dateTime =
                                              events[index]
                                                  .start
                                                  ?.dateTime
                                                  ?.copyWith(
                                                      year: chosenDate?.year,
                                                      month: chosenDate?.month,
                                                      day: chosenDate?.day);
                                        });
                                      },
                                      child: Text(
                                          "${events[index].start?.dateTime?.month}/${events[index].start?.dateTime?.day}/${events[index].start?.dateTime?.year}")),
                                  TextButton(
                                    onPressed: () async {
                                      final TimeOfDay? chosenTime =
                                          await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  TimeOfDay.fromDateTime(
                                                      events[index]
                                                              .start
                                                              ?.dateTime ??
                                                          DateTime.now()));
                                      setState(() {
                                        events[index].start?.dateTime =
                                            events[index]
                                                .start
                                                ?.dateTime
                                                ?.copyWith(
                                                    hour: chosenTime?.hour,
                                                    minute: chosenTime?.minute);
                                      });
                                    },
                                    child: Text(
                                        "${events[index].start?.dateTime?.hour}:${events[index].start?.dateTime?.minute}"),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                      onPressed: () async {
                                        final DateTime? chosenDate =
                                            await showDatePicker(
                                                context: context,
                                                initialDate: events[index]
                                                        .end
                                                        ?.dateTime ??
                                                    DateTime.now(),
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2100));
                                        setState(() {
                                          events[index].end?.dateTime =
                                              events[index]
                                                  .start
                                                  ?.dateTime
                                                  ?.copyWith(
                                                      year: chosenDate?.year,
                                                      month: chosenDate?.month,
                                                      day: chosenDate?.day);
                                        });
                                      },
                                      child: Text(
                                          "${events[index].end?.dateTime?.month}/${events[index].end?.dateTime?.day}/${events[index].end?.dateTime?.year}")),
                                  TextButton(
                                    onPressed: () async {
                                      final TimeOfDay? chosenTime =
                                          await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  TimeOfDay.fromDateTime(
                                                      events[index]
                                                              .end
                                                              ?.dateTime ??
                                                          DateTime.now()));
                                      setState(() {
                                        events[index].end?.dateTime =
                                            events[index]
                                                .end
                                                ?.dateTime
                                                ?.copyWith(
                                                    hour: chosenTime?.hour,
                                                    minute: chosenTime?.minute);
                                      });
                                    },
                                    child: Text(
                                        "${events[index].end?.dateTime?.hour}:${events[index].end?.dateTime?.minute}"),
                                  ),
                                ],
                              )
                            ]));
                      },
                      itemCount: Provider.of<AppState>(context).courses.length,
                    )),
              Offstage(
                  offstage: _notLoading,
                  child: const Center(child: CircularProgressIndicator())),
              Offstage(
                  offstage: !_importSuccessful,
                  child: const Text('Successfully imported',
                      textAlign: TextAlign.center)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _fetchEventsFromSyllabus,
                    child: const Text('Import Events'),
                  ),
                  ElevatedButton(
                      onPressed: events.isEmpty ? null : _handleAddEvents,
                      child: const Text("Add to Calendar")),
                ],
              ),
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Import from Syllabus')),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}

class UploadScreen extends StatefulWidget {
  UploadScreen({required this.courseIndex})
      : super(key: ValueKey("upload_$courseIndex"));
  final int courseIndex;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  FilePickerResult? selectedFiles;
  int syllabusIndex = -1;
  bool notUploaded = true;

  Future<void> _pickFiles() async {
    FilePickerResult? selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        "txt",
        "md",
        "py",
        "pdf",
        "csv",
        "xls",
        "xlsx",
        "docx",
        "doc",
      ],
      withData: false,
      withReadStream: true,
      allowMultiple: true,
    );
    setState(() {
      notUploaded = true;
      selectedFiles = selection;
    });
  }

  Future<void> _uploadFiles() async {
    if (selectedFiles?.files.isEmpty ?? true) {
      throw Exception('No files picked or file picker was canceled');
    }

    final uri = Uri.parse('http://localhost:8000/file_upload/');
    final request = http.MultipartRequest('POST', uri);

    for (final file in selectedFiles!.files) {
      final mimeType = lookupMimeType(file.name);
      final contentType = mimeType != null ? MediaType.parse(mimeType) : null;

      final fileReadStream = file.readStream;
      if (fileReadStream == null) {
        throw Exception('Cannot read file from null stream');
      }
      final stream = http.ByteStream(fileReadStream);

      final multipartFile = http.MultipartFile(
        'file',
        stream,
        file.size,
        filename: file.name,
        contentType: contentType,
      );
      request.files.add(multipartFile);
    }
    request.fields['syllabusIndex'] = syllabusIndex.toString();
    request.fields['courseName'] = Provider.of<AppState>(context, listen: false)
        .courses[widget.courseIndex];
    final httpClient = http.Client();
    final response = await httpClient.send(request);

    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}');
    } else {
      setState(() {
        selectedFiles = null;
        notUploaded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Files'),
      ),
      body: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _pickFiles,
                  child: const Text('Select Files'),
                ),
                Column(
                  children: [
                    Offstage(
                        offstage: selectedFiles?.files.isEmpty ?? true,
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Syllabus',
                            ),
                          ),
                        )),
                    ListView.builder(
                        itemBuilder: (context, index) {
                          if (selectedFiles?.files.isEmpty ?? true) {
                            return const ListTile(
                              title: Center(child: Text('No files selected')),
                            );
                          }
                          return ListTile(
                            key: Key(selectedFiles!.files[index].name),
                            title: Text(selectedFiles!.files[index].name),
                            leading: Checkbox(
                              value: syllabusIndex == index,
                              onChanged: (value) {
                                if (value == true) {
                                  setState(() {
                                    syllabusIndex = index;
                                  });
                                } else {
                                  setState(() {
                                    syllabusIndex = -1;
                                  });
                                }
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  selectedFiles!.files.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                        shrinkWrap: true,
                        itemCount: selectedFiles?.files.length ?? 1)
                  ],
                ),
                Offstage(
                    offstage: notUploaded,
                    child: const Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Upload Successful',
                        ),
                      ),
                    )),
                ElevatedButton(
                  onPressed: selectedFiles?.files.isEmpty ?? true
                      ? null
                      : _uploadFiles,
                  child: const Text('Upload Files'),
                ),
              ])),
    );
  }
}

class FileListScreen extends StatefulWidget {
  FileListScreen({required this.courseIndex})
      : super(key: ValueKey("files_$courseIndex"));
  final int courseIndex;

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  late List<String> fileNames;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fileNames = [];
    _isLoading = true;
    _fetchFileNames().then((value) => setState(() {
          fileNames = value;
          _isLoading = false;
        }));
  }

  Future<List<String>> _fetchFileNames() async {
    final response =
        await http.post(Uri.parse("http://localhost:8000/file_list/"), body: {
      "courseName": Provider.of<AppState>(context, listen: false)
          .courses[widget.courseIndex]
    });
    if (response.statusCode == 200) {
      final List<String> fileNames =
          jsonDecode(jsonDecode(response.body))["file_names"].cast<String>();
      return fileNames;
    } else {
      throw Exception('Failed to load file names');
    }
  }

  Future<void> _deleteFile(String fileName) async {
    final response = await http
        .delete(Uri.parse("http://localhost:8000/file_upload/"), body: {
      "file_name": fileName,
      "courseName": Provider.of<AppState>(context, listen: false)
          .courses[widget.courseIndex]
    });
    if (response.statusCode == 200) {
      setState(() {
        fileNames.remove(fileName);
      });
    } else {
      throw Exception('Failed to delete file');
    }
  }

  Future<Widget> _buildBody() async {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        if (_isLoading) const Center(child: CircularProgressIndicator()),
        if (fileNames.isEmpty && !_isLoading)
          const Center(child: Text('No files uploaded')),
        if (fileNames.isNotEmpty && !_isLoading)
          Expanded(
              child: ListView.builder(
                  itemCount: fileNames.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                        key: Key(fileNames[index]),
                        title: Text(fileNames[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            try {
                              setState(() {
                                _isLoading = true;
                              });
                              await _deleteFile(fileNames[index]);
                            } on Exception catch (e) {
                              showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                          title:
                                              const Text("Error when deleting"),
                                          content: Text(e.toString()),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('OK'),
                                            )
                                          ]));
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                          tooltip: "Delete file",
                        ));
                  }))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
      ),
      body: FutureBuilder<Widget>(
        future: _buildBody(),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) {
            return ConstrainedBox(
                constraints: const BoxConstraints.expand(),
                child: snapshot.data!);
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return Center(
              child: ConstrainedBox(
                  constraints: BoxConstraints.tight(const Size.square(50)),
                  child: const CircularProgressIndicator()));
        },
      ),
    );
  }
}
