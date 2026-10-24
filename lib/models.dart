// 데이터 모양 — db.json의 한 항목을 화면이 쓰기 좋은 객체로 바꾼다.
// 형식이 틀린 항목은 null을 돌려준다 → 목록에서 빠질 뿐 앱이 멈추지 않는다 (Dart 3 패턴 매칭).
//
// 비즈니스 명칭: Series = 작품 · Unit = 기체(도감 칸) · Kit = 키트(프라모델 상품)
//               PricePoint = 시세 기록 · CollectStatus = 소장 상태
// 점등 상태 · 수집률은 db.json에 미리 적어 둔 값을 그대로 읽는다(앱이 계산하지 않음).

/// 소장 상태: 소장 · 위시 · 미등록(도감에서는 미보유)
enum CollectStatus { owned, wanted, none }

CollectStatus parseCollectStatus(Object? value) => switch (value) {
  'owned' => CollectStatus.owned,
  'wanted' => CollectStatus.wanted,
  _ => CollectStatus.none,
};

/// 기체 — 도감의 칸 하나
class Unit {
  const Unit({
    required this.id,
    required this.seriesId,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.status,
  });

  final int id;
  final int seriesId;
  final String name;
  final String nameEn;
  final String icon;
  final CollectStatus status;

  static Unit? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'seriesId': int seriesId,
        'name': String name,
        'nameEn': String nameEn,
        'icon': String icon,
      } =>
        Unit(
          id: id,
          seriesId: seriesId,
          name: name,
          nameEn: nameEn,
          icon: icon,
          status: parseCollectStatus(json['status']),
        ),
      _ => null,
    };
  }
}

/// 작품 — 도감의 섹션 하나 (GET /series?_embed=units 로 기체가 함께 온다)
class Series {
  const Series({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.owned,
    required this.wanted,
    required this.total,
    this.units = const [],
  });

  final int id;
  final String name;
  final String nameEn;
  final int owned;
  final int wanted;
  final int total;
  final List<Unit> units;

  static Series? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'name': String name,
        'nameEn': String nameEn,
        'owned': int owned,
        'wanted': int wanted,
        'total': int total,
      } =>
        Series(
          id: id,
          name: name,
          nameEn: nameEn,
          owned: owned,
          wanted: wanted,
          total: total,
          units: switch (json['units']) {
            List<Object?> list => list.map(Unit.fromJson).nonNulls.toList(),
            _ => const [],
          },
        ),
      _ => null,
    };
  }
}

/// 키트 — 카탈로그의 상품 하나
/// (GET /kits?_embed=collection&_expand=unit → 내 소장 상태와 기체가 함께 온다)
class Kit {
  const Kit({
    required this.id,
    required this.unitId,
    required this.name,
    required this.nameJa,
    required this.grade,
    required this.scale,
    required this.priceJpy,
    required this.releaseDate,
    required this.image,
    this.barcode,
    this.myStatus = CollectStatus.none,
    this.unit,
  });

  final int id;
  final int unitId;
  final String name;
  final String nameJa;
  final String grade;
  final String scale;
  final int priceJpy;
  final String releaseDate;
  final String image;
  final String? barcode;
  final CollectStatus myStatus;
  final Unit? unit;

  static Kit? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'unitId': int unitId,
        'name': String name,
        'nameJa': String nameJa,
        'grade': String grade,
        'scale': String scale,
        'priceJpy': int priceJpy,
        'releaseDate': String releaseDate,
        'image': String image,
      } =>
        Kit(
          id: id,
          unitId: unitId,
          name: name,
          nameJa: nameJa,
          grade: grade,
          scale: scale,
          priceJpy: priceJpy,
          releaseDate: releaseDate,
          image: image,
          barcode: switch (json['barcode']) {
            String code => code,
            _ => null,
          },
          // _embed=collection: 이 키트를 가리키는 컬렉션 기록(0개 또는 1개)
          myStatus: switch (json['collection']) {
            [{'status': Object? status}, ...] => parseCollectStatus(status),
            _ => CollectStatus.none,
          },
          unit: Unit.fromJson(json['unit']),
        ),
      _ => null,
    };
  }
}

/// 시세 기록 한 줄 — 예시 데이터
class PricePoint {
  const PricePoint({
    required this.id,
    required this.kitId,
    required this.date,
    required this.priceKrw,
    required this.source,
  });

  final int id;
  final int kitId;
  final String date;
  final int priceKrw;
  final String source;

  static PricePoint? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'kitId': int kitId,
        'date': String date,
        'priceKrw': int priceKrw,
        'source': String source,
      } =>
        PricePoint(
          id: id,
          kitId: kitId,
          date: date,
          priceKrw: priceKrw,
          source: source,
        ),
      _ => null,
    };
  }
}
