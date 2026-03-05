import 'package:cutout_burst/pages/cutout_burst_text/cutout_burst_text_binding.dart';
import 'package:cutout_burst/pages/cutout_burst_text/cutout_burst_text_view.dart';
import 'package:cutout_burst/pages/cutout_burst_trim_cutout/cutout_burst_trim_east.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'db_cutout_burst/data.dart';
import '../pages/cutout_burst_tab/cutout_burst_tab_binding.dart';
import '../pages/cutout_burst_tab/cutout_burst_tab_view.dart';
import '../pages/cutout_burst_home/cutout_burst_home_binding.dart';
import '../pages/cutout_burst_home/cutout_burst_home_view.dart';
import '../pages/cutout_burst_history/cutout_burst_history_binding.dart';
import '../pages/cutout_burst_history/cutout_burst_history_view.dart';
import '../pages/cutout_burst_settings/cutout_burst_settings_binding.dart';
import '../pages/cutout_burst_settings/cutout_burst_settings_view.dart';
import '../pages/cutout_burst_select_photo/cutout_burst_select_photo_binding.dart';
import '../pages/cutout_burst_select_photo/cutout_burst_select_photo_view.dart';
import '../pages/cutout_burst_crop/cutout_burst_crop_binding.dart';
import '../pages/cutout_burst_crop/cutout_burst_crop_view.dart';
import '../pages/cutout_burst_trim_cutout/cutout_burst_trim_cutout_binding.dart';
import '../pages/cutout_burst_trim_cutout/cutout_burst_trim_cutout_view.dart';
import '../pages/cutout_burst_shape_cutout/cutout_burst_shape_cutout_binding.dart';
import '../pages/cutout_burst_shape_cutout/cutout_burst_shape_cutout_view.dart';
import '../pages/cutout_burst_edge_text/cutout_burst_edge_text_binding.dart';
import '../pages/cutout_burst_edge_text/cutout_burst_edge_text_view.dart';
import '../pages/cutout_burst_portrait_cutout/cutout_burst_portrait_cutout_binding.dart';
import '../pages/cutout_burst_portrait_cutout/cutout_burst_portrait_cutout_view.dart';
import '../pages/cutout_burst_change_bg/cutout_burst_change_bg_binding.dart';
import '../pages/cutout_burst_change_bg/cutout_burst_change_bg_view.dart';
import 'utils/colors.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Get.putAsync(() => CutoutBurstDb().init());
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          getPages: Burst,
          initialRoute: '/',
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: CutoutBurstColors.primary,
            scaffoldBackgroundColor: CutoutBurstColors.bg,
            colorScheme: ColorScheme.dark(
              primary: CutoutBurstColors.primary,
              surface: CutoutBurstColors.card,
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              toolbarHeight: 44,
              backgroundColor: CutoutBurstColors.card,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: CutoutBurstColors.textPrimary,
              ),
              iconTheme: const IconThemeData(
                size: 22,
                color: CutoutBurstColors.textPrimary,
              ),
            ),
            dividerTheme: DividerThemeData(
              thickness: 1,
              color: CutoutBurstColors.border,
            ),
          ),
        );
      },
    );
  }
}
List<GetPage<dynamic>> Burst = [
  GetPage(
    name: '/',
    page: () => const CutoutBurstTextView(),
    binding: CutoutBurstTextBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_tab',
    page: () => const CutoutBurstTabView(),
    binding: CutoutBurstTabBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_home',
    page: () => const CutoutBurstHomeView(),
    binding: CutoutBurstHomeBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_trim_east',
    page: () => const CutoutBurstTrimEast(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_history',
    page: () => const CutoutBurstHistoryView(),
    binding: CutoutBurstHistoryBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_settings',
    page: () => const CutoutBurstSettingsView(),
    binding: CutoutBurstSettingsBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_select_photo',
    page: () => const CutoutBurstSelectPhotoView(),
    binding: CutoutBurstSelectPhotoBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_crop',
    page: () => const CutoutBurstCropView(),
    binding: CutoutBurstCropBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_trim_cutout',
    page: () => const CutoutBurstTrimCutoutView(),
    binding: CutoutBurstTrimCutoutBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_shape_cutout',
    page: () => const CutoutBurstShapeCutoutView(),
    binding: CutoutBurstShapeCutoutBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_edge_text',
    page: () => const CutoutBurstEdgeTextView(),
    binding: CutoutBurstEdgeTextBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_portrait_cutout',
    page: () => const CutoutBurstPortraitCutoutView(),
    binding: CutoutBurstPortraitCutoutBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/cutout_burst_change_bg',
    page: () => const CutoutBurstChangeBgView(),
    binding: CutoutBurstChangeBgBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
];