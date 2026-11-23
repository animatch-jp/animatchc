import random, math
random.seed(7)
W,H=1200,2400
out=[]
A=out.append
A(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">')
A('''<defs>
<linearGradient id="grass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9edb74"/><stop offset=".5" stop-color="#8fd068"/><stop offset="1" stop-color="#7fc25c"/></linearGradient>
<linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9fe3f7"/><stop offset="1" stop-color="#4fb0de"/></linearGradient>
<radialGradient id="plaza" cx=".5" cy=".45" r=".6"><stop offset="0" stop-color="#f7ead0"/><stop offset="1" stop-color="#ecd9b2"/></radialGradient>
<filter id="sh" x="-20%" y="-20%" width="140%" height="160%"><feGaussianBlur stdDeviation="6"/></filter>
<filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="2"/></filter>
</defs>''')
# ground
A(f'<rect width="{W}" height="{H}" fill="url(#grass)"/>')
# mowing stripes
for i in range(-10,30):
    x=i*110
    A(f'<path d="M{x} 0 L{x+60} 0 L{x+60-900} {H} L{x-900} {H} Z" fill="#ffffff" opacity=".035"/>')
# soft hills / darker patches
for _ in range(26):
    x=random.uniform(0,W); y=random.uniform(0,H); r=random.uniform(90,220)
    A(f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{r:.0f}" ry="{r*0.55:.0f}" fill="#6fb24f" opacity=".18" filter="url(#sh)"/>')

# ---- paths ----
paths=[
 "M600 2420 C600 2200 600 2100 600 1980 C600 1860 600 1700 600 1560",            # entrance up
 "M600 1560 C420 1520 360 1400 380 1250 C400 1080 470 980 600 960 C730 980 800 1080 820 1250 C840 1400 780 1520 600 1560", # loop around pond
 "M600 960 C600 820 600 640 600 440",                                               # up to gate
 "M470 990 C380 900 320 840 250 820",                                               # to photo
 "M730 990 C820 900 880 840 960 820",                                               # to yatai
 "M390 1300 C330 1320 300 1360 250 1420",                                           # to tent
 "M810 1300 C870 1320 910 1360 960 1400",                                           # to bench
 "M600 1980 C480 1990 380 2000 300 2010",                                           # to house
 "M600 1980 C720 1990 820 2000 910 2010",                                           # to info
]
for d in paths:
    A(f'<path d="{d}" fill="none" stroke="#d9bd85" stroke-width="78" stroke-linecap="round" stroke-linejoin="round"/>')
for d in paths:
    A(f'<path d="{d}" fill="none" stroke="#f4e2b8" stroke-width="64" stroke-linecap="round" stroke-linejoin="round"/>')
for d in paths:
    A(f'<path d="{d}" fill="none" stroke="#fff3d6" stroke-width="14" stroke-linecap="round" stroke-dasharray="2 46" opacity=".8"/>')

# ---- plazas (in front of each place) ----
def plaza(cx,cy,rx,ry):
    A(f'<ellipse cx="{cx}" cy="{cy+8}" rx="{rx+8}" ry="{ry+8}" fill="#d9bd85"/>')
    A(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#plaza)"/>')
    # tiles
    for k in range(1,4):
        A(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx*k/4:.0f}" ry="{ry*k/4:.0f}" fill="none" stroke="#e3cc9c" stroke-width="3"/>')
places={'gate':(600,330),'photo':(230,700),'yatai':(970,700),'tent':(200,1330),'bench':(990,1330),'house':(250,1880),'info':(950,1880)}
for k,(x,y) in places.items():
    if k=='gate': continue
    plaza(x,y+150,190,95)
plaza(600,2120,170,70)

# ---- pond ----
A('<path d="M600 1060 C720 1050 770 1130 760 1230 C750 1340 680 1400 600 1400 C500 1400 430 1340 440 1230 C450 1120 500 1068 600 1060 Z" fill="#cfc6b3"/>')
A('<path d="M600 1078 C708 1070 748 1140 740 1230 C732 1326 672 1382 600 1382 C512 1382 458 1330 462 1230 C468 1132 512 1084 600 1078 Z" fill="url(#water)"/>')
for (x,y,r) in [(540,1170,60),(650,1290,50),(600,1220,30)]:
    A(f'<path d="M{x-r} {y} Q{x} {y-14} {x+r} {y}" fill="none" stroke="#ffffff" stroke-width="5" stroke-linecap="round" opacity=".7"/>')
for (x,y) in [(520,1290),(680,1150),(560,1330),(700,1260)]:
    A(f'<circle cx="{x}" cy="{y}" r="22" fill="#5fae55"/><path d="M{x} {y} L{x+22} {y-6} L{x+22} {y+6} Z" fill="url(#water)"/><circle cx="{x-6}" cy="{y-4}" r="5" fill="#ffd6e6"/>')
# stones around pond
for i in range(28):
    t=i/28*2*math.pi
    x=600+175*math.cos(t); y=1230+170*math.sin(t)
    A(f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="16" ry="11" fill="#e8e1d2" stroke="#c9bfaa" stroke-width="2"/>')
# little fountain
A('<ellipse cx="600" cy="1232" rx="34" ry="14" fill="#e8e1d2" stroke="#c9bfaa" stroke-width="3"/><path d="M600 1228 C596 1190 590 1180 580 1176 M600 1228 C604 1190 610 1180 620 1176 M600 1228 L600 1168" stroke="#e8fbff" stroke-width="5" fill="none" stroke-linecap="round"/>')

# ---- trees ----
pal={'g':('#3f8f3a','#58ad45','#7cc75a'),'o':('#c9632b','#ef8a3a','#ffb35c'),'y':('#c99a1e','#f0c235','#ffe07a'),'r':('#a8352c','#d9503d','#f07a5f')}
def tree(x,y,s=1.0,c='g'):
    a,b,d=pal[c]
    A(f'<ellipse cx="{x+8*s:.0f}" cy="{y+70*s:.0f}" rx="{58*s:.0f}" ry="{20*s:.0f}" fill="#2f6a2c" opacity=".35" filter="url(#soft)"/>')
    A(f'<rect x="{x-9*s:.0f}" y="{y+20*s:.0f}" width="{18*s:.0f}" height="{50*s:.0f}" rx="{6*s:.0f}" fill="#8a5a3b"/>')
    A(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{56*s:.0f}" fill="{a}"/>')
    A(f'<circle cx="{x-18*s:.0f}" cy="{y-10*s:.0f}" r="{42*s:.0f}" fill="{b}"/>')
    A(f'<circle cx="{x+20*s:.0f}" cy="{y-4*s:.0f}" r="{36*s:.0f}" fill="{b}"/>')
    A(f'<circle cx="{x-22*s:.0f}" cy="{y-26*s:.0f}" r="{18*s:.0f}" fill="{d}" opacity=".9"/>')
def bush(x,y,s=1.0,flower=None):
    A(f'<ellipse cx="{x}" cy="{y+18*s:.0f}" rx="{40*s:.0f}" ry="{12*s:.0f}" fill="#2f6a2c" opacity=".3" filter="url(#soft)"/>')
    for dx,dy,r in [(-22,4,22),(0,-6,26),(22,4,22)]:
        A(f'<circle cx="{x+dx*s:.0f}" cy="{y+dy*s:.0f}" r="{r*s:.0f}" fill="#4c9e40"/>')
    A(f'<circle cx="{x-8*s:.0f}" cy="{y-14*s:.0f}" r="{10*s:.0f}" fill="#79c45a"/>')
    if flower:
        for dx,dy in [(-20,-2),(4,-16),(18,6),(-4,8)]:
            A(f'<circle cx="{x+dx*s:.0f}" cy="{y+dy*s:.0f}" r="{5*s:.0f}" fill="{flower}"/>')

# forest band at top
cols=['g','g','o','y','g','r','g','o']
for row in range(4):
    for i in range(14):
        x=i*92+ (46 if row%2 else 0) + random.uniform(-14,14)
        y=40+row*70+random.uniform(-12,12)
        if 470<x<730 and row>=2: continue
        tree(x,y,1.05-row*0.05,random.choice(cols))
# scattered trees
spots=[(80,560),(1120,540),(70,980),(1130,1000),(90,1560),(1110,1580),(400,520),(745,470),(380,1650),(820,1650),(70,2200),(1130,2210),(410,2250),(790,2250),(140,1100),(1060,1110)]
for (x,y) in spots:
    tree(x,y,random.uniform(.8,1.0),random.choice(['g','g','o','y','r']))
for (x,y,f) in [(470,1720,'#ffffff'),(730,1720,'#ffd1e3'),(130,800,'#ffe27a'),(1070,810,'#ffffff'),(480,2380,'#ffd1e3'),(720,2380,'#ffe27a'),(300,1560,None),(900,1560,'#ffffff'),(520,640,None),(690,650,'#ffd1e3')]:
    bush(x,y,1.0,f)
# grass tufts & flowers
for _ in range(260):
    x=random.uniform(0,W); y=random.uniform(380,H)
    A(f'<path d="M{x:.0f} {y:.0f} l-5 -12 M{x:.0f} {y:.0f} l0 -15 M{x:.0f} {y:.0f} l5 -12" stroke="#5fa847" stroke-width="3" stroke-linecap="round" opacity=".55"/>')
for _ in range(140):
    x=random.uniform(0,W); y=random.uniform(380,H)
    c=random.choice(['#ffffff','#fff2a8','#ffc9dd','#ffffff'])
    A(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="4.5" fill="{c}" opacity=".9"/>')

# ---- lamp posts ----
def lamp(x,y):
    A(f'<ellipse cx="{x+6}" cy="{y+4}" rx="16" ry="6" fill="#000" opacity=".2"/><rect x="{x-4}" y="{y-90}" width="8" height="92" rx="3" fill="#3e4a54"/><rect x="{x-14}" y="{y-112}" width="28" height="26" rx="6" fill="#3e4a54"/><rect x="{x-9}" y="{y-107}" width="18" height="16" rx="4" fill="#ffe9a6"/>')
for (x,y) in [(520,1820),(680,1820),(520,880),(680,880),(360,1180),(840,1180)]:
    lamp(x,y)

# ===== buildings =====
def shadow(x,y,rx,ry):
    A(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="#2c5a2a" opacity=".35" filter="url(#sh)"/>')

# gate to animal area (log arch)
gx,gy=places['gate']
shadow(gx,gy+96,170,24)
A(f'<rect x="{gx-150}" y="{gy-110}" width="34" height="200" rx="10" fill="#8a5a3b"/><rect x="{gx+116}" y="{gy-110}" width="34" height="200" rx="10" fill="#8a5a3b"/>')
A(f'<rect x="{gx-150}" y="{gy-110}" width="12" height="200" rx="6" fill="#a8744f"/><rect x="{gx+116}" y="{gy-110}" width="12" height="200" rx="6" fill="#a8744f"/>')
A(f'<path d="M{gx-175} {gy-110} Q{gx} {gy-190} {gx+175} {gy-110}" stroke="#7a4d31" stroke-width="40" fill="none" stroke-linecap="round"/>')
A(f'<path d="M{gx-175} {gy-116} Q{gx} {gy-196} {gx+175} {gy-116}" stroke="#a8744f" stroke-width="12" fill="none" stroke-linecap="round"/>')
for i in range(9):
    t=i/8; x=gx-160+320*t; y=gy-112-70*4*t*(1-t)
    A(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{14+random.uniform(0,6):.0f}" fill="#4c9e40"/><circle cx="{x+6:.0f}" cy="{y-6:.0f}" r="5" fill="#ffd1e3"/>')
A(f'<line x1="{gx-50}" y1="{gy-140}" x2="{gx-50}" y2="{gy-100}" stroke="#6b4429" stroke-width="4"/><line x1="{gx+50}" y1="{gy-140}" x2="{gx+50}" y2="{gy-100}" stroke="#6b4429" stroke-width="4"/>')
A(f'<rect x="{gx-80}" y="{gy-102}" width="160" height="54" rx="10" fill="#c99464" stroke="#7a4d31" stroke-width="5"/>')
# paw on sign
A(f'<g fill="#7a4d31"><ellipse cx="{gx}" cy="{gy-70}" rx="13" ry="11"/><circle cx="{gx-16}" cy="{gy-88}" r="6"/><circle cx="{gx-5}" cy="{gy-93}" r="6"/><circle cx="{gx+6}" cy="{gy-93}" r="6"/><circle cx="{gx+17}" cy="{gy-88}" r="6"/></g>')

# photo studio (pavilion + backdrop + camera)
px,py=places['photo']
shadow(px+10,py+92,170,30)
A(f'<path d="M{px-150} {py-40} L{px+150} {py-40} L{px+150} {py+80} L{px-150} {py+80} Z" fill="#fff7ea"/>')
A(f'<path d="M{px-150} {py+80} L{px+150} {py+80} L{px+150} {py+94} L{px-150} {py+94} Z" fill="#e8d3b3"/>')
A(f'<rect x="{px-110}" y="{py-28}" width="220" height="104" rx="6" fill="#ffffff" stroke="#e2c98f" stroke-width="10"/>')
A(f'<rect x="{px-98}" y="{py-16}" width="196" height="80" fill="#cfefff"/><path d="M{px-98} {py+64} L{px-40} {py+10} L{px} {py+44} L{px+40} {py+4} L{px+98} {py+64} Z" fill="#9fd88a"/><circle cx="{px+60}" cy="{py+8}" r="12" fill="#ffd84d"/>')
A(f'<path d="M{px-175} {py-40} L{px} {py-130} L{px+175} {py-40} Z" fill="#3fb6a8"/><path d="M{px} {py-130} L{px+175} {py-40} L{px+140} {py-40} Z" fill="#2f978b"/>')
for i in range(-3,4):
    A(f'<path d="M{px+i*50-24} {py-40} Q{px+i*50} {py-14} {px+i*50+24} {py-40}" fill="#ffffff"/>')
A(f'<rect x="{px-158}" y="{py-40}" width="16" height="134" fill="#c99464"/><rect x="{px+142}" y="{py-40}" width="16" height="134" fill="#c99464"/>')
# tripod camera in front
cx,cy=px+40,py+190
A(f'<line x1="{cx}" y1="{cy-30}" x2="{cx-28}" y2="{cy+40}" stroke="#4a4a4a" stroke-width="6" stroke-linecap="round"/><line x1="{cx}" y1="{cy-30}" x2="{cx+28}" y2="{cy+40}" stroke="#4a4a4a" stroke-width="6" stroke-linecap="round"/><line x1="{cx}" y1="{cy-30}" x2="{cx}" y2="{cy+44}" stroke="#4a4a4a" stroke-width="6" stroke-linecap="round"/>')
A(f'<rect x="{cx-34}" y="{cy-70}" width="68" height="44" rx="10" fill="#2f3438"/><circle cx="{cx}" cy="{cy-48}" r="15" fill="#5b6770"/><circle cx="{cx}" cy="{cy-48}" r="8" fill="#9fd3ff"/><rect x="{cx+14}" y="{cy-80}" width="14" height="10" rx="3" fill="#2f3438"/>')

# yatai (food stall)
yx,yy=places['yatai']
shadow(yx+10,yy+96,170,30)
A(f'<rect x="{yx-140}" y="{yy-20}" width="280" height="110" rx="8" fill="#b9814f"/><rect x="{yx-140}" y="{yy-20}" width="280" height="22" fill="#8f5f37"/>')
for i in range(6):
    A(f'<rect x="{yx-130+i*46}" y="{yy+10}" width="38" height="70" rx="4" fill="#c99464"/>')
A(f'<rect x="{yx-150}" y="{yy-34}" width="300" height="20" rx="6" fill="#e9d2a8"/>')
A(f'<rect x="{yx-146}" y="{yy-150}" width="14" height="140" fill="#8f5f37"/><rect x="{yx+132}" y="{yy-150}" width="14" height="140" fill="#8f5f37"/>')
for i in range(7):
    c='#e0473d' if i%2==0 else '#ffffff'
    A(f'<path d="M{yx-160+i*46} {yy-160} L{yx-160+(i+1)*46} {yy-160} L{yx-160+(i+1)*46} {yy-110} L{yx-160+i*46} {yy-110} Z" fill="{c}"/>')
    A(f'<path d="M{yx-160+i*46} {yy-110} Q{yx-137+i*46} {yy-86} {yx-160+(i+1)*46} {yy-110} Z" fill="{c}"/>')
A(f'<rect x="{yx-162}" y="{yy-172}" width="326" height="16" rx="6" fill="#b3352d"/>')
for i,x in enumerate([yx-110,yx-40,yx+30,yx+100]):
    A(f'<line x1="{x}" y1="{yy-98}" x2="{x}" y2="{yy-82}" stroke="#555" stroke-width="2"/><ellipse cx="{x}" cy="{yy-62}" rx="16" ry="20" fill="#ff5a4a"/><rect x="{x-9}" y="{yy-84}" width="18" height="5" fill="#333"/><rect x="{x-9}" y="{yy-45}" width="18" height="5" fill="#333"/><ellipse cx="{x-5}" cy="{yy-68}" rx="4" ry="8" fill="#ffb3a6"/>')
# food on counter
for i,x in enumerate([yx-90,yx-40,yx+10,yx+60,yx+105]):
    A(f'<circle cx="{x}" cy="{yy-38}" r="12" fill="{["#ffcf6b","#f6a3c0","#9fd88a","#ffcf6b","#f6a3c0"][i]}"/>')

# tent
tx,ty=places['tent']
shadow(tx+10,ty+92,160,28)
A(f'<path d="M{tx-150} {ty+86} L{tx} {ty-130} L{tx+150} {ty+86} Z" fill="#5aa9e6"/>')
for i in range(1,5):
    A(f'<path d="M{tx} {ty-130} L{tx-150+i*60} {ty+86} L{tx-150+i*60+30} {ty+86} Z" fill="#ffffff" opacity=".95"/>' if i%2 else '')
A(f'<path d="M{tx} {ty-130} L{tx+150} {ty+86} L{tx+105} {ty+86} Z" fill="#3c86c4" opacity=".55"/>')
A(f'<path d="M{tx-42} {ty+86} L{tx} {ty-10} L{tx+42} {ty+86} Z" fill="#244d73"/><path d="M{tx} {ty-10} L{tx+42} {ty+86} L{tx+70} {ty+86} Z" fill="#fdf6e8"/>')
A(f'<line x1="{tx}" y1="{ty-130}" x2="{tx}" y2="{ty-176}" stroke="#7a4d31" stroke-width="5"/><path d="M{tx} {ty-176} L{tx+40} {ty-164} L{tx} {ty-152} Z" fill="#ffd84d"/>')
A(f'<line x1="{tx-110}" y1="{ty+40}" x2="{tx-175}" y2="{ty+96}" stroke="#c9b48a" stroke-width="3"/><line x1="{tx+110}" y1="{ty+40}" x2="{tx+175}" y2="{ty+96}" stroke="#c9b48a" stroke-width="3"/>')
# small sign board in front (speech bubble shape)
A(f'<rect x="{tx+70}" y="{ty+110}" width="10" height="50" fill="#8a5a3b"/><path d="M{tx+40} {ty+70} h70 a14 14 0 0 1 14 14 v26 a14 14 0 0 1 -14 14 h-40 l-14 14 v-14 h-16 a14 14 0 0 1 -14 -14 v-26 a14 14 0 0 1 14 -14z" fill="#ffffff" stroke="#9ab6cf" stroke-width="4"/><circle cx="{tx+60}" cy="{ty+97}" r="5" fill="#5aa9e6"/><circle cx="{tx+76}" cy="{ty+97}" r="5" fill="#5aa9e6"/><circle cx="{tx+92}" cy="{ty+97}" r="5" fill="#5aa9e6"/>')

# bench plaza (round plaza with tree and benches)
bx,by=places['bench']
A(f'<ellipse cx="{bx}" cy="{by+40}" rx="160" ry="80" fill="#d9bd85"/><ellipse cx="{bx}" cy="{by+34}" rx="152" ry="74" fill="url(#plaza)"/>')
for k in range(1,3):
    A(f'<ellipse cx="{bx}" cy="{by+34}" rx="{152*k/3:.0f}" ry="{74*k/3:.0f}" fill="none" stroke="#e3cc9c" stroke-width="3"/>')
A(f'<ellipse cx="{bx}" cy="{by+24}" rx="44" ry="20" fill="#a37a52"/><ellipse cx="{bx}" cy="{by+18}" rx="38" ry="16" fill="#6b4a2e"/>')
tree(bx,by-60,0.95,'o')
def bench(x,y,flip=False):
    A(f'<ellipse cx="{x+4}" cy="{y+30}" rx="50" ry="9" fill="#000" opacity=".18"/>')
    A(f'<rect x="{x-46}" y="{y-26}" width="92" height="12" rx="4" fill="#b07a4c"/><rect x="{x-46}" y="{y-10}" width="92" height="12" rx="4" fill="#c99464"/><rect x="{x-48}" y="{y+6}" width="96" height="14" rx="4" fill="#d9a877"/>')
    A(f'<rect x="{x-40}" y="{y+18}" width="8" height="16" fill="#555"/><rect x="{x+32}" y="{y+18}" width="8" height="16" fill="#555"/>')
bench(bx-110,by+50); bench(bx+110,by+50); bench(bx,by+110)
lamp(bx+150,by-10)

# rescue house
hx,hy=places['house']
shadow(hx+10,hy+96,180,32)
A(f'<path d="M{hx-130} {hy-30} L{hx+130} {hy-30} L{hx+130} {hy+90} L{hx-130} {hy+90} Z" fill="#fff1dc"/>')
A(f'<path d="M{hx+130} {hy-30} L{hx+170} {hy-60} L{hx+170} {hy+60} L{hx+130} {hy+90} Z" fill="#ead6b6"/>')
A(f'<path d="M{hx-160} {hy-24} L{hx} {hy-150} L{hx+160} {hy-24} Z" fill="#e0604a"/><path d="M{hx} {hy-150} L{hx+40} {hy-180} L{hx+200} {hy-54} L{hx+160} {hy-24} Z" fill="#c24a38"/>')
A(f'<rect x="{hx+70}" y="{hy-150}" width="26" height="50" fill="#b9814f"/>')
A(f'<rect x="{hx-26}" y="{hy+10}" width="52" height="80" rx="24" fill="#8a5a3b"/><circle cx="{hx+14}" cy="{hy+52}" r="4" fill="#ffd84d"/>')
for wx in [hx-90,hx+60]:
    A(f'<rect x="{wx-26}" y="{hy+4}" width="56" height="46" rx="6" fill="#ffffff"/><rect x="{wx-21}" y="{hy+9}" width="46" height="36" rx="4" fill="#a8dcff"/><line x1="{wx+2}" y1="{hy+9}" x2="{wx+2}" y2="{hy+45}" stroke="#fff" stroke-width="4"/>')
A(f'<path d="M{hx} {hy-60} c-14 -22 -44 -10 -30 12 l30 26 l30 -26 c14 -22 -16 -34 -30 -12z" fill="#ff7fa3"/>')
# fence & doghouse
for i in range(8):
    A(f'<rect x="{hx-170+i*18}" y="{hy+96}" width="10" height="34" rx="3" fill="#ffffff" stroke="#e3d6c4" stroke-width="2"/>')
A(f'<rect x="{hx-172}" y="{hy+104}" width="146" height="7" fill="#ffffff"/>')
dx,dy=hx+170,hy+150
A(f'<ellipse cx="{dx+4}" cy="{dy+30}" rx="46" ry="10" fill="#000" opacity=".18"/><rect x="{dx-36}" y="{dy-20}" width="72" height="50" fill="#f0b35b"/><path d="M{dx-46} {dy-16} L{dx} {dy-56} L{dx+46} {dy-16} Z" fill="#5aa9e6"/><path d="M{dx-16} {dy+30} v-22 a16 16 0 0 1 32 0 v22 z" fill="#5a3a24"/>')

# info kiosk + map board
ix,iy=places['info']
shadow(ix+10,iy+96,170,30)
A(f'<rect x="{ix-110}" y="{iy-30}" width="200" height="120" rx="8" fill="#fff7ea"/><rect x="{ix+90}" y="{iy-30}" width="34" height="120" fill="#ead6b6"/>')
A(f'<rect x="{ix-80}" y="{iy}" width="130" height="50" rx="6" fill="#cfefff" stroke="#ffffff" stroke-width="6"/><rect x="{ix-96}" y="{iy+50}" width="162" height="16" rx="4" fill="#c99464"/>')
A(f'<path d="M{ix-130} {iy-30} L{ix-110} {iy-110} L{ix+130} {iy-110} L{ix+150} {iy-30} Z" fill="#4caf6e"/><path d="M{ix+130} {iy-110} L{ix+150} {iy-30} L{ix+124} {iy-30} Z" fill="#3a8c57"/>')
A(f'<circle cx="{ix}" cy="{iy-70}" r="22" fill="#ffffff"/><rect x="{ix-4}" y="{iy-72}" width="8" height="18" rx="3" fill="#4caf6e"/><circle cx="{ix}" cy="{iy-81}" r="4.5" fill="#4caf6e"/>')
mx,my=ix-180,iy+70
A(f'<rect x="{mx-6}" y="{my}" width="10" height="70" fill="#8a5a3b"/><rect x="{mx+66}" y="{my}" width="10" height="70" fill="#8a5a3b"/><rect x="{mx-20}" y="{my-70}" width="110" height="80" rx="6" fill="#ffffff" stroke="#8a5a3b" stroke-width="6"/>')
A(f'<path d="M{mx-8} {my-30} q30 -30 60 0 t30 -10" stroke="#f0c98f" stroke-width="8" fill="none"/><circle cx="{mx+20}" cy="{my-48}" r="8" fill="#9fd88a"/><circle cx="{mx+60}" cy="{my-20}" r="7" fill="#8fd3f0"/><path d="M{mx+70} {my-58} c-6 -8 -16 -2 -10 6 l10 8 l10 -8 c6 -8 -4 -14 -10 -6z" fill="#ff7fa3"/>')

# entrance pillars
for x in [480,720]:
    A(f'<ellipse cx="{x+6}" cy="{2300}" rx="34" ry="10" fill="#000" opacity=".2"/><rect x="{x-26}" y="{2190}" width="52" height="110" rx="8" fill="#d8cfbf"/><rect x="{x-32}" y="{2180}" width="64" height="20" rx="6" fill="#efe8da"/>')
A('<path d="M480 2190 Q600 2120 720 2190" stroke="#7a4d31" stroke-width="14" fill="none"/>')
A('</svg>')
open('/tmp/art/park.svg','w').write('\n'.join(out))
print(len(out))
