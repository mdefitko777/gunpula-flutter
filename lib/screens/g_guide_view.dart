// 화면 G: 도감 — 컬렉션의 다른 보기. 모은 만큼 칸에 불이 켜진다.
//
// ┌──────── 디자인 가이드 대응표: G 도감 ──────────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ G-1  │ 채널 타일 격자                      │ '전체'일 때: 도감을 볼 IP 고르기         │ P06           │
// │ G-2  │ 범례 (컬러 · 하늘색 테두리 · 흑백)    │ 구매함 · 원함 · 미수집 읽는 법           │ P10 · P04     │
// │ G-3  │ 섹션별 작품 카드 + 진행 막대          │ 건담 작품 도감 (수집 n/전체)            │ P01 · P06     │
// │ G-4  │ 기체 칸 격자 (불 켜짐/꺼짐)           │ 작품 안의 기체                          │ P01 · P02     │
// │ G-5  │ 바텀 시트: 기체 → 대응 상품           │ 이 기체의 상품 → 상품 상세              │ P07           │
// │ G-6  │ 베이 칸 + n/3 · 부품 시트            │ 베이블레이드 X 도감 (부품 3개)          │ P01           │
// │ G-7  │ 세대 · 작품 카드 + 진행 막대          │ 포켓몬 세대 · Fate 작품 · AC 세대       │ P01           │
// │ G-8  │ LoadingView / ErrorView / EmptyView │ 불러오는 중 · 오류 · 정리 안 된 작품     │ P01 · P09     │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: 작품 카드 → 작품 도감(쌓기) → 기체 시트(덮기) → D 상품 상세(쌓기). 베이 → 부품 시트(덮기).
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';

import '../api.dart';
import '../channels.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'c_channel_screen.dart';
import 'd_kit_detail_screen.dart';

class GuideView extends StatelessWidget {
  const GuideView({
    super.key,
    required this.channel,
    required this.myChannels,
    required this.onPickChannel,
    required this.loaders,
  });

  final String channel;
  final List<String> myChannels;
  final ValueChanged<String> onPickChannel;
  final Loaders loaders;

  @override
  Widget build(BuildContext context) {
    if (channel == allChannelId) return _ChannelPicker(myChannels: myChannels, onPick: onPickChannel);
    return switch (channel) {
      'gundam' => _GundamGuide(loaders: loaders),
      'beyblade' => _BbxGuide(loaders: loaders),
      _ => _WorldGuide(channel: channel, loaders: loaders),
    };
  }
}

/// G-1 '전체'일 때: IP 고르기
class _ChannelPicker extends StatelessWidget {
  const _ChannelPicker({required this.myChannels, required this.onPick});
  final List<String> myChannels;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (myChannels.isEmpty) {
      return const EmptyView(
        icon: Icons.auto_awesome_mosaic_outlined,
        message: '내 채널이 비어 있어요',
        detail: '채널 관리에서 IP를 추가하면 도감을 볼 수 있어요',
      );
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, navClearance(context)),
      children: [
        const Text('어느 도감을 볼까요?', style: TextStyle(color: Gp.muted)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (final id in myChannels)
              GestureDetector(
                onTap: () => onPick(id), // STATE: 채널 선택 → 그 IP 도감
                child: Container(
                  decoration: Gp.raised(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleThumb(image: channelOf(id).image, label: channelOf(id).label, size: 46),
                      const SizedBox(height: 8),
                      Text(channelOf(id).label, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// G-2 범례
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget dot, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [dot, const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 12, color: Gp.muted))],
    );
    Widget box({Color? fill, Color border = Gp.line, double w = 1}) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: border, width: w),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(
        spacing: 14,
        children: [
          item(box(fill: const Color(0xFF8FB8DE)), '구매함 (컬러)'), // G-2 P10
          item(box(fill: const Color(0xFFDDE7F0), border: Gp.accent, w: 1.6), '원함'),
          item(box(fill: Gp.soft), '미수집 (흑백)'),
        ],
      ),
    );
  }
}

/// 진행 막대 + "n/전체"
class _Progress extends StatelessWidget {
  const _Progress({required this.owned, required this.total});
  final int owned;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : owned / total,
              minHeight: 4,
              backgroundColor: Gp.soft,
              color: Gp.accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$owned/$total', style: const TextStyle(fontSize: 11.5, color: Gp.muted)),
      ],
    );
  }
}

/// 작품 · 세대 카드 (이미지 + 이름 + 진행)
class _WorkCard extends StatelessWidget {
  const _WorkCard({
    required this.image,
    required this.name,
    required this.owned,
    required this.total,
    required this.onTap,
    this.subtitle = '',
    this.fit = BoxFit.contain,
  });

  final String image;
  final String name;
  final String subtitle;
  final int owned;
  final int total;
  final VoidCallback onTap;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Gp.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Gp.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(fit == BoxFit.contain ? 10 : 0),
                child: AppImage(image, fit: fit, placeholder: name),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: Gp.faint)),
                  const SizedBox(height: 6),
                  _Progress(owned: owned, total: total), // P01
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _cols(double w, double min) => (w / min).floor().clamp(2, 6);

/// G-3 건담 작품 도감
class _GundamGuide extends StatefulWidget {
  const _GundamGuide({required this.loaders});
  final Loaders loaders;

  @override
  State<_GundamGuide> createState() => _GundamGuideState();
}

class _GundamGuideState extends State<_GundamGuide> {
  late Future<List<GuideWork>> _future = widget.loaders.guideWorks(); // STATE: GET /guideWorks

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GuideWork>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingView(); // G-8
        if (snap.hasError) {
          return ErrorView(
            message: '${snap.error}',
            onRetry: () => setState(() => _future = widget.loaders.guideWorks()),
          );
        }
        final works = snap.data!;
        if (works.isEmpty) return const EmptyView(message: '도감 작품이 아직 없어요');
        final sections = <String, List<GuideWork>>{};
        for (final w in works) {
          (sections[w.section] ??= []).add(w);
        }
        return LayoutBuilder(
          builder: (context, box) => ListView(
            padding: EdgeInsets.only(bottom: navClearance(context)),
            children: [
              const _Legend(),
              for (final e in sections.entries) ...[
                SectionHeader(
                  e.key,
                  subtitle: '수집 ${e.value.fold(0, (s, w) => s + w.owned)}'
                      ' / ${e.value.fold(0, (s, w) => s + w.total)}',
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: _cols(box.maxWidth, 120),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                    children: [
                      for (final w in e.value)
                        _WorkCard( // G-3 P06
                          image: w.image,
                          name: w.name,
                          owned: w.owned,
                          total: w.total,
                          onTap: () => Navigator.of(context, rootNavigator: true).push(
                            CupertinoPageRoute<void>(
                              builder: (_) => WorkGuideScreen(work: w, loaders: widget.loaders),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// G-4 작품 하나의 기체 칸
class WorkGuideScreen extends StatefulWidget {
  const WorkGuideScreen({super.key, required this.work, required this.loaders});
  final GuideWork work;
  final Loaders loaders;

  @override
  State<WorkGuideScreen> createState() => _WorkGuideScreenState();
}

class _WorkGuideScreenState extends State<WorkGuideScreen> {
  late Future<List<GuideUnit>> _future = widget.loaders.guideUnits(widget.work.id);

  void _openUnit(GuideUnit u) {
    showModalBottomSheet<void>( // G-5 덮기
      context: context,
      isScrollControlled: true,
      builder: (_) => _UnitSheet(unit: u, loaders: widget.loaders),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.work;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            Text('수집 ${w.owned} / ${w.total}',
                style: const TextStyle(fontSize: 12, color: Gp.accent, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: FutureBuilder<List<GuideUnit>>(
        future: _future, // STATE: GET /guideUnits?workId= → 기체 칸
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) {
            return ErrorView(
              message: '${snap.error}',
              onRetry: () => setState(() => _future = widget.loaders.guideUnits(w.id)),
            );
          }
          final units = snap.data!;
          if (units.isEmpty) {
            return EmptyView( // G-8 P09
              icon: Icons.grid_view,
              message: '이 작품은 아직 기체 정리가 안 됐어요',
              detail: '정리되면 기체마다 칸이 생기고, 모은 만큼 불이 켜져요',
              action: OutlinedButton(
                onPressed: () => showToast(context, '정리 요청을 보냈어요'),
                child: const Text('정리 요청하기'),
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, box) => ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                const _Legend(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: _cols(box.maxWidth, 110),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.7,
                    children: [
                      for (final u in units)
                        _LitCell( // G-4 P01
                          image: u.image,
                          name: u.name,
                          status: u.status,
                          onTap: () => _openUnit(u),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 불 켜짐 칸: 구매함 = 컬러, 원함 = 컬러 + 하늘색 테두리, 미수집 = 흑백
class _LitCell extends StatelessWidget {
  const _LitCell({
    required this.image,
    required this.name,
    required this.status,
    required this.onTap,
    this.badge = '',
  });

  final String image;
  final String name;
  final CollectStatus status;
  final VoidCallback onTap;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final lit = status != CollectStatus.none;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Gp.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status == CollectStatus.wanted ? Gp.accent : Gp.line,
                  width: status == CollectStatus.wanted ? 1.8 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: AppImage(image, fit: BoxFit.contain, grayscale: !lit),
                  ),
                  if (badge.isNotEmpty)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xE6FFFFFF),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: Gp.line),
                        ),
                        child: Text(badge, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: lit ? Gp.ink : Gp.muted, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

/// G-5 기체 → 대응 상품
class _UnitSheet extends StatelessWidget {
  const _UnitSheet({required this.unit, required this.loaders});
  final GuideUnit unit;
  final Loaders loaders;

  @override
  Widget build(BuildContext context) {
    final status = switch (unit.status) {
      CollectStatus.owned => '구매함',
      CollectStatus.wanted => '원함',
      CollectStatus.none => '미수집',
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 64,
                  child: AppImage(unit.image, fit: BoxFit.contain, grayscale: unit.status == CollectStatus.none),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unit.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      Text('${unit.nameEn} · $status', style: const TextStyle(fontSize: 12.5, color: Gp.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SectionHeader('이 기체의 상품', padding: EdgeInsets.fromLTRB(0, 18, 0, 10)),
            FutureBuilder<List<Kit>>(
              future: loaders.kitsByIds(unit.kitIds), // STATE: GET /kits?id= → 대응 상품
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(height: 90, child: LoadingView());
                }
                if (snap.hasError) {
                  return const Text('상품을 불러오지 못했어요', style: TextStyle(color: Gp.muted));
                }
                final kits = snap.data!;
                if (kits.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('대응 상품이 아직 없어요 · 새로 나오면 홈에 먼저 알려 드려요', // P09
                        style: TextStyle(color: Gp.muted)),
                  );
                }
                return SizedBox(
                  height: 130 + 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kits.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => ProductTile(
                      image: kits[i].image,
                      title: kits[i].name,
                      imageWidth: 130,
                      onTap: () {
                        Navigator.pop(context);
                        openKitDetail(context, kits[i], loaders: loaders);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// G-6 베이블레이드 X 도감
class _BbxGuide extends StatefulWidget {
  const _BbxGuide({required this.loaders});
  final Loaders loaders;

  @override
  State<_BbxGuide> createState() => _BbxGuideState();
}

class _BbxGuideState extends State<_BbxGuide> {
  late Future<List<BbxTop>> _future = widget.loaders.bbxTops(); // STATE: GET /bbxTops

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BbxTop>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingView();
        if (snap.hasError) {
          return ErrorView(
            message: '${snap.error}',
            onRetry: () => setState(() => _future = widget.loaders.bbxTops()),
          );
        }
        final tops = snap.data!;
        if (tops.isEmpty) return const EmptyView(message: '베이 도감이 아직 없어요');
        final done = tops.where((t) => t.total > 0 && t.owned >= t.total).length;
        return LayoutBuilder(
          builder: (context, box) => ListView(
            padding: EdgeInsets.only(bottom: navClearance(context)),
            children: [
              const _Legend(),
              SectionHeader('베이', subtitle: '완성 $done / ${tops.length}',
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 10)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: _cols(box.maxWidth, 110),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.7,
                  children: [
                    for (final t in tops)
                      _LitCell( // G-6 P01
                        image: t.image,
                        name: t.name,
                        status: t.total > 0 && t.owned >= t.total ? CollectStatus.owned : CollectStatus.none,
                        badge: '${t.owned}/${t.total}',
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => _TopSheet(top: t),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopSheet extends StatelessWidget {
  const _TopSheet({required this.top});
  final BbxTop top;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(top.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            Text('부품 ${top.owned} / ${top.total} 보유',
                style: const TextStyle(fontSize: 12.5, color: Gp.accent, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            for (final p in top.parts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 52,
                      child: AppImage(p.image, fit: BoxFit.contain, grayscale: !p.have),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.typeLabel, style: const TextStyle(fontSize: 12, color: Gp.muted)),
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Text(
                      p.have ? '보유' : '미보유',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: p.have ? Gp.accent : Gp.faint,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// G-7 포켓몬 세대 · Fate 작품 · AC 세대
class _WorldGuide extends StatefulWidget {
  const _WorldGuide({required this.channel, required this.loaders});
  final String channel;
  final Loaders loaders;

  @override
  State<_WorldGuide> createState() => _WorldGuideState();
}

class _WorldGuideState extends State<_WorldGuide> {
  late Future<List<World>> _future = widget.loaders.worlds(widget.channel);

  @override
  void didUpdateWidget(_WorldGuide old) {
    super.didUpdateWidget(old);
    if (old.channel != widget.channel) _future = widget.loaders.worlds(widget.channel);
  }

  @override
  Widget build(BuildContext context) {
    final label = channelOf(widget.channel).label;
    return FutureBuilder<List<World>>(
      future: _future, // STATE: GET /worlds?franchiseId= → 카드
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingView();
        if (snap.hasError) {
          return ErrorView(
            message: '${snap.error}',
            onRetry: () => setState(() => _future = widget.loaders.worlds(widget.channel)),
          );
        }
        final worlds = snap.data!;
        if (worlds.isEmpty) {
          return EmptyView( // G-8 P09
            icon: Icons.auto_awesome_mosaic_outlined,
            message: '$label 도감은 아직 준비 중이에요',
            detail: '상품이 수록되면 도감 칸이 생겨요',
          );
        }
        final pokemon = widget.channel == 'pokemon';
        return LayoutBuilder(
          builder: (context, box) => ListView(
            padding: EdgeInsets.only(bottom: navClearance(context)),
            children: [
              SectionHeader(
                pokemon ? '세대' : (widget.channel == 'fate' ? '작품' : '게임 세대'),
                subtitle: '수집 ${worlds.fold(0, (s, w) => s + w.owned)}'
                    ' / ${worlds.fold(0, (s, w) => s + w.total)}',
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: _cols(box.maxWidth, 120),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                  children: [
                    for (final w in worlds)
                      _WorkCard( // G-7 P01
                        image: w.image,
                        name: w.label,
                        subtitle: w.subtitle,
                        owned: w.owned,
                        total: w.total,
                        fit: pokemon ? BoxFit.contain : BoxFit.cover,
                        onTap: () => showSoon(context, '${w.label} 도감'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
