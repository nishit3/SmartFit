import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {


  final _formKey = GlobalKey<FormState>();
  late ImageProvider driverImage;
  bool _isLoading = true;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final DatabaseReference ref = FirebaseDatabase.instance.ref("${FirebaseAuth.instance.currentUser!.uid}/profile");


  ImageProvider<Object> uint8ListToImageProvider(Uint8List uint8List) {
    return MemoryImage(uint8List);
  }


  Future<Uint8List> _imageProviderToUint8List(
      ImageProvider<Object> imageProvider) async {
    Image imageWidget = Image(image: imageProvider);
    Completer<Uint8List> completer = Completer<Uint8List>();
    imageWidget.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) async {
        ByteData? byteData = await info.image.toByteData(format: ImageByteFormat.png);
        Uint8List? uint8List = byteData?.buffer.asUint8List();
        completer.complete(uint8List);
      }),
    );

    return completer.future;
  }

  void _openGallery(BuildContext context) async {
    var picture = await ImagePicker.platform
        .getImageFromSource(source: ImageSource.gallery);
    if (picture != null) {
      setState(() {
        driverImage = Image(image: XFileImage(picture)).image;
        _changeProfileImage();
      });
    }
  }

  void _readValuesFromDB() async {
    final ref = FirebaseDatabase.instance.ref();
    final snap1 = await ref
        .child("${FirebaseAuth.instance.currentUser!.uid}/profile/Full-Name")
        .get();
    final snap2 = await ref
        .child("${FirebaseAuth.instance.currentUser!.uid}/profile/Phone-Number")
        .get();
    final snap3 = await ref
        .child("${FirebaseAuth.instance.currentUser!.uid}/profile/Age")
        .get();

    setState(() {
      _fullNameController.text = snap1.value as String;
      _phoneNumberController.text = snap2.value as String;
      _ageController.text = (snap3.value as int).toString();
    });
  }

  void _updateChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      FocusManager.instance.primaryFocus?.unfocus();

      await ref.update({
        "Full-Name": _fullNameController.text,
        "Age": int.parse(_ageController.text),
        "Phone-Number": _phoneNumberController.text
      });
      _readValuesFromDB();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes Saved!")));
    }
  }

  void _fetchProfileImage() async {
    driverImage = const AssetImage('lib/assets/images/user_profile.png');
    final storageRef = FirebaseStorage.instance.ref();
    final profileImgRef = storageRef.child("Profile_Photo").child(FirebaseAuth.instance.currentUser!.uid);

    try {
      final Uint8List? data = await profileImgRef.getData();
      setState(() {
        _isLoading = true;
        driverImage = uint8ListToImageProvider(data!);
      });
      setState(() {
        _isLoading=false;
      });
    } on Exception catch (e) {
      driverImage = const AssetImage('lib/assets/images/user_profile.png');
    }
  }

  void _changeProfileImage() async {
    final storageRef = FirebaseStorage.instance.ref();
    final profileImgRef = storageRef
        .child("Profile_Photo")
        .child(FirebaseAuth.instance.currentUser!.uid);
    try {
      await profileImgRef.putData(await _imageProviderToUint8List(driverImage));
      setState(() {
        _fetchProfileImage();
      });
    } on Exception catch (e) {driverImage = const AssetImage('lib/assets/images/user_profile.png');}
  }

  @override
  void initState() {
    setState(() {
      _isLoading = true;
    });
    _fetchProfileImage();
    _readValuesFromDB();
    super.initState();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(255, 29, 38, 0.9),
        title:
            const Text("Your Profile", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  InkWell(
                    onTap: () {
                      _openGallery(context);
                    },
                    radius: 80,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    child: CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      backgroundImage: driverImage,
                      radius: 90,
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                          padding: const EdgeInsets.only(
                              left: 17, right: 17, top: 7, bottom: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextFormField(
                                  decoration: const InputDecoration(
                                    label: Text("Full Name"),
                                    icon: Icon(Icons.account_box_rounded),
                                  ),
                                  controller: _fullNameController,
                                  keyboardType: TextInputType.name,
                                  onSaved: (newValue) {
                                    _fullNameController.text = newValue!;
                                  },
                                  validator: (value) {
                                    if (value == null ||
                                        value.toString().isEmpty ||
                                        !value
                                            .toString()
                                            .trim()
                                            .contains(" ")) {
                                      return "Please enter valid full name";
                                    }
                                    return null;
                                  }), // form fields for signup
                              TextFormField(
                                  decoration: const InputDecoration(
                                      label: Text("Contact Number"),
                                      prefix: Text("+91 "),
                                      icon: Icon(Icons.phone)),
                                  controller: _phoneNumberController,
                                  keyboardType: TextInputType.number,
                                  onSaved: (newValue) {
                                    _phoneNumberController.text = newValue!;
                                  },
                                  validator: (value) {
                                    if (value == null ||
                                        value.toString().isEmpty ||
                                        value.toString().trim().length < 10) {
                                      return "Please enter valid contact number";
                                    }
                                    return null;
                                  }),
                              TextFormField(
                                  decoration: const InputDecoration(
                                    label: Text("Age"),
                                    icon: Icon(Icons.numbers_rounded),
                                  ),
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  onSaved: (newValue) {
                                    _ageController.text = newValue!;
                                  },
                                  validator: (value) {
                                    if (value == null ||
                                        value.toString().isEmpty ||
                                        int.parse(value) <= 0 ||
                                        int.parse(value) >= 100) {
                                      return "Please enter valid Age";
                                    }
                                    return null;
                                  }),
                              const SizedBox(
                                height: 30,
                              ),
                              ElevatedButton(
                                  onPressed: _updateChanges,
                                  style: const ButtonStyle(
                                      backgroundColor: MaterialStatePropertyAll(
                                          Color.fromRGBO(255, 29, 38, 0.9))),
                                  child: const Text("Save Changes",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ))),
                            ],
                          ),
                        ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
