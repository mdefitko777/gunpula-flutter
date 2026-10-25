// 화면 D: 상품 상세 — 공식 사진 · 정가 · 정확한 버전 · 출처, 그리고 원함/구매함
//
// ┌──────── 디자인 가이드 대응표: D 상품 상세 ─────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ D-1  │ RaisedCircleButton(‹)              │ 뒤로 (보던 화면 그대로)                 │ P03           │
// │ D-2  │ PageView + 점 표시                 │ 공식 사진 (여러 장 넘기기)              │ P02 · P08     │
// │ D-3  │ Text(분류 · 작품 · 라인)            │ 어디에 속한 상품인지                    │ P01 · P06     │
// │ D-4  │ Text(제목) + 일본어 원래 이름        │ 상품명 (공식 사이트 검색용 원문)        │ P02           │
// │ D-5  │ Text(¥) + 발매일 + 한정 표시         │ 일본 정가 · 발매 · 한정/PB              │ P02 · P01     │
// │ D-6  │ 두 버튼 + SnackBar(되돌리기)         │ 원함 · 구매함 (가짜 저장)               │ P03 · P01     │
// │ D-7  │ 수량 − n +                         │ 원하는 수량 (원함일 때만)               │ P05           │
// │ D-8  │ SectionHeader + 표                  │ 공식 정보 (출처 링크 포함)              │ P02 · P10     │
// │ D-9  │ 추정가 2칸 / 플랫폼 검색 칩          │ 시장가 (없으면 이유 + 찾아볼 곳)        │ P01 · P09     │
// │ D-10 │ 가로 ProductTile (GET /kits)        │ 같은 작품의 다른 상품                   │ P06           │
// │ D-11 │ TextButton → showDialog(확인)       │ 정보 오류 제보 (보내기 전 확인)         │ P05 · P09     │
// │ D-12 │ LayoutBuilder ≥720dp                │ 넓은 화면: 사진 왼쪽 · 정보 오른쪽      │ 적응형        │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: 홈 · 검색 · AI 후보에서 쌓기(push, 오른쪽에서). 탭 바를 덮는 전체 화면.
// 현행 앱 문제: 상세에 내부 코드(GUNDAM_MERCH)·"보완 필요"·수동 수정 폼이 그대로 보임
//              → v2는 사용자에게 필요한 정가 · 버전 · 출처만, 수정은 "제보" 한 줄로.
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';

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
  late CollectStatus _status = widget.kit.status;
  late int _qty = widget.kit.wantedQty < 1 ? 1 : widget.kit.wantedQty;
  late final Future<List<Kit>> _related = widget.loaders.kits([widget.kit.franchiseId]);

  Kit get k => widget.kit;

  /// D-6 원함 · 구매함 — 같은 버튼을 다시 누르면 해제. 실제 저장 없이 SnackBar로 알린다.
  void _toggle(CollectStatus target) {
    final before = _status;
    final after = _status == target ? CollectStatus.none : target;
    setState(() => _status = after); // STATE: 수집 상태 → 버튼 채움 · 수량 줄 표시
    final msg = switch (after) {
      CollectStatus.wanted => '원함에 담았어요',
      CollectStatus.owned => '구매함으로 옮겼어요',
      CollectStatus.none => before == CollectStatus.owned ? '구매함에서 뺐어요' : '원함에서 뺐어요',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          action: SnackBarAction(
            label: '되돌리기', // P03
            onPressed: () => setState(() => _status = before),
          ),
        ),
      );
  }

  Future<void> _report() async {
    final ok = await showDialog<bool>( // D-11 P05
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
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제보를 받았어요. 확인되면 알려 드릴게요')),
      );
    }
  }

  void _external(String where) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$where 은(는) 프로토타입에서 열지 않아요')),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= detailWideBreakpoint; // D-12
          final gallery = _Gallery(images: k.gallery.isEmpty ? [k.image] : k.gallery, label: k.line);
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
    final channel = channelOf(k.franchiseId).label;
    return [
      // 기본 정보
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [channel, k.series, k.line].where((s) => s.isNotEmpty).join(' · '), // D-3 P06
              style: const TextStyle(fontSize: 12.5, color: Gp.muted, letterSpacing: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              k.name, // D-4 P02
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
            ),
            if (k.nameJa.isNotEmpty && k.nameJa != k.name) ...[
              const SizedBox(height: 4),
              SelectableText(k.nameJa, style: const TextStyle(fontSize: 12.5, color: Gp.faint)),
            ],
            const SizedBox(height: 16),
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
                  child: Text('발매 ${k.date}', style: const TextStyle(color: Gp.muted)),
                ),
                const Spacer(),
                if (k.pb) const _Badge('PB'),
                if (k.limited) const _Badge('한정'),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatusButton( // D-6 P03
                    label: '원함',
                    icon: Icons.bookmark_border,
                    activeIcon: Icons.bookmark,
                    active: _status == CollectStatus.wanted,
                    onTap: () => _toggle(CollectStatus.wanted),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusButton(
                    label: '구매함',
                    icon: Icons.check_circle_outline,
                    activeIcon: Icons.check_circle,
                    active: _status == CollectStatus.owned,
                    onTap: () => _toggle(CollectStatus.owned),
                  ),
                ),
              ],
            ),
            if (_status == CollectStatus.wanted) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('원하는 수량', style: TextStyle(color: Gp.muted)),
                  const Spacer(),
                  _Stepper( // D-7 P05
                    value: _qty,
                    onChanged: (v) => setState(() => _qty = v), // STATE: 수량 → 숫자
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      // 공식 정보
      _Panel(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('공식 정보'), // D-8 P02
            _InfoRow('분류', channel),
            _InfoRow('작품', k.series),
            _InfoRow('제품 라인', k.line),
            _InfoRow('상품 유형', k.type),
            _InfoRow('스케일', k.scale),
            _InfoRow('발매', k.date),
            _InfoRow('정가', yen(k.priceJpy)),
            _InfoRow('판매', k.pb ? '프리미엄 반다이 한정' : (k.limited ? '한정' : '일반 판매')),
            InkWell(
              onTap: () => _external('공식 상품 페이지'), // P10
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text('출처', style: TextStyle(color: Gp.muted, fontSize: 13.5)),
                    ),
                    Expanded(
                      child: Text(
                        '공식 상품 페이지',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 18, color: Gp.muted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 시장가
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('시장가', padding: EdgeInsets.fromLTRB(0, 0, 0, 12)), // D-9 P01
            if (k.market case final m?) ...[
              Row(
                children: [
                  Expanded(child: _Estimate('일반 추정', won(m.normalKrw))),
                  const SizedBox(width: 10),
                  Expanded(child: _Estimate('보수 추정', won(m.conservativeKrw))),
                ],
              ),
              const SizedBox(height: 8),
              Text('국내 중고·신품 거래 ${m.samples}건 기준 예시값',
                  style: const TextStyle(fontSize: 12, color: Gp.faint)),
            ] else
              const Text(
                '아직 모인 가격 샘플이 없어요. 아래에서 지금 가격을 직접 찾아보세요.', // P09
                style: TextStyle(color: Gp.muted),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in marketPlatforms)
                  ActionChip(
                    avatar: const Icon(Icons.search, size: 16),
                    label: Text('$p에서 찾기'),
                    onPressed: () => _external(p),
                    backgroundColor: Gp.panel,
                    side: const BorderSide(color: Gp.line),
                    shape: const StadiumBorder(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
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
              return Padding(
                padding: const EdgeInsets.all(16),
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
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Center(
          child: TextButton.icon(
            onPressed: _report, // D-11 P09
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
  const _Panel({required this.child, this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 18)});
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

/// 원함 · 구매함 버튼 — 선택되면 검정 채움 (색이 아니라 채움으로 상태 표시)
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            color: active ? Gp.ink : Gp.panel,
            borderRadius: BorderRadius.circular(Gp.radius),
            border: Border.all(color: active ? Gp.ink : Gp.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(active ? activeIcon : icon, size: 19, color: active ? Colors.white : Gp.ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Gp.ink,
                ),
              ),
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
      onPressed: next == null ? null : () => onChanged(next),
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(side: const BorderSide(color: Gp.line)),
    );
    return Row(
      children: [
        btn(Icons.remove, '줄이기', value > 1 ? value - 1 : null), // P05 1 아래로는 못 내림
        SizedBox(
          width: 36,
          child: Text('$value', textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ),
        btn(Icons.add, '늘리기', value < 99 ? value + 1 : null),
      ],
    );
  }
}

/// 공식 정보 표 한 줄 (값이 비면 줄 자체를 숨김)
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Gp.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: Gp.muted, fontSize: 13.5)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14.5))),
        ],
      ),
    );
  }
}

/// 시장가 한 칸
class _Estimate extends StatelessWidget {
  const _Estimate(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Gp.bg,
        borderRadius: BorderRadius.circular(Gp.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Gp.muted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
