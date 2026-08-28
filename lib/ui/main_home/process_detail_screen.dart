import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/controller/trading_process_controller.dart';
import 'package:discipline_mind/model/trading_process_model.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProcessDetailScreen extends StatefulWidget {
  const ProcessDetailScreen({super.key});

  @override
  State<ProcessDetailScreen> createState() => _ProcessDetailScreenState();
}

class _ProcessDetailScreenState extends State<ProcessDetailScreen> {
  final TradingProcessController _controller =
      Get.put(TradingProcessController());

  @override
  void initState() {
    super.initState();
    _controller.fetchProcess();
  }

  String _formatCurrency(String raw) {
    if (raw.trim().isEmpty) return '₹ 0.00';
    final clean = raw.trim().replaceAll(',', '');
    final numVal = double.tryParse(clean);
    if (numVal == null) return '₹ $raw';
    final parts = numVal.toStringAsFixed(numVal % 1 == 0 ? 0 : 2).split('.');
    final intPart = parts[0];
    String result = '';
    final len = intPart.length;
    if (len <= 3) {
      result = intPart;
    } else {
      final last3 = intPart.substring(len - 3);
      final rest = intPart.substring(0, len - 3);
      final buffer = StringBuffer();
      for (int i = 0; i < rest.length; i++) {
        if (i > 0 && (rest.length - i) % 2 == 0) {
          buffer.write(',');
        }
        buffer.write(rest[i]);
      }
      result = '${buffer.toString()},$last3';
    }
    if (parts.length > 1) {
      result = '$result.${parts[1]}';
    }
    return '₹ $result';
  }

  static String _formatBrokerName(String raw) {
    if (raw.trim().isEmpty) return 'Upstox';
    final lower = raw.trim().toLowerCase();
    if (lower == 'upstox' || lower == 'upsocks') return 'Upstox';
    if (lower == 'zerodha' || lower == 'kite' || lower == 'zerodha_kite') {
      return 'Zerodha Kite';
    }
    if (lower == 'groww') return 'Groww';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _formatTime(String raw) {
    if (raw.trim().isEmpty) return '--';
    final trimmed = raw.trim();
    try {
      if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final isPm = hour >= 12;
        final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final minStr = min.toString().padLeft(2, '0');
        final amPm = isPm ? 'PM' : 'AM';
        return '$h12:$minStr $amPm';
      }
    } catch (_) {}
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF10122D);
    final secondaryTextColor = isDark ? Colors.white60 : const Color(0xFF70717F);
    final cardBg = isDark ? const Color(0xFF1E222A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C3240) : const Color(0xFFE2E0E9);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121418) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: BackButton(color: primaryTextColor),
        title: Text(
          'Trading Process',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => _controller.fetchProcess(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final process = _controller.currentProcess.value;

        if (process == null) {
          return RefreshIndicator(
            onRefresh: () => _controller.fetchProcess(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 60),
                Icon(
                  Icons.alt_route_rounded,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _controller.errorMessage.value.isNotEmpty
                        ? _controller.errorMessage.value
                        : 'No trading process configured yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => _controller.fetchProcess(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Try Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _controller.fetchProcess(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Process #${process.id}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF208052).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF208052),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      process.status.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF208052),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            process.tradingSegment.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: secondaryTextColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        process.instrument,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Market Entry at ${_formatTime(process.marketEntryTime)} • Broker: ${process.brokingApp.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Edit Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () => _openEditProcessSheet(context, process),
                    icon: const Icon(Icons.edit_note_rounded, size: 22),
                    label: const Text(
                      'EDIT PROCESS PARAMETERS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFF2B4BF2), width: 1.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Parameters Grid
                Text(
                  'Risk & Capital Parameters',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),

                _buildParamTile(
                  title: 'Trading Capital',
                  value: _formatCurrency(process.tradingCapital),
                  icon: Icons.account_balance_wallet_outlined,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildParamTile(
                        title: 'Max Risk %',
                        value: '${process.maxRiskPercent}%',
                        icon: Icons.percent_rounded,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildParamTile(
                        title: 'Max Risk Amount',
                        value: _formatCurrency(process.maxRiskAmount),
                        icon: Icons.security_rounded,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        primaryTextColor: const Color(0xFFCC3B4D),
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildParamTile(
                        title: 'Trades / Day',
                        value: '${process.tradesPerDay} Trades',
                        icon: Icons.repeat_rounded,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildParamTile(
                        title: 'Entry Time',
                        value: _formatTime(process.marketEntryTime),
                        icon: Icons.access_time_rounded,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildParamTile(
                        title: 'Trading Segment',
                        value: process.tradingSegment.toUpperCase(),
                        icon: Icons.candlestick_chart_rounded,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildParamTile(
                        title: 'Broking App',
                        value: _formatBrokerName(process.brokingApp),
                        icon: Icons.storefront_rounded,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        primaryTextColor: const Color(0xFF2B4BF2),
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Security & Permissions
                Text(
                  'Mind Control Guard Protections',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),

                _buildProtectionTile(
                  title: 'System Overlay Protection',
                  subtitle: 'Prevents emotional overtrading & impulsive trades',
                  enabled: process.permissionOverlayEnabled == '1',
                  cardBg: cardBg,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                const SizedBox(height: 10),

                _buildProtectionTile(
                  title: 'Usage Stats Guard',
                  subtitle: 'Monitors disciplined adherence during market hours',
                  enabled: process.permissionUsageStatsEnabled == '1',
                  cardBg: cardBg,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildParamTile({
    required String title,
    required String value,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionTile({
    required String title,
    required String subtitle,
    required bool enabled,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            enabled
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            color: enabled ? const Color(0xFF208052) : Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditProcessSheet(
    BuildContext context,
    TradingProcessData process,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProcessModal(
        process: process,
        controller: _controller,
      ),
    );
  }
}

class _EditProcessModal extends StatefulWidget {
  final TradingProcessData process;
  final TradingProcessController controller;

  const _EditProcessModal({
    required this.process,
    required this.controller,
  });

  @override
  State<_EditProcessModal> createState() => _EditProcessModalState();
}

class _EditProcessModalState extends State<_EditProcessModal> {
  late final TextEditingController _capitalController;
  late String _segment;
  late String _instrument;
  late String _tradesPerDay;
  late String _entryTime;
  late String _brokingApp;

  final List<String> _segments = ['Options', 'Futures'];
  final List<String> _instruments = ['Nifty 50', 'BankNifty', 'Sensex'];
  final List<String> _tradesOptions = ['1', '2'];
  final List<String> _brokerOptions = ['Upstox', 'Zerodha Kite', 'Groww'];

  @override
  void initState() {
    super.initState();
    final p = widget.process;
    final capClean = p.tradingCapital.replaceAll('.00', '').replaceAll(',', '');
    _capitalController = TextEditingController(text: capClean);

    // Segment matching
    final pSeg = p.tradingSegment.toLowerCase();
    _segment = pSeg.contains('option') ? 'Options' : 'Futures';

    // Instrument matching
    final pInst = p.instrument.trim();
    if (pInst.toLowerCase().contains('bank')) {
      _instrument = 'BankNifty';
    } else if (pInst.toLowerCase().contains('sensex')) {
      _instrument = 'Sensex';
    } else {
      _instrument = 'Nifty 50';
    }

    // Trades per day: 1 or 2
    _tradesPerDay = (p.tradesPerDay == '1') ? '1' : '2';

    // Entry time
    _entryTime = p.marketEntryTime.isNotEmpty ? p.marketEntryTime : '09:15:00';

    // Broking App
    final pBroker = p.brokingApp.toLowerCase();
    if (pBroker.contains('zerodha') || pBroker.contains('kite')) {
      _brokingApp = 'Zerodha Kite';
    } else if (pBroker.contains('groww')) {
      _brokingApp = 'Groww';
    } else {
      _brokingApp = 'Upstox';
    }
  }

  @override
  void dispose() {
    _capitalController.dispose();
    super.dispose();
  }

  int get _tradingCapital =>
      int.tryParse(_capitalController.text.trim().replaceAll(',', '')) ?? 0;

  int get _maxRiskAmount => (_tradingCapital * 0.02).round();

  String _formatTimeDisplay(String raw) {
    try {
      if (raw.contains(':')) {
        final parts = raw.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final isPm = h >= 12;
        final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        final mStr = m.toString().padLeft(2, '0');
        return '$h12:$mStr ${isPm ? 'PM' : 'AM'}';
      }
    } catch (_) {}
    return raw;
  }

  Future<void> _pickEntryTime() async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 15);
    try {
      if (_entryTime.contains(':')) {
        final parts = _entryTime.split(':');
        initial = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minStr = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _entryTime = '$hourStr:$minStr:00';
      });
    }
  }

  Future<void> _submit() async {
    final cap = _tradingCapital;
    if (cap < 1000) {
      AppToast.showToast('Minimum capital is ₹1,000');
      return;
    }

    String apiBroker = 'upstox';
    if (_brokingApp == 'Zerodha Kite') {
      apiBroker = 'zerodha';
    } else if (_brokingApp == 'Groww') {
      apiBroker = 'groww';
    }

    final success = await widget.controller.editProcess(
      processId: widget.process.id,
      tradingSegment: _segment.toLowerCase(),
      instrument: _instrument,
      tradingCapital: cap.toString(),
      tradesPerDay: _tradesPerDay,
      maxRiskPercent: '2',
      marketEntryTime: _entryTime,
      brokingApp: apiBroker,
      permissionOverlayEnabled: widget.process.permissionOverlayEnabled,
      permissionUsageStatsEnabled: widget.process.permissionUsageStatsEnabled,
      termsAccepted: '1',
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E222A) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF10122D);
    final secondaryTextColor = isDark ? Colors.white60 : const Color(0xFF70717F);
    final fieldBg = isDark ? const Color(0xFF14171D) : const Color(0xFFF7F8FA);
    final borderColor = isDark ? const Color(0xFF2C3240) : const Color(0xFFE2E0E9);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Trading Process',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. Trading Segment (Options / Futures)
              _buildLabel('Trading Segment', secondaryTextColor),
              const SizedBox(height: 8),
              Row(
                children: _segments.map((seg) {
                  final selected = _segment == seg;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: seg == _segments.first ? 8 : 0,
                        left: seg == _segments.last ? 8 : 0,
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _segment = seg),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : fieldBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : borderColor,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            seg,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 2. Select Instrument (Nifty 50, BankNifty, Sensex)
              _buildLabel('Select Instrument', secondaryTextColor),
              const SizedBox(height: 8),
              Row(
                children: _instruments.map((inst) {
                  final selected = _instrument == inst;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _instrument = inst),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : fieldBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : borderColor,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            inst,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 3. Trading Capital (₹)
              _buildLabel('Trading Capital (₹)', secondaryTextColor),
              const SizedBox(height: 8),
              TextField(
                controller: _capitalController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. 500000',
                  filled: true,
                  fillColor: fieldBg,
                  prefixIcon: const Icon(
                    Icons.currency_rupee,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Max Risk Display (Fixed 2% as in Create Process)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF28233D)
                      : const Color(0xFFF7F4FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3F3760)
                        : const Color(0xFFE2DCF7),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Max Risk per Trade (2%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹ $_maxRiskAmount',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Trades Per Day (1 or 2)
              _buildLabel('Trades Per Day (Max 2)', secondaryTextColor),
              const SizedBox(height: 8),
              Row(
                children: _tradesOptions.map((t) {
                  final selected = _tradesPerDay == t;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: t == '1' ? 8 : 0,
                        left: t == '2' ? 8 : 0,
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _tradesPerDay = t),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : fieldBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : borderColor,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            '$t Trade${t == '1' ? '' : 's'} / Day',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 5. Broking App (Upstox, Zerodha Kite, Groww)
              _buildLabel('Broking App', secondaryTextColor),
              const SizedBox(height: 8),
              Row(
                children: _brokerOptions.map((b) {
                  final selected = _brokingApp == b;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _brokingApp = b),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : fieldBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : borderColor,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            b,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 6. Market Entry Time (Default 09:15 AM)
              _buildLabel('Market Entry Time', secondaryTextColor),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickEntryTime,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTimeDisplay(_entryTime),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              Obx(() {
                final updating = widget.controller.isUpdating.value;
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: updating ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: updating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SAVE & UPDATE PROCESS',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      ),
    );
  }
}
