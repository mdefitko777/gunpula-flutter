// 화면 A: 홈 — 매거진형 (큰 사진 한 장 + 태그 달린 2열 격자)
//
// ┌──────── 디자인 가이드 대응표: A 홈 ────────────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ A-1  │ ChannelBar                         │ 내 채널 바 (C-1 공용)                  │ P04 · P06     │
// │ A-2  │ 검색 알약 (탭하면 검색 탭으로)      │ 이름·번호로 찾기                       │ P07           │
// │ A-3  │ PageView + 점 표시                 │ 신상품 큰 사진 (최근 3일 신규)          │ P08 · P01     │
// │ A-4  │ 사진 위 알약 "NEW · 3일 8건"        │ 신규 건수                              │ P01           │
// │ A-5  │ GridView 2열(창 너비 따라 2~5열)    │ 소식 격자 (10월 발매·예고·NEW·최근 본) │ P08 · 적응형  │
// │ A-6  │ 사진 왼쪽 위 태그                   │ 소식 종류 표시                         │ P06 · P04     │
// │ A-7  │ LoadingView / ErrorView / EmptyView │ 불러오는 중 · 오류 · 빈 채널           │ P01 · P09     │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: A-2 → 검색 탭(옆으로). 카드 → 상품 상세(쌓기, 다음 단계).
// 현행 앱 문제: 홈 = 버전 번호·총 개수·IP 입구 카드 → v2 홈 = "내 채널의 새 소식"만.
import 'package:flutter/material.dart';

import '../api.dart';
import '../channels.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'c_channel_screen.dart';

/// 가짜 "최근 본 상품" 기록 — 영구 저장 금지라 상수로 둔다.
const recentViewedIds = ['gu03', 'be43', 'po21', 'fa30', 'ar35'];

/// 이번 달 (발매 태그 글자)
const currentMonthLabel = '10월 발매';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.myChannels,
    required this.onMyChannelsChanged,
    required this.onOpenSearch,
    this.leading,
    this.loaders = const Loaders(),
  });

  final List<String> myChannels;
  final ValueChanged<List<String>> onMyChannelsChanged;
  final VoidCallback onOpenSearch;
  final Widget? leading;
  final Loaders loaders;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// 격자 한 칸
class _Tile {
  const _Tile({required this.tag, required this.image, required this.title, required this.sub});
  final String tag;
  final String image;
  final String title;
  final String sub;
}

class _HomeData {
  const _HomeData(this.kits, this.announcements);
  final List<Kit> kits;
  final List<Announcement> announcements;
}

class _HomeScreenState extends State<HomeScreen> {
  String _channel = allChannelId;
  late Future<_HomeData> _future;
  List<String> _loadedFor = const [];

  /// '전체'면 내 채널 전부, 아니면 그 채널 하나
  List<String> get _ids => _channel == allChannelId ? widget.myChannels : [_channel];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _loadedFor = [..._ids];
    // STATE: 선택 채널 → GET /kits · /announcements → 큰 사진 + 격자
    _future = Future.wait([
      widget.loaders.kits(_loadedFor),
      widget.loaders.announcements(_loadedFor),
    ]).then((r) => _HomeData(r[0] as List<Kit>, r[1] as List<Announcement>));
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    if (!widget.myChannels.contains(_channel)) _channel = allChannelId;
    if (_ids.join(',') != _loadedFor.join(',')) setState(_load);
  }

  void _select(String id) => setState(() {
    _channel = id;
    _load();
  });

  void _soon() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('상품 상세 화면은 다음 단계에서 만들어요')),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.leading != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Align(alignment: Alignment.centerLeft, child: widget.leading),
          ),
        ChannelBar( // A-1 P04
          myChannels: widget.myChannels,
          selected: _channel,
          onSelect: _select,
          onMyChannelsChanged: widget.onMyChannelsChanged,
        ),
        Expanded(
          child: FutureBuilder<_HomeData>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const LoadingView(); // A-7 P01
              }
              if (snap.hasError) {
                return ErrorView( // A-7 P09
                  message: '${snap.error}',
                  onRetry: () => setState(_load),
                );
              }
              return _body(snap.data!);
            },
          ),
        ),
      ],
    );
  }

  Widget _body(_HomeData data) {
    final search = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: _SearchPill(onTap: widget.onOpenSearch), // A-2 P07
    );
    if (data.kits.isEmpty && data.announcements.isEmpty) {
      final noData = _ids.isNotEmpty && _ids.every((id) => !channelOf(id).hasData);
      return ListView(
        children: [
          search,
          EmptyView( // A-7 P09
            icon: Icons.auto_awesome_outlined,
            message: _ids.isEmpty
                ? '내 채널이 비어 있어요'
                : noData
                ? '${channelOf(_ids.first).label}은(는) 아직 수록된 상품이 없어요'
                : '새 소식이 없어요',
            detail: _ids.isEmpty ? '채널 관리에서 관심 IP를 추가하세요' : '상품이 들어오면 여기에 먼저 보여요',
            action: _channel == allChannelId
                ? null
                : OutlinedButton(onPressed: () => _select(allChannelId), child: const Text('전체 보기')),
          ),
        ],
      );
    }

    final recent = data.kits.where((k) => k.recent).toList();
    final hero = recent.take(5).toList();
    final tiles = _mix(data, recent.skip(5).toList());
    final bottomPad = MediaQuery.paddingOf(context).bottom + 100; // 떠 있는 탭 바 높이만큼

    return LayoutBuilder(
      builder: (context, box) {
        final cols = (box.maxWidth / 190).floor().clamp(2, 5); // A-5 적응형
        final heroHeight = (box.maxWidth * 0.78).clamp(260.0, 420.0);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: search),
            if (hero.isNotEmpty)
              SliverToBoxAdapter(
                child: _HeroCarousel(
                  kits: hero,
                  newCount: recent.length,
                  height: heroHeight,
                  onTap: (_) => _soon(),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, bottomPad),
              sliver: SliverGrid.builder(
                itemCount: tiles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.66,
                ),
                itemBuilder: (context, i) => _TileCard(tile: tiles[i], onTap: _soon),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 10월 발매 · 예고 · NEW · 최근 본을 번갈아 섞는다 (종류별로 따로 쌓지 않음)
  List<_Tile> _mix(_HomeData data, List<Kit> moreNew) {
    final byId = {for (final k in data.kits) k.id: k};
    String sub(Kit k) => '${k.date} · ${yen(k.priceJpy)}';
    final groups = <List<_Tile>>[
      [
        for (final k in data.kits.where((k) => k.month))
          _Tile(tag: currentMonthLabel, image: k.image, title: k.name, sub: sub(k)),
      ],
      [
        for (final a in data.announcements)
          _Tile(tag: '예고', image: a.image, title: a.title, sub: '${a.status} · ${a.date}'),
      ],
      [for (final k in moreNew) _Tile(tag: 'NEW', image: k.image, title: k.name, sub: sub(k))],
      [
        for (final id in recentViewedIds)
          if (byId[id] case final k?) _Tile(tag: '최근 본', image: k.image, title: k.name, sub: sub(k)),
      ],
    ];
    final out = <_Tile>[];
    for (var i = 0; groups.any((g) => i < g.length); i++) {
      for (final g in groups) {
        if (i < g.length) out.add(g[i]);
      }
    }
    return out;
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '검색 열기',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: Gp.raised(radius: 23),
          child: const Row(
            children: [
              Icon(Icons.search, size: 20, color: Gp.muted),
              SizedBox(width: 10),
              Expanded(
                child: Text('이름 · 번호 · 작품으로 찾기', style: TextStyle(color: Gp.faint, fontSize: 14)),
              ),
              Icon(Icons.center_focus_strong_outlined, size: 20, color: Gp.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// A-3 신상품 큰 사진 — 옆으로 넘김
class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({
    required this.kits,
    required this.newCount,
    required this.height,
    required this.onTap,
  });

  final List<Kit> kits;
  final int newCount;
  final double height;
  final ValueChanged<Kit> onTap;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.kits.length,
            onPageChanged: (i) => setState(() => _page = i), // STATE: 넘긴 쪽 → 아래 점 표시
            itemBuilder: (context, i) {
              final k = widget.kits[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: GestureDetector(
                  onTap: () => widget.onTap(k),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: Gp.panel, child: AppImage(k.image, placeholder: k.line)),
                        // 아래쪽을 흰색으로 흐리게 → 검은 글자가 읽히게
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.55, 1],
                              colors: [Color(0x00FFFFFF), Color(0xF2FFFFFF)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          top: 14,
                          child: _Tag('NEW · 3일 ${widget.newCount}건'), // A-4 P01
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                k.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.25),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${channelOf(k.franchiseId).label} · ${k.date} · ${yen(k.priceJpy)}',
                                style: const TextStyle(color: Gp.muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.kits.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == _page ? 16 : 5,
                height: 4,
                decoration: BoxDecoration(
                  color: i == _page ? Gp.ink : Gp.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 사진 위 흰 반투명 알약 태그
class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xD9FFFFFF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Gp.line),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }
}

/// A-5 격자 한 칸
class _TileCard extends StatelessWidget {
  const _TileCard({required this.tile, required this.onTap});
  final _Tile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: Gp.panel, child: AppImage(tile.image)),
                  Positioned(left: 8, top: 8, child: _Tag(tile.tag)), // A-6 P06
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tile.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3),
          ),
          const SizedBox(height: 3),
          Text(
            tile.sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Gp.muted),
          ),
        ],
      ),
    );
  }
}
