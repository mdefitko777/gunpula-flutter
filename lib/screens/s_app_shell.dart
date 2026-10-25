// 화면 S: 앱 셸 — 위: 아바타 + 화면 제목 / 아래: 홈 · 검색 · (+) · 캘린더 · 컬렉션
//
// ┌──────── 디자인 가이드 대응표: S 앱 셸 ───────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                  │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ S-1  │ CircleAvatar 버튼 (왼쪽 위)     │ 내 정보 열기                           │ P04 · P06     │
// │ S-2  │ Text(제목)                      │ 지금 있는 화면 이름                    │ P01           │
// │ S-3  │ 하단 탭 4개 (<840dp)            │ 홈 · 검색 · 캘린더 · 컬렉션            │ P06 · P04     │
// │ S-4  │ 가운데 원형 + 버튼              │ 추가 (사진으로 찾기 · 바코드 · 앨범)   │ P07           │
// │ S-5  │ NavigationRail (≥840dp)         │ 측면 탭 + 위쪽 추가 버튼               │ 적응형 · P04  │
// │ S-6  │ IndexedStack                    │ 탭 상태 유지                           │ P03           │
// │ S-7  │ 내 채널 목록(상태)              │ 네 화면이 같이 쓰는 내 IP 채널         │ P04           │
// └────────────────────────────────────────────────────────────────────────────────┘
// 전환: S-3 옆으로(탭) · S-4 덮기(bottom sheet) · S-1 쌓기(push).
// 현행 앱 문제: 위 5개 IP + 아래 5개 화면 + 도감 안 탭 → v2는 아래 탭 하나 + 화면 안 채널 바 하나.
import 'package:flutter/material.dart';

import '../api.dart';
import '../channels.dart';
import '../theme.dart';
import '../widgets.dart';
import 'c_channel_screen.dart';

/// 넓은 화면 기준 (Material 3 window size class: expanded ≥ 840dp)
const railBreakpoint = 840.0;

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.loaders = const Loaders()});

  final Loaders loaders;

  @override
  State<AppShell> createState() => _AppShellState();
}

/// 하단 탭 (가운데 +는 탭이 아니라 동작)
const _tabs = <(IconData, IconData, String)>[
  (Icons.home_outlined, Icons.home, '홈'),
  (Icons.search, Icons.search, '검색'),
  (Icons.calendar_today_outlined, Icons.calendar_today, '캘린더'),
  (Icons.bookmark_border, Icons.bookmark, '컬렉션'),
];

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  List<String> _myChannels = [...defaultMyChannels]; // S-7 P04

  void _setChannels(List<String> ids) {
    setState(() => _myChannels = ids); // STATE: 내 채널 → 네 화면의 채널 바와 목록
  }

  void _openAdd() {
    showModalBottomSheet<void>( // S-4 P07
      context: context,
      builder: (context) => const AddSheet(),
    );
  }

  Widget _page(int i) => _TabPage(
    key: ValueKey(i),
    title: _tabs[i].$3,
    myChannels: _myChannels,
    onMyChannelsChanged: _setChannels,
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;
    final body = IndexedStack( // S-6 P03
      index: _tab,
      children: [for (var i = 0; i < _tabs.length; i++) _page(i)],
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: wide
            ? Row(
                children: [
                  NavigationRail( // S-5
                    selectedIndex: _tab,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (i) => setState(() => _tab = i),
                    leading: Column(
                      children: [
                        const SizedBox(height: 8),
                        const _AvatarButton(),
                        const SizedBox(height: 16),
                        _PlusButton(onTap: _openAdd),
                        const SizedBox(height: 8),
                      ],
                    ),
                    destinations: [
                      for (final t in _tabs)
                        NavigationRailDestination(
                          icon: Icon(t.$1),
                          selectedIcon: Icon(t.$2),
                          label: Text(t.$3),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
            : Column(
                children: [
                  _TopBar(title: _tabs[_tab].$3),
                  Expanded(child: body),
                ],
              ),
      ),
      bottomNavigationBar: wide
          ? null
          : _BottomBar(
              index: _tab,
              onSelect: (i) => setState(() => _tab = i), // STATE: 탭 번호 → IndexedStack
              onPlus: _openAdd,
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 12),
          const _AvatarButton(), // S-1 P04
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), // S-2 P01
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '내 정보',
      child: InkResponse(
        radius: 22,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내 정보 화면은 다음 단계에서 만들어요')),
        ),
        child: const CircleAvatar(
          radius: 17,
          backgroundColor: Gp.ink,
          foregroundColor: Colors.white,
          child: Text('A', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '추가',
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(color: Gp.ink, shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect, required this.onPlus});

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    Widget item(int i) {
      final t = _tabs[i];
      final on = i == index;
      return Expanded(
        child: InkResponse(
          onTap: () => onSelect(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(on ? t.$2 : t.$1, color: on ? Gp.ink : Gp.faint),
              const SizedBox(height: 2),
              Text(
                t.$3,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: on ? Gp.ink : Gp.faint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Gp.bg,
        border: Border(top: BorderSide(color: Gp.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              item(0), // S-3 P06
              item(1),
              Expanded(child: Center(child: _PlusButton(onTap: onPlus))), // S-4 P07
              item(2),
              item(3),
            ],
          ),
        ),
      ),
    );
  }
}

/// S-4 추가 시트: 사진으로 찾기 · 바코드 · 앨범
class AddSheet extends StatelessWidget {
  const AddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    void soon(String what) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$what 화면은 다음 단계에서 만들어요')),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.center_focus_strong_outlined),
              title: const Text('사진으로 찾기'),
              subtitle: const Text('상자나 실물을 찍으면 후보를 보여 줘요'),
              onTap: () => soon('사진으로 찾기'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('바코드 스캔'),
              subtitle: const Text('상자 뒷면 바코드로 정확히 찾기'),
              onTap: () => soon('바코드 스캔'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('앨범에서 선택'),
              subtitle: const Text('저장해 둔 사진·캡처로 찾기'),
              onTap: () => soon('앨범에서 선택'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 이번 단계의 임시 탭 화면 — 채널 바만 붙여 두고 내용은 다음 단계에서 채운다.
class _TabPage extends StatefulWidget {
  const _TabPage({
    super.key,
    required this.title,
    required this.myChannels,
    required this.onMyChannelsChanged,
  });

  final String title;
  final List<String> myChannels;
  final ValueChanged<List<String>> onMyChannelsChanged;

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage> {
  String _selected = allChannelId;

  @override
  Widget build(BuildContext context) {
    // 내 채널에서 빠진 채널을 보고 있었다면 '전체'로 돌아간다
    final sel = widget.myChannels.contains(_selected) ? _selected : allChannelId;
    return Column(
      children: [
        ChannelBar(
          myChannels: widget.myChannels,
          selected: sel,
          onSelect: (id) => setState(() => _selected = id),
          onMyChannelsChanged: widget.onMyChannelsChanged,
        ),
        const Divider(),
        Expanded(
          child: EmptyView(
            icon: Icons.construction_outlined,
            message: '${widget.title} 화면 — 다음 단계에서 설계',
            detail: sel == allChannelId ? '지금 채널: 전체' : '지금 채널: ${channelOf(sel).label}',
          ),
        ),
      ],
    );
  }
}
