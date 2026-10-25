// 화면 K: 설정 — 오른쪽 위 ⚙ 에서 열림 (내 정보와 따로)
//
// ┌──────── 디자인 가이드 대응표: K 설정 ──────────────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                     │ 비즈니스 명칭(한글)                    │ 원칙(P번호)   │
// │ K-1  │ SwitchListTile × 2                 │ 새 소식 알림 · 내 채널 예고만 알림       │ P03 · P07     │
// │ K-2  │ ListTile → 바텀 시트(선택)          │ 언어                                   │ P04           │
// │ K-3  │ ListTile → 토스트                   │ 데이터 백업 · 복원 (가짜)               │ P10           │
// │ K-4  │ ListTile                           │ 버전 · 도움말                           │ P10           │
// │ K-5  │ 로그아웃 → showDialog(확인)          │ 로그아웃 (실제 로그인 없음)             │ P05           │
// └──────────────────────────────────────────────────────────────────────────────────┘
// 전환: 앱 셸 ⚙ → 쌓기(push, 오른쪽에서). 언어 → 덮기(바텀 시트). 데이터 GET 없음(화면 안 상수).
// 현행 앱 문제: 설정 안에 콘솔 · GitHub Token · 소스 상태 같은 관리자 기능이 섞여 있음 → v2는 사용자 설정만.
import 'package:flutter/material.dart';

import '../detail_pane.dart';
import '../theme.dart';
import '../widgets.dart';

void openSettings(BuildContext context) {
  openPage(context, const SettingsScreen());
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notify = true;
  bool _onlyMine = true;
  String _language = '한국어';

  void _fake(String what) => showToast(context, '$what은(는) 프로토타입이라 실제로 하지 않아요');

  Future<void> _pickLanguage() async {
    final l = await showPickSheet(
      // K-2 덮기 (정렬과 같은 시트)
      context,
      title: '언어',
      values: const ['한국어', '中文', 'English', '日本語'],
      current: _language,
      label: (l) => l,
    );
    if (l != null) setState(() => _language = l); // STATE: 언어 → 설정 줄 글자 (화면 번역은 없음)
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      // K-5 P05
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃할까요?'),
        content: const Text('이 기기의 컬렉션은 그대로 남고, 다른 기기와의 동기화만 멈춰요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('로그아웃')),
        ],
      ),
    );
    if (ok == true && mounted) showToast(context, '프로토타입이라 로그아웃 화면은 없어요');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          SectionPanel(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('알림'),
                SwitchListTile(
                  // K-1 P03
                  secondary: const Icon(Icons.notifications_none),
                  title: const Text('새 소식 알림'),
                  subtitle: const Text('새 상품 · 예고 · 친구 소식'),
                  value: _notify,
                  activeThumbColor: Gp.accent,
                  onChanged: (v) => setState(() => _notify = v), // STATE: 알림 스위치
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.filter_alt_outlined),
                  title: const Text('내 채널 소식만'),
                  subtitle: const Text('관심 없는 IP의 알림은 받지 않아요'),
                  value: _onlyMine,
                  activeThumbColor: Gp.accent,
                  onChanged: _notify ? (v) => setState(() => _onlyMine = v) : null, // 알림이 꺼지면 함께 꺼짐 P05
                ),
              ],
            ),
          ),
          SectionPanel(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('앱'),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('언어'),
                  trailing: Text('$_language ›', style: const TextStyle(color: Gp.muted)),
                  onTap: _pickLanguage, // K-2
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('데이터 백업'),
                  subtitle: const Text('컬렉션 · 채널 설정을 파일로 내보내기'),
                  onTap: () => _fake('데이터 백업'), // K-3 P10
                ),
                ListTile(leading: const Icon(Icons.restore), title: const Text('백업에서 복원'), onTap: () => _fake('복원')),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('도움말'),
                  onTap: () => showSoon(context, '도움말'), // K-4 P10
                ),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('버전'),
                  trailing: Text('Gunpula v2.0.0', style: TextStyle(color: Gp.muted)),
                ),
              ],
            ),
          ),
          SectionPanel(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Gp.danger),
              title: const Text('로그아웃', style: TextStyle(color: Gp.danger)),
              onTap: _signOut, // K-5 P05
            ),
          ),
        ],
      ),
    );
  }
}
