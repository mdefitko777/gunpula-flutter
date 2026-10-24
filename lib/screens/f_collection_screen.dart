// 화면 F: 내 컬렉션 (GET /kits) — 홈 탭 구조(S)의 세 번째 탭 · 소장 | 위시 탭
//
// ┌──────── 디자인 가이드 대응표: F 내 컬렉션 ──────────────────────────────────┐
// │ 번호 │ Flutter 위젯명            │ 비즈니스 명칭(한글)          │ 원칙(P번호)     │
// │ F-1  │ AppBar + TabBar           │ 내 컬렉션 · 소장 / 위시 탭   │ P06 재인        │
// │ F-2  │ Row(StatusBadge)          │ 소장 n · 위시 n 요약         │ P01 가시성      │
// │ F-3  │ ListView + KitCard        │ 소장 · 위시 목록             │ P08 · P04       │
// │ F-4  │ LoadingView               │ 불러오는 중 표시             │ P01 가시성      │
// │ F-5  │ ErrorView + FilledButton  │ 오류 안내·다시 시도          │ P09 오류 복구   │
// │ F-6  │ EmptyView                 │ 빈 목록 안내                 │ P01 · P10       │
// └─────────────────────────────────────────────────────────────────────────────┘
// 전환: F 안에서 옆으로(tab) · F → B 쌓기(push).  적응형: 600dp 이상이면 가운데 720dp 폭.
// 소장 · 위시 목록은 받은 키트를 상태별로 나눠 보여 줄 뿐이다(금액 합계 등 계산 없음).
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'b_kit_detail_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, this.loaders = const Loaders()});

  final Loaders loaders;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late Future<List<Kit>> _future = widget.loaders.kits();

  void _retry() {
    setState(() {
      _future = widget.loaders.kits();
    });
  }

  void _open(Kit kit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KitDetailScreen(kit: kit, loaders: widget.loaders),
      ),
    );
  }

  Widget _list(List<Kit> kits, String emptyMessage) {
    if (kits.isEmpty) {
      return EmptyView(message: emptyMessage); // F-6 P01 P10
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: kits.length,
      itemBuilder: (context, i) => KitCard(kits[i], onTap: () => _open(kits[i])),
    ); // F-3 P08 P04
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('내 컬렉션'),
          bottom: const TabBar(tabs: [Tab(text: '소장'), Tab(text: '위시')]),
        ), // F-1 P06
        body: FutureBuilder<List<Kit>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingView(label: '내 컬렉션을 불러오는 중…'); // F-4 P01
            }
            if (snap.hasError) {
              return ErrorView(
                title: '내 컬렉션을 불러오지 못했습니다.',
                message: '${snap.error}',
                onRetry: _retry,
              ); // F-5 P09
            }
            final kits = snap.data ?? const <Kit>[];
            final owned = kits.where((k) => k.myStatus == CollectStatus.owned).toList();
            final wanted = kits.where((k) => k.myStatus == CollectStatus.wanted).toList();
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.check_circle, color: CollectColors.owned),
                        label: Text('소장 ${owned.length}'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.star, color: CollectColors.wanted),
                        label: Text('위시 ${wanted.length}'),
                      ),
                    ],
                  ),
                ), // F-2 P01
                Expanded(
                  child: TabBarView(
                    children: [
                      _list(owned, '아직 소장한 키트가 없습니다.\n카탈로그 → 키트 상세에서 소장 상태를 바꿔 보세요.'),
                      _list(wanted, '아직 위시에 넣은 키트가 없습니다.\n카탈로그 → 키트 상세에서 위시로 표시해 보세요.'),
                    ],
                  ),
                ),
              ],
            );
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) return content;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: content,
                  ),
                ); // 적응형: 넓은 화면은 가운데 720dp
              },
            );
          },
        ),
      ),
    );
  }
}
