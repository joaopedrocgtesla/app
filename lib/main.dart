import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scanner());
  }
}

class Scanner extends StatefulWidget {
  const Scanner({super.key});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  final List<ScanResult> _recordList = [];

  void requestPermissions() async {
    PermissionStatus bl = await Permission.bluetoothConnect.request();
    PermissionStatus loc = await Permission.location.request();

    if (bl.isGranted && loc.isGranted) {
      startScanning();
    } else {}
  }

  void startScanning() async {
    _recordList.clear();
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!_recordList.contains(result)) {
          _recordList.add(result);
        }
      }
      setState(() {});
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    FlutterBluePlus.stopScan();
    await device.connect();
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("BLE Scanner"), centerTitle: true),
      body: SingleChildScrollView(
        physics: ScrollPhysics(),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              itemCount: _recordList.length,
              itemBuilder: (context, index) {
                return Container(
                  height: 52,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _recordList[index].device.advName.length > 0
                                ? _recordList[index].device.advName
                                : "Unknown Device",
                          ),
                          Text(_recordList[index].rssi.toString()),
                        ],
                      ),
                      Text(_recordList[index].device.remoteId.str),
                    ],
                  ),
                );
              },
            ),
            TextButton(onPressed: startScanning, child: Text("Rescan")),
          ],
        ),
      ),
    );
  }
}
