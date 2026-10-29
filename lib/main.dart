// Hobby Atlas (hobbyDB v2 재설계) — GAI3008 중간고사 (UI만 구현)
//
// ┌──────── 디자인 가이드 대응표: 앱 뼈대 ──────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명        │ 비즈니스 명칭(한글)                        │ 원칙(P번호)   │
// │ S-14 │ MaterialApp           │ Hobby Atlas                                │ —             │
// │ S-15 │ buildGpTheme()        │ 흑백 + 파랑(고름) · 민트(가진 것) · 글자 6단계 │ P08 · P04 │
// │ S-16 │ MarksHost · PaneHost  │ 좋아요 · 구매함 / 오른쪽 칸에 연 것 (앱 전체) │ P04 · P01 │
// └────────────────────────────────────────────────────────────────────────────┘
// 기획 문서(docs/디자인가이드.md)에 없는 화면은 만들지 않는다(감점). 화면을 늘리면 이 주석·가이드도 같이 고친다.
import 'package:flutter/material.dart';

import 'detail_pane.dart';
import 'marks.dart';
import 'screens/s_app_shell.dart';
import 'theme.dart';

void main() => runApp(const HobbyAtlasApp());

class HobbyAtlasApp extends StatelessWidget {
  const HobbyAtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hobby Atlas', // S-14
      debugShowCheckedModeBanner: false,
      theme: buildGpTheme(), // S-15 P08
      // S-16 앱 전체 한 벌(setState 를 위로): 좋아요 · 구매함(MarksHost) · 반반 화면 오른쪽 칸에 연 것(PaneHost)
      builder: (context, child) => MarksHost(child: PaneHost(child: child!)),
      home: const AppShell(),
    );
  }
}
