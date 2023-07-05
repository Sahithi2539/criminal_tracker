import 'package:criminal_tracker/screens/add_criminal.dart';
import 'package:criminal_tracker/screens/calender.dart';
import 'package:criminal_tracker/screens/detailsscreen.dart';
import 'package:criminal_tracker/models/criminal.dart';
import 'package:criminal_tracker/screens/login_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criminal Attendance'),
        backgroundColor: Color(0xFF646FD4),
        actions: [
          MaterialButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddCriminal(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromRGBO(155, 163, 235, 1),
              ), //BoxDecoration
              child: UserAccountsDrawerHeader(
                decoration:
                    BoxDecoration(color: Color.fromRGBO(155, 163, 235, 1)),
                accountName: Text(
                  "User",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
                accountEmail: Text(
                  "user@gmail.com",
                  style: TextStyle(color: Colors.black),
                ),
                currentAccountPictureSize: Size.square(50),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Color.fromRGBO(100, 111, 212, 1),
                  child: Text(
                    "",
                    style: TextStyle(
                        fontSize: 30.0, color: Color.fromRGBO(0, 0, 0, 1)),
                  ),
                ),
              ),
            ),
            // ListTile(
            //   leading: const Icon(Icons.person),
            //   title: const Text(' My Profile '),
            //   onTap: () {
            //     Navigator.pop(context);
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.edit),
            //   title: const Text('Edit Profile'),
            //   onTap: () {
            //     Navigator.pop(context);
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('LogOut'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Login(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter UID or Name to search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              // Wrap the ListView with Expanded
              child: StreamBuilder(
                stream: _searchQuery.isEmpty
                    ? FirebaseDatabase.instance
                        .reference()
                        .child('criminals')
                        .orderByChild('uid')
                        .onValue
                    : FirebaseDatabase.instance
                        .reference()
                        .child('criminals')
                        .orderByChild('uid')
                        .equalTo(_searchQuery)
                        .onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data?.snapshot.value != null) {
                    // Process the data and display the list of criminals
                    Map<dynamic, dynamic> criminals =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    List<Widget> criminalList = [];
                    criminals.forEach((key, value) {
                      // Create a widget for each criminal
                      Criminal criminal = Criminal.fromMap(value);
                      criminalList.add(
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(criminal.image!),
                          ),
                          title: Text(criminal.name),
                          subtitle: Text('UID: ${criminal.uid}'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CriminalDetailsScreen(criminal: criminal),
                                ),
                              );
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                Color(0xFF646FD4),
                              ),
                            ),
                            child: const Text('Mark Attendance'),
                          ),
                          onLongPress: () {
                            // Perform custom navigation animation on long press
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        AttendanceCalendar(criminal: criminal),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const Offset begin = Offset(1.0, 0.0);
                                  const Offset end = Offset.zero;
                                  final tween = Tween(begin: begin, end: end);
                                  final offsetAnimation =
                                      animation.drive(tween);

                                  return SlideTransition(
                                    position: offsetAnimation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    });
                    return ListView(
                      children: criminalList,
                    );
                  } else {
                    return const Text('No criminals found.');
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the new screen when the plus button is pressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCriminal()),
          );
        },
        backgroundColor: Color(0xFF646FD4),
        child: const Icon(Icons.add),
      ),
    );
  }
}
