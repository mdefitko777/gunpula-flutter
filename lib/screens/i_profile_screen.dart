// 화면 I: 내 정보 — 프로필 · 수집 요약 · 공유 공간과 친구 · 설정 (아바타에서 열림)
//
// ┌──────── 디자인 가이드 대응표: I 내 정보 ───────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ I-1  │ 색 고리 큰 아바타 · 이름 · @아이디    │ 내 프로필                              │ P04           │
// │ I-2  │ TagPill 줄                          │ 내 취향 태그                           │ P06           │
// │ I-3  │ 프로필 편집 → 바텀 시트(액션 목록)    │ 아바타 · 배경 · 닉네임 · 태그 바꾸기 (가짜) │ P03 · P07  │
// │ I-4  │ 숫자 3칸                            │ 원함 · 구매함 · 구매 지출              │ P01           │
// │ I-5  │ 초대 코드 + 복사 · 멤버 줄           │ 공유 공간과 친구                        │ P07           │
// │ I-6  │ 설정 줄 (스위치 · ›)                 │ 알림 · 언어 · 데이터 백업 · 버전        │ P04 · P10     │
// │ I-7  │ 로그아웃 → showDialog(확인)          │ 로그아웃 (실제 로그인 없음, 확인 후 토스트) │ P05      │
// │ I-8  │ LoadingView / ErrorView             │ 프로필 불러오기 (GET /profile)          │ P01 · P09     │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: 앱 셸 아바타 → 쌓기(push, 오른쪽에서). 편집 · 언어 → 덮기(바텀 시트).
// 현행 앱 문제: 로그인 전엔 아바타가 곧바로 설정, 후엔 서랍 — 같은 버튼이 다르게 동작 → v2는 늘 이 화면.
// 실제 로그인 · 저장 없음: 바꾸는 동작은 토스트로만 응답한다.
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

void openProfile(BuildContext context, {Loaders loaders = const Loaders()}) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoPageRoute<void>(builder: (_) => ProfileScreen(loaders: loaders)),
  );
}

class _ProfileData {
  const _ProfileData(this.profile, this.collection);
  final Profile profile;
  final List<Kit> collection;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.loaders = const Loaders()});
  final Loaders loaders;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _future;
  bool _notify = true;
  String _language = '한국어';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // STATE: GET /profile · /kits?status_ne=none → 프로필 · 수집 요약
    _future = Future.wait([widget.loaders.profile(), widget.loaders.collection()])
        .then((r) => _ProfileData(r[0] as Profile, r[1] as List<Kit>));
  }

  void _fake(String what) => showToast(context, '$what은(는) 프로토타입이라 실제로 바뀌지 않아요');

  void _editProfile() {
    showModalBottomSheet<void>( // I-3 덮기
      context: context,
      builder: (sheet) {
        Widget item(IconData icon, String label) => ListTile(
          leading: Icon(icon),
          title: Text(label),
          onTap: () {
            Navigator.pop(sheet);
            _fake(label);
          },
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              item(Icons.account_circle_outlined, '아바타 변경'),
              item(Icons.wallpaper_outlined, '배경 변경'),
              item(Icons.edit_outlined, '닉네임 변경'),
              item(Icons.sell_outlined, '취향 태그 선택'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _pickLanguage() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in const ['한국어', '中文', 'English', '日本語'])
              ListTile(
                title: Text(l),
                trailing: l == _language ? const Icon(Icons.check, color: Gp.accent) : null,
                onTap: () {
                  Navigator.pop(sheet);
                  setState(() => _language = l); // STATE: 언어 → 설정 줄 글자 (화면 번역은 없음)
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>( // I-7 P05
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃할까요?'),
        content: const Text('이 기기의 컬렉션은 그대로 남고, 다른 기기와의 동기화만 멈춰요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('로그아웃')),
        ],
      ),
    );
    if (ok == true && mounted) showToast(context, '프로토타입이라 로그아웃 화면은 없어요');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      body: FutureBuilder<_ProfileData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView(); // I-8
          if (snap.hasError) return ErrorView(message: '${snap.error}', onRetry: () => setState(_load));
          final p = snap.data!.profile;
          final kits = snap.data!.collection;
          final wanted = kits.where((k) => k.status == CollectStatus.wanted).length;
          final owned = kits.where((k) => k.status == CollectStatus.owned).length;
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _Header(profile: p, onEdit: _editProfile), // I-1 · I-2
              SectionPanel(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: _Stat('원함', '$wanted')), // I-4 P01
                      const VerticalDivider(width: 1, indent: 6, endIndent: 6),
                      Expanded(child: _Stat('구매함', '$owned')),
                      const VerticalDivider(width: 1, indent: 6, endIndent: 6),
                      Expanded(child: _Stat('구매 지출', won(p.spendKrw))),
                    ],
                  ),
                ),
              ),
              SectionPanel( // I-5
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader('공유 공간과 친구', subtitle: p.workspace),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                      decoration: BoxDecoration(color: Gp.bg, borderRadius: BorderRadius.circular(Gp.radius)),
                      child: Row(
                        children: [
                          const Text('초대 코드', style: TextStyle(color: Gp.muted, fontSize: 13)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(p.inviteCode,
                                style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2)),
                          ),
                          IconButton(
                            tooltip: '초대 코드 복사', // P07
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: p.inviteCode));
                              showToast(context, '초대 코드를 복사했어요');
                            },
                            icon: const Icon(Icons.content_copy_rounded, size: 18, color: Gp.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final m in p.members)
                      ListTile(
                        leading: CircleThumb(image: '', label: m.name, size: 36),
                        title: Text(m.self ? '${m.name} (나)' : m.name),
                        trailing: TagPill(m.role),
                        onTap: m.self ? null : () => showSoon(context, '${m.name}의 컬렉션'),
                      ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined),
                      title: const Text('친구 추가'),
                      onTap: () => _fake('친구 추가'),
                    ),
                  ],
                ),
              ),
              SectionPanel( // I-6
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('설정'),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_none),
                      title: const Text('새 소식 알림'),
                      subtitle: const Text('내 채널에 새 상품 · 예고가 생기면'),
                      value: _notify,
                      activeThumbColor: Gp.accent,
                      onChanged: (v) => setState(() => _notify = v), // STATE: 알림 스위치
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('언어'),
                      trailing: Text('$_language ›', style: const TextStyle(color: Gp.muted)),
                      onTap: _pickLanguage,
                    ),
                    ListTile(
                      leading: const Icon(Icons.cloud_download_outlined),
                      title: const Text('데이터 백업'),
                      subtitle: const Text('컬렉션 · 채널 설정을 파일로 내보내기'),
                      onTap: () => _fake('데이터 백업'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('버전'),
                      trailing: Text('Gunpula v2.0.0', style: TextStyle(color: Gp.muted)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Gp.danger),
                      title: const Text('로그아웃', style: TextStyle(color: Gp.danger)),
                      onTap: _signOut, // I-7 P05
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.onEdit});
  final Profile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [Gp.accent, Gp.accent2, Gp.accent]),
      ),
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Gp.panel),
        child: Text(profile.avatarText, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
      ),
    );
    return ColoredBox(
      color: Gp.panel,
      child: Stack(
        children: [
          Column(
            children: [
              Container(height: 70, color: Gp.soft), // 배경(커버)
              const SizedBox(height: 56), // 아바타가 겹쳐 앉는 자리
              Text(profile.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text('@${profile.handle}', style: const TextStyle(color: Gp.muted)),
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: [for (final t in profile.tags) TagPill(t)]), // I-2 P06
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onEdit, // I-3
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                child: const Text('프로필 편집'),
              ),
              const SizedBox(height: 18),
            ],
          ),
          Positioned(top: 30, left: 0, right: 0, child: Center(child: avatar)), // I-1 P04
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 12, color: Gp.muted)),
      ],
    );
  }
}
