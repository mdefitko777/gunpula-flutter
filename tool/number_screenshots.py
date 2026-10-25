# 스크린샷에 요소 번호(디자인 가이드 3장과 같은 번호)를 붙인다 — 발표자료 07장 · 부록 B1 · B5-4 용
# 쓰는 법: flutter test tool/screenshots_test.dart 다음에  python tool/number_screenshots.py
# 좌표는 390×844 화면 기준(스크린샷은 2배), 화면 배치를 바꾸면 여기 좌표도 고친다.
import sys
from PIL import Image, ImageDraw, ImageFont
f=ImageFont.truetype('C:/Windows/Fonts/malgunbd.ttf',26)
B=(47,111,228)
def run(src,dst,marks,rings=()):
    im=Image.open(src).convert('RGB'); d=ImageDraw.Draw(im)
    for lab,x,y,box in marks:
        if box: d.rounded_rectangle([v*2 for v in box],radius=12,outline=B,width=4)
    for cx,cy,r in rings: d.ellipse([(cx-r)*2,(cy-r)*2,(cx+r)*2,(cy+r)*2],outline=B,width=4)
    for lab,x,y,box in marks:
        X,Y=x*2,y*2; w=int(d.textlength(lab,font=f))+30;h=40
        d.rounded_rectangle([X-w//2,Y-h//2,X+w//2,Y+h//2],radius=20,fill=B,outline='white',width=3)
        tw=d.textlength(lab,font=f); d.text((X-tw/2,Y-18),lab,font=f,fill='white')
    im.save(dst)
R=sys.argv[1] if len(sys.argv) > 1 else 'docs/screenshots'
run(R+'/02_v2_a.png',R+'/02_v2_a_numbered.png',[
 ('A-1',200,40,(4,8,386,108)),('A-2',356,118,(8,124,382,172)),('A-3',340,200,(0,184,390,402)),
 ('A-4',350,420,(8,412,382,470)),('A-5',300,536,(8,534,382,582)),('A-6',300,600,(140,590,390,770)),
 ('A-9',56,640,None),('A-8',300,506,None),('S-3',300,790,(0,784,390,844))],rings=[(39,611,13),(37,721,13)])
run(R+'/03_v2_b.png',R+'/03_v2_b_numbered.png',[
 ('D-1',75,32,(12,12,52,52)),('D-2',330,70,(40,55,350,365)),('D-4',340,410,(8,412,382,467)),
 ('D-5',290,505,(8,476,250,537)),('D-5b',340,543,(15,543,375,582)),('D-5c',320,590,(15,590,375,632)),
 ('D-8',340,660,(5,660,385,735)),('D-10',300,770,(10,758,250,786)),('D-6',250,790,(116,788,380,838)),('D-14',60,780,(8,790,108,838))])
run(R+'/04_v2_c.png',R+'/04_v2_c_numbered.png',[
 ('G-3',230,30,(8,6,200,52)),('G-2',318,28,(348,12,380,44)),('G-4a',330,96,(10,60,380,88)),
 ('G-4',200,94,(10,100,382,745)),('G-4b',200,258,None)],rings=[(155,115,14),(155,197,14),(278,697,14)])
