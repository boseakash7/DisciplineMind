import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/controller/chat_controller.dart';
import 'package:discipline_mind/model/chat_message_model.dart';
import 'package:discipline_mind/services/notification/notification_handler.dart';
import 'package:discipline_mind/ui/main_home/widgets/dmt_score_popup.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.onMonkkTap, this.isActive = true});

  final VoidCallback? onMonkkTap;

  /// True when this tab is selected in `MainHomeScreen` bottom nav.
  final bool isActive;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;
  final Set<String> _revealedUnreadMessageIds = <String>{};
  bool _isLoadingOlder = false;
  bool _suppressAutoBottomScroll = false;
  bool _skipNextAutoBottomScroll = false;
  bool _didInitialBottomSnap = false;
  String _previousFirstMessageId = '';
  String _previousLastMessageId = '';

  /// DMT score popup staged animation shown once per message (while unread).
  final Set<String> _dmtScorePopupAnimatedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollForOlderMessages);
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _syncOnTabFocus();
    }
  }

  void _syncOnTabFocus() {
    if (!Get.isRegistered<ChatController>()) return;
    // Same effect as Sync button, but without UI noise.
    Get.find<ChatController>().loadNewMessages(silent: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollForOlderMessages);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) <= 80;
  }

  String _firstMessageId(List<ChatMessage> list) {
    for (final m in list) {
      final id = m.messageId.trim();
      if (id.isNotEmpty) return id;
    }
    return '';
  }

  String _lastMessageId(List<ChatMessage> list) {
    for (var i = list.length - 1; i >= 0; i--) {
      final id = list[i].messageId.trim();
      if (id.isNotEmpty) return id;
    }
    return '';
  }

  Future<void> _handleScrollForOlderMessages() async {
    if (_isLoadingOlder) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels > 24) return;
    if (!Get.isRegistered<ChatController>()) return;
    final controller = Get.find<ChatController>();
    if (controller.isLoading.value || controller.messages.isEmpty) return;
    if (!controller.hasMoreOlderMessages.value) return;
    _isLoadingOlder = true;
    _suppressAutoBottomScroll = true;
    _skipNextAutoBottomScroll = true;
    final beforeIds = controller.messages
        .map((m) => m.messageId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final previousPixels = _scrollController.position.pixels;
    final previousMax = _scrollController.position.maxScrollExtent;
    try {
      await controller.loadOlderMessages();
      if (mounted) {
        final prependedUnreadIds = <String>{};
        for (final m in controller.messages) {
          final id = m.messageId.trim();
          if (id.isEmpty) continue;
          if (beforeIds.contains(id)) break;
          if (m.isUnread) prependedUnreadIds.add(id);
        }
        if (prependedUnreadIds.isNotEmpty) {
          setState(() {
            _revealedUnreadMessageIds.addAll(prependedUnreadIds);
          });
        }
      }
      if (!mounted || !_scrollController.hasClients) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final newMax = _scrollController.position.maxScrollExtent;
        final addedExtent = (newMax - previousMax).clamp(0.0, double.infinity);
        final target = previousPixels + addedExtent;
        final bounded = target.clamp(0.0, newMax);
        _scrollController.jumpTo(bounded);
      });
    } finally {
      _isLoadingOlder = false;
      // Keep suppression for this frame so list-length rebuild won't try to
      // snap to bottom while older messages are being inserted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _suppressAutoBottomScroll = false;
      });
    }
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  /// Scroll until [maxScrollExtent] stabilizes so tall messages are fully visible.
  void _scheduleScrollToBottom({int attempt = 0}) {
    const maxAttempts = 18;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final max = _scrollController.position.maxScrollExtent;
      _scrollToBottom(animated: false);

      if (attempt >= maxAttempts) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final nextMax = _scrollController.position.maxScrollExtent;
        final nextPixels = _scrollController.position.pixels;
        final stillGrowing = nextMax > max + 0.5;
        final notFullyScrolled = (nextMax - nextPixels).abs() > 2.0;

        if (stillGrowing || notFullyScrolled) {
          _scheduleScrollToBottom(attempt: attempt + 1);
          return;
        }

        // Late layout (images, rich cards) can still grow after extent looks stable.
        if (attempt < 8) {
          Future.delayed(Duration(milliseconds: 40 + attempt * 25), () {
            if (mounted) _scheduleScrollToBottom(attempt: attempt + 1);
          });
        }
      });
    });
  }

  void _scheduleScrollAfterUnreadReveal(
    String messageId,
    ChatController controller,
  ) {
    final isLast = messageId == _lastMessageId(controller.messages);
    if (isLast || _isNearBottom()) {
      _scheduleScrollToBottom();
    }
  }

  /// Spreads [lx] so adjacent markers are at least [minSep] apart without
  /// reversing price order (low price → left, high → right).
  List<double> _spreadTimelineAnchorsByPrice(
    List<double> lx,
    List<double> numeric,
    double minSep,
    double maxWidth,
  ) {
    final n = lx.length;
    final order = List<int>.generate(n, (i) => i);
    order.sort((a, b) {
      final c = numeric[a].compareTo(numeric[b]);
      if (c != 0) return c;
      return a.compareTo(b);
    });
    final xs = order.map((i) => lx[i]).toList();

    for (var k = 1; k < n; k++) {
      if (xs[k] - xs[k - 1] < minSep) {
        xs[k] = xs[k - 1] + minSep;
      }
    }
    if (xs[n - 1] > maxWidth) {
      xs[n - 1] = maxWidth;
      for (var k = n - 2; k >= 0; k--) {
        if (xs[k + 1] - xs[k] < minSep) {
          xs[k] = xs[k + 1] - minSep;
        }
      }
      if (xs[0] < 0) {
        xs[0] = 0;
        for (var k = 1; k < n; k++) {
          if (xs[k] - xs[k - 1] < minSep) {
            xs[k] = xs[k - 1] + minSep;
          }
        }
      }
    }

    final out = List<double>.filled(n, 0);
    for (var k = 0; k < n; k++) {
      out[order[k]] = xs[k];
    }
    return out;
  }

  /// For trade card display: if value ends with `.00`, show whole number.
  /// Keep non-numeric and mixed values (e.g. `390 - 400`) unchanged.
  String _formatTradeCardPrice(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return raw;
    final parsed = double.tryParse(value);
    if (parsed == null) return raw;
    final fixed = parsed.toStringAsFixed(2);
    if (fixed.endsWith('.00')) {
      return parsed.toInt().toString();
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      init: Get.put(ChatController(), permanent: true),
      builder: (controller) => Scaffold(
        backgroundColor: AppColors.backgroundGray,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, controller),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final currentFirstId = _firstMessageId(controller.messages);
                  final currentLastId = _lastMessageId(controller.messages);
                  final wasNearBottom = _isNearBottom();
                  if (_lastMessageCount != controller.messages.length) {
                    _lastMessageCount = controller.messages.length;
                    if (!_didInitialBottomSnap &&
                        controller.messages.isNotEmpty) {
                      _didInitialBottomSnap = true;
                      _scheduleScrollToBottom();
                    } else if (_skipNextAutoBottomScroll) {
                      _skipNextAutoBottomScroll = false;
                    } else if (_previousFirstMessageId.isNotEmpty &&
                        currentFirstId.isNotEmpty &&
                        _previousFirstMessageId != currentFirstId &&
                        _previousLastMessageId == currentLastId) {
                      // Older history prepended at top -> keep user's viewport.
                    } else if (!_suppressAutoBottomScroll &&
                        _previousLastMessageId.isNotEmpty &&
                        currentLastId.isNotEmpty &&
                        _previousLastMessageId != currentLastId) {
                      // New messages appended at bottom -> always take user to latest.
                      _scheduleScrollToBottom();
                    } else if (!_suppressAutoBottomScroll &&
                        wasNearBottom &&
                        _previousLastMessageId.isEmpty &&
                        currentLastId.isNotEmpty) {
                      // Fallback: if IDs were absent previously but user was already at end.
                      _scheduleScrollToBottom();
                    }
                  }
                  _previousFirstMessageId = currentFirstId;
                  _previousLastMessageId = currentLastId;

                  // If user tapped a "DMT score" notification, auto-open the
                  // unread DMT score popup for the matching (or latest) message.
                  if (NotificationHandler.dmtScoreAutoOpenPending) {
                    final pendingDate =
                        NotificationHandler.dmtScoreAutoOpenScoreDate;
                    DmtScoreMessage? target;
                    for (var i = controller.messages.length - 1; i >= 0; i--) {
                      final msg = controller.messages[i];
                      if (msg is! DmtScoreMessage) continue;
                      final id = msg.messageId.trim();
                      if (id.isEmpty) continue;
                      if (!msg.isUnread) continue;
                      if (_dmtScorePopupAnimatedIds.contains(id)) continue;
                      if (pendingDate != null && pendingDate.isNotEmpty) {
                        if (msg.scoreDate.trim() != pendingDate.trim())
                          continue;
                      }
                      target = msg;
                      break;
                    }

                    if (target != null) {
                      final t = target;
                      NotificationHandler.clearDmtScoreAutoOpen();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        final id = t.messageId.trim();
                        setState(() => _dmtScorePopupAnimatedIds.add(id));
                        showDmtScorePopup(
                          context,
                          scoreDate: t.scoreDate,
                          instructionsScore: t.instructionsScore,
                          commitmentScore: t.commitmentScore,
                          patienceScore: t.patienceScore,
                          consistencyScore: t.consistencyScore,
                          dmtTotalScore: t.dmtTotalScore,
                          dmtMaxScore: t.dmtMaxScore,
                          animateReveal: true,
                        );
                      });
                    }
                  }
                  return controller.messages.isEmpty
                      ? ListView(
                          controller: _scrollController,
                          children: const [
                            SizedBox(
                              height: 420,
                              child: Center(
                                child: Text(
                                  'No messages yet.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: controller.messages.length,
                          itemBuilder: (_, i) {
                            final msg = controller.messages[i];
                            final bubble = _buildMessage(
                              context,
                              msg,
                              controller,
                            );
                            final rowKey = msg.messageId.trim().isNotEmpty
                                ? ValueKey(
                                    'chat_row_${msg.messageId}_${msg.type.name}',
                                  )
                                : ValueKey(
                                    'chat_row_fallback_${msg.type.name}_$i',
                                  );
                            final id = msg.messageId.trim();
                            if (!msg.isUnread || id.isEmpty) {
                              return KeyedSubtree(key: rowKey, child: bubble);
                            }
                            if (_revealedUnreadMessageIds.contains(id)) {
                              return KeyedSubtree(key: rowKey, child: bubble);
                            }
                            return KeyedSubtree(
                              key: rowKey,
                              child: _UnreadRevealGate(
                                messageId: id,
                                onRevealed: (messageId) {
                                  if (!mounted) return;
                                  setState(() {
                                    _revealedUnreadMessageIds.add(messageId);
                                  });
                                  _scheduleScrollAfterUnreadReveal(
                                    messageId,
                                    controller,
                                  );
                                },
                              ),
                            );
                          },
                        );
                }),
              ),
              _buildInput(context, controller, _textController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ChatController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onMonkkTap,
            child: const Text(
              'Discipline Mind',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Row(
            children: [
              const Text(
                'Credits : 250',
                style: TextStyle(color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              CircleAvatar(radius: 12, backgroundColor: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context,
    ChatMessage msg,
    ChatController controller,
  ) {
    switch (msg.type) {
      case ChatMessageType.simpleText:
        return _buildSimpleText(context, msg as SimpleTextMessage);
      case ChatMessageType.agentWithButton:
        return _buildAgentWithButton(context, msg as AgentWithButtonMessage);
      case ChatMessageType.newTradeOpportunity:
        return _buildNewTradeOpportunity(
          context,
          msg as NewTradeOpportunityMessage,
          controller,
        );
      case ChatMessageType.tradeExecutionPrompt:
        return _buildTradeExecutionPrompt(
          context,
          msg as TradeExecutionPromptMessage,
          controller,
        );
      case ChatMessageType.tradeExecuted:
        return _buildTradeExecuted(
          context,
          msg as TradeExecutedMessage,
          controller,
        );
      case ChatMessageType.alertHitWithButton:
        return _buildAlertHitWithButton(
          context,
          msg as AlertHitWithButtonMessage,
          controller,
        );
      case ChatMessageType.dmtScore:
        return _buildDmtScore(context, msg as DmtScoreMessage);
    }
  }

  Widget _buildDmtScore(BuildContext context, DmtScoreMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _monkkSparkleIcon(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.headline.isNotEmpty
                      ? msg.headline
                      : 'Your daily discipline analysis is ready.',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final id = msg.messageId.trim();
                      final shouldAnimate =
                          msg.isUnread &&
                          id.isNotEmpty &&
                          !_dmtScorePopupAnimatedIds.contains(id);
                      showDmtScorePopup(
                        context,
                        scoreDate: msg.scoreDate,
                        instructionsScore: msg.instructionsScore,
                        commitmentScore: msg.commitmentScore,
                        patienceScore: msg.patienceScore,
                        consistencyScore: msg.consistencyScore,
                        dmtTotalScore: msg.dmtTotalScore,
                        dmtMaxScore: msg.dmtMaxScore,
                        animateReveal: shouldAnimate,
                      ).then((_) {
                        if (!mounted || !shouldAnimate || id.isEmpty) return;
                        setState(() => _dmtScorePopupAnimatedIds.add(id));
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Discipline Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleText(BuildContext context, SimpleTextMessage msg) {
    if (msg.isFromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(color: Colors.black87, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentWithButton(
    BuildContext context,
    AgentWithButtonMessage msg,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                  ),
                  if (msg.actionTaken == null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg.buttonLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDeleteTradeAction(NewTradeOpportunityMessage msg) =>
      msg.action.toLowerCase() == 'delete';
  bool _isEditTradeAction(NewTradeOpportunityMessage msg) =>
      msg.action.toLowerCase() == 'edit';
  bool _showButtons(ChatMessage msg) => msg.actionTaken == null;

  String _tradeDeleteStepLine(int n, String api, String fallback) {
    final t = api.trim();
    if (t.isEmpty) return '$n. $fallback';
    if (RegExp(r'^\d+\.').hasMatch(t)) return t;
    return '$n. $t';
  }

  String _deleteTradeStep1Text(NewTradeOpportunityMessage msg) {
    if (msg.buttonType == 'open_app_button' && msg.apiMessage.isNotEmpty) {
      return _tradeDeleteStepLine(
        1,
        msg.apiMessage,
        'Go to Trading APP and delete the Trade',
      );
    }
    return _tradeDeleteStepLine(
      1,
      '',
      'Go to Trading APP and delete the Trade',
    );
  }

  String _deleteTradeStep2Text(NewTradeOpportunityMessage msg) {
    if (msg.buttonType == 'delete_button' && msg.apiMessage.isNotEmpty) {
      return _tradeDeleteStepLine(
        2,
        msg.apiMessage,
        'Intimate me once you delete the Open Trade',
      );
    }
    return _tradeDeleteStepLine(
      2,
      '',
      'Intimate me once you delete the Open Trade',
    );
  }

  Widget _buildNewTradeOpportunity(
    BuildContext context,
    NewTradeOpportunityMessage msg,
    ChatController controller,
  ) {
    if (_isEditTradeAction(msg) && msg.buttonType == 'edit_button') {
      return _buildTradeEditCombinedMessage(context, msg, controller);
    }
    if (_isDeleteTradeAction(msg) &&
        (msg.buttonType == 'open_app_button' ||
            msg.buttonType == 'delete_button')) {
      return _buildTradeDeleteCombinedMessage(context, msg, controller);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _monkkSparkleIcon(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.apiMessage.isNotEmpty
                      ? msg.apiMessage
                      : 'New Trade Opportunity is spotted for you',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTradeOpportunityCard(msg, showInvalidOverlay: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monkkSparkleIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
    );
  }

  /// Invalid card + cross + both steps and buttons in one bubble (open_app / delete_button).
  Widget _buildTradeDeleteCombinedMessage(
    BuildContext context,
    NewTradeOpportunityMessage msg,
    ChatController controller,
  ) {
    final stepStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey.shade800,
      height: 1.35,
    );
    final titleStyle = TextStyle(
      color: Colors.grey.shade800,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _monkkSparkleIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trade recommendation invalid — please delete this trade',
                      style: titleStyle,
                    ),
                    const SizedBox(height: 8),
                    _buildTradeOpportunityCard(msg, showInvalidOverlay: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _monkkSparkleIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trading App Unlocked', style: titleStyle),
                    const SizedBox(height: 12),
                    Text(_deleteTradeStep1Text(msg), style: stepStyle),
                    const SizedBox(height: 8),
                    _tradePromptPrimaryButton(
                      label: 'Open Trading APP',
                      enabled: _showButtons(msg),
                      onTap: () => controller.openTradingApp(),
                    ),
                    const SizedBox(height: 14),
                    Text(_deleteTradeStep2Text(msg), style: stepStyle),
                    const SizedBox(height: 8),
                    _tradePromptPrimaryButton(
                      label: 'Trade Deleted',
                      enabled: _showButtons(msg),
                      onTap: () => controller.acknowledgeTradeDeleted(msg),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Edit flow bubble: SL Edited + trade card + backend message + two buttons.
  Widget _buildTradeEditCombinedMessage(
    BuildContext context,
    NewTradeOpportunityMessage msg,
    ChatController controller,
  ) {
    final stepStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey.shade800,
      height: 1.35,
    );
    final titleStyle = TextStyle(
      color: Colors.grey.shade800,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    final backendText = msg.apiMessage.trim().isNotEmpty
        ? msg.apiMessage.trim()
        : 'Open Trading App and Trail your SL to reduce risk.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _monkkSparkleIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SL Edited', style: titleStyle),
                    const SizedBox(height: 8),
                    _buildTradeOpportunityCard(msg, showInvalidOverlay: false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _monkkSparkleIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trading App Unlocked', style: titleStyle),
                    const SizedBox(height: 12),
                    Text(
                      _tradeDeleteStepLine(1, backendText, backendText),
                      style: stepStyle,
                    ),
                    const SizedBox(height: 8),
                    _tradePromptPrimaryButton(
                      label: 'Open Trading APP',
                      enabled: _showButtons(msg),
                      onTap: () => controller.openTradingApp(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '2. Intimate me once you Trail your SL',
                      style: stepStyle,
                    ),
                    const SizedBox(height: 8),
                    _tradePromptPrimaryButton(
                      label: 'SL Trailed',
                      enabled: _showButtons(msg),
                      onTap: () => _showTrailSlDialog(context, msg, controller),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeOpportunityCard(
    NewTradeOpportunityMessage msg, {
    required bool showInvalidOverlay,
  }) {
    final tradeName = msg.tradeName.trim().isNotEmpty
        ? msg.tradeName.trim()
        : msg.instrument;
    final tradeSymbol = msg.tradeSymbol.trim().isNotEmpty
        ? msg.tradeSymbol.trim()
        : msg.contract;
    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            msg.analystInfo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              height: 1.25,
            ),
          ),
        ),
        Divider(height: 18, color: Colors.grey.shade300, thickness: 1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                tradeName.isEmpty ? '?' : tradeName[0].toUpperCase(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tradeName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tradeSymbol,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        (_isEditTradeAction(msg) && msg.buttonType == 'edit_button')
            ? _buildTradeTimelineForEdit(msg)
            : _buildTradeTimeline(msg),
        if (msg.rtt.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: _BlinkingCurrentPriceBadge(
              price: _formatTradeCardPrice(msg.rtt),
            ),
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: showInvalidOverlay
          ? Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                inner,
                Positioned.fill(
                  child: CustomPaint(painter: _InvalidTradeCrossPainter()),
                ),
              ],
            )
          : inner,
    );
  }

  Widget _buildTradeExecutionPrompt(
    BuildContext context,
    TradeExecutionPromptMessage msg,
    ChatController controller,
  ) {
    return _buildTradeExecutedBlock(
      context,
      msg.tradeData,
      controller,
      text: msg.text,
      sourceMessage: msg,
    );
  }

  Widget _buildTradeExecutedBlock(
    BuildContext context,
    NewTradeOpportunityMessage msg,
    ChatController controller, {
    String? text,
    ChatMessage? sourceMessage,
  }) {
    final actionSource = sourceMessage ?? msg;
    final bodyStyle = TextStyle(fontSize: 14, color: Colors.grey.shade800);
    final stepStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey.shade800,
      height: 1.35,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        text ?? 'Trading App is unlocked.',
                        style: bodyStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('1. Go to Trading APP and apply Levels', style: stepStyle),
                const SizedBox(height: 8),
                _tradePromptPrimaryButton(
                  label: 'Open Trading APP',
                  enabled: _showButtons(actionSource),
                  onTap: () => controller.openTradingApp(),
                ),
                const SizedBox(height: 14),
                Text('2. Intimate me once you apply the GTT', style: stepStyle),
                const SizedBox(height: 8),
                _tradePromptPrimaryButton(
                  label: 'GTT / Levels Applied',
                  enabled: _showButtons(actionSource),
                  onTap: () => _showGttDialog(context, msg, controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tradePromptPrimaryButton({
    required String label,
    VoidCallback? onTap,
    bool enabled = true,

    /// When false, same look but no tap / ripple (e.g. Open Trading APP display-only).
    bool interactive = true,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
    final canTap = interactive && enabled && onTap != null;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled ? AppColors.primary : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(8),
        child: canTap
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: child,
              )
            : child,
      ),
    );
  }

  void _showGttDialog(
    BuildContext context,
    NewTradeOpportunityMessage msg,
    ChatController controller,
  ) {
    final useExtendedFields = controller.shouldUseExtendedGttInputs();
    final gttPriceController = TextEditingController(
      text: ChatController.getDefaultGttPrice(msg.entryRange),
    );
    final stopLossController = TextEditingController(text: msg.stopLoss);
    final takeProfitController = TextEditingController(text: msg.frr);

    showChatFadeDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Trade Applied as GTT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            msg.instrument[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.instrument.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg.contract,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (!useExtendedFields)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'GTT is set at',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: gttPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _popupField('GTT is set at', gttPriceController, ''),
                          const SizedBox(height: 12),
                          _popupField('Stop Loss', stopLossController, ''),
                          const SizedBox(height: 12),
                          _popupField('Target', takeProfitController, ''),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await controller.createGttAlert(
                        msg,
                        gttPriceController.text,
                        stopLoss: useExtendedFields
                            ? stopLossController.text
                            : null,
                        takeProfit: useExtendedFields
                            ? takeProfitController.text
                            : null,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'SUBMIT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrailSlDialog(
    BuildContext context,
    NewTradeOpportunityMessage msg,
    ChatController controller,
  ) {
    final slController = TextEditingController(text: msg.stopLoss);
    showChatFadeDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Trail Stop Loss',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            (msg.tradeName.trim().isNotEmpty
                                    ? msg.tradeName.trim()
                                    : msg.instrument)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (msg.tradeName.trim().isNotEmpty
                                        ? msg.tradeName.trim()
                                        : msg.instrument)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg.tradeSymbol.trim().isNotEmpty
                                    ? msg.tradeSymbol.trim()
                                    : msg.contract,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _popupField('New Stop Loss', slController, ''),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final v = slController.text.trim();
                      Navigator.pop(ctx);
                      await controller.acknowledgeSlTrailed(msg, newSl: v);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'SUBMIT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradeTimeline(NewTradeOpportunityMessage msg) {
    const dotRadius = 6.0;
    final labels = ['SL', 'Entry', 'Target'];
    final values = [
      _formatTradeCardPrice(msg.stopLoss),
      _formatTradeCardPrice(msg.entryRange),
      _formatTradeCardPrice(msg.frr),
    ];

    double parseNumeric(String raw) {
      final matches = RegExp(r'[\d.]+').allMatches(raw);
      final nums = matches
          .map((m) => double.tryParse(m.group(0) ?? ''))
          .whereType<double>()
          .toList();
      if (nums.isEmpty) return 0.0;
      final sum = nums.fold<double>(0.0, (a, b) => a + b);
      return sum / nums.length;
    }

    final numeric = [
      parseNumeric(msg.stopLoss),
      parseNumeric(msg.entryRange),
      parseNumeric(msg.frr),
    ];
    final minV = numeric.reduce((a, b) => a < b ? a : b);
    final maxV = numeric.reduce((a, b) => a > b ? a : b);
    final denom = (maxV - minV).abs();

    final rttTrim = msg.rtt.trim();
    final hasCurrent = rttTrim.isNotEmpty;
    final currentNumeric = hasCurrent ? parseNumeric(rttTrim) : null;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final usableW = w.clamp(0.0, double.infinity);

        List<double> fractions;
        if (denom < 0.000001) {
          fractions = const [0.0, 0.5, 1.0];
        } else {
          fractions = numeric
              .map((v) => ((v - minV) / denom).clamp(0.0, 1.0))
              .toList();
        }

        const lW = 56.0;
        const minGap = 2.0;

        List<double> lx = List.generate(3, (i) => usableW * fractions[i]);
        lx = _spreadTimelineAnchorsByPrice(lx, numeric, lW + minGap, w);

        double? lxCurrent;
        if (hasCurrent && currentNumeric != null) {
          if (denom < 0.000001) {
            lxCurrent = usableW * 0.5;
          } else {
            final frac = ((currentNumeric - minV) / denom).clamp(0.0, 1.0);
            lxCurrent = usableW * frac;
          }
        }

        return Column(
          children: [
            SizedBox(
              height: 28,
              child: Stack(
                children: List.generate(3, (i) {
                  double left;
                  if (i == 0) {
                    left = lx[i].clamp(0.0, w - lW);
                  } else if (i == 2) {
                    left = (lx[i] - lW).clamp(0.0, w - lW);
                  } else {
                    left = (lx[i] - lW / 2).clamp(0.0, w - lW);
                  }

                  return Positioned(
                    left: left,
                    width: lW,
                    child: Align(
                      alignment: i == 0
                          ? Alignment.centerLeft
                          : (i == 2 ? Alignment.centerRight : Alignment.center),
                      child: Text(
                        labels[i],
                        textAlign: i == 0
                            ? TextAlign.left
                            : (i == 2 ? TextAlign.right : TextAlign.center),
                        style: TextStyle(
                          height: 1.1,
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 2),
            if (lxCurrent != null)
              SizedBox(
                height: 16,
                width: w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: (lxCurrent - 22).clamp(0.0, w - 44),
                      width: 44,
                      top: 0,
                      child: Text(
                        'LTP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: dotRadius * 2 + 4,
              width: w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: dotRadius,
                    height: 2,
                    child: CustomPaint(
                      size: Size(w, 2),
                      painter: _DottedLinePainter(),
                    ),
                  ),
                  ...List.generate(3, (i) {
                    return Positioned(
                      left: (lx[i] - dotRadius).clamp(0.0, w - dotRadius * 2),
                      top: 1,
                      child: Container(
                        width: dotRadius * 2,
                        height: dotRadius * 2,
                        decoration: const BoxDecoration(
                          color: Color(0xFF616161),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                  if (lxCurrent != null)
                    Positioned(
                      left: (lxCurrent - dotRadius).clamp(
                        0.0,
                        w - dotRadius * 2,
                      ),
                      top: 1,
                      child: Tooltip(
                        message: 'Current market price (LTP)',
                        child: Container(
                          width: dotRadius * 2,
                          height: dotRadius * 2,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 32,
              child: Stack(
                children: List.generate(3, (i) {
                  double left;
                  if (i == 0) {
                    left = lx[i].clamp(0.0, w - lW);
                  } else if (i == 2) {
                    left = (lx[i] - lW).clamp(0.0, w - lW);
                  } else {
                    left = (lx[i] - lW / 2).clamp(0.0, w - lW);
                  }

                  return Positioned(
                    left: left,
                    width: lW,
                    child: Align(
                      alignment: i == 0
                          ? Alignment.centerLeft
                          : (i == 2 ? Alignment.centerRight : Alignment.center),
                      child: Text(
                        values[i],
                        textAlign: i == 0
                            ? TextAlign.left
                            : (i == 2 ? TextAlign.right : TextAlign.center),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          height: 1.1,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTradeTimelineForEdit(NewTradeOpportunityMessage msg) {
    const dotRadius = 6.0;
    final labels = ['Stop Loss', 'Trail SL', 'Target'];
    final oldSl = msg.oldStopLoss.trim().isNotEmpty
        ? msg.oldStopLoss
        : msg.stopLoss;
    final values = [
      _formatTradeCardPrice(oldSl),
      _formatTradeCardPrice(msg.stopLoss),
      _formatTradeCardPrice(msg.frr),
    ];

    double parseNumeric(String raw) {
      final matches = RegExp(r'[\d.]+').allMatches(raw);
      final nums = matches
          .map((m) => double.tryParse(m.group(0) ?? ''))
          .whereType<double>()
          .toList();
      if (nums.isEmpty) return 0.0;
      final sum = nums.fold<double>(0.0, (a, b) => a + b);
      return sum / nums.length;
    }

    final numeric = [
      parseNumeric(oldSl),
      parseNumeric(msg.stopLoss),
      parseNumeric(msg.frr),
    ];
    final minV = numeric.reduce((a, b) => a < b ? a : b);
    final maxV = numeric.reduce((a, b) => a > b ? a : b);
    final denom = (maxV - minV).abs();

    final rttTrim = msg.rtt.trim();
    final hasCurrent = rttTrim.isNotEmpty;
    final currentNumeric = hasCurrent ? parseNumeric(rttTrim) : null;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final usableW = w.clamp(0.0, double.infinity);
        List<double> fractions;
        if (denom < 0.000001) {
          fractions = const [0.0, 0.5, 1.0];
        } else {
          fractions = numeric
              .map((v) => ((v - minV) / denom).clamp(0.0, 1.0))
              .toList();
        }

        // Wider slots for "Stop Loss" / "Trail SL"; anchors need >= 1.5*lW apart
        // because slot 0 is left-aligned, 1 centered, 2 right-aligned (64px boxes
        // would overlap with the old lW + minGap rule).
        const lW = 76.0;
        const minGap = 4.0;
        final minAnchorSep = lW * 1.5 + minGap;
        List<double> lx = List.generate(3, (i) => usableW * fractions[i]);
        lx = _spreadTimelineAnchorsByPrice(lx, numeric, minAnchorSep, w);

        double? lxCurrent;
        if (hasCurrent && currentNumeric != null) {
          if (denom < 0.000001) {
            lxCurrent = usableW * 0.5;
          } else {
            lxCurrent =
                usableW * ((currentNumeric - minV) / denom).clamp(0.0, 1.0);
          }
        }

        return Column(
          children: [
            SizedBox(
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(3, (i) {
                  final left = i == 0
                      ? lx[i].clamp(0.0, w - lW)
                      : (i == 2
                            ? (lx[i] - lW).clamp(0.0, w - lW)
                            : (lx[i] - lW / 2).clamp(0.0, w - lW));
                  return Positioned(
                    left: left,
                    width: lW,
                    child: Align(
                      alignment: i == 0
                          ? Alignment.centerLeft
                          : (i == 2 ? Alignment.centerRight : Alignment.center),
                      child: Text(
                        labels[i],
                        textAlign: i == 0
                            ? TextAlign.left
                            : (i == 2 ? TextAlign.right : TextAlign.center),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          height: 1.15,
                          fontSize: 11,
                          color: i == 0
                              ? Colors.grey.shade500
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: dotRadius * 2 + 4,
              width: w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: dotRadius,
                    height: 2,
                    child: CustomPaint(
                      size: Size(w, 2),
                      painter: _DottedLinePainter(),
                    ),
                  ),
                  ...List.generate(3, (i) {
                    final color = i == 0
                        ? Colors.grey.shade400
                        : const Color(0xFF616161);
                    return Positioned(
                      left: (lx[i] - dotRadius).clamp(0.0, w - dotRadius * 2),
                      top: 1,
                      child: Container(
                        width: dotRadius * 2,
                        height: dotRadius * 2,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                  if (lxCurrent != null)
                    Positioned(
                      left: (lxCurrent - dotRadius).clamp(
                        0.0,
                        w - dotRadius * 2,
                      ),
                      top: 1,
                      child: Container(
                        width: dotRadius * 2,
                        height: dotRadius * 2,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 32,
              child: Stack(
                children: List.generate(3, (i) {
                  final left = i == 0
                      ? lx[i].clamp(0.0, w - lW)
                      : (i == 2
                            ? (lx[i] - lW).clamp(0.0, w - lW)
                            : (lx[i] - lW / 2).clamp(0.0, w - lW));
                  return Positioned(
                    left: left,
                    width: lW,
                    child: Align(
                      alignment: i == 0
                          ? Alignment.centerLeft
                          : (i == 2 ? Alignment.centerRight : Alignment.center),
                      child: Text(
                        values[i],
                        textAlign: i == 0
                            ? TextAlign.left
                            : (i == 2 ? TextAlign.right : TextAlign.center),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: i == 0
                              ? Colors.grey.shade500
                              : const Color(0xFF424242),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTradeParamsPopup(
    BuildContext context,
    NewTradeOpportunityMessage msg,
    ChatController controller,
  ) {
    // From API: entry_price, stop_loss, take_profit
    final entryPriceController = TextEditingController(text: msg.entryRange);
    final stopLossController = TextEditingController(text: msg.stopLoss);
    final takeProfitController = TextEditingController(text: msg.frr);

    showChatFadeDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      msg.instrument[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.instrument,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          msg.contract,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _popupField(
                'Entry Price',
                entryPriceController,
                '${msg.lotNumbers[1]} Lots',
              ),
              const SizedBox(height: 16),
              _popupField(
                'Stop Loss',
                stopLossController,
                '${msg.lotNumbers[0]} Lots',
              ),
              const SizedBox(height: 16),
              _popupField(
                'Take Profit',
                takeProfitController,
                '${msg.lotNumbers[2]} Lots',
              ),
              const SizedBox(height: 14),
              Text(
                '1 lot is preferred to be under RTT mode',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await controller.submitTradeExecuted(
                          msg: msg,
                          entryPrice: entryPriceController.text,
                          stopLoss: stopLossController.text,
                          takeProfit: takeProfitController.text,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popupField(
    String label,
    TextEditingController controller,
    String suffix,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.backgroundGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              suffix,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  void _showTargetHitConfirmDialog(
    BuildContext context,
    AlertHitWithButtonMessage msg,
    ChatController controller,
  ) {
    final rawPrice = msg.targetHitPrice.trim();
    final initialPrice = rawPrice.isNotEmpty
        ? _formatTradeCardPrice(rawPrice)
        : '';

    showChatFadeDialog(
      context: context,
      builder: (ctx) => _TargetHitConfirmDialog(
        msg: msg,
        controller: controller,
        initialPrice: initialPrice,
      ),
    );
  }

  Widget _buildAlertHitWithButton(
    BuildContext context,
    AlertHitWithButtonMessage msg,
    ChatController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 12),
                if (msg.isGttHit) ...[
                  _tradePromptPrimaryButton(
                    label: 'Open Trading APP',
                    enabled: _showButtons(msg),
                    onTap: () => controller.openTradingApp(),
                  ),
                  const SizedBox(height: 10),
                ],
                GestureDetector(
                  onTap: _showButtons(msg)
                      ? () {
                          if (msg.buttonType == 'trade_executed') {
                            _showTargetHitConfirmDialog(
                              context,
                              msg,
                              controller,
                            );
                          } else if (msg.isGttHit && msg.tradeData != null) {
                            _showTradeParamsPopup(
                              context,
                              msg.tradeData!,
                              controller,
                            );
                          } else {
                            controller.onTradeExecuted();
                          }
                        }
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showButtons(msg)
                          ? AppColors.primary
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        msg.buttonLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeExecuted(
    BuildContext context,
    TradeExecutedMessage msg,
    ChatController controller,
  ) {
    final stepStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey.shade800,
      height: 1.35,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 14),
                Text('1. Go to Trading APP and apply Levels', style: stepStyle),
                const SizedBox(height: 8),
                _tradePromptPrimaryButton(
                  label: 'Open Trading APP',
                  enabled: _showButtons(msg),
                  onTap: () => controller.openTradingApp(),
                ),
                const SizedBox(height: 14),
                Text('2. Intimate me once you apply the GTT', style: stepStyle),
                const SizedBox(height: 8),
                _tradePromptPrimaryButton(
                  label: msg.buttonLabel,
                  enabled: _showButtons(msg),
                  onTap: () => AppToast.showToast('Thanks for confirming'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    BuildContext context,
    ChatController controller,
    TextEditingController textController,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Send a message',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (text) {
                controller.sendTextMessage(text);
                textController.clear();
                _scheduleScrollToBottom();
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final text = textController.text;
              controller.sendTextMessage(text);
              textController.clear();
              _scheduleScrollToBottom();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetHitConfirmDialog extends StatefulWidget {
  const _TargetHitConfirmDialog({
    required this.msg,
    required this.controller,
    required this.initialPrice,
  });

  final AlertHitWithButtonMessage msg;
  final ChatController controller;
  final String initialPrice;

  @override
  State<_TargetHitConfirmDialog> createState() =>
      _TargetHitConfirmDialogState();
}

class _TargetHitConfirmDialogState extends State<_TargetHitConfirmDialog> {
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.initialPrice);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final price = _priceController.text.trim();
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.acknowledgeTradeExecuted(widget.msg, hitPrice: price);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Confirm target hit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Target hit on this price',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Enter price',
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'CONFIRM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fade-in open animation for chat dialogs (GTT, trail SL, trade details).
Future<T?> showChatFadeDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return builder(dialogContext);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
        child: child,
      );
    },
  );
}

class _UnreadRevealGate extends StatefulWidget {
  const _UnreadRevealGate({required this.messageId, required this.onRevealed});

  final String messageId;
  final ValueChanged<String> onRevealed;

  @override
  State<_UnreadRevealGate> createState() => _UnreadRevealGateState();
}

class _UnreadRevealGateState extends State<_UnreadRevealGate> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      widget.onRevealed(widget.messageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(children: [SizedBox(width: 44), _TypingDots()]),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        double opacityFor(int i) {
          final phase = ((_controller.value * 3) - i).clamp(0.0, 1.0);
          return 0.25 + (phase * 0.75);
        }

        Widget dot(int i) => Opacity(
          opacity: opacityFor(i),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF9E9E9E),
              shape: BoxShape.circle,
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dot(0),
              const SizedBox(width: 4),
              dot(1),
              const SizedBox(width: 4),
              dot(2),
            ],
          ),
        );
      },
    );
  }
}

/// Large “X” over invalidated trade cards (delete / recommendation void).
class _InvalidTradeCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade500.withOpacity(0.65)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const inset = 8.0;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dashWidth, size.height / 2),
        paint,
      );
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlinkingCurrentPriceBadge extends StatefulWidget {
  const _BlinkingCurrentPriceBadge({required this.price});

  final String price;

  @override
  State<_BlinkingCurrentPriceBadge> createState() =>
      _BlinkingCurrentPriceBadgeState();
}

class _BlinkingCurrentPriceBadgeState extends State<_BlinkingCurrentPriceBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.35,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Text(
          'Current Market Price: ${widget.price}',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
