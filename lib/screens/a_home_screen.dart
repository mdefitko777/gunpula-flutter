// 화면 A: 홈 — 큰 배너(공식 예고) + 종류별 가로 스크롤 줄
//
// ┌──────── 디자인 가이드 대응표: A 홈 ────────────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ A-1  │ ChannelBar                         │ 내 채널 바 (C-1 공용)                  │ P04 · P06     │
// │ A-2  │ 검색 알약 (탭하면 검색 탭으로)      │ 이름·번호로 찾기                       │ P07           │
// │ A-3  │ PageView(화면 끝까지) + 점 표시     │ 공식 예고 배너 (완성된 홍보 이미지)     │ P08 · P02     │
// │ A-4  │ 배너 아래 상태 · 제목               │ 예고 상태(공식 발표·상품화 확정·예약)   │ P01           │
// │ A-5  │ 색 막대 + 제목 줄 + ›               │ 줄 이름 · 전체 보기 (최근 추가는 기간)  │ P06 · P07     │
// │ A-6  │ 가로 ListView (사진 + 이름 한 줄)   │ 최근 추가 · 10월 발매 · 공식 예고 · 최근 본 │ P08        │
// │ A-8  │ 흰 띠(섹션마다) + 회백색 틈          │ 줄과 줄 사이 층 구분                   │ P08 · P04     │
// │ A-9  │ 사진 왼쪽 위 + 자리                 │ 원함 담기 (컬렉션 연결 예정 자리)       │ P07           │
// │ A-7  │ LoadingView / ErrorView / EmptyView │ 불러오는 중 · 오류 · 빈 채널           │ P01 · P09     │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: A-2 → 검색 탭(옆으로). 카드 → 상품 상세(쌓기, 다음 단계).
// 줄 안에는 날짜·가격을 쓰지 않는다 — 궁금하면 눌러서 상세에서 본다 (P08).
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

/// 이번 달 발매 줄 제목
const currentMonthTitle = '10월 발매';

/// "최근 3일" 기간 (프로토타입의 오늘 = 2026-10-25)
const recentRangeLabel = '10.23 – 10.25';

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

class _HomeData {
  const _HomeData(this.kits, this.announcements);
  final List<Kit> kits;
  final List<Announcement> announcements;
}

/// 가로 줄 한 칸 (사진 + 이름). [canAdd] = 상품이라 원함에 담을 수 있음
class _Item {
  const _Item(this.image, this.title, {this.canAdd = true});
  final String image;
  final String title;
  final bool canAdd;
}

/// 가로 줄 하나
class _Row {
  const _Row(this.title, this.items, {this.subtitle = '', this.wide = false});
  final String title;
  final List<_Item> items;
  final String subtitle;
  final bool wide;
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
    // STATE: 선택 채널 → GET /kits · /announcements → 배너 + 가로 줄
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

  void _soon([String what = '상품 상세']) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$what 화면은 다음 단계에서 만들어요')),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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

    final byId = {for (final k in data.kits) k.id: k};
    _Item kitItem(Kit k) => _Item(k.image, k.name);
    final recent = [for (final k in data.kits.where((k) => k.recent)) kitItem(k)];
    final rows = [
      _Row('최근 추가', recent, subtitle: recentRangeLabel),
      _Row(currentMonthTitle, [for (final k in data.kits.where((k) => k.month)) kitItem(k)]),
      _Row('공식 예고', [
        for (final a in data.announcements) _Item(a.image, a.title, canAdd: false),
      ], wide: true),
      _Row('최근 본', [for (final id in recentViewedIds) if (byId[id] case final k?) kitItem(k)]),
    ];
    final heroes = data.announcements.where((a) => a.hero).toList();

    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 100),
      children: [
        search,
        if (heroes.isNotEmpty)
          ColoredBox(
            color: Gp.panel,
            child: _HeroBanner(items: heroes, onTap: () => _soon('공식 예고 상세')), // A-3
          ),
        for (final row in rows)
          if (row.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10), // A-8 회백색 틈 = 층 구분
              child: ColoredBox(
                color: Gp.panel,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RowHeader( // A-5 P06
                        title: row.title,
                        subtitle: row.subtitle,
                        onMore: () => _soon('${row.title} 전체 목록'),
                      ),
                      _HorizontalRow( // A-6 P08
                        items: row.items,
                        wide: row.wide,
                        onTap: _soon,
                        onAdd: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('원함 담기는 컬렉션 화면과 함께 연결할 예정이에요')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
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

/// A-3 공식 예고 배너 — 화면 끝까지 꽉 찬 16:9 사진, 아래에 상태와 제목
class _HeroBanner extends StatefulWidget {
  const _HeroBanner({required this.items, required this.onTap});
  final List<Announcement> items;
  final VoidCallback onTap;

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // 넓은 창에서는 너무 커지지 않게 높이 제한 (적응형)
        final imageHeight = (box.maxWidth * 9 / 16).clamp(180.0, 420.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight + 78,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _page = i), // STATE: 넘긴 쪽 → 점 표시
                itemBuilder: (context, i) {
                  final a = widget.items[i];
                  return GestureDetector(
                    onTap: widget.onTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: imageHeight,
                          width: double.infinity,
                          child: AppImage(a.image),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${a.status} · ${channelOf(a.franchiseId).label}', // A-4 P01
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  letterSpacing: 0.8,
                                  color: Gp.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                a.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              child: Row(
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 5),
                      width: i == _page ? 16 : 5,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i == _page ? Gp.accent : Gp.line, // 브랜드 포인트 색
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A-5 색 막대 + 줄 제목 + 전체 보기(›) — IMDb 줄 제목처럼
class _RowHeader extends StatelessWidget {
  const _RowHeader({required this.title, required this.onMore, this.subtitle = ''});
  final String title;
  final String subtitle;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onMore,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 22,
              margin: const EdgeInsets.only(top: 1, right: 10),
              decoration: BoxDecoration(
                color: Gp.accent, // 브랜드 포인트 색
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Gp.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Gp.muted),
          ],
        ),
      ),
    );
  }
}

/// A-6 가로 스크롤 줄 — 사진 + 이름 한 줄 (날짜·가격 없음)
class _HorizontalRow extends StatelessWidget {
  const _HorizontalRow({
    required this.items,
    required this.wide,
    required this.onTap,
    required this.onAdd,
  });
  final List<_Item> items;

  /// true = 가로로 긴 배너 사진(공식 예고)
  final bool wide;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final w = wide ? 232.0 : 148.0;
    final h = wide ? 132.0 : 148.0;
    return SizedBox(
      height: h + 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: Gp.soft, child: AppImage(items[i].image)),
                        if (items[i].canAdd)
                          Positioned(left: 6, top: 6, child: _AddSlot(onTap: onAdd)), // A-9 P07
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  items[i].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Gp.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A-9 사진 왼쪽 위 + 자리 — 원함 담기 (컬렉션과 연결할 때 동작을 정한다)
class _AddSlot extends StatelessWidget {
  const _AddSlot({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '원함에 담기',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xD9FFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: Gp.line),
          ),
          child: const Icon(Icons.add, size: 18, color: Gp.ink),
        ),
      ),
    );
  }
}
