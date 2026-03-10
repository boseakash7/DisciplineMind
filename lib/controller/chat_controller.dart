import 'dart:io';

import 'package:app_limiter/app_limiter.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:discipline_mind/model/chat_message_model.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final NativeAppBlockService _blockService = NativeAppBlockService();
  static const _blockedPackages = blockedTradingAppPackages;

  final messages = <ChatMessage>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSampleMessages();
  }

  void _loadSampleMessages() {
    messages.assignAll([
      const SimpleTextMessage(text: 'Hello Mr. Vikas'),
      const SimpleTextMessage(text: 'I am Monkk AI Agent. I am empowered by MSB Trading Process'),
      const SimpleTextMessage(text: 'Hi', isFromUser: true),
      const SimpleTextMessage(text: 'Hi'),
      const AgentWithButtonMessage(
        text: 'I can see that you have not yet attended the Demo session. Please attend the same before i can assist you further',
        buttonLabel: 'Register for Demo',
      ),
      const NewTradeOpportunityMessage(
        analystInfo: 'SEBI REG ANALYST - INH0000244567',
        instrument: 'SENSEX',
        contract: '05 MAR 79000 PE',
        stopLoss: '350',
        entryRange: '390 - 400',
        frr: '450',
        frrRatio: '1:1',
        rttRatio: 'Min 1:3',
      ),
      const TradeExecutedMessage(),
    ]);
  }

  void addMessage(ChatMessage msg) {
    messages.add(msg);
    if (msg is TradeExecutedMessage) {
      onTradeExecuted();
    }
  }

  void sendTextMessage(String text) {
    if (text.trim().isEmpty) return;
    addMessage(SimpleTextMessage(text: text.trim(), isFromUser: true));
  }

  /// Called when user submits trade params from New Trade Opportunity popup.
  /// Blocks trading apps (Zerodha, Upstox, Groww).
  Future<void> onSubmitTradeParams({
    required String stopLoss,
    required String entry,
    required String frr,
    required String instrument,
    required String contract,
  }) async {
    try {
      if (Platform.isAndroid) {
        final userId = Common.userData.value?.payload?.id?.toString();
        if (userId != null) {
          await _blockService.saveUserIdForOverlay(userId);
        }
        final perms = await _blockService.checkPermissions();
        if (perms['hasOverlayPermission'] != true) {
          await _blockService.requestOverlayPermission();
        }
        if (perms['hasUsageStatsPermission'] != true) {
          await _blockService.requestUsageStatsPermission();
        }
        for (final package in _blockedPackages) {
          await _blockService.blockApp(package);
        }
        try {
          await _blockService.startBlockingService();
        } catch (e) {
          print('[ChatController] startBlockingService failed: $e');
        }
        AppToast.showToast('Trading apps have been locked');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        final granted = await limiter.requestIosPermission();
        if (granted) {
          await limiter.blockAndUnblockIOSApp();
          AppToast.showToast('Trading apps have been locked');
        } else {
          AppToast.showToast('iOS permission required to block apps');
        }
      }
    } catch (e) {
      AppToast.showToast('Error: $e');
    }
  }

  /// Called when Trade Executed message is received. Unlocks trading apps.
  Future<void> onTradeExecuted() async {
    try {
      if (Platform.isAndroid) {
        for (final package in _blockedPackages) {
          await _blockService.unblockApp(package);
        }
        await _blockService.unblockAndClose(_blockedPackages);
        await _blockService.stopBlockingService();
        AppToast.showToast('Trading apps unlocked');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        await limiter.blockAndUnblockIOSApp();
        AppToast.showToast('Trading apps unlocked');
      }
    } catch (e) {
      print('[ChatController] onTradeExecuted failed: $e');
    }
  }
}
