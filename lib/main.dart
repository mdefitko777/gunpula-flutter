// hobbyDB v2 (건프라 도감) — GAI3008 중간고사 (UI만 구현)
//
// ┌──────── 디자인 가이드 대응표: 앱 뼈대 ──────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명        │ 비즈니스 명칭(한글)                        │ 원칙(P번호)   │
// │ S-1  │ MaterialApp           │ hobbyDB v2                                 │ —             │
// │ S-2  │ ThemeData(seedColor)  │ 브랜드 색 (상태 색은 widgets.dart CollectColors) │ P04 일관성 │
// └────────────────────────────────────────────────────────────────────────────┘
// 화면 흐름(docs/디자인가이드.md 1장과 같게):
//   S 홈 탭 구조 [옆으로(탭): A 카탈로그 | D 도감 | F 내 컬렉션]
//   A ──덮기(modal)──▶ C 바코드 스캔 결과(임의) ──쌓기(push)──▶ B 키트 상세
//   A ──쌓기(push)──▶ B 키트 상세 [옆으로(tab): 정보 | 시세 기록] ──쌓기(push)──▶ E 기체 상세
//   D ──쌓기(push)──▶ E 기체 상세 ──쌓기(push)──▶ B ·  E ──덮기(dialog)──▶ 누락 키트 제보 확인
//   F [옆으로(tab): 소장 | 위시] ──쌓기(push)──▶ B
// 기획 문서에 없는 화면은 만들지 않는다(감점). 화면을 늘리면 이 주석·가이드도 같이 고친다.
import 'package:flutter/material.dart';

import 'screens/s_home_shell.dart';

void main() => runApp(const HobbyDbApp());

class HobbyDbApp extends StatelessWidget {
  const HobbyDbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'hobbyDB v2', // S-1
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2A5DB0)), // S-2 P04
      home: const HomeShell(),
    );
  }
}
