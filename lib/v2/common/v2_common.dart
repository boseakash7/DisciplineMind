import 'package:get/get.dart';
import '../models/v2_user_model.dart';

class V2Common {
  static Rx<V2LoginResponseModel?> userData = Rx<V2LoginResponseModel?>(null);

  static String get userId => userData.value?.payload?.id ?? '';
  static String get userName => userData.value?.payload?.fullName ?? '';
  static String get userEmail => userData.value?.payload?.email ?? '';
  static String get userPhone => userData.value?.payload?.phone ?? '';
  static String get dmtLevelCode => userData.value?.payload?.dmtLevelCode ?? 'BM';
}
