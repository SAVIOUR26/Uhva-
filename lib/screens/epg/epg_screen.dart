import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../player/player_screen.dart';

const double _kPpm = 3.5; // pixels per minute
const double _kChanColW = 130.0; // fixed left column
const double _kRowH = 62.0; // each channel row height
const double _kHeaderH = 38.0; // time-strip height
const int _kWindowHours = 9; // total hours in the grid
const int _kMaxChannels = 30;

class EpgScreen extends StatefulWidget {
  const EpgScreen({super.key});

  @override
  State<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends State<EpgScreen> {
  final _horzCtrl = ScrollController();
  bool _loading = true;
  List<LiveChannel> _channels = [];
  final Map<int, List<EpgEntry>> _epgMap = {};
  bool _syncing = false;
  Timer? _clockTimer;

  late DateTime _windowStart;
  late DateTime _windowEnd;
  late double _totalWidth;

  @override
  void initState() {
    super.initState();
    _calcWindow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _scrollToNow();
    });
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _calcWindow() {
    final now = DateTime.now();
    _windowStart = DateTime(now.year, now.month, now.day, now.hour - 1);
    _windowEnd = _windowStart.add(Duration(hours: _kWindowHours));
    _totalWidth = _windowEnd.difference(_windowStart).inMinutes * _kPpm;
  }

  void _scrollToNow() {
    final minutesFromStart = DateTime.now().difference(_windowStart).inMinutes;
    final target = (minutesFromStart * _kPpm - 80).clamp(0.0, double.infinity);
    if (_horzCtrl.hasClients) _horzCtrl.jumpTo(target);
  }

  double _timeToX(DateTime t) =>
      t.difference(_windowStart).inMinutes * _kPpm;

  double get _nowX => _timeToX(DateTime.now());

  Future<void> _loadData() async {
    final provider = context.read<AppProvider>();
    var channels = provider.filteredChannels.take(_kMaxChannels).toList();
    if (channels.isEmpty) channels = provider.allChannels.take(_kMaxChannels).toList();

    setState(() {
      _channels = channels;
      _loading = false;
    });

    // Load EPG in parallel — only for channels that have an epgChannelId
    await Future.wait(
      channels
          .where((ch) => ch.epgChannelId.isNotEmpty)
          .map((ch) => provider
              .getEpg(ch.epgChannelId, limit: 24)
              .then((entries) {
                if (mounted) setState(() => _epgMap[ch.streamId] = entries);
              })),
    );
  }

  // Sync all horizontal scroll positions to the given offset.
  void _syncHorz(double offset) {
    if (_syncing) return;
    _syncing = true;
    for (final pos in List.from(_horzCtrl.positions)) {
      if ((pos.pixels - offset).abs() > 0.5) pos.jumpTo(offset);
    }
    _syncing = false;
  }

  @override
  void dispose() {
    _horzCtrl.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UhvaColors.background,
      appBar: AppBar(
        title: const Text('TV Guide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time_outlined),
            tooltip: 'Jump to Now',
            onPressed: _scrollToNow,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: UhvaColors.primary))
          : Column(
              children: [
                // ── Time header ──────────────────────────────────────────
                SizedBox(
                  height: _kHeaderH,
                  child: Row(
                    children: [
                      // Channel label cell
                      Container(
                        width: _kChanColW,
                        alignment: Alignment.center,
                        color: UhvaColors.surface,
                        child: const Text('Channel',
                            style: TextStyle(
                                fontSize: 10,
                                color: UhvaColors.onSurfaceMuted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8)),
                      ),
                      const VerticalDivider(width: 1),
                      // Scrollable time slots (shares _horzCtrl)
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n is ScrollUpdateNotification) {
                              _syncHorz(n.metrics.pixels);
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _horzCtrl,
                            child: _TimeStrip(
                              windowStart: _windowStart,
                              windowEnd: _windowEnd,
                              totalWidth: _totalWidth,
                              nowX: _nowX,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // ── Channel rows ─────────────────────────────────────────
                Expanded(
                  child: _channels.isEmpty
                      ? const Center(
                          child: Text('No channels to display',
                              style: TextStyle(color: UhvaColors.onSurfaceMuted)))
                      : ListView.separated(
                          itemCount: _channels.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: _kChanColW),
                          itemBuilder: (_, i) => _EpgRow(
                            channel: _channels[i],
                            epgEntries: _epgMap[_channels[i].streamId] ?? [],
                            totalWidth: _totalWidth,
                            windowStart: _windowStart,
                            windowEnd: _windowEnd,
                            nowX: _nowX,
                            horzCtrl: _horzCtrl,
                            syncHorz: _syncHorz,
                            onChannelTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      PlayerScreen(channel: _channels[i])),
                            ),
                            onProgramTap: (entry) =>
                                _showProgramSheet(_channels[i], entry),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showProgramSheet(LiveChannel channel, EpgEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: UhvaColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProgramSheet(channel: channel, entry: entry),
    );
  }
}

// ── Time Strip ─────────────────────────────────────────────────────────────

class _TimeStrip extends StatelessWidget {
  final DateTime windowStart;
  final DateTime windowEnd;
  final double totalWidth;
  final double nowX;

  const _TimeStrip({
    required this.windowStart,
    required this.windowEnd,
    required this.totalWidth,
    required this.nowX,
  });

  @override
  Widget build(BuildContext context) {
    // Generate hour labels
    final slots = <Widget>[];
    var t = DateTime(
        windowStart.year, windowStart.month, windowStart.day, windowStart.hour);
    while (t.isBefore(windowEnd)) {
      final x = t.difference(windowStart).inMinutes * _kPpm;
      slots.add(Positioned(
        left: x + 4,
        top: 0,
        bottom: 0,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${t.hour.toString().padLeft(2, '0')}:00',
            style: const TextStyle(
                fontSize: 11,
                color: UhvaColors.onSurfaceMuted,
                fontWeight: FontWeight.w500),
          ),
        ),
      ));
      t = t.add(const Duration(hours: 1));
    }

    return SizedBox(
      width: totalWidth,
      height: _kHeaderH,
      child: Stack(
        children: [
          // Hour tick lines
          ...List.generate(
            windowEnd.difference(windowStart).inHours + 1,
            (i) => Positioned(
              left: i * 60.0 * _kPpm,
              top: _kHeaderH * 0.4,
              bottom: 0,
              child: Container(
                  width: 1, color: UhvaColors.divider),
            ),
          ),
          // Hour labels
          ...slots,
          // NOW indicator line
          Positioned(
            left: nowX,
            top: 0,
            bottom: 0,
            child: Container(width: 2, color: UhvaColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── EPG Row ────────────────────────────────────────────────────────────────

class _EpgRow extends StatelessWidget {
  final LiveChannel channel;
  final List<EpgEntry> epgEntries;
  final double totalWidth;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double nowX;
  final ScrollController horzCtrl;
  final void Function(double) syncHorz;
  final VoidCallback onChannelTap;
  final void Function(EpgEntry) onProgramTap;

  const _EpgRow({
    required this.channel,
    required this.epgEntries,
    required this.totalWidth,
    required this.windowStart,
    required this.windowEnd,
    required this.nowX,
    required this.horzCtrl,
    required this.syncHorz,
    required this.onChannelTap,
    required this.onProgramTap,
  });

  double _timeToX(DateTime t) =>
      t.difference(windowStart).inMinutes * _kPpm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kRowH,
      child: Row(
        children: [
          // ── Fixed channel name ──────────────────────────────────────
          GestureDetector(
            onTap: onChannelTap,
            child: Container(
              width: _kChanColW,
              height: _kRowH,
              color: UhvaColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  channel.name,
                  style: const TextStyle(
                      fontSize: 11,
                      color: UhvaColors.onBackground,
                      fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // ── Scrollable EPG cells ────────────────────────────────────
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollUpdateNotification && n.depth == 0) {
                  syncHorz(n.metrics.pixels);
                }
                return false;
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: horzCtrl,
                child: SizedBox(
                  width: totalWidth,
                  height: _kRowH,
                  child: Stack(
                    children: [
                      // Programs
                      ..._buildProgramCells(),
                      // Now line
                      if (nowX > 0 && nowX < totalWidth)
                        Positioned(
                          left: nowX,
                          top: 0,
                          bottom: 0,
                          child:
                              Container(width: 2, color: UhvaColors.primary.withValues(alpha: 0.7)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProgramCells() {
    if (epgEntries.isEmpty) {
      return [
        Positioned.fill(
          child: Container(
            color: UhvaColors.card,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: const Text('No guide data',
                style: TextStyle(
                    color: UhvaColors.onSurfaceHint, fontSize: 11)),
          ),
        ),
      ];
    }

    final cells = <Widget>[];
    for (final entry in epgEntries) {
      // Skip if ends before window
      if (entry.end.isBefore(windowStart)) continue;
      // Skip if starts after window
      if (entry.start.isAfter(windowEnd)) break;

      final clampedStart =
          entry.start.isBefore(windowStart) ? windowStart : entry.start;
      final clampedEnd =
          entry.end.isAfter(windowEnd) ? windowEnd : entry.end;

      final x = _timeToX(clampedStart);
      final w = (_timeToX(clampedEnd) - x).clamp(1.0, totalWidth - x);

      cells.add(Positioned(
        left: x + 1,
        top: 4,
        bottom: 4,
        width: w - 2,
        child: _ProgramCell(
          entry: entry,
          onTap: () => onProgramTap(entry),
        ),
      ));
    }
    return cells;
  }
}

// ── Program Cell ───────────────────────────────────────────────────────────

class _ProgramCell extends StatelessWidget {
  final EpgEntry entry;
  final VoidCallback onTap;

  const _ProgramCell({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLive = entry.isLive;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isLive ? UhvaColors.epgNow : UhvaColors.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isLive
                ? UhvaColors.primary
                : UhvaColors.divider,
            width: isLive ? 1.5 : 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                if (isLive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: UhvaColors.liveRed,
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isLive ? FontWeight.w600 : FontWeight.w400,
                      color: isLive
                          ? UhvaColors.onBackground
                          : UhvaColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              entry.timeRange,
              style: const TextStyle(
                  fontSize: 9,
                  color: UhvaColors.onSurfaceMuted),
            ),
            if (isLive)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: entry.progress,
                    backgroundColor: UhvaColors.surface,
                    valueColor:
                        const AlwaysStoppedAnimation(UhvaColors.primary),
                    minHeight: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Program Detail Sheet ───────────────────────────────────────────────────

class _ProgramSheet extends StatelessWidget {
  final LiveChannel channel;
  final EpgEntry entry;

  const _ProgramSheet({required this.channel, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: UhvaColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (entry.isLive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: UhvaColors.liveRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              Expanded(
                child: Text(
                  entry.title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: UhvaColors.onBackground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${channel.name}  ·  ${entry.timeRange}',
            style: const TextStyle(
                fontSize: 12, color: UhvaColors.onSurfaceMuted),
          ),
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.description,
              style: const TextStyle(
                  fontSize: 13, color: UhvaColors.onSurface, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Watch Now'),
              style: FilledButton.styleFrom(
                backgroundColor: UhvaColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PlayerScreen(channel: channel)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
