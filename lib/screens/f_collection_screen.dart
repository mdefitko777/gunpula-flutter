// 화면 F: 컬렉션 — 원함 · 구매함 (목록 | 도감)
//
// ┌──────── 디자인 가이드 대응표: F 컬렉션 ────────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ F-1  │ ChannelHeader                      │ 아바타 줄 + 내 채널 바 (C-0 공용)       │ P04 · P06     │
// │ F-2  │ 밑줄 탭 2개 + 개수                   │ 원함 · 구매함                          │ P06 · P01     │
// │ F-3  │ 아이콘 두 개 (목록 · 도감)            │ 보기 방식 전환                          │ P07           │
// │ F-4  │ Text(합계)                         │ 원함 예산 (정가 × 수량 합)              │ P01           │
// │ F-5  │ ListView 줄 (사진 · 이름 · ×n)        │ 컬렉션 목록 → 상품 상세                 │ P08           │
// │ F-6  │ 편집 → 체크박스 + 선택 삭제           │ 정리하기 (편집 모드에서만 삭제 보임)     │ P05 · P03     │
// │ F-7  │ showDialog(확인) → 토스트(되돌리기)   │ 삭제 전 확인 · 바로 되돌리기             │ P05 · P03     │
// │ F-8  │ GuideView (g_guide_view.dart)       │ 도감 — 모은 만큼 불이 켜지는 칸          │ P01 · P06     │
// │ F-9  │ LoadingView / ErrorView / EmptyView │ 불러오는 중 · 오류 · 빈 컬렉션           │ P01 · P09     │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: 줄 → D 상품 상세(쌓기). 빈 상태 "검색하러 가기" → 검색 탭(옆으로).
// 현행 앱 문제: 컬렉션 화면에 빨간 "전체 삭제"가 늘 보임(실수 위험) · 도감이 따로 떨어진 화면
//              → v2는 편집 모드에서만 삭제, 도감은 컬렉션의 다른 보기.
import 'package:flutter/material.dart';

import '../api.dart';
import '../channels.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'c_channel_screen.dart';
import 'd_kit_detail_screen.dart';
import 'g_guide_view.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    required this.myChannels,
    required this.onMyChannelsChanged,
    required this.onGoSearch,
    this.leading,
    this.loaders = const Loaders(),
  });

  final List<String> myChannels;
  final ValueChanged<List<String>> onMyChannelsChanged;
  final VoidCallback onGoSearch;
  final Widget? leading;
  final Loaders loaders;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with ChannelScope {
  late Future<List<Kit>> _future;

  /// true = 구매함 탭, false = 원함 탭
  bool _ownedTab = false;

  /// true = 도감 보기, false = 목록 보기
  bool _guide = false;
  bool _editing = false;
  final Set<String> _selected = {};

  /// 이 화면에서 지운 상품 (가짜 삭제 — 저장하지 않음)
  final Set<String> _removed = {};

  @override
  List<String> get myChannels => widget.myChannels;

  @override
  void loadScope(List<String> ids) {
    _future = widget.loaders.collection(); // STATE: GET /kits?status_ne=none → 원함 · 구매함
  }

  @override
  void initState() {
    super.initState();
    reloadScope();
  }

  @override
  void didUpdateWidget(CollectionScreen old) {
    super.didUpdateWidget(old);
    syncScope();
  }

  List<Kit> _visible(List<Kit> all) {
    final ids = scopeIds;
    final want = _ownedTab ? CollectStatus.owned : CollectStatus.wanted;
    return all
        .where((k) => k.status == want && ids.contains(k.franchiseId) && !_removed.contains(k.id))
        .toList();
  }

  Future<void> _deleteSelected() async {
    final n = _selected.length;
    final ok = await showDialog<bool>( // F-7 P05
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$n개를 ${_ownedTab ? '구매함' : '원함'}에서 뺄까요?'),
        content: const Text('상품 자체는 지워지지 않고, 내 컬렉션에서만 빠져요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('빼기')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final gone = {..._selected};
    setState(() {
      _removed.addAll(gone); // STATE: 선택 → 목록에서 빠짐
      _selected.clear();
      _editing = false;
    });
    showToast(context, '$n개를 뺐어요', onUndo: () => setState(() => _removed.removeAll(gone))); // P03
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChannelHeader( // F-1 P04
          leading: widget.leading,
          myChannels: widget.myChannels,
          selected: channel,
          onSelect: selectChannel,
          onMyChannelsChanged: widget.onMyChannelsChanged,
        ),
        Expanded(
          child: FutureBuilder<List<Kit>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const LoadingView(); // F-9 P01
              }
              if (snap.hasError) {
                return ErrorView(message: '${snap.error}', onRetry: () => setState(reloadScope));
              }
              final all = snap.data!;
              final ids = scopeIds;
              int count(CollectStatus s) => all
                  .where((k) => k.status == s && ids.contains(k.franchiseId) && !_removed.contains(k.id))
                  .length;
              return Column(
                children: [
                  _TopRow(
                    wantedCount: count(CollectStatus.wanted),
                    ownedCount: count(CollectStatus.owned),
                    ownedTab: _ownedTab,
                    guide: _guide,
                    onTab: (owned) => setState(() {
                      _ownedTab = owned; // STATE: 탭 → 목록 내용
                      _selected.clear();
                      _editing = false;
                    }),
                    onGuide: (g) => setState(() {
                      _guide = g; // STATE: 보기 방식 → 목록 ↔ 도감
                      _editing = false;
                    }),
                  ),
                  Expanded(
                    child: _guide
                        ? GuideView( // F-8
                            channel: channel,
                            myChannels: widget.myChannels,
                            onPickChannel: selectChannel,
                            loaders: widget.loaders,
                          )
                        : _list(_visible(all)),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _list(List<Kit> kits) {
    if (kits.isEmpty) {
      return EmptyView( // F-9 P09
        icon: _ownedTab ? Icons.check_circle_outline : Icons.bookmark_border,
        message: _ownedTab ? '아직 구매함에 넣은 상품이 없어요' : '아직 원함에 담은 상품이 없어요',
        detail: channel == allChannelId
            ? '상품 상세에서 원함 · 구매함을 누르면 여기에 모여요'
            : '${channelOf(channel).label} 채널에는 아직 없어요',
        action: OutlinedButton.icon(
          onPressed: widget.onGoSearch,
          icon: const Icon(Icons.search, size: 18),
          label: const Text('검색하러 가기'),
        ),
      );
    }
    final total = kits.fold<int>(0, (s, k) => s + (k.priceJpy ?? 0) * (k.wantedQty < 1 ? 1 : k.wantedQty));
    final pieces = kits.fold<int>(0, (s, k) => s + (k.wantedQty < 1 ? 1 : k.wantedQty));
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(bottom: navClearance(context) + (_editing ? 60 : 0)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _ownedTab ? '구매함 ${kits.length}개' : '합계 ${yen(total)} · $pieces개', // F-4 P01
                      style: const TextStyle(color: Gp.muted, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _editing = !_editing; // STATE: 편집 → 체크박스 · 삭제 바
                      _selected.clear();
                    }),
                    child: Text(_editing ? '완료' : '편집'), // F-6
                  ),
                ],
              ),
            ),
            for (final k in kits)
              InkWell(
                onTap: _editing
                    ? () => setState(() => _selected.contains(k.id) ? _selected.remove(k.id) : _selected.add(k.id))
                    : () => openKitDetail(context, k, loaders: widget.loaders),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      if (_editing)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            _selected.contains(k.id) ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: _selected.contains(k.id) ? Gp.accent : Gp.faint,
                          ),
                        ),
                      SizedBox.square(dimension: 68, child: PhotoThumb(k.image, radius: 12)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(k.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(
                              [channelOf(k.franchiseId).label, k.line, k.series]
                                  .where((s) => s.isNotEmpty)
                                  .join(' · '),
                              style: const TextStyle(fontSize: 12.5, color: Gp.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(yen(k.priceJpy), style: const TextStyle(fontSize: 13)),
                          if (!_ownedTab && k.wantedQty > 1)
                            Text('×${k.wantedQty}',
                                style: const TextStyle(fontSize: 12.5, color: Gp.accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (_editing)
          Positioned(
            left: 16,
            right: 16,
            bottom: navClearance(context) - 30,
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    if (_selected.length == kits.length) {
                      _selected.clear();
                    } else {
                      _selected.addAll(kits.map((k) => k.id));
                    }
                  }),
                  child: Text(_selected.length == kits.length ? '모두 해제' : '모두 선택'),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _selected.isEmpty ? null : _deleteSelected, // F-6 P05
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Gp.panel,
                    foregroundColor: Gp.danger,
                    side: BorderSide(color: _selected.isEmpty ? Gp.line : Gp.danger),
                  ),
                  child: Text('선택 빼기 (${_selected.length})'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// F-2 · F-3 원함 | 구매함 탭 + 목록/도감 전환
class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.wantedCount,
    required this.ownedCount,
    required this.ownedTab,
    required this.guide,
    required this.onTab,
    required this.onGuide,
  });

  final int wantedCount;
  final int ownedCount;
  final bool ownedTab;
  final bool guide;
  final ValueChanged<bool> onTab;
  final ValueChanged<bool> onGuide;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, int n, bool owned) {
      final on = !guide && ownedTab == owned;
      return GestureDetector(
        onTap: () {
          onGuide(false);
          onTab(owned);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: label),
                  TextSpan(text: ' $n', style: TextStyle(color: on ? Gp.accent : Gp.faint)),
                ]),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                  color: on ? Gp.ink : Gp.muted,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 2,
                width: on ? 16 : 0,
                color: Gp.accent,
              ),
            ],
          ),
        ),
      );
    }

    Widget icon(IconData i, String tip, bool on, VoidCallback onTap) => IconButton(
      tooltip: tip,
      onPressed: onTap,
      icon: Icon(i, color: on ? Gp.ink : Gp.faint),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
      child: Row(
        children: [
          tab('원함', wantedCount, false), // F-2 P06
          tab('구매함', ownedCount, true),
          const Spacer(),
          icon(Icons.view_agenda_outlined, '목록', !guide, () => onGuide(false)), // F-3 P07
          icon(Icons.auto_awesome_mosaic_outlined, '도감', guide, () => onGuide(true)),
        ],
      ),
    );
  }
}
