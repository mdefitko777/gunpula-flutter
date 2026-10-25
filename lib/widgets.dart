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
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Gp.muted)),
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
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: Gp.muted)),
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
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
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

/// 섹션 제목 줄: 제목 + 오른쪽 작은 글자/버튼
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

String _comma(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// 일본 정가: ¥3,850 (없으면 '가격 미정')
String yen(int? v) => v == null ? '가격 미정' : '¥${_comma(v)}';

/// 원화: 41,000원
String won(int v) => '${_comma(v)}원';
