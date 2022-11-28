import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_browser/utils/js_channel/dart_to_js.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

///
/// BleUtil
///
/// Created by Jack Zhang on 2022/11/26 .
///
class BleUtil {
  factory BleUtil() => _getInstance();

  BleUtil._internal() {
    ble = FlutterReactiveBle();
  }

  static BleUtil get instance => _getInstance();
  static BleUtil? _instance;

  static BleUtil _getInstance() {
    _instance ??= BleUtil._internal();
    return _instance!;
  }

  late final FlutterReactiveBle ble;

  List<DiscoveredDevice> bleDiscoveredDevicesList = <DiscoveredDevice>[];

  Stream<BleStatus> get statusStream => ble.statusStream;

  StreamSubscription<DiscoveredDevice>? _subscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;

  Future init() async {
    await _askBlePermission();
    statusStream.listen((BleStatus status) {
      DartToJs.instance.onBleStatusChanged(status == BleStatus.ready);
    });
  }

  Future _askBlePermission() async {
    var blePermission = await Permission.bluetooth.status;
    if (blePermission.isDenied) {
      Permission.bluetooth.request();
    }
    // Android Vr > 12 required These Ble Permission
    if (Platform.isAndroid) {
      var bleConnectPermission = await Permission.bluetoothConnect.status;
      var bleScanPermission = await Permission.bluetoothScan.status;
      if (bleConnectPermission.isDenied) {
        Permission.bluetoothConnect.request();
      }
      if (bleScanPermission.isDenied) {
        Permission.bluetoothScan.request();
      }
    }
  }

  void startScan({List<Uuid>? services}) {
    _subscription?.cancel();
    _subscription = ble.scanForDevices(withServices: services ?? [], scanMode: ScanMode.lowLatency).listen((DiscoveredDevice device) {
      DartToJs.instance.onScanNewDevice(device);
    }, onError: (e) {
      debugPrint(e.toString());
    });
  }

  Future stopScan() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void connect(String deviceId) {
    _connection = ble.connectToDevice(id: deviceId).listen((ConnectionStateUpdate update) {
      DartToJs.instance.onBleDeviceStatusChanged(update);
    }, onError: (error) {
      debugPrint(error.toString());
    });
  }

  Future disconnect(String deviceId) async {
    await _connection?.cancel();
    _connection = null;
  }
}
