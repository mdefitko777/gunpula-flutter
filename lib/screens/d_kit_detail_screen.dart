// 화면 D: 상품 상세 — 공식 사진 · 정가 · 정확한 버전 · 출처, 그리고 원함/구매함
//
// ┌──────── 디자인 가이드 대응표: D 상품 상세 ─────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ D-1  │ RaisedCircleButton(‹)              │ 뒤로 (보던 화면 그대로)                 │ P03           │
// │ D-2  │ PageView + 점 표시                 │ 공식 사진 (여러 장 넘기기)              │ P02 · P08     │
// │ D-4  │ 제목 + 일본어 원래 이름              │ 상품명 (공식 사이트 검색용 원문)        │ P02           │
// │ D-5  │ Text(¥) + 발매일 + 한정 표시         │ 일본 정가 · 발매 · 한정/PB              │ P02 · P01     │
// │ D-5b │ 정가 아래 시세 한 줄 (누르면 시장가로) │ 정가 ↔ 국내 시세 비교                  │ P01 · P07     │
// │ D-6  │ 하단 고정 바: 원함 · 구매함           │ 원함 · 구매함 (따로 켜고 끔, 가짜 저장)  │ P03 · P07     │
// │ D-7  │ "원함 ×n" → 바텀 시트 − n + · 해제   │ 원하는 수량 (원함일 때만)               │ P05 · P03     │
// │ D-8  │ 가로 스크롤 요약 줄 → 바텀 시트       │ 공식 정보 (요약 → 전체 표)              │ P08 · P06     │
// │ D-9  │ 시세 카드: 가격 범위 · 플랫폼 3칸     │ 시장가 (없으면 이유 + 찾아볼 곳)        │ P01 · P08     │
// │ D-10 │ 가로 ProductTile (GET /kits)        │ 같은 작품의 다른 상품                   │ P06           │
// │ D-11 │ 세로 사진 목록                      │ 상품 상세 (공식 사진 전부)              │ P02           │
// │ D-12 │ TextButton → showDialog(확인)       │ 정보 오류 제보 (보내기 전 확인)         │ P05 · P09     │
// │ D-13 │ LayoutBuilder ≥720dp                │ 넓은 화면: 사진 왼쪽 · 정보 오른쪽      │ 적응형        │
// │ D-14 │ 하단 고정 바 왼쪽: 복사 · 공식        │ 상품명 복사 · 공식 상품 페이지(출처)    │ P07 · P10     │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: 홈 · 검색 · AI 후보에서 쌓기(push, 오른쪽에서). 공식 정보 · 원하는 수량 → 덮기(바텀 시트).
// 원함 · 구매함은 화면 아래에 고정 — 길게 내려 읽어도 바로 누를 수 있다 (쇼핑 앱 상세와 같은 위치).
// 현행 앱 문제: 상세에 내부 코드(GUNDAM_MERCH)·"보완 필요"·수동 수정 폼이 그대로 보임
//              → v2는 사용자에게 필요한 정가 · 버전 · 출처만, 수정은 "제보" 한 줄로.
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../api.dart';
import '../channels.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// 상품 상세 열기 — 어느 화면에서든 같은 방식(오른쪽에서 밀려 들어옴)
void openKitDetail(BuildContext context, Kit kit, {Loaders loaders = const Loaders()}) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoPageRoute<void>(builder: (_) => KitDetailScreen(kit: kit, loaders: loaders)),
  );
}

/// 넓은 화면 기준 (사진 왼쪽 · 정보 오른쪽)
const detailWideBreakpoint = 720.0;

/// 시세를 찾아볼 국내 플랫폼 (프로토타입: 외부 링크는 열지 않는다)
const marketPlatforms = ['네이버쇼핑', '번개장터', '중고나라'];

class KitDetailScreen extends StatefulWidget {
  const KitDetailScreen({super.key, required this.kit, this.loaders = const Loaders()});

  final Kit kit;
  final Loaders loaders;

  @override
  State<KitDetailScreen> createState() => _KitDetailScreenState();
}

class _KitDetailScreenState extends State<KitDetailScreen> {
  // 원함 · 구매함은 따로 켜고 끈다 (둘 다 켤 수 있음)
  late bool _wanted = widget.kit.status == CollectStatus.wanted;
  late bool _owned = widget.kit.status == CollectStatus.owned;
  late int _qty = widget.kit.wantedQty < 1 ? 1 : widget.kit.wantedQty;
  late final Future<List<Kit>> _related = widget.loaders.kits([widget.kit.franchiseId]);

  Kit get k => widget.kit;

  /// 시세 한 줄을 누르면 이 위치로 내려간다
  final _marketKey = GlobalKey();

  void _scrollToMarket() {
    final ctx = _marketKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), alignment: 0.1);
    }
  }

  /// 원함 버튼: 꺼져 있으면 담기, 켜져 있으면 수량 시트(여기서 해제도)
  void _tapWanted() {
    if (!_wanted) {
      _toggleWanted();
      return;
    }
    showModalBottomSheet<void>( // D-7 덮기
      context: context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('원하는 수량',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Center(
                  child: _Stepper( // P05
                    value: _qty,
                    onChanged: (v) {
                      setState(() => _qty = v); // STATE: 수량 → "원함 ×n"
                      setSheet(() {});
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    _toggleWanted(); // 해제 + 되돌리기 토스트
                  },
                  child: const Text('원함에서 빼기', style: TextStyle(color: Gp.muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _toggleWanted() {
    final before = _wanted;
    setState(() => _wanted = !before); // STATE: 원함 → 버튼 · 수량 줄
    showToast(context, before ? '원함에서 뺐어요' : '원함에 담았어요',
        onUndo: () => setState(() => _wanted = before));
  }

  void _toggleOwned() {
    final before = _owned;
    setState(() => _owned = !before); // STATE: 구매함 → 버튼
    showToast(context, before ? '구매함에서 뺐어요' : '구매함에 넣었어요',
        onUndo: () => setState(() => _owned = before));
  }

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(context, '$what을(를) 복사했어요');
  }

  void _external(String where) => showToast(context, '$where 은(는) 프로토타입에서 열지 않아요');

  Future<void> _report() async {
    final ok = await showDialog<bool>( // D-12 P05
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정보 오류 제보'),
        content: Text('「${k.name}」의 이름 · 가격 · 발매일 중 틀린 곳을 운영자에게 알릴까요?\n'
            '보낸 뒤에는 운영자가 확인할 때까지 그대로 보여요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('제보하기')),
        ],
      ),
    );
    if (ok == true && mounted) showToast(context, '제보를 받았어요. 확인되면 알려 드릴게요');
  }

  /// 공식 정보 (요약 줄과 바텀 시트가 같은 목록을 쓴다)
  List<(String, String)> get _specs => [
    ('판매', k.pb ? 'PB 한정' : (k.limited ? '한정' : '일반 판매')),
    ('분류', channelOf(k.franchiseId).label),
    ('작품', k.series),
    ('제품 라인', k.line),
    ('상품 유형', k.type),
    ('스케일', k.scale),
    ('발매', k.date),
    ('정가', yen(k.priceJpy)),
  ].where((e) => e.$2.isNotEmpty).toList();

  void _openSpecs() {
    showModalBottomSheet<void>( // D-8 덮기
      context: context,
      isScrollControlled: true,
      builder: (context) => _SpecSheet(specs: _specs),
    );
  }

  List<String> get _images => k.gallery.isEmpty ? [k.image] : k.gallery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _BottomActions( // D-6 · D-14
        wanted: _wanted,
        owned: _owned,
        qty: _qty,
        onWanted: _tapWanted,
        onOwned: _toggleOwned,
        onCopy: () => _copy(k.name, '상품명'),
        onOfficial: () => _external('공식 상품 페이지'),
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= detailWideBreakpoint; // D-13
          final gallery = _Gallery(images: _images, label: k.line);
          final info = _info(context);
          return Stack(
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ColoredBox(color: Gp.panel, child: SafeArea(child: Center(child: gallery))),
                    ),
                    SizedBox(
                      width: (box.maxWidth * 0.46).clamp(360.0, 560.0),
                      child: ListView(padding: const EdgeInsets.only(top: 56), children: info),
                    ),
                  ],
                )
              else
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ColoredBox(color: Gp.panel, child: SafeArea(bottom: false, child: gallery)),
                    ...info,
                  ],
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: RaisedCircleButton( // D-1 P03
                    tooltip: '뒤로',
                    size: 40,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Gp.ink),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _info(BuildContext context) {
    return [
      // 기본 정보: 이름 → 정가 → 시세 한 줄
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              k.name, // D-4 P02
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
            ),
            if (k.nameJa.isNotEmpty && k.nameJa != k.name) ...[
              const SizedBox(height: 3),
              Text(k.nameJa, style: const TextStyle(fontSize: 12.5, color: Gp.faint)),
            ],
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  yen(k.priceJpy), // D-5 P02
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('발매 ${k.date}', style: const TextStyle(color: Gp.muted, fontSize: 13)),
                ),
                const Spacer(),
                if (k.limited) const _Badge('한정'),
                if (k.pb) const _Badge('PB'),
              ],
            ),
            const SizedBox(height: 10),
            // D-5b 정가 바로 아래 국내 시세 — 누르면 시장가 카드로 내려감
            InkWell(
              onTap: _scrollToMarket,
              borderRadius: BorderRadius.circular(Gp.radius),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                decoration: BoxDecoration(
                  color: Gp.bg,
                  borderRadius: BorderRadius.circular(Gp.radius),
                ),
                child: Row(
                  children: [
                    const Text('국내 시세', style: TextStyle(fontSize: 13, color: Gp.muted)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        switch (k.market) {
                          final m? => '${won(m.normalKrw).replaceAll('원', '')} ~ ${won(m.conservativeKrw)}',
                          null => '아직 모인 시세가 없어요',
                        },
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: k.market == null ? FontWeight.w400 : FontWeight.w600,
                          color: k.market == null ? Gp.muted : Gp.ink,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: Gp.muted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 공식 정보: 가로 요약 줄 → 누르면 전체 표
      _Panel(
        padding: EdgeInsets.zero,
        child: _SpecStrip(specs: _specs, onTap: _openSpecs), // D-8 P08
      ),
      // 시장가: 한 덩어리 (가격 범위 → 플랫폼 3칸), 겹 상자 없이
      _Panel(
        key: _marketKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('시장가', padding: EdgeInsets.fromLTRB(0, 0, 0, 10)), // D-9 P01
            _MarketCard(market: k.market, onOpen: _external),
          ],
        ),
      ),
      // 같은 작품의 다른 상품
      _Panel(
        padding: const EdgeInsets.only(bottom: 18),
        child: FutureBuilder<List<Kit>>(
          future: _related,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(height: 120, child: LoadingView()); // P01
            }
            if (snap.hasError) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('관련 상품을 불러오지 못했어요', style: TextStyle(color: Gp.muted)),
              );
            }
            final same = snap.data!.where((r) => r.id != k.id && r.series == k.series).toList();
            final rest = same.isNotEmpty ? same : snap.data!.where((r) => r.id != k.id).toList();
            if (rest.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(same.isNotEmpty ? '같은 작품의 다른 상품' : '같은 채널의 다른 상품'), // D-10 P06
                SizedBox(
                  height: 148 + 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rest.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => ProductTile(
                      image: rest[i].image,
                      title: rest[i].name,
                      imageWidth: 148,
                      onTap: () => openKitDetail(context, rest[i], loaders: widget.loaders),
                      onAdd: () => showAddSoon(context),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // 상품 상세: 공식 사진을 세로로 전부
      _Panel(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('상품 상세'), // D-11 P02
            for (final img in _images)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Gp.radius),
                  child: AppImage(img, fit: BoxFit.fitWidth, placeholder: k.line),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Center(
          child: TextButton.icon(
            onPressed: _report, // D-12 P09
            icon: const Icon(Icons.flag_outlined, size: 18, color: Gp.muted),
            label: const Text('정보가 틀렸나요? 제보하기', style: TextStyle(color: Gp.muted)),
          ),
        ),
      ),
    ];
  }
}

/// 흰 띠 섹션 (홈과 같은 층 구분: 위 회백색 틈 10)
class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 18),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ColoredBox(
        color: Gp.panel,
        child: SizedBox(width: double.infinity, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// D-2 공식 사진 넘기기 (정사각형, 전체가 보이게 contain)
class _Gallery extends StatefulWidget {
  const _Gallery({required this.images, required this.label});
  final List<String> images;
  final String label;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _page = i), // STATE: 사진 번호 → 점
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 28),
              child: AppImage(widget.images[i], fit: BoxFit.contain, placeholder: widget.label),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
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
      ),
    );
  }
}

/// D-8 공식 정보 요약 줄 — 아이콘 + (값 / 이름) 칸들이 가로로 넘어가고, 누르면 전체 표
class _SpecStrip extends StatelessWidget {
  const _SpecStrip({required this.specs, required this.onTap});
  final List<(String, String)> specs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 6),
              child: Icon(Icons.assignment_outlined, size: 22, color: Gp.ink),
            ),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: specs.length,
                separatorBuilder: (_, _) => const VerticalDivider(width: 1, indent: 18, endIndent: 18),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(specs[i].$2, style: const TextStyle(fontSize: 14.5)),
                      const SizedBox(height: 3),
                      Text(specs[i].$1, style: const TextStyle(fontSize: 12, color: Gp.muted)),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: Gp.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// D-8 공식 정보 전체 (바텀 시트): 위 4칸은 회색 카드 2열, 나머지는 줄
class _SpecSheet extends StatelessWidget {
  const _SpecSheet({required this.specs});
  final List<(String, String)> specs;

  @override
  Widget build(BuildContext context) {
    final top = specs.take(4).toList();
    final rest = specs.skip(4).toList();
    Widget cell((String, String) e) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.$1, style: const TextStyle(fontSize: 13, color: Gp.muted)),
          const SizedBox(height: 6),
          Text(e.$2, style: const TextStyle(fontSize: 15.5)),
        ],
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                '공식 정보',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(color: Gp.bg, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  for (var r = 0; r < top.length; r += 2)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cell(top[r])),
                          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                          Expanded(child: r + 1 < top.length ? cell(top[r + 1]) : const SizedBox()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final e in rest)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(e.$1, style: const TextStyle(color: Gp.muted))),
                    Expanded(child: Text(e.$2, style: const TextStyle(fontSize: 15))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Gp.ink),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}

/// 원함 · 구매함 버튼 — 켜지면 옅은 하늘색 바탕 + 브랜드 색 테두리·아이콘 (검정 채움 대신)
class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        // 하단 고정 바의 알약 버튼
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? Gp.accent.withValues(alpha: 0.07) : Gp.panel,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: active ? Gp.accent : Gp.line, width: active ? 1.3 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(active ? activeIcon : icon, size: 18, color: active ? Gp.accent : Gp.ink),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 수량 − n + (1–99)
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String tip, int? next) => IconButton(
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      onPressed: next == null ? null : () => onChanged(next),
      icon: Icon(icon, size: 16),
      style: IconButton.styleFrom(side: const BorderSide(color: Gp.line)),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove, '줄이기', value > 1 ? value - 1 : null), // P05 1 아래로는 못 내림
        SizedBox(
          width: 30,
          child: Text('$value', textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
        btn(Icons.add, '늘리기', value < 99 ? value + 1 : null),
      ],
    );
  }
}

/// D-9 시세 카드 — 가격 범위 → (가는 선) → 플랫폼 3칸
class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.market, required this.onOpen});

  final Market? market;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final m = market;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (m == null)
          const Text(
            '아직 모인 시세가 없어요 · 아래에서 지금 가격을 찾아보세요', // P09
            style: TextStyle(color: Gp.muted),
          )
        else ...[
          Text(
            '${won(m.normalKrw).replaceAll('원', '')} ~ ${won(m.conservativeKrw)}',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text('국내 시세 · 거래 ${m.samples}건', style: const TextStyle(fontSize: 12.5, color: Gp.muted)),
        ],
        const SizedBox(height: 12),
        const Divider(height: 1),
        IntrinsicHeight(
          child: Row(
            children: [
              for (final (i, p) in marketPlatforms.indexed) ...[
                if (i > 0) const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => onOpen(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 2),
                          const Icon(Icons.north_east, size: 12, color: Gp.muted),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// D-6 · D-14 하단 고정 바 — 왼쪽: 복사 · 공식 / 오른쪽: 원함 · 구매함
class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.wanted,
    required this.owned,
    required this.qty,
    required this.onWanted,
    required this.onOwned,
    required this.onCopy,
    required this.onOfficial,
  });

  final bool wanted;
  final bool owned;
  final int qty;
  final VoidCallback onWanted;
  final VoidCallback onOwned;
  final VoidCallback onCopy;
  final VoidCallback onOfficial;

  @override
  Widget build(BuildContext context) {
    Widget small(IconData icon, String label, VoidCallback onTap) => InkResponse(
      onTap: onTap,
      radius: 28,
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: Gp.ink),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10.5, color: Gp.muted)),
          ],
        ),
      ),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Gp.panel,
        border: Border(top: BorderSide(color: Gp.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                small(Icons.content_copy_rounded, '복사', onCopy), // P07
                small(Icons.north_east, '공식', onOfficial), // P10 출처
                const SizedBox(width: 6),
                Expanded(
                  child: _StatusButton( // P03
                    label: wanted ? '원함 ×$qty' : '원함',
                    icon: Icons.bookmark_border,
                    activeIcon: Icons.bookmark,
                    active: wanted,
                    onTap: onWanted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusButton(
                    label: '구매함',
                    icon: Icons.check_circle_outline,
                    activeIcon: Icons.check_circle,
                    active: owned,
                    onTap: onOwned,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
