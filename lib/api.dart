// 데이터 가져오기 — GET만 쓴다 (중간고사 안내 5장: POST/PUT/DELETE·저장은 감점)
// 화면 코드는 이 파일의 fetchKits() · fetchKitsOfUnit() · fetchPrices() · fetchSeries()만 부른다. (관심사 분리)
//
// 서버 주소 (코드 수정 없이 실행할 때 바꾼다):
//   기본값  Android 에뮬레이터 → http://10.0.2.2:3000   그 외(Chrome·macOS·iOS 시뮬레이터) → http://localhost:3000
//   실기기  flutter run --dart-define=API_BASE=http://192.168.0.10:3000   (같은 Wi-Fi의 PC IP)
//   배포    flutter build web --dart-define=API_BASE=https://<프로젝트>.vercel.app/api   (가산점)
//
// 발표·데모용 상태 스위치 (로딩·오류·빈 상태를 눈으로 보여 주기):
//   --dart-define=DEMO_STATE=loading → 3초 늦게 응답 (로딩 상태)
//   --dart-define=DEMO_STATE=error   → 항상 실패 (오류 상태 + 다시 시도)
//   --dart-define=DEMO_STATE=empty   → 빈 목록 (빈 상태)
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

const _apiBaseOverride = String.fromEnvironment('API_BASE');

/// json-server 주소. API_BASE를 넘기면 그 값, 아니면 실행 대상에 맞는 기본값.
String get apiBase {
  if (_apiBaseOverride.isNotEmpty) return _apiBaseOverride;
  // Android 에뮬레이터 안의 localhost는 에뮬레이터 자신 → PC는 10.0.2.2
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

/// loading(=slow) · error · empty — 그 외 값이면 평소처럼 서버에서 가져온다.
const demoState = String.fromEnvironment('DEMO_STATE');

/// 화면에 그대로 보여 줄 수 있는 오류 문장
class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// GET {apiBase}/{path} → JSON 배열
Future<List<Object?>> _getList(String path) async {
  switch (demoState) {
    case 'loading' || 'slow':
      await Future<void>.delayed(const Duration(seconds: 3));
    case 'error':
      throw const ApiException('DEMO_STATE=error 로 일부러 낸 오류입니다.');
    case 'empty':
      return const [];
  }
  final url = '$apiBase/$path';
  final http.Response res;
  try {
    res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
  } on Exception catch (e) {
    debugPrint('[GET 실패] $url — $e');
    throw ApiException('서버에 연결하지 못했습니다.\n$apiBase\nmock_server가 켜져 있는지 확인하세요.');
  }
  if (res.statusCode != 200) {
    throw ApiException('서버 응답 오류 (HTTP ${res.statusCode})\n$url');
  }
  // 한글이 깨지지 않도록 bytes를 UTF-8로 직접 디코딩
  final decoded = jsonDecode(utf8.decode(res.bodyBytes));
  if (decoded is! List) {
    throw ApiException('$url 의 응답이 배열이 아닙니다. db.json을 확인하세요.');
  }
  return decoded;
}

// db.json 최상위 키: series · units · kits · prices · collection
// _embed / _expand / _sort 는 json-server의 GET 쿼리 — 서버가 묶어서 내려 줄 뿐 쓰기 요청이 아니다.

/// A 카탈로그 · F 내 컬렉션: GET /kits (내 소장 상태 + 기체 포함)
Future<List<Kit>> fetchKits() async {
  final list = await _getList('kits?_embed=collection&_expand=unit');
  return list.map(Kit.fromJson).nonNulls.toList();
}

/// E 기체 상세의 대응 키트: GET /kits?unitId=
Future<List<Kit>> fetchKitsOfUnit(int unitId) async {
  final list = await _getList(
    'kits?unitId=$unitId&_embed=collection&_expand=unit',
  );
  return list.map(Kit.fromJson).nonNulls.toList();
}

/// B 키트 상세 '시세 기록' 탭: GET /prices?kitId= (최신이 위)
Future<List<PricePoint>> fetchPrices(int kitId) async {
  final list = await _getList('prices?kitId=$kitId&_sort=date&_order=desc');
  return list.map(PricePoint.fromJson).nonNulls.toList();
}

/// D 도감: GET /series (작품마다 기체 목록 포함)
Future<List<Series>> fetchSeries() async {
  final list = await _getList('series?_embed=units');
  return list.map(Series.fromJson).nonNulls.toList();
}

/// 화면이 데이터를 받는 함수 모양 — 테스트에서는 가짜 함수를 넣는다.
typedef KitsLoader = Future<List<Kit>> Function();
typedef UnitKitsLoader = Future<List<Kit>> Function(int unitId);
typedef PricesLoader = Future<List<PricePoint>> Function(int kitId);
typedef SeriesLoader = Future<List<Series>> Function();

/// 화면 사이에 그대로 넘겨 주는 데이터 함수 묶음 (상태관리가 아니라 의존성 주입).
/// 앱은 기본값(실제 GET)을, 테스트는 가짜 함수를 넣는다.
class Loaders {
  const Loaders({
    this.kits = fetchKits,
    this.kitsOfUnit = fetchKitsOfUnit,
    this.prices = fetchPrices,
    this.series = fetchSeries,
  });

  final KitsLoader kits;
  final UnitKitsLoader kitsOfUnit;
  final PricesLoader prices;
  final SeriesLoader series;
}
