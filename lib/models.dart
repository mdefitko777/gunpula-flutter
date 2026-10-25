// db.json 레코드 → Dart 객체. 모양이 맞지 않는 레코드는 null로 버린다(화면이 죽지 않게).
// db.json 최상위 키: kits · worlds · guideWorks · guideUnits · bbxTops · bbxParts · announcements · profile
enum CollectStatus { owned, wanted, none }

CollectStatus parseCollectStatus(Object? v) => switch (v) {
  'owned' => CollectStatus.owned,
  'wanted' => CollectStatus.wanted,
  _ => CollectStatus.none,
};

String _s(Map<String, Object?> j, String k) => j[k] is String ? j[k]! as String : '';
int _i(Map<String, Object?> j, String k) => j[k] is num ? (j[k]! as num).toInt() : 0;
int? _iOrNull(Map<String, Object?> j, String k) => j[k] is num ? (j[k]! as num).toInt() : null;
bool _b(Map<String, Object?> j, String k) => j[k] == true;
List<String> _strs(Object? v) => v is List ? v.whereType<String>().toList() : const [];

/// 시장가 예시 (원화, 미리 적어 둔 값)
class Market {
  const Market({required this.normalKrw, required this.conservativeKrw, required this.samples});
  final int normalKrw;
  final int conservativeKrw;
  final int samples;

  static Market? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    return Market(
      normalKrw: _i(json, 'normalKrw'),
      conservativeKrw: _i(json, 'conservativeKrw'),
      samples: _i(json, 'samples'),
    );
  }
}

/// 상품(키트·피규어·굿즈)
class Kit {
  const Kit({
    required this.id,
    required this.franchiseId,
    required this.name,
    required this.nameJa,
    required this.series,
    required this.line,
    required this.type,
    required this.scale,
    required this.universe,
    required this.date,
    required this.priceJpy,
    required this.image,
    required this.gallery,
    required this.limited,
    required this.pb,
    required this.status,
    required this.wantedQty,
    required this.recent,
    required this.month,
    required this.market,
    required this.keywords,
  });

  final String id;
  final String franchiseId;
  final String name;
  final String nameJa;
  final String series;
  final String line;
  final String type;
  final String scale;
  final String universe;

  /// 'yyyy-mm' 또는 'yyyy-mm-dd'
  final String date;
  final int? priceJpy;
  final String image;
  final List<String> gallery;
  final bool limited;

  /// 프리미엄 반다이 한정
  final bool pb;
  final CollectStatus status;
  final int wantedQty;

  /// 최근 3일 신규 수록
  final bool recent;

  /// 이번 달 발매
  final bool month;
  final Market? market;
  final List<String> keywords;

  static Kit? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    if (id is! String) return null;
    return Kit(
      id: id,
      franchiseId: _s(json, 'franchiseId'),
      name: _s(json, 'name'),
      nameJa: _s(json, 'nameJa'),
      series: _s(json, 'series'),
      line: _s(json, 'line'),
      type: _s(json, 'type'),
      scale: _s(json, 'scale'),
      universe: _s(json, 'universe'),
      date: _s(json, 'date'),
      priceJpy: _iOrNull(json, 'priceJpy'),
      image: _s(json, 'image'),
      gallery: _strs(json['gallery']),
      limited: _b(json, 'limited'),
      pb: _b(json, 'pb'),
      status: parseCollectStatus(json['status']),
      wantedQty: _i(json, 'wantedQty'),
      recent: _b(json, 'recent'),
      month: _b(json, 'month'),
      market: Market.fromJson(json['market']),
      keywords: _strs(json['keywords']),
    );
  }
}

/// 세계관 묶음 (건담 우주세기 · 포켓몬 세대 · Fate 작품 · AC 세대 · BBX 라인)
class World {
  const World({
    required this.id,
    required this.franchiseId,
    required this.label,
    required this.subtitle,
    required this.image,
    required this.total,
    required this.owned,
  });

  final String id;
  final String franchiseId;
  final String label;
  final String subtitle;
  final String image;
  final int total;
  final int owned;

  static World? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    if (id is! String) return null;
    return World(
      id: id,
      franchiseId: _s(json, 'franchiseId'),
      label: _s(json, 'label'),
      subtitle: _s(json, 'subtitle'),
      image: _s(json, 'image'),
      total: _i(json, 'total'),
      owned: _i(json, 'owned'),
    );
  }
}

/// 도감의 작품 (건담)
class GuideWork {
  const GuideWork({
    required this.id,
    required this.section,
    required this.name,
    required this.image,
    required this.total,
    required this.owned,
  });

  final String id;
  final String section;
  final String name;
  final String image;
  final int total;
  final int owned;

  static GuideWork? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    if (id is! String) return null;
    return GuideWork(
      id: id,
      section: _s(json, 'section'),
      name: _s(json, 'name'),
      image: _s(json, 'image'),
      total: _i(json, 'total'),
      owned: _i(json, 'owned'),
    );
  }
}

/// 도감의 기체 칸 — 구매함이면 컬러로 "점등"
class GuideUnit {
  const GuideUnit({
    required this.id,
    required this.workId,
    required this.name,
    required this.nameEn,
    required this.image,
    required this.status,
    required this.kitIds,
  });

  final String id;
  final String workId;
  final String name;
  final String nameEn;
  final String image;
  final CollectStatus status;
  final List<String> kitIds;

  static GuideUnit? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    if (id is! String) return null;
    return GuideUnit(
      id: id,
      workId: _s(json, 'workId'),
      name: _s(json, 'name'),
      nameEn: _s(json, 'nameEn'),
      image: _s(json, 'image'),
      status: parseCollectStatus(json['status']),
      kitIds: _strs(json['kitIds']),
    );
  }
}

/// 베이블레이드 부품 (블레이드 · 래칫 · 비트)
class BbxPart {
  const BbxPart({
    required this.id,
    required this.typeLabel,
    required this.name,
    required this.image,
    required this.have,
    required this.topId,
    required this.stats,
  });

  final String id;
  final String typeLabel;
  final String name;
  final String image;
  final bool have;
  final String topId;

  /// 공격 · 방어 · 지구력 … (부품 대화상자에서만 씀)
  final Map<String, int> stats;

  static BbxPart? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    if (id is! String) return null;
    final raw = json['stats'];
    return BbxPart(
      id: id,
      typeLabel: _s(json, 'typeLabel'),
      name: _s(json, 'name'),
      image: _s(json, 'image'),
      have: _b(json, 'have'),
      topId: _s(json, 'topId'),
      stats: raw is Map<String, Object?>
          ? {for (final e in raw.entries) if (e.value is num) e.key: (e.value! as num).toInt()}
          : const {},
    );
  }
}

/// 베이블레이드 (완성 베이 = 부품 3개)
class BbxTop {
  const BbxTop({
    required this.id,
    required this.line,
    required this.name,
    required this.image,
    required this.owned,
    required this.total,
    required this.parts,
    required this.kitIds,
  });

  final String id;
  final String line;
  final String name;
  final String image;
  final int owned;
  final int total;
  final List<BbxPart> parts;
  final List<String> kitIds;

  static BbxTop? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    if (id is! String) return null;
    final parts = json['parts'];
    return BbxTop(
      id: id,
      line: _s(json, 'line'),
      name: _s(json, 'name'),
      image: _s(json, 'image'),
      owned: _i(json, 'owned'),
      total: _i(json, 'total'),
      parts: parts is List ? parts.map(BbxPart.fromJson).nonNulls.toList() : const [],
      kitIds: _strs(json['kitIds']),
    );
  }
}

/// 공식 예고 (반다이 방송·공지)
class Announcement {
  const Announcement({
    required this.id,
    required this.franchiseId,
    required this.title,
    required this.status,
    required this.date,
    required this.source,
    required this.image,
    required this.hero,
  });

  final String id;
  final String franchiseId;
  final String title;
  final String status;
  final String date;
  final String source;
  final String image;

  /// 가로로 넓은 고화질 배너 — 홈 맨 위 큰 사진에 쓴다
  final bool hero;

  static Announcement? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    if (id is! String) return null;
    return Announcement(
      id: id,
      franchiseId: _s(json, 'franchiseId'),
      title: _s(json, 'title'),
      status: _s(json, 'status'),
      date: _s(json, 'date'),
      source: _s(json, 'source'),
      image: _s(json, 'image'),
      hero: _b(json, 'hero'),
    );
  }
}

/// 내 정보 (가짜 계정 — 실제 로그인 없음)
class Profile {
  const Profile({
    required this.name,
    required this.handle,
    required this.avatarText,
    required this.tags,
    required this.spendKrw,
    required this.workspace,
    required this.inviteCode,
    required this.members,
  });

  final String name;
  final String handle;
  final String avatarText;
  final List<String> tags;
  final int spendKrw;
  final String workspace;
  final String inviteCode;
  final List<({String name, String role, bool self})> members;

  static Profile? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final members = json['members'];
    return Profile(
      name: _s(json, 'name'),
      handle: _s(json, 'handle'),
      avatarText: _s(json, 'avatarText'),
      tags: _strs(json['tags']),
      spendKrw: _i(json, 'spendKrw'),
      workspace: _s(json, 'workspace'),
      inviteCode: _s(json, 'inviteCode'),
      members: [
        if (members is List)
          for (final m in members.whereType<Map<String, Object?>>())
            (name: _s(m, 'name'), role: _s(m, 'role'), self: _b(m, 'self')),
      ],
    );
  }
}
