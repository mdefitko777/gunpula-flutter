// 공용 화면 조각 — GET을 쓰는 화면은 모두 이 세 상태를 그린다 (AGENTS.md MUST).
//   LoadingView  불러오는 중          P01 시스템 상태의 가시성
//   ErrorView    오류 안내·다시 시도   P09 오류 인식·진단·복구
//   EmptyView    빈 목록 안내(+ 할 일) P01 · P09
// 그리고 여러 화면이 같은 모양으로 쓰는 조각 (P04 일관성):
//   CollectColors 상태 색(소장 초록 · 위시 주황) · StatusBadge 소장 상태 배지
//   AppImage 박스아트·기체 아이콘 · KitCard 키트 카드
import 'package:flutter/material.dart';

import 'models.dart';

/// 로딩 상태
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = '불러오는 중…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label),
        ],
      ),
    );
  }
}

/// 오류 상태: 무엇이 잘못됐는지 + 다시 시도 버튼
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = '정보를 불러오지 못했습니다.',
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
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
    this.message = '표시할 항목이 없습니다.',
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final IconData icon;

  /// 빈 화면에서 바로 할 수 있는 일 (예: 필터 초기화, 누락 제보)
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// 상태 색 — 소장 = 초록, 위시 = 주황. 모든 화면이 이 두 색만 쓴다 (S-2 P04)
abstract final class CollectColors {
  static const owned = Color(0xFF2E9E6B);
  static const wanted = Color(0xFFE0A63A);

  static Color? of(CollectStatus status) => switch (status) {
    CollectStatus.owned => owned,
    CollectStatus.wanted => wanted,
    CollectStatus.none => null,
  };
}

String collectLabel(CollectStatus status) => switch (status) {
  CollectStatus.owned => '소장',
  CollectStatus.wanted => '위시',
  CollectStatus.none => '미등록',
};

/// 소장 상태 배지 — 색 + 기호를 같이 써서 색만으로 구분하지 않는다
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.noneLabel});

  final CollectStatus status;

  /// 미등록일 때 보여 줄 글자. null이면 미등록 배지는 그리지 않는다.
  final String? noneLabel;

  @override
  Widget build(BuildContext context) {
    final color = CollectColors.of(status);
    if (color == null && noneLabel == null) return const SizedBox.shrink();
    final symbol = switch (status) {
      CollectStatus.owned => '✓',
      CollectStatus.wanted => '★',
      CollectStatus.none => '·',
    };
    final fill = color ?? Theme.of(context).colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$symbol ${status == CollectStatus.none ? noneLabel : collectLabel(status)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 이미지 — 앱에 넣어 둔 자산(assets/…) 또는 주소(http…). 실패해도 화면은 그대로.
class AppImage extends StatelessWidget {
  const AppImage(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        SizedBox(
          width: width,
          height: height,
          child: const Icon(Icons.image_not_supported_outlined, size: 32),
        );
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: fallback,
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: fallback,
    );
  }
}

/// 엔화 정가 표시 (천 단위 쉼표) — 계산이 아니라 글자 모양 바꾸기
String yen(int value) => '¥${_comma(value)}';
String won(int value) => '${_comma(value)}원';
String _comma(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

/// 키트 카드 — 카탈로그 · 기체 상세 · 내 컬렉션이 같은 카드를 쓴다 (P04 · P08)
/// 순서: 사진 → 이름 → 등급·발매 → 정가, 오른쪽 위에 소장 상태 배지
class KitCard extends StatelessWidget {
  const KitCard(this.kit, {super.key, this.onTap, this.vertical = false});

  final Kit kit;
  final VoidCallback? onTap;

  /// true: 넓은 화면 격자용(사진 위, 글 아래) · false: 폰 목록용(사진 왼쪽)
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          kit.name,
          style: text.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${kit.grade} · ${kit.releaseDate} 발매',
          style: text.bodySmall,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(yen(kit.priceJpy), style: text.bodyMedium),
      ],
    );
    final badge = StatusBadge(kit.myStatus); // A-7 P04 P01
    return Card(
      margin: vertical
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: Colors.white,
                          child: AppImage(kit.image, fit: BoxFit.contain),
                        ),
                        Positioned(top: 8, right: 8, child: badge),
                      ],
                    ),
                  ),
                  Padding(padding: const EdgeInsets.all(12), child: info),
                ],
              )
            : Row(
                children: [
                  ColoredBox(
                    color: Colors.white,
                    child: AppImage(
                      kit.image,
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: info,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: badge,
                  ),
                ],
              ),
      ),
    );
  }
}
