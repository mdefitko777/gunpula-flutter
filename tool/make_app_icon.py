# 쓰는 법: python tool/make_app_icon.py icon.png  (1024px PNG + _64 미리보기)
# Hobby Atlas 아이콘 — 아바타와 같은 파랑→연두 고리 + 도감 칸으로 된 지구 (모은 칸만 색이 켜짐)
import math, sys
from PIL import Image, ImageDraw
SS = 4; N = 1024 * SS
BLUE = (28, 134, 217); GREEN = (44, 198, 160)
GREY = (228, 232, 236); BG = (255, 255, 255)
def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
img = Image.new('RGB', (N, N), BG); d = ImageDraw.Draw(img)
cx = cy = N / 2
# 고리: 왼쪽 위 파랑 → 오른쪽 아래 연두 (앱 Gp.accentGradient)
grad = Image.new('RGB', (N, N)); gd = ImageDraw.Draw(grad)
for i in range(0, 2 * N, 6):
    gd.line([(i, 0), (0, i)], fill=lerp(BLUE, GREEN, min(1, i / (2 * N))), width=8)
R_out, R_in = 0.392 * N, 0.352 * N
mask = Image.new('L', (N, N), 0); md = ImageDraw.Draw(mask)
md.ellipse([cx - R_out, cy - R_out, cx + R_out, cy + R_out], fill=255)
md.ellipse([cx - R_in, cy - R_in, cx + R_in, cy + R_in], fill=0)
img.paste(grad, (0, 0), mask)
# 지구 칸 (위도 · 경도로 나눈 칸을 도(°) 단위로 줄여 틈을 만든다 → 깔끔한 모양)
Rg = 0.292 * N
tilt = math.radians(16); rot = math.radians(-15)
def proj(lat, lon):
    la, lo = math.radians(lat), math.radians(lon) + rot
    x = math.cos(la) * math.sin(lo); y0 = math.sin(la); z0 = math.cos(la) * math.cos(lo)
    y = y0 * math.cos(tilt) - z0 * math.sin(tilt); z = y0 * math.sin(tilt) + z0 * math.cos(tilt)
    return cx + x * Rg, cy - y * Rg, z
bands = [(-90, -60), (-60, -24), (-24, 12), (12, 48), (48, 90)]
lit = {(1, 5), (2, 5), (2, 6), (3, 5), (2, 4), (3, 6), (1, 6)}
cells = []
for bi, (la0, la1) in enumerate(bands):
    step = 60 if bi in (0, 4) else 30
    for li in range(360 // step):
        lo0 = -180 + li * step; lo1 = lo0 + step
        g = 3.2
        a0, a1 = la0 + (g if la0 > -90 else 0), la1 - (g if la1 < 90 else 0)
        mid = math.radians((a0 + a1) / 2)
        gl = min(12, g / max(0.25, math.cos(mid)))
        b0, b1 = lo0 + gl, lo1 - gl
        if la1 == 90: a1 = 90 - 0.01
        if la0 == -90: a0 = -90 + 0.01
        pts = []
        K = 14
        for k in range(K + 1): pts.append(proj(a0, b0 + (b1 - b0) * k / K))
        for k in range(K + 1): pts.append(proj(a0 + (a1 - a0) * k / K, b1))
        for k in range(K + 1): pts.append(proj(a1, b1 - (b1 - b0) * k / K))
        for k in range(K + 1): pts.append(proj(a1 - (a1 - a0) * k / K, b0))
        vis = [(x, y) for x, y, z in pts if z > 0.0]
        if len(vis) < len(pts) * 0.9: continue
        zc = sum(p[2] for p in pts) / len(pts)
        mx = sum(p[0] for p in vis) / len(vis); my = sum(p[1] for p in vis) / len(vis)
        cells.append((zc, bi, li, vis, mx, my))
for zc, bi, li, vis, mx, my in sorted(cells):
    if (bi, li) in lit:
        t = min(1, max(0, (mx - (cx - Rg)) / (2 * Rg) * 0.7 + (my - (cy - Rg)) / (2 * Rg) * 0.3))
        col = lerp(BLUE, GREEN, t)
    else:
        col = GREY
    d.polygon(vis, fill=col)
out = img.resize((1024, 1024), Image.LANCZOS); out.save(sys.argv[1])
out.resize((64, 64), Image.LANCZOS).save(sys.argv[1].replace('.png', '_64.png'))
print('lit cells drawn', sum(1 for c in cells if (c[1], c[2]) in lit), 'cells', len(cells))
