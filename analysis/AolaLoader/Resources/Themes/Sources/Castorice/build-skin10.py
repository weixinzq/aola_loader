"""Galaxy display list + approved native UI art -> independently namespaced Skin10.

Original definitions/HitTest records, instance names, timeline frames and leaf scripts
are retained. Only visual references are replaced. FFDec compiles the decoration class.
PNG decoding below encodes pixels into SWF ARGB; it does not edit source artwork.
"""
from pathlib import Path
import argparse
import base64
import copy
import html
import json
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as E
import zlib
from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[5]
sys.path.insert(0, str(REPO / 'analysis/tools'))
from theme_bridge_assets import theme_asset

LABELS = {
    21:('›',''),39:('发送',''),44:('','chat'),50:('频道',''),55:('短语',''),58:('真心话',''),
    67:('›',''),75:('⌄',''),159:('订单','home'),168:('战队','fleet'),175:('师徒','book'),
    180:('兵团','fleet'),185:('组队','friends'),190:('孵化','far'),201:('舰队','fleet'),
    213:('好友','friends'),222:('家园','home'),226:('仓库','far'),273:('剧情','book'),
    280:('任务','book'),288:('商城','shop'),330:('聊天','chat'),334:('排行','rank'),
    343:('⌄',''),345:('聊天记录','chat'),352:('全部','book'),357:('皮肤','skin'),
    362:('图鉴','book'),369:('荣誉','rank'),373:('最高荣耀','rank'),394:('地图','map'),
    400:('','shoot'),410:('↗',''),420:('飞行','action'),425:('跳舞','action'),
    430:('骑乘','action'),437:('骑乘','action'),442:('骑乘','action'),448:('','action'),
    972:('','nfa'),977:('','skin'),983:('','nfa'),985:('','nfa'),990:('亚比背包','pet'),
    1003:('周任务','book'),1014:('','pause'),1021:('客服','service'),
    1100:('↑',''),1101:('',''),
    # HistoryPanelV2.TYPE_DESC / mcTab channel ids, not the visual-preview placeholders.
    1173:('队伍',''),1177:('师徒',''),1181:('附近',''),1183:('本服',''),1189:('世界',''),
    1193:('系统',''),1199:('舰队',''),1204:('×',''),1226:('','chat'),1231:('屏蔽','')
}
for identifiers,glyph in [([1039,1040],'♪'),([1045,1047],'◉'),([1051,1052],'♥'),
                          ([1055,1058],'HD'),([1062,1065],'☷'),([1070,1073],'▣')]:
    for identifier in identifiers:LABELS[identifier]=(glyph,'')
MAIN = {201,213,222,226,288,330,334,362,394,990,1021}
BLUE = {623,691,754,755,756,819,882,947}
MENU = {159,168,175,180,185,190,352,357,369,373}
# Keep game-owned numeric counters, red points and avatar holders readable.
PRESERVE_SPRITES = {283,387,1089,1033,1034,1024,1110,1141,1150}
ORIGINAL_BUTTONS = {1140,1146}

def run(*args):
    subprocess.run([str(a) for a in args], check=True)

def matrix(x=0, y=0, sx=1, sy=1):
    return E.Element('matrix', {'type':'MATRIX','hasRotate':'false','hasScale':str(sx!=1 or sy!=1).lower(),
        'nRotateBits':'0','nScaleBits':'31','nTranslateBits':'31','rotateSkew0':'0.0','rotateSkew1':'0.0',
        'scaleX':str(sx),'scaleY':str(sy),'translateX':str(round(x*20)),'translateY':str(round(y*20))})

def rect_shape(identifier, box, bitmap=None, pixel_size=None, alpha=None):
    x0,y0,x1,y1 = [round(x*20) for x in box]
    tag = E.Element('item',type='DefineShape3Tag',forceWriteAsLong='true',shapeId=str(identifier))
    E.SubElement(tag,'shapeBounds',type='RECT',Xmin=str(x0),Ymin=str(y0),Xmax=str(x1),Ymax=str(y1),nbits='31')
    shapes=E.SubElement(tag,'shapes',type='SHAPEWITHSTYLE',numFillBits='1',numLineBits='0')
    fills=E.SubElement(E.SubElement(shapes,'fillStyles',type='FILLSTYLEARRAY'),'fillStyles')
    fill=E.SubElement(fills,'item',type='FILLSTYLE',fillStyleType='65' if bitmap else '0',bitmapId=str(bitmap or 0))
    if bitmap:
        m=matrix(box[0],box[1],(x1-x0)/pixel_size[0],(y1-y0)/pixel_size[1]);m.tag='bitmapMatrix';fill.append(m)
    else:
        E.SubElement(fill,'color',type='RGBA',alpha='0',red='0',green='0',blue='0')
    lines=E.SubElement(shapes,'lineStyles',type='LINESTYLEARRAY');E.SubElement(lines,'lineStyles');E.SubElement(lines,'lineStyles2')
    records=E.SubElement(shapes,'shapeRecords')
    regions=[(x0,y0,x1,y1)]
    if alpha is not None:
        # Bitmap transparency does not remove a Shape's rectangular fill geometry.
        # Keep the original bitmap, but fill only runs of pixels that contain artwork.
        pixels=alpha.load();w,h=alpha.size;regions=[]
        for y in range(h):
            x=0
            while x<w:
                if pixels[x,y]==0:x+=1;continue
                start=x
                while x<w and pixels[x,y]!=0:x+=1
                regions.append((x0+round(start*(x1-x0)/w),y0+round(y*(y1-y0)/h),
                    x0+round(x*(x1-x0)/w),y0+round((y+1)*(y1-y0)/h)))
    for left,top,right,bottom in regions:
        E.SubElement(records,'item',type='StyleChangeRecord',stateMoveTo='true',moveDeltaX=str(left),moveDeltaY=str(top),
            moveBits='31',stateFillStyle0='true',fillStyle0='1',stateFillStyle1='false',fillStyle1='0',
            stateLineStyle='false',lineStyle='0',stateNewStyles='false',numFillBits='0',numLineBits='0')
        for dx,dy in [(right-left,0),(0,bottom-top),(left-right,0),(0,top-bottom)]:
            E.SubElement(records,'item',type='StraightEdgeRecord',deltaX=str(dx),deltaY=str(dy),
                generalLineFlag='false',vertLineFlag=str(dx==0).lower(),numBits='31')
    E.SubElement(records,'item',type='EndShapeRecord')
    return tag

def svg(width,height,body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{body}</svg>'

def native_art(buttons):
    preview=(HERE/'preview.html').read_text(encoding='utf-8')
    icons=dict(re.findall(r"(\w+):'([^']+)'",preview.split('const paths={',1)[1].split('};',1)[0]))
    chibi='data:image/png;base64,'+base64.b64encode((HERE/'castorice-chibi-v2.png').read_bytes()).decode()
    ring='data:image/png;base64,'+base64.b64encode((HERE/'mingdie-ring-transparent.png').read_bytes()).decode()
    assets=[]
    for button in buttons:
        identifier=button['resource_id']
        if identifier in ORIGINAL_BUTTONS:continue
        box=button['state_bounds'].get('Up') or button['state_bounds'].get('HitTest')
        if not box: continue
        if identifier in BLUE: box=[-13.35,-55.15,95.65,69.85]
        button['visual_bounds']=box
        w,h=box[2]-box[0],box[3]-box[1]
        label,kind=LABELS.get(identifier,('','skin'))
        for state,color in [('up','#dfd6ed'),('over','#fff2ff'),('down','#ac8acb')]:
            shift=1 if state=='down' else 0
            if identifier==394:
                body=f'<svg x="{(w-74)/2}" y="2" width="74" height="{h-4}" viewBox="111 31 1099 1207"><image href="{ring}" width="1254" height="1254" opacity="{.8 if state=="down" else 1}"/></svg>'
            elif identifier in BLUE:
                body=f'<image href="{chibi}" x="0" y="0" width="109" height="115" preserveAspectRatio="xMidYMid meet" opacity="{.85 if state=="down" else 1}"/>'
                body+=f'<text x="54.5" y="123" fill="{color}" font-family="Microsoft YaHei" font-size="12" text-anchor="middle">蓝宝石</text>'
            else:
                body=''
                if identifier in {1039,1040,1045,1047,1051,1052,1055,1058,1062,1065,1070,1073}:
                    body+=f'<circle cx="{w/2}" cy="{h/2}" r="{min(w,h)/2-.6}" fill="#30253f" stroke="{color}" stroke-opacity=".65"/>'
                if identifier in MENU or identifier in {39,50,55,58,345,1173,1177,1181,1183,1189,1193,1199,1231}:
                    body+=f'<rect x=".6" y=".6" width="{w-1.2}" height="{h-1.2}" rx="{min(h/2,12)}" fill="{"#594071" if state=="over" else "#29223e"}" stroke="{color}" stroke-opacity=".6"/>'
                if kind:
                    size=min(w*.65,h*.6,48 if identifier in MAIN else 30)
                    if identifier==394:size=48
                    top=(h-size-(25 if label and identifier in MAIN else 0))/2+shift
                    if identifier in MENU: size=14;top=(h-14)/2+shift;left=8
                    else:left=(w-size)/2
                    body+=f'<svg x="{left}" y="{top}" width="{size}" height="{size}" viewBox="0 0 30 30"><path d="{icons[kind]}" fill="none" stroke="{color}" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>'
                if label:
                    font=26 if identifier==990 else 21 if identifier in MAIN else min(10,h*.5)
                    baseline=h*.86+shift if identifier in MAIN else h*.5+font*.35+shift
                    body+=f'<text x="{w/2+(7 if identifier in MENU else 0)}" y="{baseline}" fill="{color}" font-family="Microsoft YaHei" font-size="{font}" text-anchor="middle">{html.escape(label)}</text>'
            assets.append({'name':f'button-{identifier}-{state}','width':w,'height':h,'svg':svg(w,h,body)})
    return assets

def external_art():
    preview=(HERE/'preview.html').read_text(encoding='utf-8')
    icons=dict(re.findall(r"(\w+):'([^']+)'",preview.split('const paths={',1)[1].split('};',1)[0]))
    chibi='data:image/png;base64,'+base64.b64encode((HERE/'castorice-chibi-v2.png').read_bytes()).decode()
    assets=[]
    for name,label,kind,w,h in [('team','组队','friends',78,24),('scene','场景','map',56,57),
                               ('activity','活动','rank',56,57),('message','消息盒子','',66,70)]:
        for state,color in [('up','#dfd6ed'),('over','#fff2ff'),('down','#ac8acb')]:
            if name=='message' and state!='up':continue
            if name=='message':
                body=f'<image href="{chibi}" x="11" y="0" width="44" height="56"/>'
                body+=f'<text x="33" y="68" text-anchor="middle" font-family="Microsoft YaHei" font-size="11" fill="{color}">{label}</text>'
            else:
                body=f'<rect x=".7" y=".7" width="{w-1.4}" height="{h-1.4}" rx="{11 if name=="team" else 8}" fill="{"#594071" if state=="over" else "#29223e"}" stroke="{color}" stroke-opacity=".65"/>'
                size=15 if name=='team' else 27
                left=8 if name=='team' else (w-size)/2;top=4 if name=='team' else 5
                body+=f'<svg x="{left}" y="{top}" width="{size}" height="{size}" viewBox="0 0 30 30"><path d="{icons[kind]}" fill="none" stroke="{color}" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>'
                body+=f'<text x="{48 if name=="team" else w/2}" y="{17 if name=="team" else 49}" text-anchor="middle" font-family="Microsoft YaHei" font-size="12" fill="{color}">{label}</text>'
            assets.append({'name':f'external-{name}-{state}','width':w,'height':h,'svg':svg(w,h,body)})
    return assets

def build(ffdec,evidence):
    evidence.mkdir(parents=True,exist_ok=True)
    original=REPO/'analysis/AolaLoader/Resources/Themes/skin9.swf'
    run(ffdec,'-swf2xml',original,evidence/'skin9.xml')
    tree=E.parse(evidence/'skin9.xml');tags=tree.getroot().find('tags')
    definitions={}
    for tag in tags:
        for key in ('spriteId','shapeId','buttonId','textID','characterID','fontId'):
            if key in tag.attrib: definitions[int(tag.get(key))]=tag;break
    buttons=json.loads((HERE/'galaxy-buttons.json').read_text(encoding='utf-8'))
    # Restored entry artwork includes the nested animation/text definitions, not just its outer clip.
    restored=set();pending=[1141,1150]
    while pending:
        identifier=pending.pop()
        if identifier in restored:continue
        restored.add(identifier);tag=definitions[identifier]
        if tag.get('type')=='DefineSpriteTag':
            pending.extend(int(p.get('characterId')) for p in tag.find('subTags') if p.get('placeFlagHasCharacter')=='true')
        elif tag.get('type')=='DefineButton2Tag':
            pending.extend(int(p.get('characterId')) for p in tag.find('characters'))
    assets=native_art(buttons)+external_art()
    # Account/background planes use original local coordinates; game text and avatar are not baked in.
    panels={
        'info':(1102,[4.3,57.7,257,133.7]),
        'chat':(1232,[50.3,120.9,413,639.8]),
        'input':(59,[0,0,330,31]),
        'actions':(444,[9.35,-9.15,109.35,170.4]),
    }
    for name,(identifier,box) in panels.items():
        if identifier not in definitions:continue
        w,h=box[2]-box[0],box[3]-box[1]
        if name=='info':
            body='<defs><linearGradient id="night" x2="0" y2="1"><stop stop-color="#41304f"/><stop offset=".35" stop-color="#29223e"/><stop offset="1" stop-color="#171323"/></linearGradient></defs>'
            body+='<path d="M.6 2H225L252 21V64L238 75H65L.6 66Z" fill="url(#night)" stroke="#eae6f3" stroke-opacity=".8"/><path d="M72 2L76 65M78 45H215M215 2L239 22" fill="none" stroke="#a994d1" opacity=".45"/><circle cx="38.5" cy="34.5" r="26.5" fill="#383045" stroke="#a994d1" stroke-opacity=".6"/><path d="M231 7L239 15L231 23L224 15Z" fill="#a994d1" opacity=".7"/><text x="84" y="17" fill="#ad9dc3" font-family="Microsoft YaHei" font-size="10">战斗力</text>'
        else:
            body=f'<rect x=".6" y=".6" width="{w-1.2}" height="{h-1.2}" rx="6" fill="#29223e" fill-opacity=".94" stroke="#a994d1" stroke-opacity=".6"/>'
        assets.append({'name':'panel-'+name,'width':w,'height':h,'svg':svg(w,h,body)})
    (evidence/'assets.json').write_text(json.dumps(assets,ensure_ascii=False),encoding='utf-8')
    run('node',HERE/'render-assets.cjs',evidence/'assets.json',evidence/'images')
    for name in ('team','scene','activity','message'):
        shutil.copyfile(evidence/'images'/f'external-{name}-up.png',HERE/f'preview-external-{name}.png')
    next_id=max(definitions)+1
    new=[];mapping=[]
    hit_characters={int(record.get('characterId')) for tag in definitions.values()
        if tag.get('type')=='DefineButton2Tag' for record in tag.find('characters')
        if record.get('buttonStateHitTest')=='true'}
    def bitmap_shape(path,box,alpha_geometry=False):
        nonlocal next_id
        bitmap_id,shape_id=next_id,next_id+1;next_id+=2
        image=Image.open(path).convert('RGBA');w,h=image.size
        pixels=bytearray()
        for r,g,b,a in image.getdata(): pixels.extend((a,(r*a+127)//255,(g*a+127)//255,(b*a+127)//255))
        new.append(E.Element('item',type='DefineBitsLossless2Tag',characterID=str(bitmap_id),bitmapFormat='5',
            bitmapWidth=str(w),bitmapHeight=str(h),bitmapColorTableSize='0',forceWriteAsLong='true',zlibBitmapData=zlib.compress(bytes(pixels)).hex()))
        new.append(rect_shape(shape_id,box,bitmap_id,(w,h),image.getchannel('A') if alpha_geometry else None))
        return shape_id
    # Replace only movie-clip visual shapes; retain original definitions referenced by hit shapes/masks.
    blank={}
    for identifier,tag in definitions.items():
        if tag.get('type')!='DefineSpriteTag' or identifier in PRESERVE_SPRITES or identifier in restored:continue
        for placement in tag.find('subTags'):
            child=definitions.get(int(placement.get('characterId','0')))
            if not placement.get('type','').startswith('PlaceObject') or child is None or 'Shape' not in child.get('type','') or int(placement.get('clipDepth','0')):continue
            child_id=int(placement.get('characterId'))
            if child_id not in blank:
                box=[float(child.find('shapeBounds').get(k))/20 for k in ('Xmin','Ymin','Xmax','Ymax')]
                blank[child_id]=next_id;new.append(rect_shape(next_id,box));next_id+=1
            placement.set('characterId',str(blank[child_id]))
    for button in buttons:
        if 'visual_bounds' not in button:continue
        identifier=button['resource_id'];characters=definitions[identifier].find('characters')
        original_hits=[copy.deepcopy(p) for p in characters if p.get('buttonStateHitTest')=='true']
        characters.clear()
        for state in ('up','over','down'):
            shape=bitmap_shape(evidence/'images'/f'button-{identifier}-{state}.png',button['visual_bounds'])
            record=E.SubElement(characters,'item',type='BUTTONRECORD',blendMode='0',buttonHasBlendMode='false',buttonHasFilterList='false',
                buttonStateDown=str(state=='down').lower(),buttonStateHitTest='false',buttonStateOver=str(state=='over').lower(),
                buttonStateUp=str(state=='up').lower(),characterId=str(shape),placeDepth='1',reserved='0')
            m=matrix();m.tag='placeMatrix';record.append(m)
            E.SubElement(record,'colorTransform',type='CXFORMWITHALPHA',hasAddTerms='false',hasMultTerms='false',nbits='1',
                alphaAddTerm='0',alphaMultTerm='256',blueAddTerm='0',blueMultTerm='256',greenAddTerm='0',greenMultTerm='256',redAddTerm='0',redMultTerm='256')
            mapping.append({'button':identifier,'state':state,'shape':shape,'source':f'button-{identifier}-{state}.png'})
        for record in original_hits:
            for state in ('Up','Over','Down'):record.set('buttonState'+state,'false')
            characters.append(record)
    # Hidden, local art sources supply external button states without replacing game objects.
    styles_id=next_id;next_id+=1
    style_tag=E.Element('item',type='DefineSpriteTag',spriteId=str(styles_id),frameCount='1',forceWriteAsLong='true')
    style_timeline=E.SubElement(style_tag,'subTags')
    for i,asset in enumerate(external_art()):
        name=asset['name'].removeprefix('external-').replace('-','_')
        shape=bitmap_shape(evidence/'images'/f'{asset["name"]}.png',[0,0,asset['width'],asset['height']])
        sprite=next_id;next_id+=1
        tag=E.Element('item',type='DefineSpriteTag',spriteId=str(sprite),frameCount='1',forceWriteAsLong='true')
        timeline=E.SubElement(tag,'subTags')
        placement=E.SubElement(timeline,'item',type='PlaceObject2Tag',characterId=str(shape),depth='1',
            placeFlagHasCharacter='true',placeFlagHasMatrix='true',placeFlagHasName='false',placeFlagMove='false')
        placement.append(matrix())
        E.SubElement(timeline,'item',type='ShowFrameTag');E.SubElement(timeline,'item',type='EndTag');new.append(tag)
        placement=E.SubElement(style_timeline,'item',type='PlaceObject2Tag',characterId=str(sprite),depth=str(i+1),name=name,
            placeFlagHasCharacter='true',placeFlagHasMatrix='true',placeFlagHasName='true',placeFlagMove='false')
        placement.append(matrix())
    E.SubElement(style_timeline,'item',type='ShowFrameTag');E.SubElement(style_timeline,'item',type='EndTag');new.append(style_tag)
    def place(sprite,shape,depth,name=None):
        timeline=definitions[sprite].find('subTags')
        # Reuse the original anonymous background slot, leaving named instances/depths intact.
        background=next((p for p in timeline if p.get('type','').startswith('PlaceObject')
            and p.get('placeFlagHasName')!='true' and int(p.get('characterId','0')) in blank.values()
            and p.get('clipDepth','0')=='0'),None)
        if background is not None:
            background.set('characterId',str(shape))
            if name:background.set('name',name);background.set('placeFlagHasName','true')
            return
        occupied={int(p.get('depth','0')) for p in timeline}
        depth=next(d for d in range(1,65535) if d not in occupied)
        node=E.Element('item',type='PlaceObject2Tag',characterId=str(shape),clipDepth='0',depth=str(depth),forceWriteAsLong='true',
            placeFlagHasCharacter='true',placeFlagHasClipActions='false',placeFlagHasClipDepth='false',placeFlagHasColorTransform='false',
            placeFlagHasMatrix='true',placeFlagHasName='false',placeFlagHasRatio='false',placeFlagMove='false',ratio='0')
        if name:node.set('name',name);node.set('placeFlagHasName','true')
        node.append(matrix());timeline.insert(0,node)
    for name,(identifier,box) in panels.items():
        if identifier in definitions:place(identifier,bitmap_shape(evidence/'images'/f'panel-{name}.png',box),0)
    # The source ornament is transformed/cropped by the SWF shape, never raster-edited.
    # Root offset in the original host is (-8.8,480.4).
    image=Image.open(HERE/'ornament-concept.png');w,h=image.size
    ornament_id=bitmap_shape(HERE/'ornament-concept.png',[8.8,-203.4,970.8,-203.4+h*962/w],alpha_geometry=True)
    place(1233,ornament_id,0,'aolaOrnament')
    place(1233,styles_id,0,'aolaStyleSources')
    # Convert original static/edit text colors only; fields, fonts and bindings remain original.
    for identifier,tag in definitions.items():
        if identifier not in hit_characters and identifier not in restored and tag.get('type') in ('DefineTextTag','DefineText2Tag','DefineEditTextTag'):
            for color in tag.iter():
                if color.get('type') in ('RGB','RGBA'):
                    color.set('red','234');color.set('green','230');color.set('blue','243')
    # New definitions must precede every timeline that references them.
    for i,tag in enumerate(new):tags.insert(i+3,tag)
    tree.write(evidence/'visual.xml',encoding='utf-8',xml_declaration=True)
    (evidence/'replacement-map.json').write_text(json.dumps(mapping,ensure_ascii=False,indent=2),encoding='utf-8')
    run(ffdec,'-xml2swf',evidence/'visual.xml',evidence/'visual.swf')
    theme_asset(evidence/'visual.swf',evidence/'namespaced.swf',10,'Skin10')
    candidate=evidence/'skin10.swf'
    run(ffdec,'-onerror','abort','-replace',evidence/'namespaced.swf',candidate,
        'aola.theme.t10.mmo.controlv2.controlbarskin.skin.Skin10',HERE/'Skin10.as')
    return candidate

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--ffdec',default='D:/Programs/FFdec/ffdec-cli.exe')
    parser.add_argument('--evidence',type=Path,default=REPO/'analysis/reverse-engineering/theme-castorice/T2')
    args=parser.parse_args()
    print(build(args.ffdec,args.evidence.resolve()))
