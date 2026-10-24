// 화면 S: 홈 탭 구조 — 첫 화면. 옆으로(탭): A 카탈로그 | D 도감 | F 내 컬렉션
//
// ┌──────── 디자인 가이드 대응표: S 홈 탭 구조 ─────────────────────────────────┐
// │ 번호 │ Flutter 위젯명              │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ S-3  │ NavigationBar (<840dp)      │ 하단 탭: 카탈로그 · 도감 · 내 컬렉션   │ P06 재인      │
// │ S-4  │ NavigationRail (≥840dp)     │ 측면 탭                                │ 적응형 · P04  │
// │ S-5  │ IndexedStack                │ 탭 상태 유지                           │ P03 통제·자유 │
// └─────────────────────────────────────────────────────────────────────────────┘
// S-1 · S-2(앱 이름 · 상태 색)는 main.dart · widgets.dart(CollectColors)에 있다.
// 적응형: LayoutBuilder 840dp 분기 (Material 3 window size class: expanded ≥ 840dp).
import 'package:flutter/material.dart';

import '../api.dart';
import 'a_catalog_screen.dart';
import 'd_picturebook_screen.dart';
import 'f_collection_screen.dart';

/// 이 너비 이상이면 하단 탭 대신 측면 탭
const railBreakpoint = 840.0;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.loaders = const Loaders()});

  final Loaders loaders;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // STATE: 현재 탭 → S-5 보이는 화면 — 이 화면 안에서만 setState
  int _index = 0;

  static const _tabs = [
    (label: '카탈로그', icon: Icons.view_list_outlined, selected: Icons.view_list),
    (label: '도감', icon: Icons.grid_view_outlined, selected: Icons.grid_view),
    (label: '내 컬렉션', icon: Icons.inventory_2_outlined, selected: Icons.inventory_2),
  ];

  void _select(int index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = IndexedStack(
      index: _index,
      children: [
        CatalogScreen(loaders: widget.loaders),
        PicturebookScreen(loaders: widget.loaders),
        CollectionScreen(loaders: widget.loaders),
      ],
    ); // S-5 P03 탭을 바꿔도 각 화면의 스크롤·필터가 그대로

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= railBreakpoint) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final t in _tabs)
                      NavigationRailDestination(
                        icon: Icon(t.icon),
                        selectedIcon: Icon(t.selected),
                        label: Text(t.label),
                      ),
                  ],
                ), // S-4 넓은 화면 P04
                const VerticalDivider(width: 1),
                Expanded(child: pages),
              ],
            ),
          );
        }
        return Scaffold(
          body: pages,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final t in _tabs)
                NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.selected),
                  label: t.label,
                ),
            ],
          ), // S-3 P06 아이콘 + 글자 항상 표시
        );
      },
    );
  }
}
