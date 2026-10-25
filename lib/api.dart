// 데이터 가져오기 — GET만 쓴다 (중간고사 안내 5장: POST/PUT/DELETE·저장은 감점)
// 화면 코드는 이 파일의 fetch…() 함수만 부른다. (관심사 분리)
//
// 서버 주소 (코드 수정 없이 실행할 때 바꾼다):
//   기본값  Android 에뮬레이터 → http://10.0.2.2:3000   그 외(Chrome·macOS·iOS 시뮬레이터) → http://localhost:3000
//   실기기  flutter run --dart-define=API_BASE=http://192.168.0.10:3000   (같은 Wi-Fi의 PC IP)
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

/// GET {apiBase}/{path} → JSON (배열 또는 객체)
Future<Object?> _get(String path) async {
  switch (demoState) {
    case 'loading' || 'slow':
      await Future<void>.delayed(const Duration(seconds: 3));
    case 'error':
      throw const ApiException('DEMO_STATE=error 로 일부러 낸 오류입니다.');
    case 'empty':
      return const <Object?>[];
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
  return jsonDecode(utf8.decode(res.bodyBytes));
}

Future<List<T>> _getList<T extends Object>(String path, T? Function(Object?) parse) async {
  final decoded = await _get(path);
  if (decoded is! List) {
    throw ApiException('$path 의 응답이 배열이 아닙니다. db.json을 확인하세요.');
  }
  return decoded.map(parse).nonNulls.toList();
}

/// 채널(IP) 여러 개 → json-server 쿼리 `franchiseId=a&franchiseId=b` (OR)
String _byChannels(List<String> ids) => ids.map((id) => 'franchiseId=$id').join('&');

/// 홈 · 검색 · 캘린더: 내 채널의 상품. 채널이 없으면 요청하지 않는다.
Future<List<Kit>> fetchKits(List<String> channelIds) async {
  if (channelIds.isEmpty) return const [];
  return _getList('kits?${_byChannels(channelIds)}&_sort=date&_order=desc', Kit.fromJson);
}

/// 컬렉션: 좋아요 · 구매함 상품 (모든 채널)
Future<List<Kit>> fetchCollection() =>
    _getList('kits?status_ne=none&_sort=date&_order=desc', Kit.fromJson);

/// 도감 대화상자의 대응 모델: GET /kits?id=a&id=b
Future<List<Kit>> fetchKitsByIds(List<String> ids) async {
  if (ids.isEmpty) return const [];
  return _getList('kits?${ids.map((id) => 'id=$id').join('&')}', Kit.fromJson);
}

/// 도감(포켓몬 세대 · Fate 작품 · AC 세대 · BBX 라인) · 홈 진행도
Future<List<World>> fetchWorlds(String channelId) =>
    _getList('worlds?franchiseId=$channelId&_sort=order', World.fromJson);

/// 도감 > 건담: 작품 목록
Future<List<GuideWork>> fetchGuideWorks() => _getList('guideWorks', GuideWork.fromJson);

/// 도감 > 건담 > 작품: 기체 칸
Future<List<GuideUnit>> fetchGuideUnits(String workId) =>
    _getList('guideUnits?workId=$workId', GuideUnit.fromJson);

/// 도감 > 베이블레이드 X
Future<List<BbxTop>> fetchBbxTops() => _getList('bbxTops', BbxTop.fromJson);

/// 캘린더 · 홈: 공식 예고
Future<List<Announcement>> fetchAnnouncements(List<String> channelIds) async {
  if (channelIds.isEmpty) return const [];
  return _getList(
    'announcements?${_byChannels(channelIds)}&_sort=date&_order=desc',
    Announcement.fromJson,
  );
}

/// 내 정보: GET /profile (객체 하나)
Future<Profile> fetchProfile() async {
  final decoded = await _get('profile');
  final p = Profile.fromJson(decoded);
  if (p == null) throw const ApiException('profile 응답 모양이 맞지 않습니다.');
  return p;
}

/// 화면 사이에 그대로 넘겨 주는 데이터 함수 묶음 (상태관리가 아니라 의존성 주입).
/// 앱은 기본값(실제 GET)을, 테스트는 가짜 함수를 넣는다.
class Loaders {
  const Loaders({
    this.kits = fetchKits,
    this.collection = fetchCollection,
    this.kitsByIds = fetchKitsByIds,
    this.worlds = fetchWorlds,
    this.guideWorks = fetchGuideWorks,
    this.guideUnits = fetchGuideUnits,
    this.bbxTops = fetchBbxTops,
    this.announcements = fetchAnnouncements,
    this.profile = fetchProfile,
  });

  final Future<List<Kit>> Function(List<String> channelIds) kits;
  final Future<List<Kit>> Function() collection;
  final Future<List<Kit>> Function(List<String> ids) kitsByIds;
  final Future<List<World>> Function(String channelId) worlds;
  final Future<List<GuideWork>> Function() guideWorks;
  final Future<List<GuideUnit>> Function(String workId) guideUnits;
  final Future<List<BbxTop>> Function() bbxTops;
  final Future<List<Announcement>> Function(List<String> channelIds) announcements;
  final Future<Profile> Function() profile;
}
