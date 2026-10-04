"""Targeted static contract checks; this is not a Flash runtime test."""
from pathlib import Path
import argparse
import copy
import re
import subprocess
import sys
import xml.etree.ElementTree as E

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[5]
sys.path.insert(0,str(REPO/'analysis/tools'))
from petfight_bridge_abc import Reader,decode_swf,parse_abc

def swf_tags(path):
    _,data=decode_swf(path.read_bytes())
    reader=Reader(data);reader.take(8)
    reader.take((5+(data[8]>>3)*4+7)//8+4)
    result=[]
    while reader.offset<len(data):
        header=reader.u16();code,size=header>>6,header&63
        if size==63:size=reader.u32()
        result.append((code,reader.take(size)))
    return result

def semantic(node):
    encoding_bits={'nbits','nScaleBits','nRotateBits','nTranslateBits','numBits','moveBits','numFillBits','numLineBits','forceWriteAsLong'}
    return (node.tag,tuple(sorted((k,v) for k,v in node.attrib.items() if k not in encoding_bits)),
        (node.text or '').strip(),tuple(semantic(child) for child in node))

def definitions(root):
    result={}
    for tag in root.find('tags'):
        for key in ('spriteId','shapeId','buttonId','textID','characterID','fontId'):
            if key in tag.attrib:result[int(tag.get(key))]=tag;break
    return result

def shape_contains(shape,point):
    # Read the candidate's emitted fill edges, not the generator's pixel-run list.
    x=y=0;winding=0;px,py=point
    for record in shape.find('shapes/shapeRecords'):
        kind=record.get('type')
        if kind=='StyleChangeRecord' and record.get('stateMoveTo')=='true':
            x=int(record.get('moveDeltaX'));y=int(record.get('moveDeltaY'))
        elif kind=='StraightEdgeRecord':
            nx=x+int(record.get('deltaX'));ny=y+int(record.get('deltaY'))
            if (y>py)!=(ny>py) and x+(py-y)*(nx-x)/(ny-y)>px:
                winding+=1 if ny>y else -1
            x,y=nx,ny
    return winding!=0

def verify(ffdec,evidence):
    subprocess.run([ffdec,'-swf2xml',str(evidence/'skin10.swf'),str(evidence/'skin10.xml')],check=True)
    subprocess.run([ffdec,'-onerror','abort','-selectclass','aola.theme.t10.mmo.controlv2.controlbarskin.skin.Skin10',
        '-export','script,symbolClass',str(evidence/'reread'),str(evidence/'skin10.swf')],check=True)
    before=definitions(E.parse(evidence/'skin9.xml').getroot())
    after=definitions(E.parse(evidence/'skin10.xml').getroot())
    named=0;buttons=0;frames=0
    for identifier,tag in before.items():
        if tag.get('type')=='DefineSpriteTag':
            assert tag.get('frameCount')==after[identifier].get('frameCount'),identifier
            frames+=1
            original=[semantic(p) for p in tag.find('subTags') if p.get('placeFlagHasName')=='true']
            current=[semantic(p) for p in after[identifier].find('subTags') if p.get('placeFlagHasName')=='true' and p.get('name') not in ('aolaOrnament','aolaStyleSources')]
            assert original==current,('Named placement changed',identifier)
            named+=len(original)
        elif tag.get('type')=='DefineButton2Tag':
            def hits(button):
                result=[]
                for record in button.find('characters'):
                    if record.get('buttonStateHitTest')!='true':continue
                    copy_record=copy.deepcopy(record)
                    for state in ('Up','Over','Down'):copy_record.set('buttonState'+state,'false')
                    result.append(semantic(copy_record))
                    child=int(record.get('characterId'))
                    assert semantic(before[child])==semantic(after[child]),('Hit definition changed',child)
                return result
            assert hits(tag)==hits(after[identifier]),('Hit records changed',identifier)
            if len(tag.find('characters')) == 0:
                assert len(after[identifier].find('characters')) == 0,identifier
            else:
                for state in ('Up','Over','Down'):
                    assert any(p.get('buttonState'+state)=='true' for p in after[identifier].find('characters')),identifier
            buttons+=1
    items=swf_tags(evidence/'skin10.swf');symbols=[]
    for code,body in items:
        if code!=76:continue
        reader=Reader(body)
        for _ in range(reader.u16()):
            identifier=reader.u16();start=reader.offset
            while reader.u8():pass
            name=body[start:reader.offset-1].decode('utf-8')
            assert name.startswith('aola.theme.t10.'),name
            symbols.append((identifier,name))
    assert (1233,'aola.theme.t10.mmo.controlv2.controlbarskin.skin.Skin10') in symbols
    targets={(name,'$iinit') for _,name in symbols};matches=[]
    for code,body in items:
        if code==82:matches+=parse_abc(body[body.index(b'\0',4)+1:],targets)
    assert {(m['className'],m['methodName']) for m in matches}==targets,'SymbolClass/ABC mismatch'
    assert before[948].get('frameCount')==after[948].get('frameCount')=='9'
    source=(evidence/'reread/scripts/aola/theme/t10/mmo/controlv2/controlbarskin/skin/Skin10.as').read_text(encoding='utf-8-sig')
    for token in ('onThemeAdded','onThemeRemoved','onThemeFrame','getTimer()','mouseEnabled = false','mouseChildren = false'):
        assert token in source,token
    constructor=source.split('public function Skin10()',1)[1].split('private function',1)[0]
    added=source.split('private function onThemeAdded(',1)[1].split('private function',1)[0]
    removed=source.split('private function onThemeRemoved(',1)[1].split('private function',1)[0]
    assert re.search(r'^\s*(?:this\.)?mouseEnabled = false;',constructor,re.M),'Skin root catches artwork hits'
    assert re.search(r'(?:this\.)?parent.mouseEnabled = false;',added),'Skin wrapper catches artwork hits'
    assert re.search(r'_mouseLayer = (?:this\.)?parent.parent;',added),'BaseControl not captured'
    assert re.search(r'_mouseLayerEnabled = (?:this\.)?_mouseLayer.mouseEnabled;',added),'BaseControl original mouse policy not saved'
    assert '_mouseLayer.mouseEnabled = false;' in added,'BaseControl catches artwork hits'
    assert re.search(r'_mouseLayer.mouseEnabled = (?:this\.)?_mouseLayerEnabled;',removed),'BaseControl original mouse policy not restored'
    assert re.search(r'if\((?:this\.)?_listening\)',added).start() < added.index('_mouseLayerEnabled ='),'Repeated attach overwrites saved policy'
    assert not re.search(r'^\s*(?:this\.)?mouseChildren = false;',constructor,re.M),'Original buttons disabled'
    for identifier in (1140,1146,1110,1141,1150):
        assert semantic(before[identifier])==semantic(after[identifier]),('Restored original entry changed',identifier)
    styles=next(p for p in after[1233].find('subTags') if p.get('name')=='aolaStyleSources')
    style_names={p.get('name') for p in after[int(styles.get('characterId'))].find('subTags') if p.get('placeFlagHasName')=='true'}
    assert style_names=={f'{name}_{state}' for name in ('team','scene','activity') for state in ('up','over','down')}|{'message_up'}
    for token in ('mmo.team.teamservice::TeamButton','mmo.notifyview::ActNotifyIcon','onTeamChildAdded','onNotifyFrame'):
        assert token in source,token
    assert not re.search(r'\.hitTestState\s*=',source),'External hitTestState overwritten'
    assert '_styledButtons = new Dictionary(true);' in removed and '_notifyIcons = new Dictionary(true);' in removed
    assert 'removeEventListener(Event.ADDED' in removed and 'removeEventListener(Event.FRAME_CONSTRUCTED' in removed
    assert re.search(r'\.name == "mcnum"',source),'Unread counter not retained'
    ornament=next(p for p in after[1233].find('subTags') if p.get('name')=='aolaOrnament')
    shape=after[int(ornament.get('characterId'))]
    bitmap=after[int(shape.find('shapes/fillStyles/fillStyles/item').get('bitmapId'))]
    width=int(bitmap.get('bitmapWidth'));height=int(bitmap.get('bitmapHeight'))
    bounds=shape.find('shapeBounds');x0,y0,x1,y1=[int(bounds.get(k)) for k in ('Xmin','Ymin','Xmax','Ymax')]
    # Four empty lower-map locations must miss; three visible bottom-art locations must hit.
    for x,y,filled in [(1086,200,False),(1086,350,False),(500,200,False),(1700,200,False),
                       (1086,550,True),(100,550,True),(1900,550,True)]:
        point=(x0+(x+.5)*(x1-x0)/width,y0+(y+.5)*(y1-y0)/height)
        assert shape_contains(shape,point)==filled,('Ornament fill blocks transparent map point',x,y)
    assert not any(code in (14,18,19,45) for code,_ in items),'Unexpected audio'
    print(f'PASS: {named} named placements; {frames} sprite timelines; {buttons} button hit contracts (empty placeholder retained); {len(symbols)} SymbolClass/ABC matches; BlueGem 9 frames; ornament transparent-map/visible-art fill geometry; decoration/root/wrapper/BaseControl mouse isolation with interactive children and policy restoration; lifecycle; no audio')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--ffdec',default='D:/Programs/FFdec/ffdec-cli.exe')
    parser.add_argument('--evidence',type=Path,default=REPO/'analysis/reverse-engineering/theme-castorice/T2')
    args=parser.parse_args();verify(args.ffdec,args.evidence.resolve())
