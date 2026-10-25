// 화면 S: 앱 셸 — 위: 아바타 줄 → 채널 바 / 아래: 떠 있는 반투명 탭 바 (홈 · 검색 · (+) · 캘린더 · 컬렉션)
//
// ┌──────── 디자인 가이드 대응표: S 앱 셸 ───────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                  │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ S-1  │ RaisedCircleButton (맨 위 줄)   │ 내 정보 열기 (아바타, 채널 바 위)      │ P04 · P06     │
// │ S-2  │ BackdropFilter 떠 있는 탭 바    │ 반투명 하단 탭 바                      │ P08           │
// │ S-3  │ 하단 탭 4개 (<840dp)            │ 홈 · 검색 · 캘린더 · 컬렉션            │ P06 · P04     │
// │ S-4  │ 가운데 떠 있는 + 버튼           │ 추가 (사진으로 찾기 · 바코드 · 앨범)   │ P07           │
// │ S-5  │ NavigationRail (≥840dp)         │ 측면 탭 + 위쪽 추가 버튼               │ 적응형 · P04  │
// │ S-6  │ IndexedStack                    │ 탭 상태 유지                           │ P03           │
// │ S-7  │ 내 채널 목록(상태)              │ 네 화면이 같이 쓰는 내 IP 채널         │ P04           │
// └────────────────────────────────────────────────────────────────────────────────┘
// 전환: S-3 옆으로(탭) · S-4 덮기(bottom sheet) · S-1 쌓기(push).
// 현행 앱 문제: 위 5개 IP + 아래 5개 화면 + 도감 안 탭 → v2는 아래 탭 하나 + 화면 안 채널 바 하나.
import 'dart:ui' show ImageFilter;

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

  void _openProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('내 정보 화면은 다음 단계에서 만들어요')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;
    final avatar = _AvatarButton(onTap: _openProfile); // S-1 P04
    Widget page(int i) => _TabPage(
      key: ValueKey(i),
      title: _tabs[i].$3,
      leading: wide ? null : avatar,
      myChannels: _myChannels,
      onMyChannelsChanged: _setChannels,
    );
    final body = IndexedStack( // S-6 P03
      index: _tab,
      children: [for (var i = 0; i < _tabs.length; i++) page(i)],
    );
    return Scaffold(
      extendBody: true, // 탭 바 뒤로 내용이 비쳐 보이게
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
                        avatar,
                        const SizedBox(height: 18),
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
            : body,
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

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RaisedCircleButton(
      tooltip: '내 정보',
      size: 38,
      onTap: onTap,
      child: const Text('A', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Gp.ink)),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RaisedCircleButton(
      tooltip: '추가',
      size: 48,
      onTap: onTap,
      child: const Icon(Icons.add, color: Gp.ink, size: 26, weight: 300),
    );
  }
}

/// S-2 떠 있는 반투명 탭 바 (뒤 내용이 흐리게 비친다)
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(i),
          child: Semantics(
            selected: on,
            button: true,
            label: t.$3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(on ? t.$2 : t.$1, size: 23, color: on ? Gp.ink : const Color(0xFF9A9A98)),
                const SizedBox(height: 3),
                Text(
                  t.$3,
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.4,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                    color: on ? Gp.ink : const Color(0xFF9A9A98),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: const [
              BoxShadow(color: Color(0x1F000000), blurRadius: 28, offset: Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xB8FFFFFF),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: const Color(0xCCFFFFFF)),
                ),
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
    this.leading,
  });

  final String title;
  final Widget? leading;
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
        if (widget.leading != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Align(alignment: Alignment.centerLeft, child: widget.leading),
          ),
        ChannelBar(
          myChannels: widget.myChannels,
          selected: sel,
          onSelect: (id) => setState(() => _selected = id),
          onMyChannelsChanged: widget.onMyChannelsChanged,
        ),
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
