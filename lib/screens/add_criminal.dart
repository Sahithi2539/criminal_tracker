import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:criminal_tracker/models/criminal.dart';

class AddCriminal extends StatefulWidget {
  const AddCriminal({super.key});
  @override
  _AddCriminalState createState() => _AddCriminalState();
}

class _AddCriminalState extends State<AddCriminal> {
  final _formKey = GlobalKey<FormState>();
  final _databaseReference = FirebaseDatabase.instance.reference();
  final _storageReference = FirebaseStorage.instance.ref();
  final _picker = ImagePicker();

  String _uid = '';
  File? _image;
  String _name = '';
  int? _age;
  int? _pincode;
  String? _imageUrl;
  bool _uploading = false;

  Future<void> _pickImage() async {
    final option = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text("Select image source"),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ImageSource.gallery);
              },
              child: const Text("Pick from gallery"),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ImageSource.camera);
              },
              child: const Text("Capture from camera"),
            ),
          ],
        );
      },
    );

    if (option == null) return;

    final pickedFile = await _picker.pickImage(source: option);

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
    });
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      setState(() {
        _uploading = true;
      });

      final storageRef =
          _storageReference.child('criminals/${DateTime.now()}.jpg');
      final uploadTask = storageRef.putFile(_image!);

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _imageUrl = downloadUrl;
        _uploading = false;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final criminal = Criminal(
        uid: _uid,
        image: _imageUrl,
        name: _name,
        age: _age!,
        pincode: _pincode!,
        timestamp: DateTime.now(),
      );

      _databaseReference
          .child('criminals')
          .push()
          .set(criminal.toMap())
          .then((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Criminal details added successfully.'),
        ));
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add criminal details. $error'),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Criminal'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                InkWell(
                  onTap: _pickImage,
                  child: _image != null
                      ? Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            image: DecorationImage(
                              image: FileImage(_image!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Icon(Icons.add_a_photo),
                        ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'UID'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a UID.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _uid = value!;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _name = value!;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter an age.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _age = int.parse(value!);
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Pincode'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a pincode.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _pincode = int.parse(value!);
                  },
                ),
                const SizedBox(height: 16.0),
                _uploading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          _uploadImage().then((_) {
                            _submitForm();
                          });
                        },
                        child: const Text('Submit'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
