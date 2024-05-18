import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for RawKeyboardListener
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event RSVP App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EventListPage(),
    );
  }
}

class EventListPage extends StatefulWidget {
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference events =
      FirebaseFirestore.instance.collection('events');
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    initializeFirebase();
  }

  void initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
  }

  Future<void> addEvent(String name, String date) {
    return events.add({
      'name': name,
      'date': date,
      'rsvps': [], // Initialize RSVPs as an empty array
    }).then((value) {
      print("Event Added");
      _controller.clear();
    }).catchError((error) {
      print("Failed to add event: $error");
      return null;
    });
  }

  Future<void> rsvpEvent(String eventId) async {
    final currentUser = 'user123'; // Replace with actual user authentication
    final DocumentReference eventRef = events.doc(eventId);
    final DocumentSnapshot eventSnapshot = await eventRef.get();

    if (eventSnapshot.exists) {
      final Map<String, dynamic>? eventData =
          eventSnapshot.data() as Map<String, dynamic>?;
      if (eventData != null) {
        final List<dynamic>? rsvps = eventData['rsvps'];

        if (rsvps != null) {
          if (!rsvps.contains(currentUser)) {
            rsvps.add(currentUser);
            await eventRef.update({'rsvps': rsvps});
            print('RSVP successful');
          } else {
            print('Already RSVPed');
          }
        } else {
          print('RSVPs list is null');
        }
      } else {
        print('Event data is null');
      }
    } else {
      print('Event does not exist');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        body: Center(child: Text('Failed to initialize Firebase')),
      );
    }

    if (!_initialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Event RSVP App'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RawKeyboardListener(
              // Add RawKeyboardListener here
              focusNode:
                  FocusNode(), // Ensures the text field doesn't get focus
              onKey: (event) {
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  if (_controller.text.isNotEmpty) {
                    addEvent(_controller.text, '2024-06-01');
                  }
                }
              },
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Event Name',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        addEvent(_controller.text, '2024-06-01');
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: events.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                final data = snapshot.requireData;

                return ListView.builder(
                  itemCount: data.size,
                  itemBuilder: (context, index) {
                    final event = data.docs[index];
                    final eventId = event.id;

                    return ListTile(
                      title: Text(event['name']),
                      subtitle: Text(event['date']),
                      trailing: IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () {
                          rsvpEvent(eventId);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
