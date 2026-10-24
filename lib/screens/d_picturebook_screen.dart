// 화면 D: 도감 (GET /series?_embed=units) — 홈 탭 구조(S)의 두 번째 탭
//
// ┌──────── 디자인 가이드 대응표: D 도감 ───────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                         │ 비즈니스 명칭(한글)              │ 원칙(P번호)   │
// │ D-1  │ FilterChip(토글, 범례 줄 오른쪽)       │ 풀컬러 미리보기                  │ P07 · P03     │
// │ D-2  │ Wrap(StatusBadge) + Text               │ 점등 범례(소장·위시·미보유)      │ P06 · P10     │
// │ D-3  │ Text + LinearProgressIndicator         │ 작품별 수집률                    │ P01 가시성    │
// │ D-4  │ GridView(maxCrossAxisExtent) + UnitCell│ 기체 칸(아이콘·이름)             │ P08 · 적응형  │
// │ D-5  │ UnitCell 테두리색·배지·흑백 필터       │ 점등 상태(소장 ✓·위시 ★·미보유)  │ P01 · P04     │
// │ D-6  │ LoadingView                            │ 불러오는 중 표시                 │ P01 가시성    │
// │ D-7  │ ErrorView + FilledButton               │ 오류 안내·다시 시도              │ P09 오류 복구 │
// │ D-8  │ EmptyView                              │ 빈 도감 안내                     │ P01 가시성    │
// └─────────────────────────────────────────────────────────────────────────────┘
// 전환: D → E 쌓기(push).  적응형: 칸 최대 폭 112dp 격자 — 창이 넓을수록 한 줄 칸 수가 늘어난다.
// 점등 상태와 수집률은 db.json에 적힌 값을 그대로 쓴다(앱이 계산하지 않음).
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'e_unit_detail_screen.dart';

/// 미보유 칸에 씌우는 흑백 필터
const _grayscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

class PicturebookScreen extends StatefulWidget {
  const PicturebookScreen({super.key, this.loaders = const Loaders()});

  final Loaders loaders;

  @override
  State<PicturebookScreen> createState() => _PicturebookScreenState();
}

class _PicturebookScreenState extends State<PicturebookScreen> {
  late Future<List<Series>> _future = widget.loaders.series();

  // STATE: 풀컬러 미리보기 켜짐 여부 → D-5 모든 칸 — 이 화면 안에서만 setState
  bool _fullColor = false;

  void _retry() {
    setState(() {
      _future = widget.loaders.series();
    });
  }

  void _openUnit(Unit unit, Series series) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UnitDetailScreen(
          unit: unit,
          seriesName: series.name,
          loaders: widget.loaders,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('도감')),
      body: FutureBuilder<List<Series>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(label: '도감을 불러오는 중…'); // D-6 P01
          }
          if (snap.hasError) {
            return ErrorView(
              title: '도감을 불러오지 못했습니다.',
              message: '${snap.error}',
              onRetry: _retry,
            ); // D-7 P09
          }
          final seriesList = (snap.data ?? const <Series>[])
              .where((s) => s.units.isNotEmpty)
              .toList();
          if (seriesList.isEmpty) {
            return const EmptyView(
              message: '도감에 표시할 기체가 없습니다.',
              icon: Icons.grid_off,
            ); // D-8 P01
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: StatusLegend(
                  fullColor: _fullColor,
                  onFullColorChanged: (value) => setState(() {
                    _fullColor = value;
                  }),
                ),
              ), // D-2 P06 P10 · D-1 P07 P03
              for (final series in seriesList) ...[
                SliverToBoxAdapter(child: SeriesProgress(series: series)), // D-3 P01
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 112,
                      mainAxisExtent: 144,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: series.units.length,
                    itemBuilder: (context, i) => UnitCell(
                      unit: series.units[i],
                      fullColor: _fullColor,
                      onTap: () => _openUnit(series.units[i], series),
                    ),
                  ),
                ), // D-4 P08
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 점등 범례 — 색의 뜻을 화면 위에서 먼저 설명하고, 바로 옆에 풀컬러 미리보기 토글을 둔다
class StatusLegend extends StatelessWidget {
  const StatusLegend({
    super.key,
    required this.fullColor,
    required this.onFullColorChanged,
  });

  final bool fullColor;
  final ValueChanged<bool> onFullColorChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    StatusBadge(CollectStatus.owned),
                    StatusBadge(CollectStatus.wanted),
                    StatusBadge(CollectStatus.none, noneLabel: '미보유'),
                  ],
                ),
              ), // D-2 P06
              FilterChip(
                avatar: const Icon(Icons.palette_outlined, size: 18),
                label: const Text('풀컬러'),
                tooltip: fullColor ? '미보유 칸을 흑백으로 보기' : '모든 칸을 컬러로 미리보기',
                selected: fullColor,
                onSelected: onFullColorChanged,
              ), // D-1 P07 P03
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fullColor
                ? '풀컬러 미리보기 중 — 테두리와 배지로 소장 상태를 구분하세요.'
                : '흑백 칸은 아직 없는 기체예요. 칸을 누르면 키트를 볼 수 있어요.',
            style: text.bodySmall,
          ), // D-2 P10
        ],
      ),
    );
  }
}

/// 작품별 수집률 — "5 / 12 소장 · 위시 2" + 진행 막대
class SeriesProgress extends StatelessWidget {
  const SeriesProgress({super.key, required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(series.name, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${series.owned} / ${series.total} 소장 · 위시 ${series.wanted}',
            style: text.bodySmall,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: series.total == 0 ? 0 : series.owned / series.total,
              minHeight: 6,
              color: CollectColors.owned,
            ),
          ),
        ],
      ),
    );
  }
}

/// 기체 칸 — 점등 상태를 테두리색 + 기호 배지 + 흑백 필터로 보여 준다 (D-5 P01 P04)
class UnitCell extends StatelessWidget {
  const UnitCell({
    super.key,
    required this.unit,
    required this.fullColor,
    required this.onTap,
  });

  final Unit unit;
  final bool fullColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = CollectColors.of(unit.status);
    final dim = unit.status == CollectStatus.none && !fullColor;

    Widget art = AppImage(unit.icon);
    if (dim) {
      art = Opacity(
        opacity: 0.55,
        child: ColorFiltered(colorFilter: _grayscale, child: art),
      );
    } // D-5 P01 미보유 = 흑백 (풀컬러면 컬러)

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color ?? scheme.outlineVariant,
          width: color == null ? 1 : 2.5,
        ),
      ), // D-5 P04 소장=초록 · 위시=주황 테두리
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  art,
                  if (color != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: color,
                        child: Text(
                          unit.status == CollectStatus.owned ? '✓' : '★',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ), // D-5 P01 색 + 기호
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
              child: Text(
                unit.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
