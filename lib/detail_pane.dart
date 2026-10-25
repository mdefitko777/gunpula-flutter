// 넓은 화면(폴드 펼침 · 태블릿 · 넓은 창)의 반반 화면 — QQ 처럼 왼쪽은 앱 그대로, 오른쪽은 자세히 칸.
// 상세 · 공고 · 친구 · 내 정보 · 알림 · 설정 · 작품 도감은 openPage 로 연다:
//   폰(칸 없음)  → 지금처럼 쌓기(push, 오른쪽에서)
//   왼쪽에서 열기 → 오른쪽 칸의 내용을 바꿈 (메신저에서 대화방을 고르듯)
//   오른쪽 안에서 열기 → 오른쪽 칸 안에서 쌓기 (‹ 로 돌아감)
// 상태관리 패키지 없이: 칸 Navigator 의 GlobalKey 하나 + "칸 안쪽" 표시 InheritedWidget.
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';

import 'theme.dart';

/// 오른쪽 자세히 칸의 Navigator — 앱에 칸은 하나뿐. 넓은 화면에서만 붙어 있다(아니면 currentState == null)
final detailPaneKey = GlobalKey<NavigatorState>();

/// 오른쪽 칸 안쪽 표시 — 여기서 연 화면은 칸 안에서 쌓는다
class _InsidePane extends InheritedWidget {
  const _InsidePane({required super.child});

  @override
  bool updateShouldNotify(_InsidePane old) => false;
}

/// 화면 열기: 넓으면 오른쪽 칸, 아니면 쌓기
void openPage(BuildContext context, Widget page) {
  final nav = detailPaneKey.currentState;
  final inside = context.getInheritedWidgetOfExactType<_InsidePane>() != null;
  // 앱 셸(맨 아래 화면: 왼쪽 · 서랍 · 🔔 ⚙)에서 연 것만 칸으로. 위에 덮인 전체 화면(카메라 결과 등)에서는 그 위에 쌓기
  final fromShell = ModalRoute.of(context)?.isFirst ?? false;
  if (nav == null || (!inside && !fromShell)) {
    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute<void>(builder: (_) => page));
    return;
  }
  if (inside) {
    nav.push(CupertinoPageRoute<void>(builder: (_) => page)); // 칸 안에서 더 들어가기
  } else {
    // 왼쪽에서 고름 → 칸 내용을 바꿈 (빈 칸 안내 위에 하나만)
    nav.pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => page,
        transitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
      (r) => r.isFirst,
    );
  }
}

/// 오른쪽 칸 본체: 칸 전용 Navigator + 아무것도 안 골랐을 때 안내
class DetailPaneView extends StatelessWidget {
  const DetailPaneView({super.key});

  @override
  Widget build(BuildContext context) {
    return _InsidePane(
      // 안드로이드 뒤로 가기: 오른쪽 칸에 쌓인 게 있으면 그것부터 닫는다
      child: NavigatorPopHandler<void>(
        onPopWithResult: (_) => detailPaneKey.currentState?.maybePop(),
        child: ClipRect(
          child: Navigator(
            key: detailPaneKey,
            onGenerateRoute: (_) => PageRouteBuilder<void>(pageBuilder: (_, _, _) => const _EmptyPane()),
          ),
        ),
      ),
    );
  }
}

/// 빈 칸: 옅은 로고 + 한 줄 안내 (QQ 의 펭귄 자리)
class _EmptyPane extends StatelessWidget {
  const _EmptyPane();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Gp.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_in_ar_outlined, size: 72, color: Color(0xFFDCDCDA)),
            SizedBox(height: 10),
            Text(
              'Gunpula',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFFDCDCDA)),
            ),
            SizedBox(height: 8),
            Text('상품 · 공고 · 친구를 고르면 여기에 보여요', style: TextStyle(fontSize: 13, color: Gp.faint)),
          ],
        ),
      ),
    );
  }
}
