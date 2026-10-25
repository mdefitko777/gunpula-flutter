// 화면 I: 내 정보 — 프로필 · 수집 숫자 · 게시물 · 공유 공간과 친구 (아바타에서 열림, 설정은 K 화면)
// 같은 화면을 친구 보기로도 쓴다: 친구 이름을 누르면 그 친구의 숫자 · 게시물 (편집 · 친구 목록 없음)
//
// ┌──────── 디자인 가이드 대응표: I 내 정보 ───────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ I-1  │ 색 고리 큰 아바타 · 이름 · @아이디    │ 내 프로필                              │ P04           │
// │ I-2  │ TagPill 줄                          │ 내 취향 태그                           │ P06           │
// │ I-3  │ 프로필 편집 → 바텀 시트(액션 목록)    │ 아바타 · 배경 · 닉네임 · 태그 바꾸기 (가짜) │ P03 · P07  │
// │ I-4  │ 숫자 3칸 (누르면 이동)               │ 좋아요 · 도감 레벨(배지 n) · 구매함 → 컬렉션 │ P01 · P07   │
// │ I-5  │ 초대 코드 + 복사 · 멤버 줄           │ 공유 공간과 친구 → 친구 프로필          │ P07           │
// │ I-6  │ 사진 3열 격자                       │ 게시물 (도감에서 인증한 사진 · 친구 공개)  │ P02 · P06    │
// │ I-7  │ 사진 보기: 미리보기 + 워터마크 스위치  │ 저장 시 "GP · @아이디" 워터마크 (끌 수 있음) │ P05 · P10  │
// │ I-9  │ 바텀 시트: 스위치 + 친구 체크 목록     │ 게시물 공개 범위 (전체 끄기 · 친구별 숨기기) │ P05 · P07 │
// │ I-10 │ 사진 보기의 "게시물에 보이기" 스위치  │ 사진 한 장만 숨기기 (흐리게 + 눈 꺼짐 표시) │ P05 · P01  │
// │ I-11 │ 친구 숫자 → L 친구 컬렉션            │ 친구의 좋아요 · 구매함 · 도감 보기         │ P07        │
// │ I-8  │ LoadingView / ErrorView             │ 프로필 불러오기 (GET /profile)          │ P01 · P09     │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: 앱 셸 아바타 → 쌓기(push, 오른쪽에서). 숫자 → 닫고 컬렉션 탭(옆으로). 게시물 · 친구 → 쌓기. 편집 → 덮기.
// 현행 앱 문제: 로그인 전엔 아바타가 곧바로 설정, 후엔 서랍 — 같은 버튼이 다르게 동작 → v2는 늘 이 화면.
// 실제 로그인 · 저장 없음: 바꾸는 동작은 토스트로만 응답한다.
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'f_collection_screen.dart' show CollectionJump;
import 'l_friend_collection_screen.dart';

void openProfile(
  BuildContext context, {
  Loaders loaders = const Loaders(),
  ValueChanged<CollectionJump>? onJump,
  List<String>? myChannels,
}) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoPageRoute<void>(
      builder: (_) => ProfileScreen(loaders: loaders, onJump: onJump, myChannels: myChannels),
    ),
  );
}

/// 친구 프로필 (같은 화면, 보기 전용)
void openFriend(BuildContext context, Member friend, {Loaders loaders = const Loaders()}) {
  Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => ProfileScreen(loaders: loaders, friend: friend),
    ),
  );
}

class _ProfileData {
  const _ProfileData(this.profile, this.collection, this.lit);
  final Profile profile;
  final List<Kit> collection;

  /// 도감 점등 칸 수 (작품 도감의 수집 합)
  final int lit;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.loaders = const Loaders(), this.onJump, this.friend, this.myChannels});
  final Loaders loaders;

  /// 주면 숫자를 내 채널 안에서만 센다 (컬렉션 탭 '전체'와 같은 범위)
  final List<String>? myChannels;

  /// 숫자를 누르면 이 화면을 닫고 컬렉션 탭의 그 목록으로
  final ValueChanged<CollectionJump>? onJump;

  /// 있으면 친구 보기
  final Member? friend;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _future;

  // 게시물 공개 범위 (가짜 — 저장하지 않음)
  bool _postsPublic = true;

  /// 게시물을 안 보여 줄 친구 아이디
  final Set<String> _hiddenFrom = {};

  /// 게시물에서 숨긴 사진 id
  final Set<String> _hiddenPhotos = {};

  /// 사진 id → 워터마크 (바꾼 것만, 나머지는 데이터 값)
  final Map<String, bool> _watermark = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // STATE: GET /profile · /kits?status_ne=none · /guideWorks → 프로필 · 숫자 · 게시물
    _future = Future.wait([
      widget.loaders.profile(),
      widget.loaders.collection(),
      widget.loaders.guideWorks(),
    ]).then((r) => _ProfileData(r[0] as Profile, r[1] as List<Kit>, litCount(r[2] as List<GuideWork>)));
  }

  void _fake(String what) => showToast(context, '$what은(는) 프로토타입이라 실제로 바뀌지 않아요');

  /// I-9 게시물 공개 범위
  void _openPrivacy(Profile p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          void change(VoidCallback f) {
            setState(f); // STATE: 공개 범위 → 게시물 제목 줄 · 친구 체크
            setSheet(() {});
          }

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.75),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  const SectionHeader('게시물 공개 범위', padding: EdgeInsets.fromLTRB(16, 0, 16, 4)),
                  SwitchListTile(
                    title: const Text('친구에게 게시물 보이기'),
                    subtitle: const Text('끄면 모든 게시물이 나만 보기로 바뀌어요'),
                    value: _postsPublic,
                    activeThumbColor: Gp.accent,
                    onChanged: (v) => change(() => _postsPublic = v),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, 2),
                    child: Text('보여 줄 친구', style: TextStyle(fontSize: 13, color: Gp.muted)),
                  ),
                  for (final f in p.friends)
                    CheckboxListTile(
                      secondary: CircleThumb(image: '', label: f.name, size: 34),
                      title: Text(f.name),
                      subtitle: Text('@${f.handle}', style: const TextStyle(fontSize: 12, color: Gp.muted)),
                      value: _postsPublic && !_hiddenFrom.contains(f.handle),
                      activeColor: Gp.accent,
                      onChanged:
                          _postsPublic // 전체를 끄면 친구별 선택도 잠김 P05
                          ? (v) => change(() => v == true ? _hiddenFrom.remove(f.handle) : _hiddenFrom.add(f.handle))
                          : null,
                    ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      '사진 한 장만 숨기려면 그 사진을 눌러 "게시물에 보이기"를 끄세요.',
                      style: TextStyle(fontSize: 12, color: Gp.muted),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _postsSubtitle() {
    if (!_postsPublic) return '나만 보기 · 친구에게 보이지 않아요';
    final n = _hiddenFrom.length;
    return n == 0 ? '도감에서 인증한 사진 · 친구에게 보여요' : '도감에서 인증한 사진 · 친구 $n명에게는 숨김';
  }

  void _jump(CollectionJump j) {
    Navigator.pop(context);
    widget.onJump?.call(j);
  }

  void _editProfile() {
    showModalBottomSheet<void>(
      // I-3 덮기
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

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          friend == null ? '내 정보' : '${friend.name}의 컬렉션',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<_ProfileData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView(); // I-8
          if (snap.hasError) return ErrorView(message: '${snap.error}', onRetry: () => setState(_load));
          final p = snap.data!.profile;
          return friend == null ? _mine(p, snap.data!) : _friend(p, friend);
        },
      ),
    );
  }

  Widget _mine(Profile p, _ProfileData d) {
    final scope = widget.myChannels;
    final mine = d.collection.where((k) => scope == null || scope.contains(k.franchiseId));
    final liked = mine.where((k) => k.status == CollectStatus.wanted).length;
    final owned = mine.where((k) => k.status == CollectStatus.owned).length;
    final photos = p.myPosts;
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        _Header(name: p.name, handle: p.handle, avatarText: p.avatarText, tags: p.tags, onEdit: _editProfile),
        _Stats(
          liked: liked,
          lit: d.lit,
          verified: photos.length,
          owned: owned,
          spendKrw: p.spendKrw,
          onJump: widget.onJump == null ? null : _jump, // I-4
        ),
        _PhotoWall(
          // I-6
          title: '내 게시물',
          subtitle: _postsSubtitle(),
          photos: photos,
          hidden: _postsPublic ? _hiddenPhotos : {for (final ph in photos) ph.id},
          trailing: IconButton(
            // I-9
            tooltip: '공개 범위',
            onPressed: () => _openPrivacy(p),
            icon: Icon(_postsPublic ? Icons.group_outlined : Icons.lock_outline, color: Gp.muted, size: 21),
          ),
          onOpen: (ph) => _openPhoto(ph, mine: true),
        ),
        SectionPanel(
          // I-5
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
                      child: Text(p.inviteCode, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2)),
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
                  subtitle: Text(
                    m.self
                        ? '좋아요 $liked · Lv.${guideLevel(d.lit, photos.length)} · 구매 $owned'
                        : '좋아요 ${m.liked} · Lv.${guideLevel(m.lit, m.verified)} · 구매 ${m.owned}',
                    style: const TextStyle(fontSize: 12, color: Gp.muted),
                  ),
                  trailing: m.self
                      ? TagPill(m.role)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TagPill(m.role),
                            const Icon(Icons.chevron_right, color: Gp.faint),
                          ],
                        ),
                  onTap: m.self
                      ? null
                      : () => openFriend(
                          context,
                          p.friendOf(m), // 친구 목록의 자세한 정보
                          loaders: widget.loaders,
                        ),
                ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: const Text('친구 추가'),
                onTap: () => _fake('친구 추가'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _friend(Profile p, Member m) {
    final photos = p.showcase.where((s) => s.owner == m.handle).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        _Header(name: m.name, handle: m.handle, avatarText: m.name.characters.first, tags: [m.role]),
        _Stats(
          liked: m.liked,
          lit: m.lit,
          verified: m.verified,
          owned: m.owned,
          onJump: (j) => openFriendCollection(context, m, j, loaders: widget.loaders), // I-11
        ),
        _PhotoWall(
          title: '${m.name}의 게시물',
          subtitle: '저장하면 워터마크가 들어갈 수 있어요',
          photos: photos,
          onOpen: (ph) => _openPhoto(ph, mine: false),
        ),
      ],
    );
  }

  void _openPhoto(ShowcasePhoto ph, {required bool mine}) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => PhotoViewScreen(
          photo: ph,
          mine: mine,
          shown: !_hiddenPhotos.contains(ph.id),
          watermark: _watermark[ph.id] ?? ph.watermark,
          onShown: (v) => setState(() => v ? _hiddenPhotos.remove(ph.id) : _hiddenPhotos.add(ph.id)),
          onWatermark: (v) => setState(() => _watermark[ph.id] = v),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.handle, required this.avatarText, required this.tags, this.onEdit});
  final String name;
  final String handle;
  final String avatarText;
  final List<String> tags;

  /// 없으면(친구 보기) 편집 버튼을 숨긴다
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final avatar = RingAvatar(text: avatarText, size: 76, ringWidth: 3);
    return ColoredBox(
      color: Gp.panel,
      child: Stack(
        children: [
          Column(
            children: [
              Container(height: 70, color: Gp.soft), // 배경(커버)
              const SizedBox(height: 56), // 아바타가 겹쳐 앉는 자리
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text('@$handle', style: const TextStyle(color: Gp.muted)),
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: [for (final t in tags) TagPill(t)]), // I-2 P06
              if (onEdit != null) ...[
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onEdit, // I-3
                  style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                  child: const Text('프로필 편집'),
                ),
              ],
              const SizedBox(height: 18),
            ],
          ),
          Positioned(top: 30, left: 0, right: 0, child: Center(child: avatar)), // I-1 P04
        ],
      ),
    );
  }
}

/// I-4 숫자 3칸 — 누르면 컬렉션 탭의 그 목록으로 (친구 보기에서는 숫자만)
class _Stats extends StatelessWidget {
  const _Stats({
    required this.liked,
    required this.lit,
    required this.verified,
    required this.owned,
    this.spendKrw,
    this.onJump,
  });
  final int liked;
  final int lit;

  /// 3점(내 사진 인증) 칸 수 = 배지 수
  final int verified;
  final int owned;
  final int? spendKrw;
  final ValueChanged<CollectionJump>? onJump;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value, CollectionJump j, {Widget? extra}) {
      final body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            FittedBox(
              // 좁은 화면에서는 줄여서 한 줄
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  ?extra,
                ],
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Gp.muted)),
                if (onJump != null) const Icon(Icons.chevron_right, size: 14, color: Gp.faint),
              ],
            ),
          ],
        ),
      );
      return Expanded(
        child: onJump == null
            ? body
            : InkWell(borderRadius: BorderRadius.circular(Gp.radius), onTap: () => onJump!(j), child: body),
      );
    }

    return SectionPanel(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                stat('좋아요', '$liked', CollectionJump.liked),
                const VerticalDivider(width: 1, indent: 6, endIndent: 6),
                stat(
                  '도감 레벨',
                  'Lv.${guideLevel(lit, verified)}',
                  CollectionJump.guide,
                  extra: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const VerifiedBadge(size: 16),
                        Text(' $verified', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, indent: 6, endIndent: 6),
                stat('구매함', '$owned', CollectionJump.owned),
              ],
            ),
          ),
          if (spendKrw case final spend?) ...[
            const Divider(height: 20),
            Text('구매 지출 합계 ${won(spend)}', style: const TextStyle(fontSize: 12.5, color: Gp.muted)),
          ],
        ],
      ),
    );
  }
}

/// I-6 게시물 3열
class _PhotoWall extends StatelessWidget {
  const _PhotoWall({
    required this.title,
    required this.subtitle,
    required this.photos,
    required this.onOpen,
    this.hidden = const {},
    this.trailing,
  });
  final String title;
  final String subtitle;
  final List<ShowcasePhoto> photos;
  final ValueChanged<ShowcasePhoto> onOpen;

  /// 친구에게 숨긴 사진 (흐리게 + 눈 꺼짐)
  final Set<String> hidden;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title, subtitle: subtitle, trailing: trailing),
          if (photos.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                '아직 게시물이 없어요 · 도감에서 "내 사진"으로 인증하면 여기에 모여요', // P09
                style: TextStyle(color: Gp.muted, fontSize: 13),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final ph in photos)
                    GestureDetector(
                      onTap: () => onOpen(ph),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(opacity: hidden.contains(ph.id) ? 0.35 : 1, child: PhotoThumb(ph.image, radius: 10)),
                          const Positioned(right: 5, bottom: 5, child: VerifiedBadge(size: 20)),
                          if (hidden.contains(ph.id))
                            const Center(child: Icon(Icons.visibility_off_outlined, color: Gp.ink, size: 26)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// I-7 사진 한 장 보기 — 다른 사람이 저장할 때의 워터마크 미리보기 + 끄고 켜기(내 사진만)
class PhotoViewScreen extends StatefulWidget {
  const PhotoViewScreen({
    super.key,
    required this.photo,
    required this.mine,
    this.shown = true,
    this.watermark,
    this.onShown,
    this.onWatermark,
  });
  final ShowcasePhoto photo;
  final bool mine;

  /// 내 게시물에 보이는지 (I-10)
  final bool shown;

  /// null 이면 데이터 값
  final bool? watermark;
  final ValueChanged<bool>? onShown;
  final ValueChanged<bool>? onWatermark;

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  late bool _watermark = widget.watermark ?? widget.photo.watermark;
  late bool _shown = widget.shown;

  void _save() {
    final mark = watermarkText(widget.photo.owner);
    final msg = widget.mine ? '내 사진은 워터마크 없이 저장했어요' : (_watermark ? '「$mark」 워터마크가 들어간 사진을 저장했어요' : '사진을 저장했어요');
    showToast(context, '$msg (프로토타입: 실제 저장 없음)');
  }

  @override
  Widget build(BuildContext context) {
    final ph = widget.photo;
    return Scaffold(
      appBar: AppBar(
        title: Text(ph.unit, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Gp.panel,
                    child: AppImage(ph.image, fit: BoxFit.contain),
                  ),
                  if (_watermark) Positioned(right: 10, bottom: 10, child: _Watermark(text: watermarkText(ph.owner))),
                ],
              ),
            ),
          ),
          if (_watermark && widget.mine)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '다른 사람이 저장하면 이렇게 보여요',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11.5, color: Gp.faint),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              const VerifiedBadge(size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${ph.work} · ${ph.unit}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 24, top: 2),
            child: Text('도감에서 인증한 사진', style: TextStyle(fontSize: 12.5, color: Gp.muted)),
          ),
          const SizedBox(height: 8),
          if (widget.mine)
            SwitchListTile(
              // I-10 P05
              contentPadding: EdgeInsets.zero,
              title: const Text('게시물에 보이기'),
              subtitle: Text(_shown ? '친구가 볼 수 있어요' : '나만 볼 수 있어요 (게시물에서 흐리게 보여요)'),
              value: _shown,
              activeThumbColor: Gp.accent,
              onChanged: (v) {
                setState(() => _shown = v); // STATE: 이 사진 공개 → 게시물 칸
                widget.onShown?.call(v);
              },
            ),
          if (widget.mine)
            SwitchListTile(
              // I-7 P05
              contentPadding: EdgeInsets.zero,
              title: const Text('다른 사람이 저장할 때 워터마크'),
              subtitle: Text('${watermarkText(ph.owner)} 이(가) 오른쪽 아래에 들어가요'),
              value: _watermark,
              activeThumbColor: Gp.accent,
              onChanged: (v) {
                setState(() => _watermark = v); // STATE: 워터마크 → 미리보기
                widget.onWatermark?.call(v);
              },
            )
          else
            Text(
              _watermark ? '@${ph.owner} 님의 사진 · 저장하면 워터마크가 들어가요' : '@${ph.owner} 님이 워터마크를 껐어요',
              style: const TextStyle(fontSize: 12.5, color: Gp.muted),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _save,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            icon: const Icon(Icons.download_outlined, size: 20),
            label: const Text('사진 저장'),
          ),
        ],
      ),
    );
  }
}

/// 사진 오른쪽 아래 워터마크 — 작은 반투명 띠
class _Watermark extends StatelessWidget {
  const _Watermark({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0x47000000), borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }
}
