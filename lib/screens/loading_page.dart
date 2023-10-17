import 'dart:async';

import 'package:flutter/material.dart';
import 'package:test_app/screens/chat_page.dart';
import 'package:test_app/screens/home_page.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:wifi_scan/wifi_scan.dart';


class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  late Timer _timer;

  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  bool shouldCheckCan = true;

  bool get isStreaming => subscription != null;

  Future<void> _startScan(BuildContext context) async {
    // check if "can" startScan
    if (shouldCheckCan) {
      // check if can-startScan
      final can = await WiFiScan.instance.canStartScan();
      // if can-not, then show error
      if (can != CanStartScan.yes) {
        //if (mounted) kShowSnackBar(context, "Cannot start scan: $can");
        return;
      }
    }

    // call startScan API
    await WiFiScan.instance.startScan();
    //if (mounted) kShowSnackBar(context, "startScan: $result");
    // reset access points.
    setState(() => accessPoints = <WiFiAccessPoint>[]);
  }

  Future<bool> _canGetScannedResults(BuildContext context) async {
    if (shouldCheckCan) {
      // check if can-getScannedResults
      final can = await WiFiScan.instance.canGetScannedResults();
      // if can-not, then show error
      if (can != CanGetScannedResults.yes) {
        //if (mounted) kShowSnackBar(context, "Cannot get scanned results: $can");
        accessPoints = <WiFiAccessPoint>[];
        return false;
      }
    }
    return true;
  }

  Future<void> _getScannedResults(BuildContext context) async {
    if (await _canGetScannedResults(context)) {
      // get scanned results
      final results = await WiFiScan.instance.getScannedResults();
      setState(() => accessPoints = results);
    }
  }

  void _stopListeningToScanResults() {
    subscription?.cancel();
    subscription = null; // Update the value directly
  }

  Future<void> _checkAndEnableWifi() async {
    final isEnabled = await WiFiForIoTPlugin.isEnabled();
    if (!isEnabled) {
      await WiFiForIoTPlugin.setEnabled(true);
      print('wifi enabled');
    }
  }

  @override
  void dispose() {
    super.dispose();
    // stop subscription for scanned results
    _stopListeningToScanResults();
    // stop timer
    _timer.cancel();
  }

  @override
  void didUpdateWidget(LoadingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('didUpdateWidget');
    _checkAndEnableWifi();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _startScan(context);
      //Delay 5 seconds
      Future.delayed(Duration(seconds: 5));
      await _getScannedResults(context);
      //Get all SSIDs
      List<String> ssids = [];
      for (final ap in accessPoints) {
        ssids.add(ap.ssid);
      }
      //Check if any SSID is "Master"
      if (ssids.contains('AndroidWifi')) {
        print('Master found');
        _stopListeningToScanResults();
        _timer.cancel();
        //Connect to Master

        await WiFiForIoTPlugin.connect('AndroidWifi');

        // Stop scanning and cancel timer
        // Show dialog

        _showDialog(context);
        
      }

    });
  }

  @override
  void initState() {
    super.initState();
    print('initState');
    _checkAndEnableWifi();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _startScan(context);
      //Delay 5 seconds
      Future.delayed(Duration(seconds: 5));
      await _getScannedResults(context);
      //Get all SSIDs
      List<String> ssids = [];
      for (final ap in accessPoints) {
        ssids.add(ap.ssid);
      }

      // print all fields of all access points
      

      //Check if any SSID is "Master"
      if (ssids.contains('AndroidWifi')) {
        print('Master found');
        _stopListeningToScanResults();
        _timer.cancel();
        //Connect to Master

        final isConnected = await WiFiForIoTPlugin.isConnected();
        if (isConnected) {
          final currentWifi = await WiFiForIoTPlugin.getSSID();
          if (currentWifi == 'AndroidWifi') {
            print('Already connected to AndroidWifi');
          } else {
            print('Disconnecting from $currentWifi');
            await WiFiForIoTPlugin.disconnect();
            await WiFiForIoTPlugin.connect('AndroidWifi');
          }
        }
        else {
          await WiFiForIoTPlugin.connect('AndroidWifi');
        }

        // Stop scanning and cancel timer
        // Show dialog

        _showDialog(context);
        
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible:
                          false, // Prevents users from dismissing dialog by tapping outside
                      builder: (BuildContext context) {
                        Future.delayed(const Duration(seconds: 3), () {
                          Navigator.pop(context); // Dismiss the AlertDialog
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                conversation: null,
                                onConversationUpdated: (conversation) {},
                              ),
                            ),
                          );
                        });

                        return const AlertDialog(
                          title: Text('BAŞARILI', textAlign: TextAlign.center),
                          content: Text(
                            'MASTER BULUNDU CHAT\'E AKTARILIYOR!!!',
                            textAlign: TextAlign.center,
                          ),
                          contentTextStyle: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                          ),
                          titleTextStyle: TextStyle(
                            color: Colors.green,
                            fontSize: 30,
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Find Master!'),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()),
                      );
                    },
                    child: const Text('Go back!'),
                  ),
                ), // Add some space between the buttons
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.8, // 80% of screen width
                  height: MediaQuery.of(context).size.height *
                      0.4, // 80% of screen height
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 255, 0, 0)),
                    strokeWidth: 20,
                  ),
                ), // Loading animation
                const SizedBox(
                    height:
                        16), // Add some space between the CircularProgressIndicator and Text
                const Text(
                  'Master Aranıyor!!!',
                  style: TextStyle(fontSize: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* void kShowSnackBar(BuildContext context, String message) {
    print(message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  } */
  void _showDialog(BuildContext context) {
    showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('BAŞARILI', textAlign: TextAlign.center),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop()
                ,
                
              ),
            ],
          ),
        );

        _stopListeningToScanResults();
        _timer.cancel();
        showDialog(
          context: context,
          barrierDismissible:
              false, // Prevents users from dismissing dialog by tapping outside
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 3), () {
              Navigator.pop(context); // Dismiss the AlertDialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    conversation: null,
                    onConversationUpdated: (conversation) {},
                  ),
                ),
              );
            });

            return const AlertDialog(
              title: Text('BAŞARILI', textAlign: TextAlign.center),
              content: Text(
                'MASTER BULUNDU CHAT\'E AKTARILIYOR!!!',
                textAlign: TextAlign.center,
              ),
              contentTextStyle: TextStyle(
                color: Colors.red,
                fontSize: 20,
              ),
              titleTextStyle: TextStyle(
                color: Colors.green,
                fontSize: 30,
              ),
            );
          },
        );
  }
}

