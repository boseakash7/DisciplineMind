import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/model/dmt_user_levels_summary_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:get/get.dart';

/// Loads BM tab level summary (`user-levels-summary`).
class DmtUserLevelsSummaryService extends GetxService {
  final Rxn<DmtUserLevelsSummaryPayload> summaryPayload =
      Rxn<DmtUserLevelsSummaryPayload>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  bool _fetchInFlight = false;

  Future<bool> fetchSummary({bool force = false}) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      error.value = 'Please log in to view levels';
      return false;
    }

    if (!force && _fetchInFlight) {
      return summaryPayload.value != null;
    }

    _fetchInFlight = true;
    isLoading.value = true;
    error.value = null;

    try {
      final response = await _api().postFormData(
        ApiUrl.dmtLevelUserLevelsSummary,
        {'user_id': userId},
      );

      if (!response.isSuccess || response.data is! Map) {
        error.value =
            response.errorMessage ?? 'Could not load level summary';
        summaryPayload.value = null;
        return false;
      }

      final parsed = DmtUserLevelsSummaryResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      if (!parsed.isOk || parsed.payload == null) {
        error.value = 'No level summary available';
        summaryPayload.value = null;
        return false;
      }

      summaryPayload.value = parsed.payload;
      return true;
    } catch (e) {
      error.value = e.toString();
      summaryPayload.value = null;
      return false;
    } finally {
      isLoading.value = false;
      _fetchInFlight = false;
    }
  }

  Future<void> ensureLoaded() async {
    if (summaryPayload.value == null) {
      await fetchSummary();
    }
  }

  Future<void> refreshTabData() => fetchSummary(force: true);

  ApiService _api() {
    return Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put(ApiService(), permanent: true);
  }
}
