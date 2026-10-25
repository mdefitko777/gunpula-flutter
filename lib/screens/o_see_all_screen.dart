// 화면 O: 전체 목록 — 홈 가로 줄의 › 에서 열림 (최근 추가 · 10월 발매 · 공식 예고 · 최근 본)
// 홈 줄은 사진과 이름만 보여 주고(P08), 여기서는 가격 · 발매일까지 보이며 거르고 정렬한다.
//
// ┌──────── 디자인 가이드 대응표: O 전체 목록 ─────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ O-1  │ AppBar 제목 + 개수 · 보기 전환       │ 줄 이름 · 격자/목록                     │ P06 · P07     │
// │ O-2  │ 알약 거르기 + 개수                   │ 상품: 전체 · 좋아요 · 구매함 · 아직 없음  │ P06 · P01     │
// │      │                                    │ 예고: 전체 · 공식 발표 · 상품화 확정 · 예약 │              │
// │ O-3  │ PopupMenuButton                     │ 정렬: 최신순 · 발매일순 · 가격 낮은/높은순 │ P07           │
// │ O-4  │ 격자 ProductTile(♡ +) / ThumbRow     │ 상품 (가격 · 발매일 보임) → D 상세       │ P08 · P07     │
// │ O-5  │ 16:9 카드                           │ 공식 예고 → J 공고                      │ P02           │
// │ O-6  │ 기록 지우기 → showDialog → 토스트     │ 최근 본 기록 비우기 (되돌리기)            │ P05 · P03     │
// │ O-7  │ EmptyView                          │ 거른 결과 없음 · 기록 없음               │ P09           │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: 홈 › → 쌓기(push, 오른쪽에서). 칸 → 상세 쌓기. 데이터는 홈이 GET 한 목록을 그대로 받는다(다시 부르지 않음).
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';

import '../api.dart';
import '../channels.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'd_kit_detail_screen.dart';
import 'j_announcement_screen.dart';

enum KitSort { newest, release, priceLow, priceHigh }

extension on KitSort {
  String get label => switch (this) {
    KitSort.newest => '최신순',
    KitSort.release => '발매일순',
    KitSort.priceLow => '가격 낮은순',
    KitSort.priceHigh => '가격 높은순',
  };
}

void openSeeAll(
  BuildContext context, {
  required String title,
  String subtitle = '',
  List<Kit> kits = const [],
  List<Announcement> announcements = const [],
  bool history = false,
  KitSort sort = KitSort.newest,
  Loaders loaders = const Loaders(),
}) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoPageRoute<void>(
      builder: (_) => SeeAllScreen(
        title: title,
        subtitle: subtitle,
        kits: kits,
        announcements: announcements,
        history: history,
        sort: sort,
        loaders: loaders,
      ),
    ),
  );
}

/// "2026-10-05" → "2026.10.05", "2027-07" → "2027.07"
String dateLabel(String d) => d.replaceAll('-', '.');

class SeeAllScreen extends StatefulWidget {
  const SeeAllScreen({
    super.key,
    required this.title,
    this.subtitle = '',
    this.kits = const [],
    this.announcements = const [],
    this.history = false,
    this.sort = KitSort.newest,
    this.loaders = const Loaders(),
  });

  final String title;
  final String subtitle;
  final List<Kit> kits;

  /// 비어 있지 않으면 공식 예고 목록
  final List<Announcement> announcements;

  /// 최근 본 기록 (지우기 버튼)
  final bool history;
  final KitSort sort;
  final Loaders loaders;

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  late KitSort _sort = widget.sort;
  late List<Kit> _kits = widget.kits; // 최근 본 기록은 지울 수 있어서 상태로
  bool _grid = true;

  /// 상품: null = 전체, 아니면 그 상태 / 예고: '' = 전체, 아니면 그 상태 글자
  CollectStatus? _status;
  String _annStatus = '';

  bool get _isAnn => widget.announcements.isNotEmpty;

  List<Kit> _visibleKits() {
    final list = [
      for (final k in _kits)
        if (_status == null || k.status == _status) k,
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
    final before = _kits;
    setState(() => _kits = const []); // STATE: 기록 지우기 → 빈 목록
    showToast(context, '최근 본 기록을 지웠어요', onUndo: () => setState(() => _kits = before));
  }

  @override
  Widget build(BuildContext context) {
    final count = _isAnn ? widget.announcements.length : _kits.length;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            Text(
              joinDot([widget.subtitle, '$count개']),
              style: const TextStyle(fontSize: 12, color: Gp.accent, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          if (widget.history && _kits.isNotEmpty)
            TextButton(onPressed: _clearHistory, child: const Text('기록 지우기')), // O-6
          if (!_isAnn)
            IconButton(
              // O-1
              tooltip: _grid ? '목록으로 보기' : '격자로 보기',
              onPressed: () => setState(() => _grid = !_grid), // STATE: 보기 방식
              icon: Icon(_grid ? Icons.view_list_outlined : Icons.grid_view_outlined),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isAnn ? _announcementBody() : _kitBody(),
    );
  }

  // ---------- 상품 ----------

  Widget _kitBody() {
    if (_kits.isEmpty) {
      return EmptyView(
        // O-7
        icon: widget.history ? Icons.history : Icons.inbox_outlined,
        message: widget.history ? '최근 본 상품이 없어요' : '표시할 상품이 없어요',
        detail: widget.history ? '상품 상세를 열면 여기에 남아요' : '',
      );
    }
    int n(CollectStatus? s) => s == null ? _kits.length : _kits.where((k) => k.status == s).length;
    final kits = _visibleKits();
    return Column(
      children: [
        _FilterBar(
          options: [
            for (final s in [null, CollectStatus.wanted, CollectStatus.owned, CollectStatus.none])
              (
                label: switch (s) {
                  null => '전체',
                  CollectStatus.wanted => '좋아요',
                  CollectStatus.owned => '구매함',
                  CollectStatus.none => '아직 없음',
                },
                count: n(s),
                selected: _status == s,
                onTap: () => setState(() => _status = s), // STATE: 거르기 → 목록
              ),
          ],
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
          child: kits.isEmpty
              ? EmptyView(
                  message: '이 조건의 상품이 없어요',
                  action: OutlinedButton(onPressed: () => setState(() => _status = null), child: const Text('전체 보기')),
                )
              : _grid
              ? _kitGrid(kits)
              : _kitList(kits),
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
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
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      children: [
        for (final k in kits)
          ThumbRow(
            image: k.image,
            title: k.name,
            titleLines: 2,
            size: 64,
            subtitle: joinDot([channelOf(k.franchiseId).label, k.line, k.series]),
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

  Widget _announcementBody() {
    final all = widget.announcements;
    final statuses = {for (final a in all) a.status}.toList(); // 나온 순서대로 한 번씩
    final list = [
      for (final a in all)
        if (_annStatus.isEmpty || a.status == _annStatus) a,
    ];
    return Column(
      children: [
        _FilterBar(
          options: [
            for (final s in ['', ...statuses])
              (
                label: s.isEmpty ? '전체' : s,
                count: s.isEmpty ? all.length : all.where((a) => a.status == s).length,
                selected: _annStatus == s,
                onTap: () => setState(() => _annStatus = s), // STATE: 거르기 → 목록
              ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= 720 ? 2 : 1;
              final cell = (box.maxWidth - 32 - (cols - 1) * 14) / cols;
              return GridView.builder(
                // O-5
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
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

/// O-2 가로로 넘기는 거르기 알약 줄 (+ 오른쪽 정렬)
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.options, this.trailing});
  final List<({String label, int count, bool selected, VoidCallback onTap})> options;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final o in options)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${o.label} ${o.count}'),
                        selected: o.selected,
                        onSelected: (_) => o.onTap(),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: o.selected ? Gp.accent : Gp.ink,
                          fontWeight: o.selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        backgroundColor: Gp.panel,
                        selectedColor: Gp.accent.withValues(alpha: 0.08),
                        side: BorderSide(color: o.selected ? Gp.accent : Gp.line),
                        shape: const StadiumBorder(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
