"""Run:  python3 check_data.py   (in the folder with the JSON files)
Checks that every NASA fact points to a NASA page and that game files do not hold NASA-looking data."""
import json, sys, re
from urllib.parse import urlparse
ok = True
def bad(m):
    global ok; ok = False; print("PROBLEM:", m)
src = {s["id"]: s for s in json.load(open("sources.json"))["sources"]}
nasa_hosts = ("nasa.gov",)
for s in src.values():
    h = urlparse(s["url"]).hostname or ""
    if not h.endswith(nasa_hosts): bad(f'{s["id"]} is not a nasa.gov host: {h}')
facts = json.load(open("nasa_data.json"))["facts"]
used = set()
for k, f in facts.items():
    if not f.get("source_ids"): bad(f"fact {k} has no source")
    for i in f.get("source_ids", []):
        used.add(i)
        if i not in src: bad(f"fact {k} cites unknown source {i}")
    if f.get("value") in (None, ""): bad(f"fact {k} has no value")
for name in ["sites","equipment","loads","levels","events","lessons","crew","radio","badges","game_constants"]:
    d = json.load(open(name + ".json"))
    if d["_meta"].get("data_class") != "GAME_VALUE": bad(f"{name}.json is not marked GAME_VALUE")
    txt = json.dumps(d)
    for m in re.findall(r'"nasa_fact_ids": ?(\{[^}]*\}|\[[^\]]*\])', txt):
        for fid in re.findall(r'"([a-z0-9_]+)"', m):
            if fid not in facts and fid not in ("lat","lon","elevation","air_temp_high","air_temp_low","radiation","ice_depth","ice_rank","temp_mean"): bad(f"{name}.json uses unknown fact id {fid}")
    if '"provenance": "measured"' in txt or '"provenance": "published"' in txt: bad(f"{name}.json claims measured/published data; move it to nasa_data.json")
for sid in src:
    if sid not in used and sid not in ("S19","S20","S21","S22","S24","S14","S23","S06"): print("note: source not used by a fact:", sid)
print("facts:", len(facts), "| sources:", len(src), "|", "ALL OK" if ok else "FIX THE PROBLEMS ABOVE")
sys.exit(0 if ok else 1)
