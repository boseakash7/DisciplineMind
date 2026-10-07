import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/model/mct_plan_notification_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:get/get.dart';

class MctPlanNotificationController extends GetxController {
  final notification = Rxn<MctPlanNotification>();
  final openRequested = false.obs;
  Future<void>? _activeRequest;

  void requestOpen() => openRequested.value = true;

  void consumeOpenRequest() => openRequested.value = false;

  Future<void> fetchToday() {
    return _activeRequest ??= _fetchToday().whenComplete(() {
      _activeRequest = null;
    });
  }

  Future<void> _fetchToday() async {
    final userId = Common.userData.value?.payload?.id?.toString().trim() ?? '';
    if (userId.isEmpty) return;

    final api = Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put(ApiService(), permanent: true);
    final response = await api.postFormData(ApiUrl.notificationToday, {
      'user_id': userId,
    });
    if (!response.isSuccess) return;

    final data = response.data;
    if (data is! Map) return;
    final payload = data['payload'];
    if (payload is! List) {
      notification.value = null;
      return;
    }

    MctPlanNotification? latest;
    for (final rawNotification in payload) {
      if (rawNotification is! Map) continue;
      final candidate = MctPlanNotification.fromJson(
        Map<String, dynamic>.from(rawNotification),
      );
      if (candidate.type.toLowerCase() == 'mct_plan' && candidate.hasContent) {
        latest = candidate;
        break;
      }
    }
    notification.value = latest;
  }
}
