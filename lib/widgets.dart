// 공용 화면 조각 — GET을 쓰는 화면은 모두 이 세 상태를 그린다 (AGENTS.md MUST).
//   LoadingView  불러오는 중          P01 시스템 상태의 가시성
//   ErrorView    오류 안내·다시 시도   P09 오류 인식·진단·복구
//   EmptyView    빈 목록 안내(+ 할 일) P01 · P09
// 그리고 여러 화면이 같은 모양으로 쓰는 조각 (P04 일관성): AppImage · SectionTitle · 가격 표기
import 'package:flutter/material.dart';

import 'theme.dart';

/// 로딩 상태
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = '불러오는 중…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Gp.ink),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Gp.muted)),
          ],
        ),
      ),
    );
  }
}

/// 오류 상태: 무엇이 잘못됐는지 + 다시 시도 버튼
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = '정보를 불러오지 못했어요',
    this.message = '',
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: Gp.ink),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Gp.muted),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 빈 상태: 왜 비었는지 + (있으면) 다음에 할 일 버튼
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.message = '표시할 항목이 없어요',
    this.detail = '',
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final String detail;
  final IconData icon;

  /// 예: 필터 초기화 · 채널 추가 버튼
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Gp.faint),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Gp.muted),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

/// 상품·로고 이미지. 경로가 비었거나 못 읽으면 회색 칸 + 글자.
/// [grayscale] = 도감에서 아직 모으지 않은 칸 (불 꺼짐)
class AppImage extends StatelessWidget {
  const AppImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.placeholder = '',
    this.grayscale = false,
  });

  final String path;
  final BoxFit fit;
  final String placeholder;
  final bool grayscale;

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext _, Object _, StackTrace? _) => _Placeholder(placeholder);
    if (path.isEmpty) return _Placeholder(placeholder);
    final Widget img = path.startsWith('http')
        ? Image.network(path, fit: fit, errorBuilder: fallback)
        : Image.asset(path, fit: fit, errorBuilder: fallback);
    if (!grayscale) return img;
    return Opacity(
      opacity: 0.55,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: img,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Gp.soft,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Gp.faint, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// 원 안에 사진(또는 첫 글자) — 채널 아이콘 · 아바타
class CircleThumb extends StatelessWidget {
  const CircleThumb({super.key, required this.image, required this.label, this.size = 40});

  final String image;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Gp.soft,
        border: Border.all(color: Gp.line),
      ),
      child: image.isEmpty
          ? Center(
              child: Text(
                label.characters.first,
                style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w800),
              ),
            )
          : AppImage(image),
    );
  }
}

/// 떠 있는 흰 원형 버튼 — 아바타 · 가운데 + 버튼
class RaisedCircleButton extends StatelessWidget {
  const RaisedCircleButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.tooltip,
    this.size = 40,
  });

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: Gp.raised(shape: BoxShape.circle),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 채널 관리 아이콘: 짧은 선(왼쪽 위) · 긴 선(가운데) · 짧은 선(오른쪽 아래)
class ChannelGlyph extends StatelessWidget {
  const ChannelGlyph({super.key, this.size = 22, this.color = Gp.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ChannelGlyphPainter(color));
}

class _ChannelGlyphPainter extends CustomPainter {
  const _ChannelGlyphPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = s.width * 0.085
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        Offset(s.width * 0.12, s.height * 0.26),
        Offset(s.width * 0.52, s.height * 0.26),
        p,
      )
      ..drawLine(Offset(s.width * 0.12, s.height * 0.5), Offset(s.width * 0.88, s.height * 0.5), p)
      ..drawLine(
        Offset(s.width * 0.48, s.height * 0.74),
        Offset(s.width * 0.88, s.height * 0.74),
        p,
      );
  }

  @override
  bool shouldRepaint(_ChannelGlyphPainter old) => old.color != color;
}

/// 검색창 — 홈과 검색 화면이 같은 것을 쓴다 (크기 · 글자 · 아이콘 통일, P04).
/// [onTap]을 주면 입력하지 않는 "입구"(홈): 누르면 검색 화면으로 간다.
/// 아니면 [controller]로 바로 입력하는 검색창(검색 화면).
class GpSearchBar extends StatelessWidget {
  const GpSearchBar({
    super.key,
    required this.onCamera,
    this.onTap,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  /// 오른쪽 카메라 → 찍어서 찾기 (하단 카메라 버튼과 같은 동작)
  final VoidCallback onCamera;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  static const hint = '이름 · 번호 · 생김새로 찾기';
  static const _textStyle = TextStyle(fontSize: 14.5, color: Gp.ink);
  static const _hintStyle = TextStyle(fontSize: 14.5, color: Gp.faint);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    // 홈 입구도 같은 TextField로 그린다(읽기 전용) — 안내 문구의 위치·간격이 두 화면에서 똑같게
    final Widget field = TextField(
      controller: c,
      focusNode: focusNode,
      readOnly: onTap != null,
      showCursor: onTap == null,
      enableInteractiveSelection: onTap == null,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: _textStyle,
      decoration: const InputDecoration(
        hintText: hint,
        hintStyle: _hintStyle,
        filled: false,
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
    return Semantics(
      button: onTap != null,
      label: onTap != null ? '검색 열기' : null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 16, right: 4),
          decoration: Gp.raised(radius: 24),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: Gp.muted),
              const SizedBox(width: 10),
              Expanded(child: field),
              if (c != null && onTap == null)
                ValueListenableBuilder(
                  valueListenable: c,
                  builder: (context, v, _) => v.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: '지우기', // P03
                          icon: const Icon(Icons.cancel, size: 18, color: Gp.faint),
                          onPressed: () {
                            c.clear();
                            onChanged?.call('');
                          },
                        ),
                ),
              IconButton(
                tooltip: '찍어서 찾기',
                icon: const Icon(Icons.photo_camera_outlined, size: 21, color: Gp.ink),
                onPressed: onCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 아직 만들지 않은 화면으로 가는 자리 — 같은 안내 문구로 통일
void showSoon(BuildContext context, [String what = '상품 상세']) =>
    showToast(context, '$what 화면은 다음 단계에서 만들어요');

/// 짧은 알림(토스트) — 흰 바탕 · 검정 글자, 2.5초 뒤 사라진다. [onUndo]가 있으면 "되돌리기" (P03)
void showToast(BuildContext context, String message, {VoidCallback? onUndo}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 2500),
        persist: false, // 되돌리기가 있어도 몇 초 뒤 저절로 사라지게
        action: onUndo == null ? null : SnackBarAction(label: '되돌리기', onPressed: onUndo),
      ),
    );
}

/// 목록 맨 아래 여백 — 하단 탭 바 · 카메라 버튼에 가려지지 않게
double navClearance(BuildContext context) => MediaQuery.paddingOf(context).bottom + 100;

/// 섹션 제목: 브랜드 색 세로 막대 + 제목 (+ 기간 같은 보조 글 · 오른쪽 버튼 · › 전체 보기)
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle = '',
    this.trailing,
    this.onMore,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 12, 12),
  });

  final String title;

  /// 브랜드 색 작은 글자 (예: 최근 추가 기간)
  final String subtitle;
  final Widget? trailing;

  /// 주면 오른쪽에 › 가 붙고 줄 전체를 누를 수 있다
  final VoidCallback? onMore;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 20,
            margin: const EdgeInsets.only(top: 1, right: 10),
            decoration: BoxDecoration(
              color: Gp.accent, // 브랜드 포인트 색
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Gp.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
          if (onMore != null) const Icon(Icons.chevron_right, color: Gp.muted),
        ],
      ),
    );
    return onMore == null ? row : InkWell(onTap: onMore, child: row);
  }
}

/// 둥근 모서리 상품 사진 (회백색 바탕)
class PhotoThumb extends StatelessWidget {
  const PhotoThumb(this.image, {super.key, this.radius = 14});
  final String image;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(color: Gp.soft, child: AppImage(image)),
    );
  }
}

/// 상품 카드: 사진(+ 왼쪽 위 원함 담기) · 이름 · 보조 한 줄
/// 홈 가로 줄 · 검색 결과가 같이 쓴다. [imageWidth]가 있으면 고정 너비(가로 줄), 없으면 칸 너비.
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.image,
    required this.title,
    required this.onTap,
    this.subtitle = '',
    this.onAdd,
    this.imageWidth,
    this.imageAspect = 1,
    this.titleLines = 1,
  });

  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// 주면 사진 왼쪽 위에 + (원함 담기) 자리
  final VoidCallback? onAdd;
  final double? imageWidth;

  /// 가로 / 세로 (1 = 정사각형, 공식 예고 배너는 16:9 쯤)
  final double imageAspect;
  final int titleLines;

  @override
  Widget build(BuildContext context) {
    final photo = AspectRatio(
      aspectRatio: imageAspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PhotoThumb(image),
          if (onAdd != null) Positioned(left: 6, top: 6, child: AddSlot(onTap: onAdd!)),
        ],
      ),
    );
    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        photo,
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: titleLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5, height: 1.3),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Gp.muted),
          ),
        ],
      ],
    );
    return GestureDetector(
      onTap: onTap,
      child: imageWidth == null ? card : SizedBox(width: imageWidth, child: card),
    );
  }
}

/// 사진 왼쪽 위 + 자리 — 원함 담기 (컬렉션과 연결할 때 동작을 정한다)
class AddSlot extends StatelessWidget {
  const AddSlot({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '원함에 담기',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xD9FFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: Gp.line),
          ),
          child: const Icon(Icons.add, size: 18, color: Gp.ink),
        ),
      ),
    );
  }
}

/// 원함 담기 자리를 눌렀을 때 (컬렉션 화면과 연결 전)
void showAddSoon(BuildContext context) =>
    showToast(context, '원함 담기는 컬렉션 화면과 함께 연결할 예정이에요');

String _comma(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// 일본 정가: ¥3,850 (없으면 '가격 미정')
String yen(int? v) => v == null ? '가격 미정' : '¥${_comma(v)}';

/// 원화: 41,000원
String won(int v) => '${_comma(v)}원';
