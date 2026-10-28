# python tests/clips_gif.py <out dir> <picks.tsv> [<picks.tsv> ...]
# Each clip's frames (frames/<name>_NNN.ppm, tests/clips.ps1) into one GIF (gifs/<name>.gif): the monster and its move named
# at the top, the time into it, "STRIKE" in red on the frames it struck the stand-in; then index.html - every monster, each of
# its moves' clips, to look through in a browser.
import sys, os, glob, html
from PIL import Image, ImageDraw

out = sys.argv[1]
frames_dir = os.path.join(out, "frames")
gif_dir = os.path.join(out, "gifs")
os.makedirs(gif_dir, exist_ok=True)
STEP = float(os.environ.get("CLIP_STEP_S", "0.0667"))
SIZE = int(os.environ.get("CLIP_SIZE", "360"))

rows = []
for tsv in sys.argv[2:]:
    group = os.path.basename(tsv).replace("picks_", "").replace(".tsv", "")
    for line in open(tsv, encoding="utf-8-sig"):
        p = line.rstrip("\n").split("\t")
        if len(p) < 8:
            continue
        log, prefab, move, t0, t1, x, z, strikes = p[:8]
        rows.append(dict(group=group, prefab=prefab, move=move, t0=float(t0), t1=float(t1),
                         strikes=[float(s) for s in strikes.split(";") if s]))

made = []
done_names = set()
for r in rows:
    name = f"{r['prefab']}__{r['move']}"
    # (one in both runs - the game's monster in the Tropical Experience run too: its frames are the later run's, made once)
    if name in done_names:
        continue
    done_names.add(name)
    files = sorted(glob.glob(os.path.join(frames_dir, name + "_*.ppm")))
    if not files:
        continue
    imgs = []
    for k, f in enumerate(files):
        t = r["t0"] + k * STEP
        im = Image.open(f).transpose(Image.FLIP_TOP_BOTTOM).convert("RGB").resize((SIZE, SIZE))
        d = ImageDraw.Draw(im)
        d.rectangle([0, 0, SIZE, 18], fill=(0, 0, 0))
        d.text((4, 3), f"{r['prefab']} - {r['move']}   {t - r['t0'] - .3:+.2f}s", fill=(255, 255, 255))
        if any(0 <= t - s < .2 for s in r["strikes"]):
            d.rectangle([0, SIZE - 22, SIZE, SIZE], fill=(170, 0, 0))
            d.text((4, SIZE - 18), "STRIKE (the bench's stand-in hit here)", fill=(255, 255, 255))
        imgs.append(im)
    gif = os.path.join(gif_dir, name + ".gif")
    imgs[0].save(gif, save_all=True, append_images=imgs[1:], duration=int(STEP * 1000), loop=0, optimize=True)
    made.append((r, os.path.relpath(gif, out)))

by = {}
for r, g in made:
    by.setdefault(r["prefab"], []).append((r, g))
parts = ["<!doctype html><meta charset='utf-8'><title>True Range clips</title>",
         "<style>body{font-family:sans-serif;background:#222;color:#ddd;margin:16px}h2{margin:24px 0 6px;border-bottom:1px solid #555}"
         ".c{display:inline-block;margin:4px;vertical-align:top;text-align:center;font-size:12px}img{width:360px;height:360px;display:block}"
         "nav a{color:#9cf;margin-right:8px;font-size:13px}</style>",
         "<h1>True Range - each monster's moves as drawn</h1>",
         "<p>From the bench runs (the game's own server): white ring = the monster (line = which way it faces), blue ring = the "
         "stand-in for you, coloured areas = what True Range draws (its moves, the things it sets down - spikes, puddles - and "
         "the rings round some monsters). Pale = may strike, yellow = coming, red = striking now. Red bar at the bottom = the "
         "stand-in really got hit then. The bench's stand-in stands still near it: a move drawn far off it but never struck "
         "is not proof the drawing is wrong.</p><nav>"]
for prefab in sorted(by):
    parts.append(f"<a href='#{html.escape(prefab)}'>{html.escape(prefab)}</a>")
parts.append("</nav>")
for prefab in sorted(by):
    parts.append(f"<h2 id='{html.escape(prefab)}'>{html.escape(prefab)}</h2>")
    for r, g in sorted(by[prefab], key=lambda x: x[0]["move"]):
        hit = "hit" if r["strikes"] else "no hit in this clip"
        parts.append(f"<div class='c'><img loading='lazy' src='{html.escape(g)}'>{html.escape(r['move'])} ({hit})</div>")
open(os.path.join(out, "index.html"), "w", encoding="utf-8").write("\n".join(parts))
print(f"{len(made)} clips, {len(by)} monsters -> {os.path.join(out, 'index.html')}")
