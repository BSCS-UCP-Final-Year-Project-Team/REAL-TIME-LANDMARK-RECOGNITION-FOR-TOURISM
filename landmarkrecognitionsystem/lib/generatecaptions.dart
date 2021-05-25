import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';

class GenerateLiveCaptions extends StatefulWidget {
  @override
  _GenerateLiveCaptionsState createState() => _GenerateLiveCaptionsState();
}

class _GenerateLiveCaptionsState extends State<GenerateLiveCaptions> {
  String result = 'Fetching Response...';
  List<CameraDescription> cameras;
  CameraController controller;
  bool takePhoto = false;
  List _output;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    takePhoto = true;
    _loading = true;
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
    controller?.dispose();
    Tflite.close(); // to prevent memory leaks in app
    super.dispose();
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 25,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5);

    setState(() {
      _loading = false;
      _output = output;
      result = _output[0]['label'];
    });
  }

  void initializeController() {
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) return;

      setState(() {});

      if (takePhoto) {
        const interval = const Duration(seconds: 5);
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
          File imgFile = File(filePath);
          classifyImage(imgFile);
        } else {
          return;
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
          margin: EdgeInsets.fromLTRB(1, 10, 1, 1), //margin here
          child: IconButton(
            color: Colors.white,
            icon: Icon(Icons.arrow_back_ios),
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
              1, MediaQuery.of(context).size.height - 100, 1, 1), //margin here
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height - 700,
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
