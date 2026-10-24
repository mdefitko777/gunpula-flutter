// 3상태(로딩·오류·빈) + 화면 흐름(push · tab · modal · dialog) + 적응형 위젯 테스트.
// 네트워크를 쓰지 않도록 화면에 가짜 Loaders를 넣는다 → json-server 없이 `flutter test`가 돈다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mid_project_template/api.dart';
import 'package:mid_project_template/models.dart';
import 'package:mid_project_template/screens/a_catalog_screen.dart';
import 'package:mid_project_template/screens/d_picturebook_screen.dart';
import 'package:mid_project_template/screens/s_home_shell.dart';

const _aerial = Unit(
  id: 1,
  seriesId: 1,
  name: '건담 에어리얼',
  nameEn: 'Gundam Aerial',
  icon: '',
  status: CollectStatus.owned,
);
const _aegis = Unit(
  id: 2,
  seriesId: 1,
  name: '이지스 건담',
  nameEn: 'Aegis Gundam',
  icon: '',
  status: CollectStatus.none,
);

const _kits = [
  Kit(
    id: 4,
    unitId: 1,
    name: 'HG 1/144 건담 캘리번',
    nameJa: 'HG 1 / 144 ガンダムキャリバーン',
    grade: 'HG',
    scale: '1/144',
    priceJpy: 2200,
    releaseDate: '2023-07-15',
    image: '',
    barcode: '4573102653222',
    myStatus: CollectStatus.owned,
    unit: _aerial,
  ),
  Kit(
    id: 2,
    unitId: 1,
    name: 'FM 1/100 건담 에어리얼',
    nameJa: 'FULL MECHANICS 1 / 100 ガンダムエアリアル',
    grade: 'FM',
    scale: '1/100',
    priceJpy: 4180,
    releaseDate: '2023-04-22',
    image: '',
    myStatus: CollectStatus.wanted,
    unit: _aerial,
  ),
];

const _series = [
  Series(
    id: 1,
    name: '기동전사 건담 수성의 마녀',
    nameEn: 'The Witch from Mercury',
    owned: 1,
    wanted: 0,
    total: 2,
    units: [_aerial, _aegis],
  ),
];

Loaders _loaders({KitsLoader? kits}) => Loaders(
  kits: kits ?? () async => _kits,
  kitsOfUnit: (unitId) async => unitId == _aegis.id ? const [] : _kits,
  prices: (_) async => const [],
  series: () async => _series,
);

Widget _app(Widget home) => MaterialApp(home: home);

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('A 카탈로그 3상태: 로딩 → 오류 → 다시 시도 → 성공', (tester) async {
    _setSize(tester, const Size(400, 800));
    final first = Completer<List<Kit>>();
    var calls = 0;
    await tester.pumpWidget(
      _app(
        CatalogScreen(
          loaders: _loaders(
            kits: () => ++calls == 1 ? first.future : Future.value(_kits),
          ),
        ),
      ),
    );
    expect(find.text('키트 목록을 불러오는 중…'), findsOneWidget);

    first.completeError(Exception('테스트 오류'));
    await tester.pumpAndSettle();
    expect(find.text('키트 목록을 불러오지 못했습니다.'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('HG 1/144 건담 캘리번'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('A 카탈로그 빈 상태', (tester) async {
    await tester.pumpWidget(
      _app(CatalogScreen(loaders: _loaders(kits: () async => const []))),
    );
    await tester.pumpAndSettle();
    expect(find.text('아직 등록된 키트가 없습니다.'), findsOneWidget);
  });

  testWidgets('A 가짜 검색 · 등급 필터 · 필터 초기화', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(CatalogScreen(loaders: _loaders())));
    await tester.pumpAndSettle();
    expect(find.text('키트 2개'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'FM'));
    await tester.pumpAndSettle();
    expect(find.text('키트 1개'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '없는키트');
    await tester.pumpAndSettle();
    expect(find.text('조건에 맞는 키트가 없습니다.'), findsOneWidget);

    await tester.tap(find.text('필터 초기화'));
    await tester.pumpAndSettle();
    expect(find.text('키트 2개'), findsOneWidget);
  });

  testWidgets('흐름: A → push B → 소장 상태(가짜 저장·되돌리기) → tab 시세 기록', (
    tester,
  ) async {
    _setSize(tester, const Size(400, 900));
    await tester.pumpWidget(_app(CatalogScreen(loaders: _loaders())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('HG 1/144 건담 캘리번'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget); // push

    await tester.tap(find.text('위시'));
    await tester.pumpAndSettle();
    expect(find.textContaining('저장되지 않습니다'), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('시세 기록'));
    await tester.pumpAndSettle();
    expect(find.text('아직 이 키트의 시세 기록이 없습니다.'), findsOneWidget); // tab + 빈 상태
  });

  testWidgets('흐름: A 스캔 버튼 → modal C 스캔 결과(임의)', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(CatalogScreen(loaders: _loaders())));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('바코드 스캔'));
    await tester.pumpAndSettle();
    expect(find.text('인식 완료'), findsOneWidget);
    expect(find.textContaining('실제 스캔 기능은 없습니다'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('인식 완료'), findsNothing);
  });

  testWidgets('흐름: D 도감 → 풀컬러 → push E → 누락 키트 제보 dialog', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(PicturebookScreen(loaders: _loaders())));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2 소장 · 위시 0'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, '풀컬러'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilterChip>(find.widgetWithText(FilterChip, '풀컬러')).selected,
      isTrue,
    );

    await tester.tap(find.text('이지스 건담'));
    await tester.pumpAndSettle();
    expect(find.text('이 기체로 등록된 키트가 아직 없습니다.\n빠진 키트가 있다면 알려 주세요.'), findsOneWidget);

    await tester.tap(find.text('누락 키트 제보'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget); // dialog
    await tester.tap(find.text('제보하기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('전송하지 않았습니다'), findsOneWidget);
  });

  testWidgets('적응형: 카탈로그 600dp 이상이면 격자', (tester) async {
    _setSize(tester, const Size(1024, 768));
    await tester.pumpWidget(_app(CatalogScreen(loaders: _loaders())));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('적응형: 홈 탭 구조 840dp 기준 하단 탭 ↔ 측면 탭', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(HomeShell(loaders: _loaders())));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.text('내 컬렉션'));
    await tester.pumpAndSettle();
    expect(find.text('소장 1'), findsOneWidget);

    _setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(_app(HomeShell(loaders: _loaders())));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
