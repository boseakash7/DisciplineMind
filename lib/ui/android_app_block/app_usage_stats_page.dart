import 'dart:io';

import 'package:discipline_mind/common/app_colors.dart';
import 'package:flutter/material.dart';

import '../../services/native_app_block_service.dart';

class AppUsageStatsPage extends StatefulWidget {
  const AppUsageStatsPage({super.key});

  @override
  State<AppUsageStatsPage> createState() => _AppUsageStatsPageState();
}

class _AppUsageStatsPageState extends State<AppUsageStatsPage> {
  final _blockService = NativeAppBlockService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _stats = [];

  static const _appMeta = {
    'com.zerodha.kite3': {
      'name': 'Zerodha Kite',
      'color': Color(0xFF387ED1),
    },
    'in.upstox.app': {
      'name': 'Upstox',
      'color': Color(0xFF7B2FBE),
    },
    'com.nextbillion.groww': {
      'name': 'Groww',
      'color': Color(0xFF00B386),
    },
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Platform.isAndroid) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final data = await _blockService.getBlockedAppUsageStats();
    if (mounted) setState(() {
      _stats = data;
      _isLoading = false;
    });
  }

  String _formatDuration(int ms) {
    if (ms <= 0) return '0 min';
    final totalSeconds = ms ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes} min';
    return '${totalSeconds}s';
  }

  int _totalOpens() => _stats.fold(0, (s, e) =>
      s + ((e['openCount'] is num) ? (e['openCount'] as num).toInt() : 0));

  int _totalBlocked() => _stats.fold(0, (s, e) =>
      s + ((e['openedWhenBlockedCount'] is num) ? (e['openedWhenBlockedCount'] as num).toInt() : 0));

  int _totalUsageMs() => _stats.fold(0, (s, e) =>
      s + ((e['totalUsageTimeMs'] is num) ? (e['totalUsageTimeMs'] as num).toInt() : 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          if (_isLoading)
            SliverFillRemaining(child: _buildShimmer())
          else if (!Platform.isAndroid)
            SliverFillRemaining(child: _buildNotSupported())
          else ...[
            SliverToBoxAdapter(child: _buildSummaryStrip()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildAppCard(_stats[index]),
                  childCount: _stats.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textBlack,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textGrey),
          onPressed: () {
            setState(() => _isLoading = true);
            _load();
          },
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.85),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'App Usage Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track how you interact with blocked apps',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStrip() {
    final opens = _totalOpens();
    final blocked = _totalBlocked();
    final usageMs = _totalUsageMs();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryTile(
            icon: Icons.open_in_new_rounded,
            label: 'Total Opens',
            value: '$opens',
            color: AppColors.primary,
          ),
          _summaryDivider(),
          _summaryTile(
            icon: Icons.block_rounded,
            label: 'Blocked',
            value: '$blocked',
            color: AppColors.actionRed,
          ),
          _summaryDivider(),
          _summaryTile(
            icon: Icons.schedule_rounded,
            label: 'Total Time',
            value: _formatDuration(usageMs),
            color: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.black12,
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(Map<String, dynamic> stat) {
    final pkg = stat['packageName']?.toString() ?? '';
    final meta = _appMeta[pkg];
    final name = meta?['name'] as String? ?? pkg;
    final color = meta?['color'] as Color? ?? Colors.blueGrey;

    final opens = (stat['openCount'] is num) ? (stat['openCount'] as num).toInt() : 0;
    final blocked = (stat['openedWhenBlockedCount'] is num) ? (stat['openedWhenBlockedCount'] as num).toInt() : 0;
    final usageMs = (stat['usageTimeMs'] is num) ? (stat['usageTimeMs'] as num).toInt() : 0;
    final totalMs = (stat['totalUsageTimeMs'] is num) ? (stat['totalUsageTimeMs'] as num).toInt() : 0;

    final blockRate = opens > 0 ? blocked / opens : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name[0],
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pkg,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(blockRate * 100).toStringAsFixed(0)}% blocked',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _statTile(
                    icon: Icons.open_in_new_rounded,
                    label: 'Total Opens',
                    value: '$opens',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statTile(
                    icon: Icons.block_rounded,
                    label: 'Blocked Opens',
                    value: '$blocked',
                    color: AppColors.actionRed,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _statTile(
                    icon: Icons.schedule_rounded,
                    label: 'Total Usage',
                    value: _formatDuration(totalMs),
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statTile(
                    icon: Icons.warning_amber_rounded,
                    label: 'Blocked Usage',
                    value: _formatDuration(usageMs),
                    color: AppColors.actionRed,
                  ),
                ),
              ],
            ),
          ),

          // Block rate progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Block Rate',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      '$blocked / $opens opens blocked',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: blockRate.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      blockRate > 0.5 ? AppColors.actionRed : AppColors.primary,
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

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final tileBg = color.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    final base = Colors.grey.shade300;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 260,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildNotSupported() {
    return const Center(
      child: Text(
        'Available on Android only',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
