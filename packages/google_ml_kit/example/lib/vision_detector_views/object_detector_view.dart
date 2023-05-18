import 'dart:collection';
import 'dart:io' as io;
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'camera_view.dart';
import 'painters/object_detector_painter.dart';

class ObjectDetectorView extends StatefulWidget {
  @override
  State<ObjectDetectorView> createState() => _ObjectDetectorView();
}

class _ObjectDetectorView extends State<ObjectDetectorView> {
  late ObjectDetector _objectDetector;
  bool _canProcess = false;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  final TextToSpeech tts = TextToSpeech();
  @override
  void initState() {
    super.initState();

    _initializeDetector(DetectionMode.stream);
    if (_text != null) {
      tts.speak(_text!);
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _objectDetector.close();
    tts.stop();
    super.dispose();
  }

  // Future<void> speak_text(String text) async {
  //   await tts.setLanguage('en-US');
  //   await tts.setVolume(1.0);
  //   await tts.setPitch(1.0);
  //   await tts.speak(text);
  // }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Object Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
      },
      onScreenModeChanged: _onScreenModeChanged,
      initialDirection: CameraLensDirection.back,
    );
  }

  void _onScreenModeChanged(ScreenMode mode) {
    switch (mode) {
      case ScreenMode.gallery:
        _initializeDetector(DetectionMode.single);
        return;

      case ScreenMode.liveFeed:
        _initializeDetector(DetectionMode.stream);
        return;
    }
  }

  void _initializeDetector(DetectionMode mode) async {
    print('Set detector in mode: $mode');

    // uncomment next lines if you want to use the default model
    // final options = ObjectDetectorOptions(
    //     mode: mode,
    //     classifyObjects: true,
    //     multipleObjects: true);
    // _objectDetector = ObjectDetector(options: options);

    // uncomment next lines if you want to use a local model
    // make sure to add tflite model to assets/ml
    final path = 'assets/ml/object_labeler.tflite';
    final modelPath = await _getModel(path);
    final options = LocalObjectDetectorOptions(
      mode: mode,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);

    // uncomment next lines if you want to use a remote model
    // make sure to add model to firebase
    // final modelName = 'bird-classifier';
    // final response =
    //     await FirebaseObjectDetectorModelManager().downloadModel(modelName);
    // print('Downloaded: $response');
    // final options = FirebaseObjectDetectorOptions(
    //   mode: mode,
    //   modelName: modelName,
    //   classifyObjects: true,
    //   multipleObjects: true,
    // );
    // _objectDetector = ObjectDetector(options: options);

    _canProcess = true;
  }
  Queue<String> _queue = new Queue<String>();
  bool _speaking = false;
  Set<String> _list = {};
  int _emptyCounter=0;
  int _nonEmptyCounter = 0;

  void addToQueue(String text) {
    // if queue has more than 3 elemets clear it
    if(_queue.length > 4) _queue.clear();
    // add element to set to avoid duplicacy
    _list.add(text);
    _queue.add(text);
    if (!_speaking) {
      _speakNext();
    }
  }

  Future _speakNext() async {
    _speaking = true;
    if (_queue.isNotEmpty) {
      String word = _queue.removeFirst();
      await tts.speak(word);
      await Future.delayed(Duration(milliseconds: 1500));
      //remove word from set after speaking so it can be spoken again
      _speakNext();
    } else {
      _list.clear();
      _queue.clear();
      _speaking = false;
    }
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final objects = await _objectDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {

      final painter = ObjectDetectorPainter(
          objects,
          inputImage.inputImageData!.imageRotation,
          inputImage.inputImageData!.size);

      //check if nothing gets detected
      if(objects.isEmpty) _emptyCounter++;
      else _nonEmptyCounter++;

      // if nothing gets detected for 5 frames then we stop speaking and clear all lists
      if(_emptyCounter + _nonEmptyCounter > 30){
        if(_emptyCounter > _nonEmptyCounter) {
          tts.stop();
          _queue.clear();
          _list.clear();
          _speaking = false;
        }
        _emptyCounter=0;
        _nonEmptyCounter=0;
      }
      print(objects);

      for (final DetectedObject detectedObject in objects) {
        for (final Label label in detectedObject.labels) {
          if(label.confidence>0.8 && !_list.contains(label.text)) addToQueue(label.text);
        }
      }
        _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Objects found: \n\n';
      tts.speak(text);
      int x=0;
      for (final object in objects) {
        String Objects = "${object.labels.map((e) => e.text) }";
        if(Objects=="") continue;
        text+=Objects;
      }
      tts.speak(text);
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<String> _getModel(String assetPath) async {
    if (io.Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(dirname(path)).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }
}
