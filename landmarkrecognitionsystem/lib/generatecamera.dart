import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as Img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';

class GenerateLiveCamera extends StatefulWidget {
  @override
  _GenerateLiveCameraState createState() => _GenerateLiveCameraState();
}

class _GenerateLiveCameraState extends State<GenerateLiveCamera> {
  String result = 'Fetching Response...';
  List<CameraDescription> cameras;
  CameraController controller;
  bool takePhoto = false;
  List _output;

  @override
  void initState() {
    super.initState();
    takePhoto = true;
    detectCameras().then((_) {
      initializeController();
    });
    loadModel().then((value) {});
  }

  loadModel() async {
    await Tflite.loadModel(
        model: 'assets/landmark_model.tflite',
        labels: 'assets/landmark_labels.txt');
  }

  Future<void> detectCameras() async {
    cameras = await availableCameras;
  }

  @override
  void dispose() {
    controller.dispose();
    Tflite.close(); // to prevent memory leaks in app
    cameras = null;
    takePhoto = false;
    super.dispose();
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 25,
      threshold: 0.1,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      _output = output;
      result = _output[0]['label'];
      print(_output);
    });
  }

  void initializeController() {
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) return;

      setState(() {});

      if (takePhoto) {
        const interval = const Duration(seconds: 2);
        new Timer.periodic(interval, (Timer t) => capturePictures());
      }
    });
  }

  capturePictures() async {
    String timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/{$timestamp}.png';

    if (takePhoto) {
      controller.takePicture(filePath).then((_) {
        if (takePhoto) {
          Image im = Image(
              image:
                  ResizeImage(AssetImage(filePath), width: 224, height: 224));
          //File img = File(im.toString());
          File imgFile = File(filePath);
          classifyImage(imgFile);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.004, 1],
            colors: [
              Color(0x11232526),
              Color(0xFF232526),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(),
            (controller.value.isInitialized)
                ? Center(child: buildCameraPreview())
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget buildCameraPreview() {
    //var size = MediaQuery.of(context).size.width / 1.2;
    // return Column(
    //   children: <Widget>[
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: CameraPreview(controller),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(5, 20, 1, 1), //margin here
          child: IconButton(
            color: Colors.white,
            icon: Icon(
              Icons.arrow_back_ios,
              size: 30,
            ),
            onPressed: () {
              setState(() {
                takePhoto = false;
                result = 'Fetching Response...';
              });
              Navigator.pop(context);
            },
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(
              1, MediaQuery.of(context).size.height - 101, 1, 1), //margin here
          width: MediaQuery.of(context).size.width,
          height: 100,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                )
              ]),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 30,
              ),
              Text(
                result,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                ),
              ),
            ],
          ),
        )
      ],
    );
    //   ],
    // );
  }
}
