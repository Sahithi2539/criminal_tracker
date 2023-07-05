import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:criminal_tracker/models/criminal.dart';

class CriminalDetailsScreen extends StatefulWidget {
  final Criminal criminal;

  const CriminalDetailsScreen({required this.criminal});

  @override
  _CriminalDetailsScreenState createState() => _CriminalDetailsScreenState();
}

class _CriminalDetailsScreenState extends State<CriminalDetailsScreen> {
  File? _imageFile1;
  File? _imageFile2;
  String? _errorMessage;
  bool isLocationMatched = false;
  bool _isImageMatched = false;

  @override
  void initState() {
    super.initState();
    _loadFirstImage();
    _verifyLocation();
  }

  void _loadFirstImage() async {
    if (widget.criminal.image != null) {
      try {
        // print(widget.criminal.image);
        final response = await http.get(Uri.parse(widget.criminal.image!));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final imagePath = '${tempDir.path}/image1.jpg';
          File imageFile = File(imagePath);
          await imageFile.writeAsBytes(response.bodyBytes);
          setState(() {
            _imageFile1 = imageFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load image from URL')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred while loading image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criminal Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20,
            ),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                image: DecorationImage(
                  image: NetworkImage(widget.criminal.image!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ListTile(
              title: Text(
                widget.criminal.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              subtitle: Column(
                children: [
                  const SizedBox(height: 8.0),
                  Text(
                    'UID: ${widget.criminal.uid}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Pincode: ${widget.criminal.pincode}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _captureImageFromCamera();
              },
              child: const Text('Take Another Image'),
            ),
            if (_imageFile2 != null)
              Container(
                width: 200,
                height: 200,
                child: Image.file(_imageFile2!, fit: BoxFit.cover),
              ),
            ElevatedButton(
              onPressed: () async {
                if (_imageFile1 != null && _imageFile2 != null) {
                  _uploadImages();
                  _verifyLocation();

                  if (_isImageMatched == true && isLocationMatched == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('both face and location is verified')),
                    );
                    await updateTimestamp();
                  }
                } else {
                  setState(() {
                    _errorMessage = 'Please select two images';
                  });
                }
                // if (isLocationMatched)
                //   Padding(
                //     padding: const EdgeInsets.symmetric(horizontal: 16),
                //     child: Text(
                //       isLocationMatched == true
                //           ? 'Location verified'
                //           : 'Location not verified',
                //       style: TextStyle(
                //         fontSize: 18,
                //         color: isLocationMatched == true
                //             ? Colors.green
                //             : Colors.red,
                //       ),
                //     ),
                //   );
              },
              child: Text('Mark Attendance'),
            ),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  void _captureImageFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _imageFile2 = File(image.path);
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_imageFile1 != null && _imageFile2 != null) {
      final url = Uri.parse('http://192.168.137.245:5001/face_match');
      final request = http.MultipartRequest('POST', url);

      // Add the first image file
      final multipartFile1 = await http.MultipartFile.fromPath(
        'file1',
        _imageFile1!.path,
        filename: 'image1.jpg',
      );
      request.files.add(multipartFile1);

      final multipartFile2 = await http.MultipartFile.fromPath(
        'file2',
        _imageFile2!.path,
      );
      request.files.add(multipartFile2);

      try {
        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final jsonData = jsonDecode(responseBody);

          // print(jsonData);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonData.toString())),
          );
          setState(() {
            _isImageMatched = true;
          });
          if (jsonData['match'] == true && isLocationMatched == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Both face and location are verified')),
            );
            await updateTimestamp();
          }
        } else {
          // Request failed
          print('Request failed with status: ${response.statusCode}');
        }
      } catch (e) {
        // Handle any exceptions
        print('Error occurred: $e');
      }
    } else {
      print('Please select two images');
    }
  }

  Future<void> _verifyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    final position = await Geolocator.getCurrentPosition();

    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    final userPincode = placemarks.first.postalCode;
    print(widget.criminal.pincode);
    print('******************');
    print(userPincode);
    if (userPincode.toString() == widget.criminal.pincode.toString()) {
      setState(() {
        print('true');
        isLocationMatched = true;
      });
    }
  }

  // Future<void> updateTimestamp() async {
  //   final now = DateTime.now();
  //   final attendanceCollectionRef =
  //       FirebaseFirestore.instance.collection('attendance');
  //   final uid = widget.criminal.uid;

  //   final userAttendanceRef =
  //       attendanceCollectionRef.doc(uid).collection('timestamps');

  //   final userAttendanceDocSnapshot = await userAttendanceRef.doc(uid).get();

  //   if (userAttendanceDocSnapshot.exists) {
  //     final existingTimestamps =
  //         userAttendanceDocSnapshot.data()?['timestamps'] as List<dynamic>;

  //     if (existingTimestamps.isNotEmpty) {
  //       final lastTimestamp = existingTimestamps.last as Timestamp;

  //       final diff = now.difference(lastTimestamp.toDate());

  //       if (diff.inHours >= 24) {
  //         existingTimestamps.add(now);
  //         await userAttendanceRef
  //             .doc(uid)
  //             .update({'timestamps': existingTimestamps});

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Timestamp added to subcollection')),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content:
  //                 Text('24 hours have not passed since the last timestamp'),
  //           ),
  //         );
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('No existing timestamps found'),
  //         ),
  //       );
  //     }
  //   } else {
  //     await userAttendanceRef.doc(uid).set({
  //       'timestamps': [now]
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('New attendance document created in subcollection'),
  //       ),
  //     );
  //   }
  // }
  Future<void> updateTimestamp() async {
    final now = DateTime.now();
    final uid = widget.criminal.uid;

    final timestampsCollectionRef = FirebaseFirestore.instance
        .collection('attendance')
        .doc(uid)
        .collection('timestamps');

    final userAttendanceDocSnapshot =
        await timestampsCollectionRef.doc(uid).get();

    if (userAttendanceDocSnapshot.exists) {
      final existingTimestamps =
          userAttendanceDocSnapshot.data()?['timestamps'] as List<dynamic>;

      final lastTimestamp = existingTimestamps.isNotEmpty
          ? existingTimestamps.last as Timestamp
          : null;

      final diff =
          lastTimestamp != null ? now.difference(lastTimestamp.toDate()) : null;

      if (diff == null || diff.inHours < 24) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('24 hours have not passed since the last timestamp'),
          ),
        );
        return;
      }

      existingTimestamps.add(now);

      await timestampsCollectionRef
          .doc(uid)
          .update({'timestamps': existingTimestamps});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timestamp added to subcollection')),
      );
    } else {
      await timestampsCollectionRef.doc(uid).set({
        'timestamps': [now]
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New attendance document created in subcollection'),
        ),
      );
    }
  }
}
