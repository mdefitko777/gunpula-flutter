// 화면 O: 전체 목록 — 홈 안에서 바뀌는 보기 (새 화면을 쌓지 않음)
// 홈 위쪽(아바타 줄 · 채널 바 · 검색창)은 그대로 두고, 그 아래만 이 목록으로 바뀐다.
// 들어오는 곳: 홈 가로 줄의 › (최근 추가 · 10월 발매 · 공식 예고 · 최근 본) · 검색창 아래 "전체 상품 / 작품" 알약.
// 홈 줄은 사진과 이름만(P08), 여기서는 가격 · 발매일까지 보이고 작품으로 거르며 검색창은 이 목록 안에서만 찾는다.
//
// ┌──────── 디자인 가이드 대응표: O 전체 목록 ─────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ O-1  │ ‹ + 제목 + 개수 · 보기 전환          │ 어느 목록인지 · 홈으로 돌아가기 · 격자/목록 │ P03 · P07   │
// │ O-2  │ 알약 거르기 + 개수                   │ 상품: 작품별 (SEED · 수성 · FGO …)       │ P06 · P01     │
// │      │                                    │ 예고: 공식 발표 · 상품화 확정 · 예약 시작 │              │
// │ O-3  │ PopupMenuButton                     │ 정렬: 최신순 · 발매일순 · 가격 낮은/높은순 │ P07           │
// │ O-4  │ 격자 ProductTile(+ ♡) / ThumbRow     │ 상품 (가격 · 발매일 보임) → D 상세       │ P08 · P07     │
// │ O-5  │ 16:9 카드                           │ 공식 예고 → J 공고                      │ P02           │
// │ O-6  │ 기록 지우기 → showDialog → 토스트     │ 최근 본 기록 비우기 (되돌리기)            │ P05 · P03     │
// │ O-7  │ 홈 검색창 (이 목록 안에서만 찾기)      │ "최근 추가에서 찾기"                     │ P07 · P04     │
// │ O-8  │ EmptyView                          │ 거른 결과 · 찾은 결과 없음 · 기록 없음     │ P09           │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: 홈 안에서 바뀜(쌓지 않음) — ‹ 또는 뒤로 가기로 홈. 칸 → 상세 쌓기.
// 데이터는 홈이 GET 한 목록을 그대로 쓴다(다시 부르지 않음). 채널을 바꾸면 홈이 다시 GET 하고 목록도 따라 바뀐다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../channels.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'd_kit_detail_screen.dart';
import 'j_announcement_screen.dart';

/// 홈에서 펼칠 수 있는 목록
enum HomeSection { all, recent, month, announcements, viewed }

enum KitSort { newest, release, priceLow, priceHigh }

extension on KitSort {
  String get label => switch (this) {
    KitSort.newest => '최신순',
    KitSort.release => '발매일순',
    KitSort.priceLow => '가격 낮은순',
    KitSort.priceHigh => '가격 높은순',
  };
}

/// "2026-10-05" → "2026.10.05", "2027-07" → "2027.07"
String dateLabel(String d) => d.replaceAll('-', '.');

class SectionListView extends StatefulWidget {
  const SectionListView({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle = '',
    this.kits = const [],
    this.announcements,
    this.history = false,
    this.sort = KitSort.newest,
    this.work = '',
    this.query = '',
    this.loaders = const Loaders(),
  });

  final String title;
  final VoidCallback onBack;
  final String subtitle;
  final List<Kit> kits;

  /// 있으면 공식 예고 목록
  final List<Announcement>? announcements;

  /// 최근 본 기록 (지우기 버튼)
  final bool history;
  final KitSort sort;

  /// 처음 고른 작품 ('' = 전체)
  final String work;

  /// 홈 검색창 글자 — 이 목록 안에서만 거른다 (O-7)
  final String query;
  final Loaders loaders;

  @override
  State<SectionListView> createState() => _SectionListViewState();
}

class _SectionListViewState extends State<SectionListView> {
  late KitSort _sort = widget.sort;
  late String _work = widget.work;
  late List<Kit> _cleared = const []; // 최근 본: 지운 기록
  bool _grid = true;
  String _annStatus = '';

  List<Kit> get _kits => widget.kits.where((k) => !_cleared.contains(k)).toList();

  List<Kit> _visibleKits() {
    final list = [
      for (final k in _kits)
        if ((_work.isEmpty || kitWork(k) == _work) && kitMatches(k, widget.query)) k,
    ];
    int price(Kit k, int none) => k.priceJpy ?? none;
    switch (_sort) {
      case KitSort.newest:
        break; // 홈 줄과 같은 순서 (GET 정렬 그대로)
      case KitSort.release:
        list.sort((a, b) => a.date.compareTo(b.date));
      case KitSort.priceLow:
        list.sort((a, b) => price(a, 1 << 30).compareTo(price(b, 1 << 30)));
      case KitSort.priceHigh:
        list.sort((a, b) => price(b, -1).compareTo(price(a, -1)));
    }
    return list;
  }

  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      // O-6 P05
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('최근 본 기록을 지울까요?'),
        content: const Text('상품은 그대로이고, 이 목록만 비워져요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('지우기')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cleared = widget.kits); // STATE: 기록 지우기 → 빈 목록
    showToast(context, '최근 본 기록을 지웠어요', onUndo: () => setState(() => _cleared = const []));
  }

  @override
  Widget build(BuildContext context) {
    final anns = widget.announcements;
    final count = anns != null ? anns.length : _kits.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          // O-1
          padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: '홈으로',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
              Container(width: 3, height: 16, color: Gp.accent), // 홈 줄 제목과 같은 색 막대
              const SizedBox(width: 8),
              Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  joinDot([widget.subtitle, '$count개']),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: Gp.accent, fontWeight: FontWeight.w500),
                ),
              ),
              if (widget.history && _kits.isNotEmpty)
                TextButton(onPressed: _clearHistory, child: const Text('기록 지우기')), // O-6
              if (anns == null)
                IconButton(
                  tooltip: _grid ? '목록으로 보기' : '격자로 보기',
                  onPressed: () => setState(() => _grid = !_grid), // STATE: 보기 방식
                  icon: Icon(_grid ? Icons.view_list_outlined : Icons.grid_view_outlined, color: Gp.muted),
                ),
            ],
          ),
        ),
        Expanded(child: anns != null ? _announcementBody(anns) : _kitBody()),
      ],
    );
  }

  // ---------- 상품 ----------

  Widget _kitBody() {
    final kits = _kits;
    if (kits.isEmpty) {
      return EmptyView(
        // O-8
        icon: widget.history ? Icons.history : Icons.inbox_outlined,
        message: widget.history ? '최근 본 상품이 없어요' : '표시할 상품이 없어요',
        detail: widget.history ? '상품 상세를 열면 여기에 남아요' : '',
      );
    }
    final works = workCounts(kits.where((k) => kitMatches(k, widget.query)));
    final visible = _visibleKits();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterChipBar(
          // O-2 작품별
          options: [
            (label: '전체', count: works.fold(0, (s, w) => s + w.$2), selected: _work.isEmpty),
            for (final (w, n) in works) (label: w, count: n, selected: _work == w),
          ],
          onSelect: (i) => setState(() => _work = i == 0 ? '' : works[i - 1].$1), // STATE: 작품 → 목록
          trailing: PopupMenuButton<KitSort>(
            // O-3
            tooltip: '정렬',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s), // STATE: 정렬 → 순서
            itemBuilder: (_) => [for (final s in KitSort.values) PopupMenuItem(value: s, child: Text(s.label))],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_vert, size: 18, color: Gp.muted),
                  const SizedBox(width: 2),
                  Text(_sort.label, style: const TextStyle(fontSize: 13, color: Gp.ink)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyView(
                  // O-8
                  icon: Icons.search_off,
                  message: widget.query.isEmpty ? '이 작품의 상품이 없어요' : '「${widget.query}」 결과가 ${widget.title}에 없어요',
                  detail: widget.query.isEmpty ? '' : '전체 상품에서 찾으려면 아래 검색 탭을 쓰세요',
                  action: _work.isEmpty
                      ? null
                      : OutlinedButton(onPressed: () => setState(() => _work = ''), child: const Text('작품 전체 보기')),
                )
              : _grid
              ? _kitGrid(visible)
              : _kitList(visible),
        ),
      ],
    );
  }

  Widget _marks(Kit k) =>
      QuickMarks(name: k.name, liked: k.status == CollectStatus.wanted, owned: k.status == CollectStatus.owned);

  Widget _kitGrid(List<Kit> kits) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = (box.maxWidth / 170).floor().clamp(2, 5);
        final cell = (box.maxWidth - 32 - (cols - 1) * 12) / cols;
        return GridView.builder(
          // O-4
          padding: EdgeInsets.fromLTRB(16, 4, 16, navClearance(context)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            mainAxisExtent: cell + 80, // 사진 + 이름 두 줄 + 가격 · 날짜 한 줄
          ),
          itemCount: kits.length,
          itemBuilder: (context, i) {
            final k = kits[i];
            return ProductTile(
              image: k.image,
              title: k.name,
              titleLines: 2,
              subtitle: joinDot([yen(k.priceJpy), dateLabel(k.date)]),
              marks: _marks(k),
              onTap: () => openKitDetail(context, k, loaders: widget.loaders),
            );
          },
        );
      },
    );
  }

  Widget _kitList(List<Kit> kits) {
    return ListView(
      padding: EdgeInsets.only(top: 4, bottom: navClearance(context)),
      children: [
        for (final k in kits)
          ThumbRow(
            image: k.image,
            title: k.name,
            titleLines: 2,
            size: 64,
            subtitle: joinDot([channelOf(k.franchiseId).label, kitWork(k), k.line]),
            tag: switch (k.status) {
              CollectStatus.wanted => '좋아요',
              CollectStatus.owned => '구매함',
              CollectStatus.none => '',
            },
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(yen(k.priceJpy), style: const TextStyle(fontSize: 13)),
                Text(dateLabel(k.date), style: const TextStyle(fontSize: 11.5, color: Gp.faint)),
              ],
            ),
            onTap: () => openKitDetail(context, k, loaders: widget.loaders),
          ),
      ],
    );
  }

  // ---------- 공식 예고 ----------

  Widget _announcementBody(List<Announcement> all0) {
    final q = widget.query.trim().toLowerCase();
    final all = [
      for (final a in all0)
        if (q.isEmpty || a.title.toLowerCase().contains(q)) a,
    ];
    final statuses = {for (final a in all) a.status}.toList(); // 나온 순서대로 한 번씩
    final list = [
      for (final a in all)
        if (_annStatus.isEmpty || a.status == _annStatus) a,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterChipBar(
          options: [
            for (final s in ['', ...statuses])
              (
                label: s.isEmpty ? '전체' : s,
                count: s.isEmpty ? all.length : all.where((a) => a.status == s).length,
                selected: _annStatus == s,
              ),
          ],
          onSelect: (i) => setState(() => _annStatus = i == 0 ? '' : statuses[i - 1]), // STATE: 거르기 → 목록
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyView(icon: Icons.search_off, message: '이 조건의 예고가 없어요')
              : LayoutBuilder(
                  builder: (context, box) {
                    final cols = box.maxWidth >= 720 ? 2 : 1;
                    final cell = (box.maxWidth - 32 - (cols - 1) * 14) / cols;
                    return GridView.builder(
                      // O-5
                      padding: EdgeInsets.fromLTRB(16, 4, 16, navClearance(context)),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 14,
                        mainAxisExtent: cell * 9 / 16 + 76,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final a = list[i];
                        return GestureDetector(
                          onTap: () => openAnnouncement(context, a, loaders: widget.loaders),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(aspectRatio: 16 / 9, child: PhotoThumb(a.image, radius: 12)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TagPill(a.status, strong: a.status == '예약 시작'),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      joinDot([channelOf(a.franchiseId).label, dateLabel(a.date), a.source]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Gp.muted),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                a.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
