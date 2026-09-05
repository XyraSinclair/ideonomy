"""Build the offline catalog atlas without changing lists or map coordinates.

    python3 -m ideonomy.atlas --output docs/catalog-map.html
"""
from __future__ import annotations

import argparse
import json
from importlib import resources
from pathlib import Path

from .canon import lists


def catalog() -> dict:
    """Join catalog records to display-only orders and existing map points."""
    data = resources.files(__package__) / "data"

    def rows(name):
        return [json.loads(line) for line in (data / name).read_text(
            encoding="utf-8").splitlines() if line.strip()]

    orders = {row["name"]: row for row in rows("seriations.jsonl")}
    points = {}
    metadata = {}
    for row in rows("catalog-map.jsonl"):
        if "_meta" in row:
            metadata = row["_meta"]
        else:
            points[(row["tier"], row["name"])] = [row["x"], row["y"]]
    records = []
    for tier in ("canon", "grown"):
        for name, item in sorted(lists(tier).items()):
            record = item.to_dict()
            record["tier"] = tier
            record["position"] = points.get((tier, name))
            record["seriation"] = (item.source or {}).get("seriation") or {}
            record["display_order"] = "Stored item order"
            if tier == "canon" and name in orders:
                sidecar = orders[name]
                order = sidecar["order"]
                if (any(type(i) is not int for i in order)
                        or sorted(order) != list(range(len(item.items)))):
                    raise ValueError(f"invalid canon display order: {name}")
                record["items"] = [item.items[i] for i in order]
                record["seriation"] = {k: v for k, v in sidecar.items()
                                        if k not in ("name", "tier", "order")}
                record["display_order"] = "Sidecar order; canon text is unchanged"
            records.append(record)
    return {"lists": records, "map": metadata, "stored_points": len(points)}


def render(payload: dict) -> str:
    """Embed data as inert JSON; HTML markup never interpolates data strings."""
    encoded = json.dumps(payload, ensure_ascii=False, sort_keys=True,
                         separators=(",", ":"), allow_nan=False)
    encoded = (encoded.replace("&", "\\u0026").replace("<", "\\u003c")
               .replace(">", "\\u003e").replace("\u2028", "\\u2028")
               .replace("\u2029", "\\u2029"))
    return HTML.replace("__CATALOG_JSON__", encoded)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("docs/catalog-map.html"))
    args = parser.parse_args(argv)
    html = render(catalog())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(html, encoding="utf-8")
    print(f"Wrote {args.output}")
    return 0


HTML = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="tdm-reservation" content="1">
<meta name="tdm-policy" content="https://github.com/XyraSinclair/ideonomy/blob/main/LICENSE">
<title>Ideonomy · Catalog atlas</title>
<style>
:root{color-scheme:light;--ink:#242b2b;--muted:#576360;--line:#d4dbd4;--paper:#fafbf7;
--canon:#276797;--grown:#386e45;--focus:#9b4c15}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);
font:16px/1.55 system-ui,-apple-system,sans-serif}header,main{max-width:1440px;margin:auto;padding:24px}
h1{font-size:clamp(26px,4vw,38px);letter-spacing:-.035em;margin:0}h2{font-size:22px;line-height:1.3}
h3{font-size:17px}p{margin:.6em 0}.muted,small{color:var(--muted)}a{color:var(--canon)}
button,input,select{font:inherit}button,a,input,select,summary{touch-action:manipulation}
:focus-visible{outline:3px solid var(--focus);outline-offset:3px}button{cursor:pointer}
header{padding-bottom:8px}.intro{max-width:85ch}.legend{display:flex;gap:20px;flex-wrap:wrap}
.canon{color:var(--canon)}.grown{color:var(--grown)}.workspace{display:grid;grid-template-columns:minmax(280px,36%) minmax(0,1fr);gap:28px}
.controls{display:grid;grid-template-columns:1fr auto;gap:12px}label{display:block;font-size:14px;font-weight:600}
input,select{width:100%;background:white;color:var(--ink);border:1px solid #9aa89d;border-radius:5px;padding:9px;min-width:0}
.map-panel{border:1px solid var(--line);border-radius:8px;margin-top:18px;padding:12px;background:#f0f4ef}
canvas{display:block;width:100%;height:300px;cursor:crosshair}#map-label{min-height:3em;font-size:13px;overflow-wrap:anywhere}
#results{list-style:none;padding:0;margin:12px 0;max-height:65vh;overflow:auto;border-block:1px solid var(--line)}
#results button{display:block;text-align:left;width:100%;border:0;border-bottom:1px solid var(--line);background:transparent;color:var(--ink);padding:12px 10px;overflow-wrap:anywhere}
#results button:hover{background:#eef2eb}#results button[aria-current=true]{background:#e1e9dc;box-shadow:inset 3px 0 var(--grown)}
#results strong{display:block;font-size:14px}#results small{font-size:12px}
article{min-width:0;border-left:1px solid var(--line);padding-left:28px}#list-title{overflow-wrap:anywhere;margin-top:0}
#list-meta{font-size:14px}#axis{border-left:3px solid #9b8d67;padding-left:14px;margin:20px 0}
dl{display:grid;grid-template-columns:minmax(100px,auto) 1fr;gap:5px 16px;font-size:14px}dt{color:var(--muted)}dd{margin:0;overflow-wrap:anywhere}
#items{padding-left:2.4em}#items li{padding:10px 0 10px 7px;border-bottom:1px solid var(--line);white-space:pre-wrap;overflow-wrap:anywhere}
#items li::marker{color:var(--muted);font-variant-numeric:tabular-nums}#items li.match{background:#fff2cf}
summary{cursor:pointer;font-weight:600}details{margin:16px 0}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:12px/1.6 ui-monospace,monospace}
#empty{padding:30px 0}.reading-link{display:inline-block;margin:8px 0}#counts{font-size:14px}
@media(max-width:760px){header,main{padding:16px}.workspace{grid-template-columns:1fr;gap:20px}
article{border-left:0;border-top:1px solid var(--line);padding:24px 0 0}#results{max-height:300px}
canvas{height:240px}.controls{grid-template-columns:minmax(0,1fr) 110px}dl{grid-template-columns:1fr}dd{margin-bottom:8px}}
</style>
</head>
<body>
<header>
<h1>Ideonomy <span class="muted">/ Catalog atlas</span></h1>
<p class="intro">Browse recovered lists and machine-grown extensions. Search names, item types, and every item; select a list to read its complete order.</p>
<p id="coverage" class="muted"></p>
<p class="muted">New protected contributions: <a href="https://github.com/XyraSinclair/ideonomy/blob/main/LICENSE">Harvest Commercial 1.0</a> · commercial use requires a paid agreement. <a href="https://github.com/XyraSinclair/ideonomy/blob/main/LICENSE-MIT">Prior MIT grants</a> and third-party rights remain intact.</p>
<div class="legend"><span class="canon">● Canon · recovered Gunkel</span><span class="grown">● Grown · machine / model</span></div>
<details class="intro"><summary>What this map can — and cannot — tell you</summary>
<p>The map reuses stored two-dimensional embedding projection coordinates. Nothing is re-embedded here. Projection can distort distances and neighborhoods; proximity is not proof of equivalence, truth, quality, or exhaustive coverage. Filtering does not reposition points. Overlapping points are easier to select in the list index.</p>
<p>Item ordering and map position are different artifacts. Smoothness measures mean adjacent similarity in the original similarity matrix; the random-order baseline and their difference (seriability) describe that ordering, not its truth. Missing metrics mean not measured here, never zero.</p>
<p>Named axes and “revelatory” judgments are model interpretations, not measured dimensions or independent validation. Canon sidecar orders change this display only; the recovered text remains unchanged. Unpositioned lists are fully readable and searchable.</p>
<p id="map-claim"></p>
</details>
</header>
<main class="workspace">
<section aria-label="Find a list">
<div class="controls"><div><label for="search">Search catalog</label><input id="search" type="search" placeholder="A name, type, or item…" autocomplete="off"></div>
<div><label for="tier">Provenance</label><select id="tier"><option value="all">All tiers</option><option value="canon">Canon</option><option value="grown">Grown</option></select></div></div>
<div class="map-panel"><canvas id="map" aria-label="Catalog map. Use the list buttons below for keyboard selection." role="img"></canvas><p id="map-label" class="muted">Select a point or use the list index below.</p></div>
<p id="counts" role="status" aria-live="polite"></p>
<ul id="results" aria-label="Matching lists"></ul>
</section>
<article id="reader" aria-label="Selected list">
<p id="empty">Select a list from the map or index.</p>
<div id="content" hidden>
<h2 id="list-title" tabindex="-1"></h2><p id="list-type"></p><p id="list-meta" class="muted"></p>
<a id="permalink" class="reading-link">Link to this list</a>
<div id="axis"></div><dl id="metrics"></dl>
<details><summary>Provenance and ordering metadata</summary><pre id="provenance"></pre></details>
<ol id="items"></ol>
</div>
</article>
</main>
<noscript><p>This offline atlas needs JavaScript enabled to search and read its embedded catalog. It makes no network requests.</p></noscript>
<script id="catalog" type="application/json">__CATALOG_JSON__</script>
<script>
'use strict';
const data=JSON.parse(document.getElementById('catalog').textContent);
const $=id=>document.getElementById(id), text=value=>typeof value==='string'?value:JSON.stringify(value);
const key=row=>row.tier+'/'+row.name;
const all=data.lists, byKey=new Map(all.map(row=>[key(row),row]));
const haystacks=new Map(all.map(row=>[key(row),[row.name,row.of,...row.items.map(text)].join('\n').toLocaleLowerCase()]));
const positioned=all.filter(row=>row.position!==null);
let visible=all, selected=null, query='', plotted=[];
const cv=$('map'), ctx=cv.getContext('2d');
$('coverage').textContent=`${all.length} lists · ${positioned.length} positioned / ${all.length} total · ${all.length-positioned.length} not positioned. Stored map: ${data.stored_points} points.`;
$('map-claim').textContent='Stored catalog-axis claim: '+(data.map.axis||'not recorded')+
    (data.map.revelatory===undefined?'':' · Revelatory judgment: '+data.map.revelatory)+
    (data.map.note?' · '+data.map.note:'');
const bounds=positioned.length?[0,1].map(axis=>{
    const values=positioned.map(row=>row.position[axis]);return [Math.min(...values),Math.max(...values)];
}):[[0,1],[0,1]];
function draw(){
    const width=cv.clientWidth,height=cv.clientHeight,dpr=window.devicePixelRatio||1;
    cv.width=Math.round(width*dpr);cv.height=Math.round(height*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);
    ctx.clearRect(0,0,width,height);
    const scale=Math.min((width-32)/(bounds[0][1]-bounds[0][0]||1),(height-32)/(bounds[1][1]-bounds[1][0]||1));
    plotted=[];
    for(const row of visible){
        if(row.position===null)continue;
        const x=width/2+(row.position[0]-(bounds[0][0]+bounds[0][1])/2)*scale;
        const y=height/2+(row.position[1]-(bounds[1][0]+bounds[1][1])/2)*scale;
        plotted.push({row,x,y});
        ctx.beginPath();ctx.arc(x,y,row.tier==='grown'?4:2.5,0,Math.PI*2);
        ctx.fillStyle=row.tier==='grown'?'#386e45':'#276797';ctx.globalAlpha=.65;ctx.fill();
    }
    ctx.globalAlpha=1;
    const active=plotted.find(p=>key(p.row)===selected);
    if(active){ctx.beginPath();ctx.arc(active.x,active.y,8,0,Math.PI*2);ctx.strokeStyle='#9b4c15';ctx.lineWidth=2;ctx.stroke();}
}
function show(row,focus=false){
    selected=key(row);$('empty').hidden=true;$('content').hidden=false;
    $('list-title').textContent=row.name;$('list-type').textContent=row.of;
    $('list-meta').textContent=`${row.tier} · ${row.items.length} items · ${row.status} · ${row.source?.kind||'list'} · `+
        (row.position===null?'not positioned':`stored map coordinates (${row.position.join(', ')})`);
    $('permalink').href='#'+encodeURIComponent(selected);
    const s=row.seriation;
    $('axis').textContent=(s.axis?'Named axis (interpretive claim): '+s.axis:'No named axis recorded.')+
        (s.named_by?' · Named by: '+s.named_by:'')+
        (s.revelatory==null?'':' · Revelatory (model judgment): '+s.revelatory);
    $('metrics').replaceChildren();
    const fields=[['Display',row.display_order],['Ordering method',s.method??'not recorded'],
        ['Smoothness',s.smoothness??'not measured'],['Random baseline',s.random_smoothness??'not measured'],
        ['Seriability (difference)',s.seriability??'not measured']];
    for(const [label,value] of fields){const dt=document.createElement('dt'),dd=document.createElement('dd');dt.textContent=label;dd.textContent=value;$('metrics').append(dt,dd);}
    $('provenance').textContent=JSON.stringify({made_by:row.made_by,parents:row.parents,source:row.source,display_seriation:s},null,2);
    const items=document.createDocumentFragment();
    for(const value of row.items){const li=document.createElement('li');li.textContent=text(value);if(query&&text(value).toLocaleLowerCase().includes(query))li.className='match';items.append(li);}
    $('items').replaceChildren(items);
    for(const button of $('results').querySelectorAll('button'))button.setAttribute('aria-current',String(button.dataset.key===selected));
    draw();if(focus)$('list-title').focus();
}
function choose(row){
    const fragment='#'+encodeURIComponent(key(row));
    if(location.hash!==fragment)location.hash=fragment;
    show(row,true);
}
function filter(){
    query=$('search').value.trim().toLocaleLowerCase();
    visible=all.filter(row=>($('tier').value==='all'||row.tier===$('tier').value)&&haystacks.get(key(row)).includes(query));
    const fragment=document.createDocumentFragment();
    for(const row of visible){
        const li=document.createElement('li'),button=document.createElement('button'),name=document.createElement('strong'),meta=document.createElement('small');
        button.type='button';button.dataset.key=key(row);button.setAttribute('aria-current',String(key(row)===selected));
        name.textContent=row.name;meta.textContent=`${row.tier} · ${row.items.length} items · ${row.position===null?'not positioned':'positioned'}`;
        button.append(name,meta);button.addEventListener('click',()=>choose(row));li.append(button);fragment.append(li);
    }
    $('results').replaceChildren(fragment);
    const n=visible.filter(row=>row.position!==null).length;
    $('counts').textContent=`${visible.length} matching lists · ${n} positioned · ${visible.length-n} not positioned`+
        (selected&&!visible.some(row=>key(row)===selected)?' · Reading a list outside these filters.':'');
    if(selected)show(byKey.get(selected));else draw();
}
function fromHash(){
    let id;try{id=decodeURIComponent(location.hash.slice(1));}catch{ id=''; }
    const row=byKey.get(id);
    if(row){
        if(!visible.some(r=>key(r)===id)){$('search').value='';$('tier').value='all';filter();}
        show(row);
    }else if(location.hash){$('empty').textContent='This list link is not in the catalog. Search or select a list below.';$('empty').hidden=false;$('content').hidden=true;selected=null;filter();}
    else{selected=null;$('content').hidden=true;$('empty').textContent='Select a list from the map or index.';$('empty').hidden=false;filter();}
}
function nearest(event){
    const rect=cv.getBoundingClientRect(),x=event.clientX-rect.left,y=event.clientY-rect.top;
    let best=null,distance=144;for(const p of plotted){const d=(p.x-x)**2+(p.y-y)**2;if(d<distance){best=p;distance=d;}}return best;
}
cv.addEventListener('pointermove',event=>{const p=nearest(event);$('map-label').textContent=p?`${p.row.name} · ${p.row.tier}`:'Select a point or use the list index below.';});
cv.addEventListener('pointerleave',()=>{$('map-label').textContent='Select a point or use the list index below.';});
cv.addEventListener('click',event=>{const p=nearest(event);if(p)choose(p.row);});
$('search').addEventListener('input',filter);$('tier').addEventListener('change',filter);
addEventListener('hashchange',fromHash);addEventListener('resize',draw);
filter();fromHash();
</script>
</body>
</html>
'''


if __name__ == "__main__":
    raise SystemExit(main())
