// 화면 M: 친구 서랍 — 왼쪽 위 아바타를 누르거나, 홈에서 왼쪽 가장자리를 밀면 나온다 (QQ 옆 서랍처럼)
// 위: 내 프로필 요약(아바타를 한 번 더 누르면 I 내 정보) · 아래: 메뉴 대신 친구 (검색 · 알 수도 있는 친구 · 그룹별 목록)
//
// ┌──────── 디자인 가이드 대응표: M 친구 서랍 ─────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ M-1  │ Drawer (아바타 · 홈 가장자리 밀기)    │ 친구 서랍 열기 · 닫기(밖 누르기 · X)     │ P03 · P07     │
// │ M-2  │ 색 고리 아바타 · 이름 · Lv · 배지     │ 내 프로필 요약 → 내 정보                │ P04           │
// │ M-3  │ 알약 버튼                           │ 새 친구 요청 n건                        │ P01           │
// │ M-4  │ GpSearchBar (카메라 없는 모드)        │ 친구 검색 (홈 · 검색과 같은 검색창)       │ P07 · P04     │
// │ M-5  │ 줄 + 추가 버튼 · ×                  │ 알 수도 있는 친구 (함께 아는 친구 n명)    │ P07 · P05     │
// │ M-6  │ 밑줄 탭 + 접히는 그룹                │ 친구(특별 관심 · 친구) | 공유 공간        │ P06           │
// │ M-7  │ 친구 줄 (상태 한 줄 · Lv)            │ 친구 → 친구 프로필(I 친구 보기)          │ P07           │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: 서랍 → 내 정보 · 친구 프로필(쌓기, 서랍은 닫힘). 데이터: GET /profile · /guideWorks.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class FriendsDrawer extends StatefulWidget {
  const FriendsDrawer({
    super.key,
    required this.onOpenProfile,
    required this.onOpenFriend,
    this.loaders = const Loaders(),
  });

  final VoidCallback onOpenProfile;
  final ValueChanged<Member> onOpenFriend;
  final Loaders loaders;

  @override
  State<FriendsDrawer> createState() => _FriendsDrawerState();
}

class _FriendsDrawerState extends State<FriendsDrawer> {
  late Future<(Profile, int)> _future = _load();

  String _query = '';
  bool _spaceTab = false;
  final Set<String> _collapsed = {};

  // 알 수도 있는 친구: 요청 보냄 · 닫음 (가짜 — 저장하지 않음)
  final Set<String> _requested = {};
  final Set<String> _dismissed = {};

  Future<(Profile, int)> _load() async {
    // STATE: GET /profile · /guideWorks → 내 요약 · 친구 목록
    final r = await Future.wait([widget.loaders.profile(), widget.loaders.guideWorks()]);
    final works = r[1] as List<GuideWork>;
    return (r[0] as Profile, litCount(works));
  }

  /// 서랍을 닫고 열기
  void _close(VoidCallback then) {
    Navigator.pop(context);
    then();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Drawer(
      // M-1
      width: width < 420 ? width * 0.88 : 380,
      backgroundColor: Gp.bg,
      shape: const RoundedRectangleBorder(),
      child: FutureBuilder<(Profile, int)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) {
            return ErrorView(message: '${snap.error}', onRetry: () => setState(() => _future = _load()));
          }
          final (p, lit) = snap.data!;
          final verified = p.myPosts.length;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(p, lit, verified),
              _search(),
              _suggested(p),
              SectionPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_outlined, color: Gp.ink),
                      title: const Text('새 친구'),
                      trailing: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Badge(backgroundColor: Gp.accent, label: Text('1')),
                          Icon(Icons.chevron_right, color: Gp.faint),
                        ],
                      ),
                      onTap: () => showSoon(context, '새 친구 요청'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.home_outlined, color: Gp.ink),
                      title: const Text('공유 공간'),
                      trailing: const Icon(Icons.chevron_right, color: Gp.faint),
                      onTap: () => setState(() => _spaceTab = true), // STATE: 아래 탭 → 공유 공간
                    ),
                  ],
                ),
              ),
              _lists(p),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  /// M-2 내 프로필 요약 (QQ 서랍 머리처럼, 다만 밝은 바탕)
  Widget _header(Profile p, int lit, int verified) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 6, 6, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9F3FB), Color(0xFFE8F8F3), Gp.panel],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '친구',
                style: TextStyle(fontSize: Gp.t19, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                tooltip: '친구 추가',
                onPressed: () => showToast(context, '아이디나 초대 코드로 친구를 찾는 화면은 준비 중이에요'),
                icon: const Icon(Icons.person_add_alt_1_outlined, color: Gp.ink),
              ),
              IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Gp.ink),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(Gp.radius),
            onTap: () => _close(widget.onOpenProfile),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  RingAvatar(text: p.avatarText),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontSize: Gp.t16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '@${p.handle}',
                          style: const TextStyle(fontSize: Gp.t12, color: Gp.muted),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            LevelChip(level: guideLevel(lit, verified)),
                            const SizedBox(width: 6),
                            const VerifiedBadge(size: 16),
                            Text(
                              ' $verified',
                              style: const TextStyle(fontSize: Gp.t12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Gp.faint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ActionChip(
              // M-3
              avatar: const Icon(Icons.notifications_none, size: 16, color: Gp.accent),
              label: const Text('친구 요청 1건 · 새 게시물 2개'),
              backgroundColor: Gp.panel,
              side: const BorderSide(color: Gp.line),
              shape: const StadiumBorder(),
              onPressed: () => showSoon(context, '친구 알림'),
            ),
          ),
        ],
      ),
    );
  }

  /// M-4 친구 검색
  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GpSearchBar(
        hint: '친구 검색', // 홈 · 검색과 같은 검색창 (카메라 없음)
        onChanged: (v) => setState(() => _query = v.trim()), // STATE: 검색어 → 아래 목록 거르기
      ),
    );
  }

  /// M-5 알 수도 있는 친구
  Widget _suggested(Profile p) {
    final list = p.suggested.where((s) => !_dismissed.contains(s.handle)).toList();
    if (list.isEmpty || _query.isNotEmpty) return const SizedBox(height: 8);
    return SectionPanel(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          SectionHeader(
            '알 수도 있는 친구',
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            onMore: () {
              showSoon(context, '알 수도 있는 친구');
            },
          ),
          for (final s in list)
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
              leading: CircleThumb(image: '', label: s.name, size: 40),
              title: Text(s.name),
              subtitle: Align(alignment: Alignment.centerLeft, child: TagPill('함께 아는 친구 ${s.mutual}명')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: _requested.contains(s.handle)
                        ? null
                        : () {
                            setState(() => _requested.add(s.handle)); // STATE: 요청 보냄 → 버튼 잠김
                            showToast(
                              context,
                              '${s.name}에게 친구 요청을 보냈어요',
                              onUndo: () => setState(() => _requested.remove(s.handle)),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(_requested.contains(s.handle) ? '요청됨' : '추가'),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _dismissed.add(s.handle)),
                    icon: const Icon(Icons.close, size: 18, color: Gp.faint),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// M-6 · M-7 친구 | 공유 공간
  Widget _lists(Profile p) {
    bool hit(Member m) => _query.isEmpty || m.name.contains(_query) || m.handle.contains(_query);
    Widget friendRow(Member m) => ListTile(
      // M-7
      leading: CircleThumb(image: '', label: m.name, size: 42),
      title: Row(
        children: [
          Flexible(child: Text(m.name, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 6),
          LevelChip(level: guideLevel(m.lit, m.verified), small: true),
        ],
      ),
      subtitle: Text(
        m.status.isEmpty ? '@${m.handle}' : m.status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: Gp.t12, color: Gp.muted),
      ),
      onTap: () => _close(() => widget.onOpenFriend(m)),
    );

    Widget group(String id, String title, List<Member> all) {
      final shown = all.where(hit).toList();
      final open = !_collapsed.contains(id) || _query.isNotEmpty;
      return Column(
        children: [
          InkWell(
            onTap: () => setState(() => open ? _collapsed.add(id) : _collapsed.remove(id)), // STATE: 그룹 접기
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.arrow_right, color: Gp.muted),
                  ),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    '${shown.length}/${all.length}',
                    style: const TextStyle(fontSize: Gp.t12, color: Gp.faint),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            for (final m in shown) friendRow(m),
        ],
      );
    }

    final special = p.friends.where((f) => f.group == 'special').toList();
    final others = p.friends.where((f) => f.group != 'special').toList();
    return SectionPanel(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: Row(
              children: [
                UnderlineTab(
                  label: '친구',
                  count: p.friends.length,
                  selected: !_spaceTab,
                  onTap: () => setState(() => _spaceTab = false),
                ),
                UnderlineTab(
                  label: '공유 공간',
                  count: p.members.length,
                  selected: _spaceTab,
                  onTap: () => setState(() => _spaceTab = true),
                ),
              ],
            ),
          ),
          if (!_spaceTab) ...[
            group('special', '특별 관심', special),
            group('friend', '친구', others),
          ] else
            for (final m in p.members.where(hit))
              ListTile(
                leading: CircleThumb(image: '', label: m.name, size: 42),
                title: Text(m.self ? '${m.name} (나)' : m.name),
                subtitle: Text(
                  '@${m.handle}',
                  style: const TextStyle(fontSize: Gp.t12, color: Gp.muted),
                ),
                trailing: TagPill(m.role),
                onTap: m.self
                    ? () => _close(widget.onOpenProfile)
                    : () => _close(() => widget.onOpenFriend(p.friendOf(m))),
              ),
        ],
      ),
    );
  }
}
