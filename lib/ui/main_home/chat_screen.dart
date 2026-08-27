import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/controller/chat_controller.dart';
import 'package:discipline_mind/model/chat_message_model.dart';
import 'package:discipline_mind/services/notification/notification_handler.dart';
import 'package:discipline_mind/ui/main_home/trade_process.dart';
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

  /// Selected action in trade signal dropdowns keyed by messageId / signalId.
  final Map<String, String> _selectedSignalActions = <String, String>{};
  final Set<String> _expandedSignalDropdowns = <String>{};

  // ==================== Theme-aware color helpers ====================
  // Centralised so light/dark variants stay consistent across every bubble,
  // card, dialog and input in this screen.

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Screen / scaffold background.
  Color _screenBg(bool isDark) =>
      isDark ? const Color(0xFF12151B) : AppColors.backgroundGray;

  /// Bottom input bar background.
  Color _bottomBarBg(bool isDark) =>
      isDark ? const Color(0xFF12151B) : Colors.white;

  /// Incoming (assistant) plain text bubble background.
  Color _bubbleBg(bool isDark) =>
      isDark ? const Color(0xFF1E222A) : Colors.grey.shade200;

  /// Incoming bubble main text.
  Color _bubbleText(bool isDark) => isDark ? Colors.white : Colors.black87;

  /// Headline / primary body text outside bubbles (was Colors.grey.shade800).
  Color _headlineText(bool isDark) =>
      isDark ? Colors.white : Colors.grey.shade800;

  /// Secondary text (was Colors.grey.shade700).
  Color _secondaryText(bool isDark) =>
      isDark ? Colors.white70 : Colors.grey.shade700;

  /// Tertiary / muted text (was Colors.grey.shade600).
  Color _tertiaryText(bool isDark) =>
      isDark ? Colors.white60 : Colors.grey.shade600;

  /// Dialog / popup surface background (was Colors.white).
  Color _dialogBg(bool isDark) =>
      isDark ? const Color(0xFF3C3C3A) : Colors.white;

  /// Text field fill inside dialogs / input bar (was AppColors.backgroundGray
  /// or Colors.grey.shade100).
  Color _fieldFill(bool isDark) =>
      isDark ? const Color(0xFF7B7B7A) : AppColors.backgroundGray;

  /// Generic border color for fields/cards in dialogs.
  Color _fieldBorder(bool isDark) =>
      isDark ? Colors.white24 : Colors.grey.shade400;

  /// Divider color used inside the (always-white) trade card stays the same
  /// in both themes since the card itself stays white per design.

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
    final isDark = _isDark(context);
    return GetBuilder<ChatController>(
      init: Get.put(ChatController(), permanent: true),
      builder: (controller) => Scaffold(
        backgroundColor: _screenBg(isDark),
        body: SafeArea(
          child: Column(
            children: [
              // _buildHeader(context, controller),
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
                          children: [
                            SizedBox(
                              height: 420,
                              child: Center(
                                child: Text(
                                  'No messages yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _secondaryText(isDark),
                                  ),
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
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    "assets/logo.jpg",
                    height: 26,
                    width: 26,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Zeno AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
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
      case ChatMessageType.aiWaiting:
        return _buildAiWaiting(context, msg as AiWaitingMessage);
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
      case ChatMessageType.tradeSignal:
        return _buildTradeSignal(context, msg as TradeSignalMessage, controller);
    }
  }

  Widget _buildAiWaiting(BuildContext context, AiWaitingMessage msg) {
    final isDark = _isDark(context);
    final text = msg.text.trim();
    final subtitle = msg.subtitle.trim();
    final fullText = subtitle.isNotEmpty &&
            subtitle != 'Monkk is waiting' &&
            subtitle != 'AI is waiting'
        ? '$text\n$subtitle'
        : text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildRichMessageContent(fullText, isDark),
    );
  }

  Widget _buildDmtScore(BuildContext context, DmtScoreMessage msg) {
    final isDark = _isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichMessageContent(
            msg.headline.isNotEmpty
                ? msg.headline
                : 'Your daily discipline analysis is ready.',
            isDark,
          ),
          const SizedBox(height: 12),
          _tradePromptPrimaryButton(
            label: 'View Discipline Analysis',
            icon: Icons.analytics_outlined,
            onTap: () {
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
          ),
        ],
      ),
    );
  }

  static String _formatIndianCurrency(String raw) {
    if (raw.trim().isEmpty) return '0.00';
    final clean = raw.trim().replaceAll(',', '');
    final numVal = double.tryParse(clean);
    if (numVal == null) return raw;
    final parts = clean.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    final digits = intPart.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 3) {
      return (intPart.startsWith('-') ? '-' : '') + digits + decPart;
    }

    final lastThree = digits.substring(digits.length - 3);
    var other = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (other.length > 2) {
      groups.insert(0, other.substring(other.length - 2));
      other = other.substring(0, other.length - 2);
    }
    if (other.isNotEmpty) {
      groups.insert(0, other);
    }
    groups.add(lastThree);
    final formatted = groups.join(',');
    return (intPart.startsWith('-') ? '-' : '') + formatted + decPart;
  }

  Widget _buildTradeSignal(
    BuildContext context,
    TradeSignalMessage msg,
    ChatController controller,
  ) {
    final isDark = _isDark(context);
    final msgKey = msg.messageId.isNotEmpty
        ? msg.messageId
        : (msg.signalId.isNotEmpty ? msg.signalId : 'ts_${msg.instrument}');
    final selectedAction = _selectedSignalActions[msgKey];
    final isDropdownExpanded = _expandedSignalDropdowns.contains(msgKey);

    final openPriceFormatted = _formatIndianCurrency(msg.openPrice);
    final currentPriceFormatted = _formatIndianCurrency(msg.currentPrice);
    final dayLowFormatted = _formatIndianCurrency(msg.dayLow);
    final dayHighFormatted = _formatIndianCurrency(msg.dayHigh);

    final gapNum = double.tryParse(msg.gapPercent) ?? 0.0;
    final changeNum = double.tryParse(msg.changePercent) ?? 0.0;
    final isGapDown = gapNum < 0;
    final isChangeDown = changeNum < 0;

    final lowNum = double.tryParse(msg.dayLow.replaceAll(',', '')) ?? 0.0;
    final highNum = double.tryParse(msg.dayHigh.replaceAll(',', '')) ?? 1.0;
    final currNum =
        double.tryParse(msg.currentPrice.replaceAll(',', '')) ?? lowNum;
    final diff = highNum - lowNum;
    final ratio =
        diff > 0 ? ((currNum - lowNum) / diff).clamp(0.0, 1.0) : 0.5;

    final isMovingUp = currNum >=
        (double.tryParse(msg.openPrice.replaceAll(',', '')) ?? lowNum);
    final movementText = isMovingUp
        ? '${msg.instrument} is moving from Low to High.'
        : '${msg.instrument} is moving from High to Low.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Process Overview at 10:00 am',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _headlineText(isDark),
            ),
          ),
          const SizedBox(height: 12),

          // Top Process Overview Card
          Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E222A) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE8E6F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row (Icon + Symbol)
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF6C38FF), Color(0xFF4A22F4)],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (msg.tradingsymbol.isNotEmpty
                                      ? msg.tradingsymbol
                                      : msg.instrument)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            msg.tradingsymbol.isNotEmpty
                                ? msg.tradingsymbol
                                : msg.instrument,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _headlineText(isDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Two column stats container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF15181E)
                              : const Color(0xFFFBFBFE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFEEECF6),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Left Column (Opens At)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${msg.instrument} Opens At',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: _secondaryText(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    openPriceFormatted,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _headlineText(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '(${gapNum >= 0 ? "+$gapNum%" : "$gapNum%"} ${isGapDown ? "Gap Down" : "Gap Up"})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isGapDown
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Vertical Divider
                            Container(
                              width: 1,
                              height: 48,
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE8E6F0),
                            ),
                            const SizedBox(width: 12),

                            // Right Column (Current Status)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Status',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: _secondaryText(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    currentPriceFormatted,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _headlineText(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '(${changeNum >= 0 ? "+$changeNum%" : "$changeNum%"})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isChangeDown
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Day Low / Current / Day High Text Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Day Low',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _secondaryText(isDark),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dayLowFormatted,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _headlineText(isDark),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _secondaryText(isDark),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentPriceFormatted,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF208052),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Day High',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _secondaryText(isDark),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dayHighFormatted,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _headlineText(isDark),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Slider Track & Indicator Dots
                      SizedBox(
                        height: 18,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final totalWidth = constraints.maxWidth;
                            final dotPos = (totalWidth * ratio).clamp(
                              6.0,
                              totalWidth - 6.0,
                            );

                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Background base track
                                Container(
                                  width: totalWidth,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white12
                                        : const Color(0xFFE2E0E9),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),

                                // Active progress track from low to current
                                Container(
                                  width: dotPos,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6C38FF),
                                        Color(0xFF208052),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),

                                // Left Dot (Low)
                                Positioned(
                                  left: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF1E222A)
                                          : Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFF6C38FF),
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),

                                // Current Dot
                                Positioned(
                                  left: dotPos - 6,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF1E222A)
                                          : Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFF208052),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),

                                // Right Dot (High)
                                Positioned(
                                  right: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF1E222A)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFFB8B6C4),
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sentiment Pill
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF142B21)
                              : const Color(0xFFF0FAF6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1F4A38)
                                : const Color(0xFFD4EFE4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isMovingUp
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: isMovingUp
                                  ? const Color(0xFF208052)
                                  : const Color(0xFFD32F2F),
                              size: 18,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                movementText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isMovingUp
                                      ? const Color(0xFF208052)
                                      : const Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showButtons(msg)) ...[
                  const SizedBox(height: 18),

                  // Mind Control Guard is Deactivated
                  Text(
                    'Mind Control Guard is Deactivated',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _headlineText(isDark),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 1. Open Trading APP
                  Text(
                    '1. Open Trading APP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _headlineText(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Button: OPEN TRADING APP
                  _tradePromptPrimaryButton(
                    label: 'OPEN TRADING APP',
                    enabled: true,
                    onTap: () async {
                      await controller.openTradingApp();
                    },
                  ),

                  const SizedBox(height: 18),

                  // 2. Select your Action
                  Text(
                    '2. Select your Action',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _headlineText(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Custom Action Dropdown
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF211D33)
                          : const Color(0xFFFAF9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF7C3AED),
                        width: 1.3,
                      ),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              if (isDropdownExpanded) {
                                _expandedSignalDropdowns.remove(msgKey);
                              } else {
                                _expandedSignalDropdowns.add(msgKey);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedAction ?? 'Select an action',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selectedAction != null
                                          ? _headlineText(isDark)
                                          : _secondaryText(isDark),
                                    ),
                                  ),
                                ),
                                Icon(
                                  isDropdownExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: const Color(0xFF7C3AED),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isDropdownExpanded) ...[
                          const Divider(height: 1, color: Color(0xFFE2DCF7)),
                          // Option 1: Set Levels
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSignalActions[msgKey] = 'Set Levels';
                                _expandedSignalDropdowns.remove(msgKey);
                              });
                              _showSignalSetLevelsDialog(context, msg, controller);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.adjust_rounded,
                                    color: Color(0xFF7C3AED),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Set Levels',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (selectedAction == 'Set Levels')
                                    const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF7C3AED),
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2DCF7)),
                          // Option 2: GTT
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSignalActions[msgKey] = 'GTT (Good Till Triggered)';
                                _expandedSignalDropdowns.remove(msgKey);
                              });
                              _showSignalGttDialog(context, msg, controller);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Color(0xFF7C3AED),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'GTT (Good Till Triggered)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (selectedAction == 'GTT' || selectedAction == 'GTT (Good Till Triggered)')
                                    const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF7C3AED),
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
  }

  void _showSignalGttDialog(
    BuildContext context,
    TradeSignalMessage msg,
    ChatController controller,
  ) {
    final isDark = _isDark(context);
    final initialGtt = msg.currentPrice.trim().isNotEmpty
        ? msg.currentPrice.trim().replaceAll(',', '')
        : '';
    final gttController = TextEditingController(text: initialGtt);

    showChatFadeDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _dialogBg(isDark),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Close button
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : const Color(0xFF4A22F4),
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Center Icon
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE9FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gps_fixed_rounded,
                    color: Color(0xFF4A22F4),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'You have selected Apply GTT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _headlineText(isDark),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Please enter the level at which you have already applied the GTT order on your trading app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _secondaryText(isDark),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // Current Level Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222A) : const Color(0xFFF6F5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF10122D),
                      ),
                    ),
                    Text(
                      _formatIndianCurrency(msg.currentPrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4A22F4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Field Label
              Text(
                'GTT Applied Level',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _headlineText(isDark),
                ),
              ),
              const SizedBox(height: 8),

              // TextField
              TextField(
                controller: gttController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _bubbleText(isDark),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E222A) : const Color(0xFFF7F6FB),
                  hintText: 'Enter the GTT applied level',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFFB0B0B8),
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                  suffixIcon: const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF2B4BF2),
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E0E9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E0E9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2B4BF2), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Info note
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark ? Colors.white60 : const Color(0xFF70717F),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'We will track this level and update you accordingly.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryText(isDark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    final val = gttController.text.trim();
                    if (val.isEmpty) {
                      AppToast.showToast('Please enter GTT trigger value');
                      return;
                    }
                    Navigator.pop(ctx);
                    await controller.submitTradeSignalGtt(
                      msg: msg,
                      gttPrice: val,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2B4BF2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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

  void _showSignalSetLevelsDialog(
    BuildContext context,
    TradeSignalMessage msg,
    ChatController controller,
  ) {
    final isDark = _isDark(context);
    final initialUpper = msg.dayHigh.trim().isNotEmpty
        ? msg.dayHigh.trim().replaceAll(',', '')
        : '';
    final initialLower = msg.dayLow.trim().isNotEmpty
        ? msg.dayLow.trim().replaceAll(',', '')
        : '';
    final upperController = TextEditingController(text: initialUpper);
    final lowerController = TextEditingController(text: initialLower);
    final instrumentName = msg.tradingsymbol.isNotEmpty
        ? msg.tradingsymbol
        : (msg.instrument.isNotEmpty ? msg.instrument : 'Nifty 50');

    showChatFadeDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _dialogBg(isDark),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Close button
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : const Color(0xFF4A22F4),
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Center Bell Icon
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE9FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF4A22F4),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'Set Alert for $instrumentName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _headlineText(isDark),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Get notified when the index reaches your desired levels.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _secondaryText(isDark),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // Current Level Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222A) : const Color(0xFFF6F5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF10122D),
                      ),
                    ),
                    Text(
                      _formatIndianCurrency(msg.currentPrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4A22F4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Field 1: Upper Level Alert
              Text(
                'Upper Level Alert',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _headlineText(isDark),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: upperController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _bubbleText(isDark),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E222A) : const Color(0xFFF7F6FB),
                  hintText: 'Enter upper level',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFFB0B0B8),
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                  suffixIcon: const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF208052),
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E0E9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E0E9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2B4BF2), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),

              // Field 2: Lower Level Alert
              Text(
                'Lower Level Alert',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _headlineText(isDark),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: lowerController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _bubbleText(isDark),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E222A) : const Color(0xFFF7F6FB),
                  hintText: 'Enter lower level',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFFB0B0B8),
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                  suffixIcon: const Icon(
                    Icons.trending_down_rounded,
                    color: Color(0xFFCC3B4D),
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E0E9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E0E9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2B4BF2), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    final upperVal = upperController.text.trim();
                    final lowerVal = lowerController.text.trim();
                    if (upperVal.isEmpty || lowerVal.isEmpty) {
                      AppToast.showToast('Please enter both Upper and Lower values');
                      return;
                    }
                    Navigator.pop(ctx);
                    await controller.submitTradeSignalLevels(
                      msg: msg,
                      upperPrice: upperVal,
                      lowerPrice: lowerVal,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2B4BF2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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

  List<InlineSpan> _parseFormattedSpans(String text, Color textColor) {
    final List<InlineSpan> spans = [];
    final tagRegex = RegExp(
      r'(?:<b>(.*?)<\/b>|<strong>(.*?)<\/strong>|\*\*(.*?)\*\*)',
      caseSensitive: false,
      dotAll: true,
    );

    int lastMatchEnd = 0;
    for (final match in tagRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.normal,
              height: 1.4,
            ),
          ),
        );
      }

      final boldText = match.group(1) ?? match.group(2) ?? match.group(3) ?? '';
      spans.add(
        TextSpan(
          text: boldText,
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
        ),
      );
    }

    return spans;
  }

  Widget _buildRichMessageContent(String rawText, bool isDark) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF10122D);
    final normalized = rawText
        .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n');
    final lines = normalized.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      final isBullet = line.startsWith('•') || line.startsWith('-');

      if (isBullet) {
        final bulletText = line.replaceFirst(RegExp(r'^[•\-]\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: _parseFormattedSpans(bulletText, primaryTextColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: RichText(
              text: TextSpan(
                children: _parseFormattedSpans(line, primaryTextColor),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildSimpleText(BuildContext context, SimpleTextMessage msg) {
    final isDark = _isDark(context);
    if (msg.isFromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2B4BF2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildRichMessageContent(msg.text, isDark),
    );
  }

  Widget _buildAgentWithButton(
    BuildContext context,
    AgentWithButtonMessage msg,
  ) {
    final isDark = _isDark(context);
    final hasText = msg.text.trim().isNotEmpty;
    final label = msg.buttonLabel.trim().isNotEmpty
        ? msg.buttonLabel.trim()
        : 'CREATE A PROCESS';

    Future<void> handleButtonTap() async {
      final upperLabel = label.toUpperCase();
      if (upperLabel.contains('PROCESS') ||
          upperLabel.contains('CREATE A PROCESS')) {
        final userId = Common.userData.value?.payload?.id?.toString();
        if (userId != null && userId.isNotEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TradingProcessScreen(userId: userId),
            ),
          );
          if (Get.isRegistered<ChatController>()) {
            await Get.find<ChatController>().loadMessages(refresh: true);
          }
        } else {
          widget.onMonkkTap?.call();
        }
      } else {
        widget.onMonkkTap?.call();
      }
    }

    final buttonWidget = _tradePromptPrimaryButton(
      label: label,
      icon: msg.actionTaken != null ? Icons.check_circle_outline_rounded : null,
      isCompleted: msg.actionTaken != null,
      enabled: msg.actionTaken == null,
      onTap: msg.actionTaken == null ? handleButtonTap : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasText) ...[
            _buildRichMessageContent(msg.text, isDark),
            const SizedBox(height: 12),
          ],
          buttonWidget,
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
    final isDark = _isDark(context);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg.apiMessage.isNotEmpty
                ? msg.apiMessage
                : 'New Trade Opportunity is spotted for you',
            style: TextStyle(
              color: _headlineText(isDark),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildTradeOpportunityCard(
            context,
            msg,
            showInvalidOverlay: false,
          ),
        ],
      ),
    );
  }

  Widget _monkkSparkleIcon() {
    return const SizedBox.shrink();
  }

  /// Invalid card + cross + both steps and buttons in one bubble (open_app / delete_button).
  Widget _buildTradeDeleteCombinedMessage(
    BuildContext context,
    NewTradeOpportunityMessage msg,
    ChatController controller,
  ) {
    final isDark = _isDark(context);
    final stepStyle = TextStyle(
      fontSize: 13,
      color: _headlineText(isDark),
      height: 1.35,
    );
    final titleStyle = TextStyle(
      color: _headlineText(isDark),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trade recommendation invalid — please delete this trade',
            style: titleStyle,
          ),
          const SizedBox(height: 8),
          _buildTradeOpportunityCard(
            context,
            msg,
            showInvalidOverlay: true,
          ),
          const SizedBox(height: 16),
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
            icon: !_showButtons(msg) ? Icons.check_circle_outline_rounded : null,
            isCompleted: !_showButtons(msg),
            enabled: _showButtons(msg),
            onTap: () => controller.acknowledgeTradeDeleted(msg),
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
    final isDark = _isDark(context);
    final stepStyle = TextStyle(
      fontSize: 13,
      color: _headlineText(isDark),
      height: 1.35,
    );
    final titleStyle = TextStyle(
      color: _headlineText(isDark),
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
          Text('SL Edited', style: titleStyle),
          const SizedBox(height: 8),
          _buildTradeOpportunityCard(
            context,
            msg,
            showInvalidOverlay: false,
          ),
          const SizedBox(height: 16),
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
            icon: !_showButtons(msg) ? Icons.check_circle_outline_rounded : null,
            isCompleted: !_showButtons(msg),
            enabled: _showButtons(msg),
            onTap: () => _showTrailSlDialog(context, msg, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeOpportunityCard(
    BuildContext context,
    NewTradeOpportunityMessage msg, {
    required bool showInvalidOverlay,
  }) {
    final isDark = _isDark(context);

    final cardBg = isDark ? const Color(0xFF1B1F27) : Colors.white;
    final cardBorder = isDark ? AppColors.primary.withOpacity(.4) : Colors.grey.shade300;
    final shadowColor = isDark 
        ? Colors.black.withOpacity(0.35) 
        : Colors.black.withOpacity(0.08);

    final tradeName = msg.tradeName.trim().isNotEmpty
        ? msg.tradeName.trim()
        : msg.instrument;
    final tradeSymbol = msg.tradeSymbol.trim().isNotEmpty
        ? msg.tradeSymbol.trim()
        : msg.contract;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // color: cardBg,
        gradient: LinearGradient(colors: isDark?[
          Colors.black,Colors.white.withOpacity(.002)
        ]:[
          Colors.white,
          Colors.white,
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: showInvalidOverlay
          ? Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                _buildCardContent(context, msg, tradeName, tradeSymbol),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _InvalidTradeCrossPainter(isDark: isDark),
                  ),
                ),
              ],
            )
          : _buildCardContent(context, msg, tradeName, tradeSymbol),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    NewTradeOpportunityMessage msg,
    String tradeName,
    String tradeSymbol,
  ) {
    final isDark = _isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: const NetworkImage(
                'https://i.pravatar.cc/150?u=analyst',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SEBI REG ANALYST',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (msg.rtt.trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: !isDark ? const Color(0xFF2A2F3A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:!isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  'CMP : ${_formatTradeCardPrice(msg.rtt)}',
                  style: TextStyle(
                    color: !isDark ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Symbol Section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  tradeName.isNotEmpty ? tradeName[0].toUpperCase() : 'S',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tradeName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.apiMessage.isNotEmpty ? msg.apiMessage : tradeSymbol,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Timeline
        _buildImageStyleTimeline(context, msg),
      ],
    );
  }

  Widget _buildImageStyleTimeline(
    BuildContext context,
    NewTradeOpportunityMessage msg,
  ) {
    final isDark = _isDark(context);

    final lineColor = isDark ? Colors.white24 : Colors.grey.shade400;
    final dotColor = isDark ? Colors.white38 : Colors.grey.shade500;
    final activeDotColor = const Color(0xFF8B5CF6);
    final labelColor = isDark ? Colors.white60 : Colors.grey.shade700;
    final valueColor = isDark ? Colors.white : Colors.black87;

    final sl = _formatTradeCardPrice(msg.stopLoss);
    final entry = _formatTradeCardPrice(msg.entryRange);
    final target = _formatTradeCardPrice(msg.frr);
    final current = msg.rtt.trim().isNotEmpty ? _formatTradeCardPrice(msg.rtt) : null;

    double parseNum(String raw) {
      final matches = RegExp(r'[\d.]+').allMatches(raw);
      final nums = matches
          .map((m) => double.tryParse(m.group(0) ?? '0'))
          .whereType<double>()
          .toList();
      return nums.isEmpty ? 0 : nums.reduce((a, b) => a + b) / nums.length;
    }

    final numeric = [parseNum(sl), parseNum(entry), parseNum(target)];
    final minV = numeric.reduce((a, b) => a < b ? a : b);
    final maxV = numeric.reduce((a, b) => a > b ? a : b);
    final denom = maxV - minV;

    final fractions = denom < 0.0001
        ? const [0.0, 0.5, 1.0]
        : numeric.map((v) => ((v - minV) / denom).clamp(0.0, 1.0)).toList();

    final currentFrac = current != null && denom > 0.0001
        ? ((parseNum(current) - minV) / denom).clamp(0.0, 1.0)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final positions = fractions.map((f) => w * f).toList();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SL', style: TextStyle(color: labelColor, fontSize: 12)),
                Text('ENTRY', style: TextStyle(color: labelColor, fontSize: 12)),
                Text('TARGET', style: TextStyle(color: labelColor, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 11,
                    left: 0,
                    right: 0,
                    child: CustomPaint(
                      size: Size(w, 2),
                      painter: _DottedLinePainter(isDark: isDark),
                    ),
                  ),
                  ...List.generate(3, (i) {
                    return Positioned(
                      left: (positions[i] - 6).clamp(0.0, w - 12),
                      top: 5,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: i == 1 ? activeDotColor : dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                      ),
                    );
                  }),
                  if (currentFrac != null)
                    Positioned(
                      left: (w * currentFrac - 6).clamp(0.0, w - 12),
                      top: 5,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: activeDotColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sl, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(entry, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(target, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        );
      },
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
    final isDark = _isDark(context);
    final actionSource = sourceMessage ?? msg;
    final bodyStyle = TextStyle(fontSize: 14, color: _headlineText(isDark));
    final stepStyle = TextStyle(
      fontSize: 13,
      color: _headlineText(isDark),
      height: 1.35,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          if (_showButtons(actionSource)) ...[
            const SizedBox(height: 14),
            Text('1. Go to Trading APP and apply Levels', style: stepStyle),
            const SizedBox(height: 8),
            _tradePromptPrimaryButton(
              label: 'Open Trading APP',
              enabled: true,
              onTap: () => controller.openTradingApp(),
            ),
            const SizedBox(height: 14),
            Text('2. Intimate me once you apply the GTT', style: stepStyle),
            const SizedBox(height: 8),
            _tradePromptPrimaryButton(
              label: 'GTT / Levels Applied',
              enabled: true,
              onTap: () => _showGttDialog(context, msg, controller),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tradePromptPrimaryButton({
    required String label,
    IconData? icon,
    VoidCallback? onTap,
    bool enabled = true,
    bool interactive = true,
    bool isCompleted = false,
  }) {
    final isDark = _isDark(context);
    const primaryColor = Color(0xFF2B4BF2);
    final borderColor = (isCompleted || enabled)
        ? primaryColor
        : (isDark ? Colors.white24 : Colors.grey.shade400);
    final textColor = (isCompleted || enabled)
        ? primaryColor
        : (isDark ? Colors.white38 : Colors.grey.shade500);
    final iconColor = textColor;
    IconData getFallbackIcon() {
      final l = label.toUpperCase();
      if (isCompleted) return Icons.check_circle_outline_rounded;
      if (l.contains('PROCESS') || l.contains('CREATE')) return Icons.add_circle_outline_rounded;
      if (l.contains('OPEN') || l.contains('TRADING APP') || l.contains('APP')) return Icons.open_in_new_rounded;
      if (l.contains('GTT') || l.contains('LEVELS') || l.contains('APPLIED')) return Icons.check_circle_outline_rounded;
      if (l.contains('DELETE')) return Icons.delete_outline_rounded;
      if (l.contains('TRAIL') || l.contains('SL')) return Icons.trending_up_rounded;
      if (l.contains('SCORE') || l.contains('DMT') || l.contains('ANALYSIS') || l.contains('VIEW')) return Icons.analytics_outlined;
      if (l.contains('HIT') || l.contains('TARGET')) return Icons.flag_outlined;
      return Icons.check_circle_outline_rounded;
    }

    final effectiveIcon = icon ?? getFallbackIcon();

    final child = Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1.8,
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(effectiveIcon, size: 19, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    final canTap = interactive && enabled && onTap != null;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
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
    final isDark = _isDark(context);
    final useExtendedFields = controller.shouldUseExtendedGttInputs();
    final gttPriceController = TextEditingController(
      text: ChatController.getDefaultGttPrice(msg.entryRange),
    );
    final stopLossController = TextEditingController(text: msg.stopLoss);
    final takeProfitController = TextEditingController(text: msg.frr);

    showChatFadeDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _dialogBg(isDark),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Close button
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : const Color(0xFF4A22F4),
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Center Icon
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE9FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gps_fixed_rounded,
                    color: Color(0xFF4A22F4),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'You have selected Apply GTT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _headlineText(isDark),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Please enter the level at which you have already applied the GTT order on your trading app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _secondaryText(isDark),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // Current Level Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222A) : const Color(0xFFF6F5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF10122D),
                      ),
                    ),
                    Text(
                      _formatIndianCurrency(
                        ChatController.getDefaultGttPrice(msg.entryRange),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4A22F4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Fields
              if (!useExtendedFields) ...[
                Text(
                  'GTT Applied Level',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _headlineText(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: gttPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _bubbleText(isDark),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E222A) : const Color(0xFFF7F6FB),
                    hintText: 'Enter the GTT applied level',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : const Color(0xFFB0B0B8),
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                    suffixIcon: const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF2B4BF2),
                      size: 22,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E0E9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E0E9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2B4BF2), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ] else ...[
                _popupField('GTT is set at', gttPriceController, '', isDark),
                const SizedBox(height: 12),
                _popupField('Stop Loss', stopLossController, '', isDark),
                const SizedBox(height: 12),
                _popupField('Target', takeProfitController, '', isDark),
              ],
              const SizedBox(height: 12),

              // Info note
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark ? Colors.white60 : const Color(0xFF70717F),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'We will track this level and update you accordingly.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryText(isDark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    final val = gttPriceController.text.trim();
                    if (val.isEmpty) {
                      AppToast.showToast('Please enter GTT trigger value');
                      return;
                    }
                    Navigator.pop(ctx);
                    await controller.createGttAlert(
                      msg,
                      gttPriceController.text,
                      stopLoss: useExtendedFields ? stopLossController.text : null,
                      takeProfit: useExtendedFields ? takeProfitController.text : null,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2B4BF2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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
    final isDark = _isDark(context);
    final slController = TextEditingController(text: msg.stopLoss);
    showChatFadeDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _dialogBg(isDark),
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
                child: Row(
                  children: [
                    Icon(Icons.close,color: Colors.white,),
                    const Text(
                      'Trail Stop Loss',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _bubbleText(isDark),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg.tradeSymbol.trim().isNotEmpty
                                    ? msg.tradeSymbol.trim()
                                    : msg.contract,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _secondaryText(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _popupField('New Stop Loss', slController, '', isDark),
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

  Widget _buildTradeTimeline(BuildContext context, NewTradeOpportunityMessage msg) {
    final isDark = _isDark(context);
    final labelColor = isDark ? Colors.white60 : Colors.grey.shade700;
    final valueColor = isDark ? Colors.white : const Color(0xFF424242);
    final dotColor = isDark ? Colors.white38 : const Color(0xFF616161);
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
                          color: labelColor,
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
                      painter: _DottedLinePainter(isDark: isDark),
                    ),
                  ),
                  ...List.generate(3, (i) {
                    return Positioned(
                      left: (lx[i] - dotRadius).clamp(0.0, w - dotRadius * 2),
                      top: 1,
                      child: Container(
                        width: dotRadius * 2,
                        height: dotRadius * 2,
                        decoration: BoxDecoration(
                          color: dotColor,
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
                        style: TextStyle(
                          height: 1.1,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: valueColor,
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

  Widget _buildTradeTimelineForEdit(BuildContext context, NewTradeOpportunityMessage msg) {
    final isDark = _isDark(context);
    final dimLabelColor = isDark ? Colors.white38 : Colors.grey.shade500;
    final labelColor = isDark ? Colors.white60 : Colors.grey.shade700;
    final dimValueColor = isDark ? Colors.white38 : Colors.grey.shade500;
    final valueColor = isDark ? Colors.white : const Color(0xFF424242);
    final dimDotColor = isDark ? Colors.white24 : Colors.grey.shade400;
    final dotColor = isDark ? Colors.white38 : const Color(0xFF616161);
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
                          color: i == 0 ? dimLabelColor : labelColor,
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
                      painter: _DottedLinePainter(isDark: isDark),
                    ),
                  ),
                  ...List.generate(3, (i) {
                    final color = i == 0 ? dimDotColor : dotColor;
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
                          color: i == 0 ? dimValueColor : valueColor,
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
    final isDark = _isDark(context);
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
          decoration: BoxDecoration(
            color: _dialogBg(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
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
                      msg.instrument.trim().isNotEmpty
                          ? msg.instrument.trim()[0].toUpperCase()
                          : (msg.contract.trim().isNotEmpty
                              ? msg.contract.trim()[0].toUpperCase()
                              : 'T'),
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
                          msg.instrument.isNotEmpty ? msg.instrument : msg.contract,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _bubbleText(isDark),
                          ),
                        ),
                        Text(
                          msg.contract,
                          style: TextStyle(
                            fontSize: 13,
                            color: _tertiaryText(isDark),
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
                '${msg.lotNumbers.length > 1 ? msg.lotNumbers[1] : 1} Lots',
                isDark,
              ),
              const SizedBox(height: 16),
              _popupField(
                'Stop Loss',
                stopLossController,
                '${msg.lotNumbers.isNotEmpty ? msg.lotNumbers[0] : 1} Lots',
                isDark,
              ),
              const SizedBox(height: 16),
              _popupField(
                'Take Profit',
                takeProfitController,
                '${msg.lotNumbers.length > 2 ? msg.lotNumbers[2] : 1} Lots',
                isDark,
              ),
              const SizedBox(height: 14),
              Text(
                '1 lot is preferred to be under RTT mode',
                style: TextStyle(fontSize: 12, color: _tertiaryText(isDark)),
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
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: _headlineText(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(color: _bubbleText(isDark)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _fieldFill(isDark),
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
              style: TextStyle(fontSize: 13, color: _tertiaryText(isDark)),
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
    final isDark = _isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichMessageContent(msg.text, isDark),
          const SizedBox(height: 12),
          if (msg.isGttHit) ...[
            _tradePromptPrimaryButton(
              label: 'Open Trading APP',
              enabled: _showButtons(msg),
              onTap: () => controller.openTradingApp(),
            ),
            const SizedBox(height: 10),
          ],
          _tradePromptPrimaryButton(
            label: msg.buttonLabel,
            icon: !_showButtons(msg)
                ? Icons.check_circle_outline_rounded
                : (msg.isSlHit
                    ? Icons.error_outline_rounded
                    : Icons.flag_outlined),
            isCompleted: !_showButtons(msg),
            enabled: _showButtons(msg),
            onTap: () {
              _showTargetHitConfirmDialog(
                context,
                msg,
                controller,
              );
            },
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
    final isDark = _isDark(context);
    final stepStyle = TextStyle(
      fontSize: 13,
      color: _headlineText(isDark),
      height: 1.35,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg.text,
            style: TextStyle(fontSize: 14, color: _headlineText(isDark)),
          ),
          if (_showButtons(msg)) ...[
            const SizedBox(height: 14),
            Text('1. Go to Trading APP and apply Levels', style: stepStyle),
            const SizedBox(height: 8),
            _tradePromptPrimaryButton(
              label: 'Open Trading APP',
              enabled: true,
              onTap: () => controller.openTradingApp(),
            ),
            const SizedBox(height: 14),
            Text('2. Intimate me once you apply the GTT', style: stepStyle),
            const SizedBox(height: 8),
            _tradePromptPrimaryButton(
              label: msg.buttonLabel,
              enabled: true,
              onTap: () => AppToast.showToast('Thanks for confirming'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInput(
    BuildContext context,
    ChatController controller,
    TextEditingController textController,
  ) {
    final isDark = _isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: _bottomBarBg(isDark),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF2B4BF2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                style: TextStyle(color: _bubbleText(isDark), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Send a message',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF70717F),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (text) {
                  if (text.trim().isEmpty) return;
                  controller.sendTextMessage(text);
                  textController.clear();
                  _scheduleScrollToBottom();
                },
              ),
            ),
            InkWell(
              onTap: () {
                final text = textController.text;
                if (text.trim().isEmpty) return;
                controller.sendTextMessage(text);
                textController.clear();
                _scheduleScrollToBottom();
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Icon(
                  Icons.send_rounded,
                  color: Color(0xFF2B4BF2),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1B1F27) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final fieldFill = isDark ? const Color(0xFF22262F) : AppColors.backgroundGray;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: dialogBg,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.msg.isSlHit
                  ? 'Confirm SL hit'
                  : (widget.msg.isGttHit ? 'Confirm GTT hit' : 'Confirm target hit'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.msg.isSlHit
                  ? 'SL hit on this price'
                  : (widget.msg.isGttHit
                      ? 'GTT hit on this price'
                      : 'Target hit on this price'),
              style: TextStyle(fontSize: 14, color: bodyColor),
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
                fillColor: fieldFill,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E222A) : Colors.white;
    final dotColor = isDark ? Colors.white60 : const Color(0xFF9E9E9E);

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
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
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
  const _InvalidTradeCrossPainter({this.isDark = false});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white54 : Colors.grey.shade500).withOpacity(
        0.65,
      )
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
  bool shouldRepaint(covariant _InvalidTradeCrossPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({this.isDark = false});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white24 : Colors.grey.shade400
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
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
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
    // Kept identical in both themes (matches screenshots — red badge sits on
    // the always-white trade card, so it doesn't need a dark variant).
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