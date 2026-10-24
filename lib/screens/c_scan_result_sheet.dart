// 화면 C: 바코드 스캔 결과(임의) — 카탈로그의 스캔 버튼(A-1)에서 덮기(modal)
//
// ┌──────── 디자인 가이드 대응표: C 바코드 스캔 결과(임의) ─────────────────────┐
// │ 번호 │ Flutter 위젯명                 │ 비즈니스 명칭(한글)                │ 원칙(P번호)   │
// │ C-1  │ showModalBottomSheet + 손잡이  │ 스캔 결과 시트                     │ P03 통제·자유 │
// │ C-2  │ Row(Icon + Text)               │ 인식 상태 표시(인식 완료·인식 실패)│ P01 가시성    │
// │ C-3  │ ListTile(AppImage)             │ 인식된 키트                        │ P06 재인      │
// │ C-4  │ FilledButton → push B          │ 키트 상세 보기                     │ P07 효율성    │
// │ C-5  │ Text(bodySmall, 회색)          │ 예시 결과 고지                     │ P10 도움말    │
// │ C-6  │ Icon + Text + TextButton       │ 인식 실패 안내 · 다시 스캔         │ P09 오류 복구 │
// └─────────────────────────────────────────────────────────────────────────────┘
//
// ⚠ 카메라·바코드 인식 없음 (안내 5장: 실제 비즈니스 로직은 감점).
//   언제 열어도 미리 정한 키트(presetScanKitId)를 보여 준다. 목록이 비어 있으면 인식 실패 화면.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'b_kit_detail_screen.dart';

/// 미리 정한 스캔 결과 — HG 1/144 건담 캘리번 (db.json kits id 4)
const presetScanKitId = 4;

class ScanResultSheet extends StatelessWidget {
  const ScanResultSheet({
    super.key,
    required this.kit,
    this.loaders = const Loaders(),
  });

  /// 인식된 키트 — null이면 인식 실패
  final Kit? kit;
  final Loaders loaders;

  /// 덮기(modal): 지금 화면 위에 잠깐 띄우고 닫는다.
  static Future<void> show(
    BuildContext context, {
    required Kit? kit,
    Loaders loaders = const Loaders(),
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true, // C-1 P03
      isScrollControlled: true,
      builder: (_) => ScanResultSheet(kit: kit, loaders: loaders),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final found = kit;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('바코드 스캔 결과', style: text.titleLarge),
            const SizedBox(height: 8),
            if (found == null) ...[
              Row(
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  const Text('인식 실패'),
                ],
              ), // C-2 P01
              const SizedBox(height: 8),
              const Text('바코드를 인식하지 못했습니다.\n바코드가 화면 가운데에 오도록 맞춘 뒤 다시 스캔하세요.'), // C-6 P09
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.check_circle, color: CollectColors.owned),
                  SizedBox(width: 8),
                  Text('인식 완료'),
                ],
              ), // C-2 P01
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ColoredBox(
                  color: Colors.white,
                  child: AppImage(found.image, width: 56, height: 56, fit: BoxFit.contain),
                ),
                title: Text(found.name),
                subtitle: Text('바코드 ${found.barcode ?? '정보 없음'} · ${yen(found.priceJpy)}'),
                trailing: StatusBadge(found.myStatus),
              ), // C-3 P06
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute<void>(
                        builder: (_) => KitDetailScreen(kit: found, loaders: loaders),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('키트 상세 보기'),
                ),
              ), // C-4 P07
            ],
            const SizedBox(height: 12),
            Text(
              '※ 카메라 없이 미리 정한 예시 결과입니다. 실제 스캔 기능은 없습니다.',
              style: text.bodySmall?.copyWith(color: Colors.grey),
            ), // C-5 P10
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(found == null ? '다시 스캔' : '닫기'),
              ), // C-6 P09
            ),
          ],
        ),
      ),
    );
  }
}
