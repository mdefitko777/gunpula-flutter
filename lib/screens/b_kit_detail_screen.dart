// 화면 B: 키트 상세 — 쌓기(push)로 들어옴 · 정보 | 시세 기록 탭
//
// ┌──────── 디자인 가이드 대응표: B 키트 상세 ──────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                       │ 비즈니스 명칭(한글)          │ 원칙(P번호)      │
// │ B-1  │ AppBar + BackButton                  │ 키트 상세 제목줄             │ P03 통제·자유    │
// │ B-2  │ TabBar + TabBarView                  │ 정보 · 시세 기록 탭          │ P06 재인         │
// │ B-3  │ AppImage + Text(titleLarge)          │ 박스아트 · 키트 이름         │ P02 실세계       │
// │ B-4  │ Wrap(Chip)                           │ 등급 · 스케일 · 발매일 칩    │ P08 미니멀       │
// │ B-5  │ Text                                 │ 정가(엔)                     │ P02 실세계       │
// │ B-6  │ SegmentedButton → SnackBar(되돌리기) │ 소장 상태 선택 (가짜 저장)   │ P03 · STATE      │
// │ B-7  │ OutlinedButton → push E              │ 도감에서 보기                │ P06 재인         │
// │ B-8  │ FutureBuilder(GET /prices) + ListTile│ 시세 기록 목록(예시)         │ P07 · P01 · P09  │
// │ B-9  │ Text(bodySmall 회색)                 │ 예시 시세 고지               │ P10 도움말       │
// └─────────────────────────────────────────────────────────────────────────────┘
// 전환: A·C·E·F → B 쌓기(push) · B 안에서 옆으로(tab) · B → E 쌓기(push)
// 적응형: 창 너비 720dp 이상이면 사진 왼쪽 · 정보 오른쪽 (LayoutBuilder)
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'e_unit_detail_screen.dart';

/// 이 너비 이상이면 사진과 정보를 나란히 놓는다
const detailWideBreakpoint = 720.0;

class KitDetailScreen extends StatelessWidget {
  const KitDetailScreen({
    super.key,
    required this.kit,
    this.loaders = const Loaders(),
  });

  final Kit kit;
  final Loaders loaders;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(kit.name), // B-1 P03 (뒤로 버튼 자동)
          bottom: const TabBar(
            tabs: [Tab(text: '정보'), Tab(text: '시세 기록')],
          ), // B-2 P06
        ),
        body: TabBarView(
          children: [
            KitInfoTab(kit: kit, loaders: loaders),
            PriceHistoryTab(kitId: kit.id, load: loaders.prices),
          ],
        ),
      ),
    );
  }
}

/// '정보' 탭 — 박스아트 · 기본 정보 · 소장 상태 선택
class KitInfoTab extends StatefulWidget {
  const KitInfoTab({super.key, required this.kit, required this.loaders});

  final Kit kit;
  final Loaders loaders;

  @override
  State<KitInfoTab> createState() => _KitInfoTabState();
}

class _KitInfoTabState extends State<KitInfoTab> {
  // STATE: 내 소장 상태 → B-6 선택 칸 · A-7 배지 · D-5 점등 · D-3 수집률 · E-3 · F-2 · F-3
  //   지금은 이 화면 안의 표시만 setState로 바꾼다. 다른 화면 반영·저장은 구현하지 않는다(영구 저장은 감점).
  late CollectStatus _status = widget.kit.myStatus;

  void _changeStatus(CollectStatus next) {
    final previous = _status;
    setState(() {
      _status = next;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text("'${collectLabel(next)}'(으)로 표시했습니다 — 프로토타입이라 저장되지 않습니다."),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () {
            if (!mounted) return;
            setState(() {
              _status = previous;
            });
          },
        ), // B-6 P03 바로 되돌리기
      ),
    );
  }

  void _openUnit(Unit unit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UnitDetailScreen(unit: unit, loaders: widget.loaders),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kit = widget.kit;
    final text = Theme.of(context).textTheme;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.white,
        child: AspectRatio(
          aspectRatio: 1,
          child: AppImage(kit.image, fit: BoxFit.contain),
        ),
      ),
    ); // B-3 P02

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kit.name, style: text.titleLarge), // B-3 P02
        const SizedBox(height: 2),
        Text(kit.nameJa, style: text.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Chip(label: Text(kit.grade)),
            Chip(label: Text(kit.scale)),
            Chip(label: Text('${kit.releaseDate} 발매')),
          ],
        ), // B-4 P08
        const SizedBox(height: 12),
        Text('정가 ${yen(kit.priceJpy)}', style: text.titleMedium), // B-5 P02
        Text('일본 출시 가격', style: text.bodySmall),
        const SizedBox(height: 20),
        Text('내 소장 상태', style: text.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<CollectStatus>(
          segments: const [
            ButtonSegment(
              value: CollectStatus.owned,
              label: Text('소장'),
              icon: Icon(Icons.check_circle_outline),
            ),
            ButtonSegment(
              value: CollectStatus.wanted,
              label: Text('위시'),
              icon: Icon(Icons.star_outline),
            ),
            ButtonSegment(value: CollectStatus.none, label: Text('미등록')),
          ],
          selected: {_status},
          onSelectionChanged: (selection) => _changeStatus(selection.first),
        ), // B-6 P03 STATE
        if (kit.unit != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openUnit(kit.unit!),
            icon: const Icon(Icons.grid_view_outlined),
            label: Text('도감에서 보기 · ${kit.unit!.name}'),
          ), // B-7 P06
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= detailWideBreakpoint) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: image),
                const SizedBox(width: 24),
                Expanded(flex: 6, child: info),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [image, const SizedBox(height: 16), info],
        );
      },
    );
  }
}

/// '시세 기록' 탭 — 두 번째 GET (GET /prices?kitId=…), 횟수 제한 없이 보여 준다
class PriceHistoryTab extends StatefulWidget {
  const PriceHistoryTab({super.key, required this.kitId, required this.load});

  final int kitId;
  final PricesLoader load;

  @override
  State<PriceHistoryTab> createState() => _PriceHistoryTabState();
}

class _PriceHistoryTabState extends State<PriceHistoryTab> {
  late Future<List<PricePoint>> _future = widget.load(widget.kitId);

  void _retry() {
    setState(() {
      _future = widget.load(widget.kitId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FutureBuilder<List<PricePoint>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView(label: '시세 기록을 불러오는 중…'); // B-8 P01
        }
        if (snap.hasError) {
          return ErrorView(
            title: '시세 기록을 불러오지 못했습니다.',
            message: '${snap.error}',
            onRetry: _retry,
          ); // B-8 P09
        }
        final prices = snap.data ?? const <PricePoint>[];
        if (prices.isEmpty) {
          return const EmptyView(
            message: '아직 이 키트의 시세 기록이 없습니다.',
            icon: Icons.show_chart,
          ); // B-8 P01
        }
        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text('최근 기록이 위에 있습니다 · 조회 횟수 제한 없음', style: text.bodySmall),
            ), // B-8 P07
            for (final p in prices)
              ListTile(
                leading: const Icon(Icons.sell_outlined),
                title: Text(won(p.priceKrw), style: text.titleMedium),
                subtitle: Text('${p.date} · ${p.source}'),
              ), // B-8
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '※ 예시 시세입니다. 실제 거래 가격이 아닙니다.',
                style: text.bodySmall?.copyWith(color: Colors.grey),
              ),
            ), // B-9 P10
          ],
        );
      },
    );
  }
}
