import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const String SERVICE_UUID        = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE com ESP32 ',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BleHomePage(),
    );
  }
}

class BleHomePage extends StatefulWidget {
  const BleHomePage({super.key});
  @override
  State<BleHomePage> createState() => _BleHomePageState();
}

class _BleHomePageState extends State<BleHomePage> {
  StreamSubscription? scanSubscription;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  List<ScanResult> scanResults = [];
  String receivedData = '';

  @override
  void initState() {
    super.initState();
    startScan();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  void startScan() {
    scanSubscription = FlutterBluePlus.scanResults.listen((scanResult) {
      scanResult.map(
              (e){
            scanResults.add(e);
          }
      );
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() => connectedDevice = device);

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == SERVICE_UUID) {
        for (var char in service.characteristics) {
          if (char.uuid.toString() == CHARACTERISTIC_UUID) {
            targetCharacteristic = char;
            if (char.properties.notify) {
              await char.setNotifyValue(true);
              char.value.listen((value) {
                setState(() {
                  receivedData = String.fromCharCodes(value);
                });
              });
            }
          }
        }
      }
    }
  }

  Future<void> sendData(String text) async {
    if (targetCharacteristic != null && targetCharacteristic!.properties.write) {
      Uint8List bytes = Uint8List.fromList(text.codeUnits);
      await targetCharacteristic!.write(bytes, withoutResponse: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE com ESP32')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Dispositivos encontrados:'),
            Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (_, i) {
                  final r = scanResults[i];
                  return ListTile(
                    title: Text(r.device.name),
                    subtitle: Text(r.device.id.toString()),
                    trailing: ElevatedButton(
                      onPressed: () => connectToDevice(r.device),
                      child: const Text('Conectar'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (connectedDevice != null) ...[
              Text('Conectado: ${connectedDevice!.name}'),
              ElevatedButton(
                onPressed: () => sendData("Olá, ESP32!"),
                child: const Text('Enviar mensagem'),
              ),
              const SizedBox(height: 10),
              Text('Recebido: $receivedData'),
            ],
          ],
        ),
      ),
    );
  }
}
