import 'package:alan_voice/alan_voice.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'nlp_detector_views/language_translator_view.dart';
import 'vision_detector_views/barcode_scanner_view.dart';
import 'vision_detector_views/object_detector_view.dart';
import 'vision_detector_views/text_detector_view.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  // _MyHomePageState createState()=> _MyHomePageState();
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
      routes: {
        '/second': (context) => BarcodeScannerView(),
        '/third': (context) => ObjectDetectorView(),
        '/fourth': (context) => TextRecognizerView(),
      },
    );
  }
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  void handleCommand(Map<String, dynamic> command) {
    switch (command['command']) {
      case 'page1':
        //Navigator.pushNamed(context, './second');
        Navigator.pushNamed(context, '/second');
        break;
      case 'page2':
        Navigator.pushNamed(context, '/third');
        break;
      case 'page3':
        Navigator.pushNamed(context, '/fourth');
        break;
      case 'closing':
        Navigator.pop(context);
        break;
      default:
        debugPrint('Command Unknown');
    }
  }

  _HomeState() {
    AlanVoice.addButton(
        '65b2bb7b8add6b4a6acca4fccf36d4922e956eca572e1d8b807a3e2338fdd0dc/stage');
    AlanVoice.onCommand.add((command) => handleCommand(command.data));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google ML Kit Demo App'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  CustomCard('Barcode Scanner', BarcodeScannerView()),
                  CustomCard('Object Detection', ObjectDetectorView()),
                  CustomCard('Text Recognition', TextRecognizerView()),
                  CustomCard('On-device Translation', LanguageTranslatorView()),
                  // ExpansionTile(
                  //   title: const Text('Vision APIs'),
                  //   children: [
                  //     CustomCard('Barcode Scanning', BarcodeScannerView()),
                  //     //CustomCard('Face Detection', FaceDetectorView()),
                  //     // CustomCard('Image Labeling', ImageLabelView()),
                  //     CustomCard('Object Detection', ObjectDetectorView()),
                  //     CustomCard('Text Recognition', TextRecognizerView()),
                  //     // CustomCard('Digital Ink Recognition', DigitalInkView()),
                  //     // CustomCard('Pose Detection', PoseDetectorView()),
                  //     // CustomCard('Selfie Segmentation', SelfieSegmenterView()),
                  //   ],
                  // ),
                  // SizedBox(
                  //   height: 20,
                  // ),
                  // ExpansionTile(
                  //   title: const Text('Natural Language APIs'),
                  //   children: [
                  //     //CustomCard('Language ID', LanguageIdentifierView()),
                  //     CustomCard(
                  //         'On-device Translation', LanguageTranslatorView()),
                  //     //CustomCard('Smart Reply', SmartReplyView()),
                  //     // CustomCard('Entity Extraction', EntityExtractionView()),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String _label;
  final Widget _viewPage;
  final bool featureCompleted;

  const CustomCard(this._label, this._viewPage, {this.featureCompleted = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Theme.of(context).primaryColor,
        title: Text(
          _label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          if (!featureCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    const Text('This feature has not been implemented yet')));
          } else {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => _viewPage));
          }
        },
      ),
    );
  }
}
