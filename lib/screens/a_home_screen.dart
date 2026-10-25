// 화면 A: 홈 — 큰 배너(공식 예고) + 종류별 가로 스크롤 줄
//
// ┌──────── 디자인 가이드 대응표: A 홈 ────────────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ A-1  │ ChannelHeader                      │ 아바타 줄 + 내 채널 바 (C-0 공용)       │ P04 · P06     │
// │ A-2  │ GpSearchBar 입구 (탭하면 검색 탭)   │ 검색창(검색 화면과 같은 모양) · 카메라  │ P07 · P04     │
// │ A-3  │ PageView(화면 끝까지) + 점 표시     │ 공식 예고 배너 (완성된 홍보 이미지)     │ P08 · P02     │
// │ A-4  │ 배너 아래 상태 · 제목               │ 예고 상태(공식 발표·상품화 확정·예약)   │ P01           │
// │ A-5  │ SectionHeader (색 막대 + ›)         │ 줄 이름 · 전체 보기 (최근 추가는 기간)  │ P06 · P07     │
// │ A-6  │ 가로 ListView + ProductTile         │ 최근 추가 · 10월 발매 · 공식 예고 · 최근 본 │ P08        │
// │ A-7  │ LoadingView / ErrorView / EmptyView │ 불러오는 중 · 오류 · 빈 채널           │ P01 · P09     │
// │ A-8  │ 흰 띠(섹션마다) + 회백색 틈          │ 줄과 줄 사이 층 구분                   │ P08 · P04     │
// │ A-9  │ ProductTile 의 QuickMarks ♡ +       │ 좋아요 · 구매함 바로 담기 (가짜 저장)     │ P07           │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: A-2 → 검색 탭(옆으로). 상품 카드 → D 상품 상세(쌓기). 배너 · 예고 카드 → J 공식 예고 상세(쌓기).
// 줄 안에는 날짜·가격을 쓰지 않는다 — 궁금하면 눌러서 상세에서 본다 (P08).
// 현행 앱 문제: 홈 = 버전 번호·총 개수·IP 입구 카드 → v2 홈 = "내 채널의 새 소식"만.
import 'package:flutter/material.dart';

import '../api.dart';
import '../channels.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'c_channel_screen.dart';
import 'd_kit_detail_screen.dart';
import 'j_announcement_screen.dart';

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
    required this.onCamera,
    this.leading,
    this.loaders = const Loaders(),
  });

  final List<String> myChannels;
  final ValueChanged<List<String>> onMyChannelsChanged;
  final VoidCallback onOpenSearch;

  /// 검색창 카메라 → 앱 셸의 찍어서 찾기 시트
  final VoidCallback onCamera;
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

/// 가로 줄 한 칸 (사진 + 이름). [kit]이 있으면 상품(상세 · 좋아요 담기), 없으면 공식 예고
class _Item {
  const _Item(this.image, this.title, {this.kit, this.ann});
  final String image;
  final String title;
  final Kit? kit;
  final Announcement? ann;
}

/// 가로 줄 하나
class _Row {
  const _Row(this.title, this.items, {this.subtitle = '', this.wide = false});
  final String title;
  final List<_Item> items;
  final String subtitle;
  final bool wide;
}

class _HomeScreenState extends State<HomeScreen> with ChannelScope {
  late Future<_HomeData> _future;

  @override
  List<String> get myChannels => widget.myChannels;

  @override
  void loadScope(List<String> ids) {
    // STATE: 선택 채널 → GET /kits · /announcements → 배너 + 가로 줄
    _future = Future.wait([
      widget.loaders.kits(ids),
      widget.loaders.announcements(ids),
    ]).then((r) => _HomeData(r[0] as List<Kit>, r[1] as List<Announcement>));
  }

  @override
  void initState() {
    super.initState();
    reloadScope();
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    syncScope();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChannelHeader( // A-1 P04
          leading: widget.leading,
          myChannels: widget.myChannels,
          selected: channel,
          onSelect: selectChannel,
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
                  onRetry: () => setState(reloadScope),
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
      child: GpSearchBar(onTap: widget.onOpenSearch, onCamera: widget.onCamera), // A-2 P04
    );
    final ids = scopeIds;
    if (data.kits.isEmpty && data.announcements.isEmpty) {
      final noData = ids.isNotEmpty && ids.every((id) => !channelOf(id).hasData);
      return ListView(
        children: [
          search,
          EmptyView( // A-7 P09
            icon: Icons.auto_awesome_outlined,
            message: ids.isEmpty
                ? '내 채널이 비어 있어요'
                : noData
                ? '${channelOf(ids.first).label}은(는) 아직 수록된 상품이 없어요'
                : '새 소식이 없어요',
            detail: ids.isEmpty ? '채널 관리에서 관심 IP를 추가하세요' : '상품이 들어오면 여기에 먼저 보여요',
            action: channel == allChannelId
                ? null
                : OutlinedButton(
                    onPressed: () => selectChannel(allChannelId),
                    child: const Text('전체 보기'),
                  ),
          ),
        ],
      );
    }

    final byId = {for (final k in data.kits) k.id: k};
    _Item kitItem(Kit k) => _Item(k.image, k.name, kit: k);
    final rows = [
      _Row('최근 추가', [for (final k in data.kits.where((k) => k.recent)) kitItem(k)],
          subtitle: recentRangeLabel),
      _Row(currentMonthTitle, [for (final k in data.kits.where((k) => k.month)) kitItem(k)]),
      _Row('공식 예고', [
        for (final a in data.announcements) _Item(a.image, a.title, ann: a),
      ], wide: true),
      _Row('최근 본', [for (final id in recentViewedIds) if (byId[id] case final k?) kitItem(k)]),
    ];
    final heroes = data.announcements.where((a) => a.hero).toList();

    return ListView(
      padding: EdgeInsets.only(bottom: navClearance(context)),
      children: [
        search,
        if (heroes.isNotEmpty)
          ColoredBox(
            color: Gp.panel,
            child: _HeroBanner( // A-3
              items: heroes,
              onTap: (a) => openAnnouncement(context, a, loaders: widget.loaders),
            ),
          ),
        for (final row in rows)
          if (row.items.isNotEmpty)
            SectionPanel( // A-8 흰 띠 + 회백색 틈 = 층 구분 (상세와 같은 부품)
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader( // A-5 P06
                    row.title,
                    subtitle: row.subtitle,
                    onMore: () => showSoon(context, '${row.title} 전체 목록'),
                  ),
                  _HorizontalRow(row: row, loaders: widget.loaders), // A-6 P08
                ],
              ),
            ),
      ],
    );
  }
}

/// A-3 공식 예고 배너 — 화면 끝까지 꽉 찬 16:9 사진, 아래에 상태와 제목
class _HeroBanner extends StatefulWidget {
  const _HeroBanner({required this.items, required this.onTap});
  final List<Announcement> items;
  final ValueChanged<Announcement> onTap;

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
                    onTap: () => widget.onTap(a),
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
              padding: const EdgeInsets.fromLTRB(18, 4, 20, 18),
              child: PageDots(count: widget.items.length, index: _page, center: false),
            ),
          ],
        );
      },
    );
  }
}

/// A-6 가로 스크롤 줄 — ProductTile (사진 + 이름 한 줄, 날짜·가격 없음)
class _HorizontalRow extends StatelessWidget {
  const _HorizontalRow({required this.row, required this.loaders});
  final _Row row;
  final Loaders loaders;

  @override
  Widget build(BuildContext context) {
    // 공식 예고는 가로로 긴 배너 사진
    final width = row.wide ? 232.0 : 148.0;
    final aspect = row.wide ? 232 / 132 : 1.0;
    return SizedBox(
      height: width / aspect + 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: row.items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = row.items[i];
          final kit = item.kit;
          return ProductTile(
            image: item.image,
            title: item.title,
            imageWidth: width,
            imageAspect: aspect,
            onTap: () {
              final ann = item.ann;
              if (kit != null) {
                openKitDetail(context, kit, loaders: loaders);
              } else if (ann != null) {
                openAnnouncement(context, ann, loaders: loaders);
              }
            },
            marks: kit == null ? null : QuickMarks(name: kit.name, liked: kit.status == CollectStatus.wanted, owned: kit.status == CollectStatus.owned), // A-9 P07
          );
        },
      ),
    );
  }
}
