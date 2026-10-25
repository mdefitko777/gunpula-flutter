// 화면 S: 앱 셸 — 위: 아바타 줄 → 채널 바 / 아래: 바닥에 붙은 반투명 탭 바 (홈 · 검색 · (카메라) · 캘린더 · 컬렉션)
//
// ┌──────── 디자인 가이드 대응표: S 앱 셸 ───────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                  │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ S-1  │ RaisedCircleButton + 색 고리    │ 내 정보 열기 (아바타, 채널 바 위)      │ P04 · P06     │
// │ S-2  │ BackdropFilter 바닥 탭 바       │ 반투명 하단 탭 바 (양옆 여백 없음)      │ P08           │
// │ S-3  │ 하단 탭 4개 (<840dp)            │ 홈 · 검색 · 캘린더 · 컬렉션            │ P06 · P04     │
// │ S-4  │ 가운데 카메라 버튼              │ 찍어서 찾기 (사진 · 바코드 · 앨범)     │ P07           │
// │ S-5  │ NavigationRail (≥840dp)         │ 측면 탭 + 위쪽 추가 버튼               │ 적응형 · P04  │
// │ S-6  │ IndexedStack                    │ 탭 상태 유지                           │ P03           │
// │ S-7  │ 내 채널 목록(상태)              │ 네 화면이 같이 쓰는 내 IP 채널         │ P04           │
// │ S-8  │ AnimatedSlide · AnimatedPositioned │ 아래로 스크롤하면 탭 바 숨김, 카메라만 오른쪽 아래 │ P08 · P07 │
// └────────────────────────────────────────────────────────────────────────────────┘
// 전환: S-3 옆으로(탭) · S-4 덮기(bottom sheet) · S-1 쌓기(push).
// S-8: X · Threads처럼 내용을 내려 읽는 동안 탭 바를 숨겨 화면을 넓히고, 카메라 버튼만 남긴다.
// 현행 앱 문제: 위 5개 IP + 아래 5개 화면 + 도감 안 탭 → v2는 아래 탭 하나 + 화면 안 채널 바 하나.
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../api.dart';
import '../channels.dart';
import '../theme.dart';
import '../widgets.dart';
import 'a_home_screen.dart';
import 'b_search_screen.dart';
import 'c_channel_screen.dart';
import 'e_camera_screen.dart';
import 'f_collection_screen.dart';

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

  /// 하단 탭 바가 보이는지 (아래로 스크롤하면 숨김)
  bool _barShown = true;

  /// 홈 검색 알약 → 검색 탭 검색창에 커서
  int _searchFocusTick = 0;
  List<String> _myChannels = [...defaultMyChannels]; // S-7 P04

  void _setChannels(List<String> ids) {
    setState(() => _myChannels = ids); // STATE: 내 채널 → 네 화면의 채널 바와 목록
  }

  /// 검색 탭으로 + 검색창 커서 (홈 검색창 · 카메라 결과의 "이름으로 검색")
  void _goSearch() => setState(() {
    _tab = 1; // STATE: 검색으로 → 검색 탭 + 커서
    _searchFocusTick++;
    _barShown = true;
  });

  void _openAdd() {
    showModalBottomSheet<void>(
      // S-4 P07
      context: context,
      builder: (sheet) => AddSheet(
        onPick: (pick) {
          Navigator.pop(sheet);
          switch (pick) {
            case 'photo':
              openCamera(context, CameraMode.photo, loaders: widget.loaders, onGoSearch: _goSearch);
            case 'barcode':
              openCamera(context, CameraMode.barcode, loaders: widget.loaders, onGoSearch: _goSearch);
            default:
              openAlbum(context, loaders: widget.loaders, onGoSearch: _goSearch);
          }
        },
      ),
    );
  }

  void _openProfile() => showSoon(context, '내 정보');

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;
    final avatar = _AvatarButton(onTap: _openProfile); // S-1 P04
    Widget page(int i) => i == 0
        ? HomeScreen(
            // A
            key: const ValueKey(0),
            leading: wide ? null : avatar,
            myChannels: _myChannels,
            onMyChannelsChanged: _setChannels,
            onCamera: _openAdd,
            onOpenSearch: _goSearch,
            loaders: widget.loaders,
          )
        : i == 1
        ? SearchScreen(
            // B
            key: const ValueKey(1),
            leading: wide ? null : avatar,
            myChannels: _myChannels,
            onMyChannelsChanged: _setChannels,
            onCamera: _openAdd,
            focusTick: _searchFocusTick,
            loaders: widget.loaders,
          )
        : i == 3
        ? CollectionScreen(
            // F
            key: const ValueKey(3),
            leading: wide ? null : avatar,
            myChannels: _myChannels,
            onMyChannelsChanged: _setChannels,
            onGoSearch: _goSearch,
            loaders: widget.loaders,
          )
        : _TabPage(
            key: ValueKey(i),
            title: _tabs[i].$3,
            leading: wide ? null : avatar,
            myChannels: _myChannels,
            onMyChannelsChanged: _setChannels,
          );
    final body = IndexedStack(
      // S-6 P03
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
                  NavigationRail(
                    // S-5
                    selectedIndex: _tab,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (i) => setState(() => _tab = i),
                    leading: Column(
                      children: [
                        const SizedBox(height: 8),
                        avatar,
                        const SizedBox(height: 18),
                        _CameraButton(onTap: _openAdd),
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
            : _NarrowLayout(
                body: body,
                barShown: _barShown,
                bar: _BottomBar(
                  index: _tab,
                  onSelect: (i) => setState(() {
                    _tab = i; // STATE: 탭 번호 → IndexedStack
                    _barShown = true;
                  }),
                ),
                camera: _CameraButton(onTap: _openAdd),
                onScroll: (shown) {
                  if (shown != _barShown) setState(() => _barShown = shown); // STATE: 스크롤 방향 → 탭 바 숨김/표시
                },
              ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 브랜드 색 고리(하늘색 → 민트) — 인스타그램 프로필 고리처럼
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [Gp.accent, Gp.accent2, Gp.accent]),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Gp.bg),
        child: RaisedCircleButton(
          tooltip: '내 정보',
          size: 34,
          onTap: onTap,
          child: const Text(
            'A',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Gp.ink),
          ),
        ),
      ),
    );
  }
}

/// S-4 카메라 버튼 — 홈 카드의 +(원함 담기)와 구분되게 카메라 모양
class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RaisedCircleButton(
      tooltip: '찍어서 찾기',
      size: _cameraSize,
      onTap: onTap,
      child: const Icon(Icons.photo_camera_outlined, color: Gp.ink, size: 24),
    );
  }
}

const _cameraSize = 52.0;
const _barHeight = 62.0;

/// 좁은 화면: 내용 + 바닥 탭 바 + 카메라 버튼(S-8 스크롤에 따라 위치 이동)
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.body,
    required this.bar,
    required this.camera,
    required this.barShown,
    required this.onScroll,
  });

  final Widget body;
  final Widget bar;
  final Widget camera;
  final bool barShown;
  final ValueChanged<bool> onScroll;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const curve = Curves.easeOutCubic;
    const duration = Duration(milliseconds: 260);
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollMetricsNotification>(
              // 내용이 짧아 스크롤할 수 없게 되면 탭 바를 다시 보인다
              onNotification: (n) {
                if (n.metrics.axis == Axis.vertical && n.metrics.maxScrollExtent <= 0) onScroll(true);
                return false;
              },
              child: NotificationListener<UserScrollNotification>(
                onNotification: (n) {
                  // 세로 스크롤만 본다 (가로로 넘기는 줄은 무시)
                  if (n.metrics.axis == Axis.vertical) {
                    if (n.direction == ScrollDirection.reverse) onScroll(false);
                    if (n.direction == ScrollDirection.forward) onScroll(true);
                  }
                  return false;
                },
                child: body,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide( // S-8
              offset: barShown ? Offset.zero : const Offset(0, 1.1),
              duration: duration,
              curve: curve,
              child: bar,
            ),
          ),
          AnimatedPositioned( // S-8 P07
            duration: duration,
            curve: curve,
            left: barShown ? (box.maxWidth - _cameraSize) / 2 : box.maxWidth - _cameraSize - 18,
            bottom: barShown ? safeBottom + (_barHeight - _cameraSize) / 2 : safeBottom + 22,
            child: camera,
          ),
        ],
      ),
    );
  }
}

/// S-2 바닥에 붙은 반투명 탭 바 (양옆 여백 없이 화면 끝까지)
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

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

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xE0FFFFFF),
            border: Border(top: BorderSide(color: Gp.line)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: _barHeight,
              child: Row(
                children: [
                  item(0), // S-3 P06
                  item(1),
                  const Spacer(), // 가운데: 카메라 버튼 자리(S-4는 위에 겹쳐 놓는다)
                  item(2),
                  item(3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// S-4 찍어서 찾기 시트: 사진으로 찾기 · 바코드 · 앨범 → E 화면
class AddSheet extends StatelessWidget {
  const AddSheet({super.key, required this.onPick});

  /// 'photo' · 'barcode' · 'album'
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
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
              onTap: () => onPick('photo'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('바코드 스캔'),
              subtitle: const Text('상자 뒷면 바코드로 정확히 찾기'),
              onTap: () => onPick('barcode'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('앨범에서 선택'),
              subtitle: const Text('저장해 둔 사진·캡처로 찾기'),
              onTap: () => onPick('album'),
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
        ChannelHeader(
          leading: widget.leading,
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
