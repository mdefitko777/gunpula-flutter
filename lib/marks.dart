// 좋아요 · 구매함 — 앱 전체가 함께 보는 한 벌.
// 홈에서 ♡ 를 누르면 컬렉션 · 상세 · 내 정보 숫자 · 친구 컬렉션의 "나도 있음"까지 같이 바뀐다.
// 맨 위(MaterialApp.builder)의 MarksHost 가 setState 로 바꾸고, InheritedWidget(Marks)이 아래로 알린다.
// = 상태관리 패키지 없이 setState 를 위로 올린 것. 가짜 저장: 앱을 끄면 db.json 의 처음 값으로 돌아간다.
import 'package:flutter/material.dart';

import 'models.dart';
import 'widgets.dart' show showToast;

class MarksHost extends StatefulWidget {
  const MarksHost({super.key, required this.child});
  final Widget child;

  @override
  State<MarksHost> createState() => _MarksHostState();
}

class _MarksHostState extends State<MarksHost> {
  /// 상품 id → 바꾼 값 (없으면 GET 으로 받은 status 그대로)
  final Map<String, bool> _liked = {};
  final Map<String, bool> _owned = {};
  int _version = 0;

  void _set(Kit k, {bool? liked, bool? owned}) => setState(() {
    // STATE: 좋아요 · 구매함 → 앱 전체의 하트 · 리본 · 목록 · 숫자
    if (liked != null) _liked[k.id] = liked;
    if (owned != null) _owned[k.id] = owned;
    _version++;
  });

  @override
  Widget build(BuildContext context) => Marks._(host: this, version: _version, child: widget.child);
}

class Marks extends InheritedWidget {
  const Marks._({required _MarksHostState host, required this.version, required super.child}) : _host = host;

  final _MarksHostState _host;
  final int version;

  /// 그리는 중(build)에 — 바뀌면 다시 그려진다
  static Marks of(BuildContext context) {
    final m = context.dependOnInheritedWidgetOfExactType<Marks>();
    assert(m != null, 'MarksHost 가 위에 없어요 (main.dart 의 MaterialApp.builder)');
    return m!;
  }

  /// 누를 때(콜백)에
  static Marks read(BuildContext context) => context.getInheritedWidgetOfExactType<Marks>()!;

  bool liked(Kit k) => _host._liked[k.id] ?? k.status == CollectStatus.wanted;
  bool owned(Kit k) => _host._owned[k.id] ?? k.status == CollectStatus.owned;

  void set(Kit k, {bool? liked, bool? owned}) => _host._set(k, liked: liked, owned: owned);

  /// ♡ 누르기 + 토스트(되돌리기) — 상품 사진 · 상세 · 카메라 결과 공통
  void toggleLike(BuildContext context, Kit k) {
    final before = liked(k);
    set(k, liked: !before);
    showToast(context, before ? '좋아요를 취소했어요' : '「${k.name}」 좋아요', onUndo: () => set(k, liked: before));
  }

  /// 리본 누르기 + 토스트(되돌리기)
  void toggleOwn(BuildContext context, Kit k) {
    final before = owned(k);
    set(k, owned: !before);
    showToast(context, before ? '구매함에서 뺐어요' : '「${k.name}」 구매함에 넣었어요', onUndo: () => set(k, owned: before));
  }

  @override
  bool updateShouldNotify(Marks old) => version != old.version;
}
