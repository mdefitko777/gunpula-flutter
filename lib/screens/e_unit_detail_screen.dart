// 화면 E: 기체 상세 — 도감 칸(D-4) 또는 키트 상세의 "도감에서 보기"(B-7)에서 쌓기(push)
//
// ┌──────── 디자인 가이드 대응표: E 기체 상세 ──────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)          │ 원칙(P번호)     │
// │ E-1  │ AppBar + BackButton               │ 기체 상세 제목줄             │ P03 통제·자유   │
// │ E-2  │ AppImage(아이콘) + Text           │ 기체 아이콘 · 이름 · 작품    │ P02 실세계      │
// │ E-3  │ StatusBadge                       │ 점등 상태                    │ P04 일관성      │
// │ E-4  │ ListView + KitCard                │ 대응 키트 목록               │ P06 재인        │
// │ E-5  │ LoadingView                       │ 불러오는 중 표시             │ P01 가시성      │
// │ E-6  │ ErrorView + FilledButton          │ 오류 안내·다시 시도          │ P09 오류 복구   │
// │ E-7  │ EmptyView + FilledButton.tonal    │ 누락 키트 제보(가짜)         │ P09 · P10       │
// │ E-8  │ showDialog(AlertDialog) → SnackBar│ 제보 확인 대화상자           │ P05 오류 예방   │
// └─────────────────────────────────────────────────────────────────────────────┘
// 전환: D·B → E 쌓기(push) · E → B 쌓기(push) · E → 제보 확인 덮기(dialog)
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'b_kit_detail_screen.dart';

class UnitDetailScreen extends StatefulWidget {
  const UnitDetailScreen({
    super.key,
    required this.unit,
    this.seriesName,
    this.loaders = const Loaders(),
  });

  final Unit unit;

  /// 도감에서 들어오면 작품 이름을 같이 받는다 (키트 상세에서 오면 없음)
  final String? seriesName;
  final Loaders loaders;

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  late Future<List<Kit>> _future = widget.loaders.kitsOfUnit(widget.unit.id);

  void _retry() {
    setState(() {
      _future = widget.loaders.kitsOfUnit(widget.unit.id);
    });
  }

  void _openKit(Kit kit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KitDetailScreen(kit: kit, loaders: widget.loaders),
      ),
    );
  }

  // STATE: 누락 키트 제보 목록 → (보여 줄 화면 없음) — 서버로 보내지 않는다(POST는 감점).
  Future<void> _confirmReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('누락 키트 제보'),
        content: Text(
          "'${widget.unit.name}'의 키트가 빠져 있다고 제보할까요?\n"
          '(프로토타입: 실제로 전송되지 않습니다)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('제보하기'),
          ),
        ],
      ),
    ); // E-8 P05 보내기 전에 한 번 확인
    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('제보가 접수된 것처럼 보이는 예시입니다 — 전송하지 않았습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final text = Theme.of(context).textTheme;
    final statusColor = CollectColors.of(unit.status);

    final header = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor ?? Theme.of(context).colorScheme.outlineVariant,
                width: 3,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: AppImage(unit.icon),
          ), // E-2 P02
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.name, style: text.titleLarge), // E-2 P02
                Text(unit.nameEn, style: text.bodySmall),
                if (widget.seriesName != null)
                  Text(widget.seriesName!, style: text.bodySmall),
                const SizedBox(height: 8),
                StatusBadge(unit.status, noneLabel: '미보유'), // E-3 P04
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(unit.name)), // E-1 P03
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('대응 키트', style: text.titleSmall),
          ),
          Expanded(
            child: FutureBuilder<List<Kit>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingView(label: '대응 키트를 불러오는 중…'); // E-5 P01
                }
                if (snap.hasError) {
                  return ErrorView(
                    title: '대응 키트를 불러오지 못했습니다.',
                    message: '${snap.error}',
                    onRetry: _retry,
                  ); // E-6 P09
                }
                final kits = snap.data ?? const <Kit>[];
                if (kits.isEmpty) {
                  return EmptyView(
                    message: '이 기체로 등록된 키트가 아직 없습니다.\n빠진 키트가 있다면 알려 주세요.',
                    icon: Icons.search_off,
                    action: FilledButton.tonalIcon(
                      onPressed: _confirmReport,
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('누락 키트 제보'),
                    ),
                  ); // E-7 P09 P10
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: kits.length,
                  itemBuilder: (context, i) =>
                      KitCard(kits[i], onTap: () => _openKit(kits[i])),
                ); // E-4 P06
              },
            ),
          ),
        ],
      ),
    );
  }
}
