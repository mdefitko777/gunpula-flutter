// Gunpula v2 — GAI3008 중간고사 (UI만 구현)
//
// ┌──────── 디자인 가이드 대응표: 앱 뼈대 ──────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명        │ 비즈니스 명칭(한글)                        │ 원칙(P번호)   │
// │ M-1  │ MaterialApp           │ Gunpula v2                                 │ —             │
// │ M-2  │ buildGpTheme()        │ 흑백 테마 (색은 상품 사진에만)              │ P08 · P04     │
// └────────────────────────────────────────────────────────────────────────────┘
// 기획 문서(docs/디자인가이드.md)에 없는 화면은 만들지 않는다(감점). 화면을 늘리면 이 주석·가이드도 같이 고친다.
import 'package:flutter/material.dart';

import 'screens/s_app_shell.dart';
import 'theme.dart';

void main() => runApp(const GunpulaApp());

class GunpulaApp extends StatelessWidget {
  const GunpulaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gunpula v2', // M-1
      debugShowCheckedModeBanner: false,
      theme: buildGpTheme(), // M-2 P08
      home: const AppShell(),
    );
  }
}
