import 'package:discipline_mind/common/common.dart';
import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  var selectedIndex = 0.obs;
  @override
  void onInit() {
    super.onInit();
    Common.getFcmToken();
  }

  void changeIndex(int index) {
    selectedIndex.value = index;
  }
}
