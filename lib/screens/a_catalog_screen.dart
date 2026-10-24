// 화면 A: 카탈로그 (GET /kits) — 홈 탭 구조(S)의 첫 탭
//
// ┌──────── 디자인 가이드 대응표: A 카탈로그 ───────────────────────────────────┐
// │ 번호 │ Flutter 위젯명               │ 비즈니스 명칭(한글)                      │ 원칙(P번호)     │
// │ A-1  │ AppBar + IconButton(스캔)    │ 카탈로그 제목줄 · 바코드 스캔 버튼       │ P07 효율성      │
// │ A-2  │ TextField                    │ 키트 검색창                              │ P07 효율성      │
// │ A-3  │ FilterChip × 5               │ 등급 필터(전체·HG·MG·FM·EG)             │ P06 재인        │
// │ A-4  │ Text                         │ 결과 개수                                │ P01 가시성      │
// │ A-5  │ ListView + KitCard (<600dp)  │ 키트 카드 목록                           │ P08 미니멀      │
// │ A-6  │ GridView + KitCard (≥600dp)  │ 키트 카드 격자                           │ 적응형          │
// │ A-7  │ StatusBadge                  │ 소장 상태 배지(소장·위시)                │ P04 · P01       │
// │ A-8  │ LoadingView                  │ 불러오는 중 표시                         │ P01 가시성      │
// │ A-9  │ ErrorView + FilledButton     │ 오류 안내·다시 시도                      │ P09 오류 복구   │
// │ A-10 │ EmptyView + TextButton       │ 빈 목록 · 검색 결과 없음 · 필터 초기화   │ P09 · P03       │
// └─────────────────────────────────────────────────────────────────────────────┘
// 전환: A → B 쌓기(push) · A → C 덮기(modal).  적응형: LayoutBuilder 600dp 분기(A-5 ↔ A-6).
// A-7은 KitCard 안(widgets.dart)에 있다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'b_kit_detail_screen.dart';
import 'c_scan_result_sheet.dart';

/// 이 너비 이상이면 넓은 화면 배치 (Material 3 window size class: medium ≥ 600dp)
const wideBreakpoint = 600.0;

/// 등급 필터 칩 — '전체' + db.json에 있는 등급
const gradeFilters = ['전체', 'HG', 'MG', 'FM', 'EG'];

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.loaders = const Loaders()});

  final Loaders loaders;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Kit>> _future = widget.loaders.kits();
  final _searchController = TextEditingController();

  // STATE: 검색어 · 등급 필터 → A-4 개수 · A-5/A-6 목록 — 이 화면 안에서만 setState (가짜 검색)
  String _query = '';
  String _grade = gradeFilters.first;

  /// 마지막으로 받은 목록 — 스캔 결과(임의)를 고를 때만 쓴다
  List<Kit> _loaded = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _future = widget.loaders.kits();
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _grade = gradeFilters.first;
    });
  }

  void _open(Kit kit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KitDetailScreen(kit: kit, loaders: widget.loaders),
      ),
    );
  }

  void _scan() {
    final preset = _loaded.where((k) => k.id == presetScanKitId).firstOrNull;
    ScanResultSheet.show(context, kit: preset, loaders: widget.loaders);
  }

  /// 받은 목록 안에서만 거른다 — 서버에 다시 묻지 않는 가짜 검색 결과
  bool _matches(Kit kit) {
    final q = _query.trim().toLowerCase();
    final gradeOk = _grade == gradeFilters.first || kit.grade == _grade;
    final queryOk =
        q.isEmpty ||
        kit.name.toLowerCase().contains(q) ||
        kit.nameJa.toLowerCase().contains(q);
    return gradeOk && queryOk;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카탈로그'),
        actions: [
          IconButton(
            onPressed: _scan,
            tooltip: '바코드 스캔',
            icon: const Icon(Icons.qr_code_scanner),
          ), // A-1 P07
        ],
      ),
      body: FutureBuilder<List<Kit>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(label: '키트 목록을 불러오는 중…'); // A-8 P01
          }
          if (snap.hasError) {
            return ErrorView(
              title: '키트 목록을 불러오지 못했습니다.',
              message: '${snap.error}',
              onRetry: _retry,
            ); // A-9 P09
          }
          final kits = snap.data ?? const <Kit>[];
          _loaded = kits;
          if (kits.isEmpty) {
            return const EmptyView(message: '아직 등록된 키트가 없습니다.'); // A-10 P01
          }
          final shown = kits.where(_matches).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {
                    _query = value;
                  }),
                  decoration: InputDecoration(
                    hintText: '키트 이름 검색 (예: 에어리얼, 프리덤)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '검색어 지우기',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ), // A-2 P07
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final grade in gradeFilters)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(grade),
                          selected: _grade == grade,
                          onSelected: (_) => setState(() {
                            _grade = grade;
                          }),
                        ),
                      ),
                  ],
                ),
              ), // A-3 P06
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  '키트 ${shown.length}개',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ), // A-4 P01
              Expanded(
                child: shown.isEmpty
                    ? EmptyView(
                        message: '조건에 맞는 키트가 없습니다.',
                        icon: Icons.search_off,
                        action: TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('필터 초기화'),
                        ),
                      ) // A-10 P09 P03
                    : LayoutBuilder(
                        // 적응형: 기기 종류가 아니라 "이 영역의 너비"로 나눈다
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= wideBreakpoint) {
                            return GridView.builder(
                              // A-6 넓은 화면: 카드 격자
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 240,
                                    mainAxisExtent: 320,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: shown.length,
                              itemBuilder: (context, i) => KitCard(
                                shown[i],
                                vertical: true,
                                onTap: () => _open(shown[i]),
                              ),
                            );
                          }
                          return ListView.builder(
                            // A-5 P08 폰: 카드 목록
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: shown.length,
                            itemBuilder: (context, i) =>
                                KitCard(shown[i], onTap: () => _open(shown[i])),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
