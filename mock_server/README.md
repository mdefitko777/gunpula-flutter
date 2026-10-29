# 목업 서버 (json-server) — Hobby Atlas

`db.json` 의 데이터를 **GET 으로만** 앱에 내려 주는 서버입니다. 중간고사 안내 5장: json-server 의 `GET` 은 허용, `POST`/`PUT`/`DELETE` · 저장은 감점.

- 데이터: `franchises`(IP 5) · `kits`(상품 48) · `announcements`(공식 예고 9) · `guideWorks`(건담 작품 16) · `guideUnits` · `bbxTops` · `bbxParts` · `worlds` · `notifications`(13) · `profile` — 모두 예시 값(실제 개인정보 없음)
- **배포**: https://gunpula-flutter-mockserver.vercel.app/api (Vercel, `api/server.js` = 읽기 전용 json-server · `vercel.json` = `/api/*` 연결). 예: `curl "https://gunpula-flutter-mockserver.vercel.app/api/kits?franchiseId=gundam"`
- 로컬: `npm install && npm start` → http://localhost:3000 (`curl "http://localhost:3000/kits?franchiseId=gundam"`)

---

(아래는 템플릿에서 받은 원래 안내 — 데이터 이름은 위 목록이 최신)

# 목업 서버 (json-server) — 내 앱 v2

`db.json`의 데이터를 **GET으로만** 앱에 내려 주는 로컬 서버입니다.
중간고사 안내 5장: json-server에서 `GET`은 **허용**, `POST`/`PUT`/`DELETE`·저장은 **감점**입니다.

```
mock_server/
├── db.json        # [필수] series 2 · units 24 · kits 24 · prices 80 · collection 15 (개인정보 없음)
├── package.json   # json-server 0.17.4 고정 · "npm start" (= "npm run mock")
├── api/server.js  # (가산 +5) Vercel 서버리스 함수 — 읽기 전용 GET
└── vercel.json    # (가산 +5) /api/* → api/server.js
```

## 1. 설치 → 실행 → 확인

Node.js(18 이상 권장)가 필요합니다.

```bash
cd mock_server
npm install      # json-server 0.17.4 설치 (node_modules/는 git에 올리지 않음)
npm start        # = json-server --watch db.json --port 3000 --host 0.0.0.0  (npm run mock 도 같음)
```

다른 터미널에서:

```bash
curl "http://localhost:3000/kits?_embed=collection&_expand=unit"   # 키트 24개 + 내 소장 상태 + 기체 — 화면 A · F
curl "http://localhost:3000/kits?unitId=1&_embed=collection"       # 기체 1의 대응 키트 — 화면 E
curl "http://localhost:3000/prices?kitId=1&_sort=date&_order=desc" # 키트 1의 시세 기록(예시) — 화면 B '시세 기록' 탭
curl "http://localhost:3000/series?_embed=units"                   # 작품 2개 + 기체 — 화면 D 도감
```

`_embed` · `_expand` · `_sort`는 json-server의 GET 쿼리입니다(서버가 묶어서 내려 줄 뿐, 쓰기가 아님).
`units.status` · `series.owned/wanted/total`(점등 상태 · 수집률)은 미리 적어 둔 값이고 앱은 계산하지 않습니다.

- `--watch`: `db.json`을 고치고 저장하면 서버를 다시 켜지 않아도 반영됩니다.
- `--host 0.0.0.0`: 같은 Wi-Fi의 실기기에서도 접속할 수 있게 엽니다(macOS 방화벽 창이 뜨면 "허용").
- 끄기: 서버 터미널에서 `Ctrl + C`.
- 쓰기 요청을 아예 막고 싶으면 `npx json-server --watch db.json --port 3000 --host 0.0.0.0 --read-only` (GET 외 403).
- 로딩 화면을 서버 쪽에서 늦추고 싶으면 `--delay 2000` (앱 쪽은 `DEMO_STATE=loading`).

> ⚠ json-server는 원래 POST/PUT/DELETE도 받아 `db.json`에 **실제로 저장**합니다.
> 중간고사에서는 앱이 GET만 보내야 합니다(쓰기 요청은 감점 항목).

## 2. `db.json` 바꾸기

- 최상위 키 하나 = 주소 하나 (`"kits": [...]` → `/kits`). 키 이름을 바꾸면 `lib/api.dart`의 경로도 같이 바꿉니다.
- 항목마다 `id`가 있어야 `/kits/1` 같은 단건 조회가 됩니다. `kitId` · `unitId` · `seriesId`가 `_embed` · `_expand`의 연결 고리입니다.
- 이미지 경로(`image` · `icon`)는 앱 안의 `assets/`를 가리킵니다(`pubspec.yaml`의 `assets:`).
- 필드를 바꾸면 `lib/models.dart`의 `fromJson` 패턴도 같이 바꿉니다(모양이 다르면 그 항목은 목록에서 빠집니다).
- **실제 개인정보(이름·전화·학번·주소 등)는 넣지 않습니다**(감점 항목). 이미지는 `https://picsum.photos/seed/<아무 글자>/400/300` 같은 예시 이미지를 씁니다.

## 3. Flutter 앱에서 쓸 주소

| 실행 대상 | 주소 | 앱 설정 |
|---|---|---|
| Chrome(웹) · macOS · Windows · iOS 시뮬레이터 | `http://localhost:3000` | 기본값 — 그대로 `flutter run` |
| **Android 에뮬레이터** | **`http://10.0.2.2:3000`** | 기본값 — 템플릿이 Android를 알아서 10.0.2.2로 바꾼다 |
| 실기기(폰) | 같은 Wi-Fi PC의 IP, 예: `http://192.168.0.10:3000` | `--dart-define=API_BASE=http://192.168.0.10:3000` |

PC IP 확인: macOS `ipconfig getifaddr en0` · Windows `ipconfig`(IPv4 주소).

플랫폼 설정(템플릿에 이미 반영):
- Android: 평문 `http://` 허용 — `android/app/src/debug/AndroidManifest.xml`의 `usesCleartextTraffic="true"`(디버그 빌드만).
- macOS: `macos/Runner/*.entitlements`에 `com.apple.security.network.client`.

## 4. CORS (Flutter 웹)

Chrome에서 실행한 Flutter 웹(`http://localhost:<임의 포트>`)이 `http://localhost:3000`을 부르면 출처(origin)가 달라 서버가 CORS 헤더를 줘야 합니다.
json-server 0.17.4는 **기본으로 CORS를 허용**합니다(`--no-cors`를 붙이지 마세요). 모바일·데스크톱 앱은 CORS와 무관합니다.

## 5. (가산 +5) Vercel 배포 — 읽기 전용

서버리스 함수(`api/server.js`)가 `db.json`을 메모리로만 읽고(`jsonServer.router(객체)`), `readOnly: true`로 **GET 외 요청은 403**으로 거절합니다.
구조는 [kitloong/json-server-vercel](https://github.com/kitloong/json-server-vercel)(MIT)을 참고해 최소 구성으로 다시 썼습니다(`midterm/mock_server`와 같은 파일).

1. 내 GitHub 저장소를 [vercel.com](https://vercel.com)에서 **Add New… → Project**로 Import.
2. **Root Directory**를 `mock_server`로, Framework Preset은 **Other** → **Deploy**.
3. 확인: `https://<프로젝트>.vercel.app/api/kits`
4. 앱 웹 빌드도 같은 프로젝트로(발표 URL 하나):

```bash
# 저장소 루트(pubspec.yaml 있는 곳)에서
flutter build web --dart-define=API_BASE=https://<프로젝트>.vercel.app/api
rm -rf mock_server/public && cp -R build/web mock_server/public
# mock_server/public/ 을 커밋해서 push → https://<프로젝트>.vercel.app/
```

확인 필요: 실제 Vercel 배포는 계정이 필요해 템플릿에서 하지 않았습니다. `public/` 정적 서비스 여부·Node 런타임 기본값은 배포 때 Vercel 대시보드에서 확인하세요. 데이터를 바꾸려면 `db.json`을 고쳐 다시 push합니다.
