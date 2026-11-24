#!/usr/bin/env python3
"""
Génère un paquet REAPER (.ReaperPkg) par plug-in dans packages/.
Usage : python3 make_pkgs.py [PSEUDO_GITHUB] [NOM_DU_DEPOT] [BRANCHE]
Chaque paquet installe le plug-in au même endroit que ReaPack
(Effects/<dépôt>/<Catégorie>/), ses données éventuelles dans Data/<plugin>/,
et une fiche dans Docs/ReNo Mellow/ affichée par REAPER à l'installation.
"""
import os, re, sys, zipfile, glob
user = sys.argv[1] if len(sys.argv) > 1 else "renothestraws"
repo = sys.argv[2] if len(sys.argv) > 2 else "reno-mellow"
branch = sys.argv[3] if len(sys.argv) > 3 else "main"
CATS = ["Dynamics", "EQ", "Color", "Utility", "Instruments", "Reverb", "Amp", "Modulation", "MIDI"]
os.makedirs("packages", exist_ok=True)
for old in glob.glob("packages/*.ReaperPkg"): os.remove(old)
rows = []
def tag(s, k):
    m = re.search(r"^//@%s[ \t]+(.*)$" % k, s, re.M); return m.group(1).strip() if m else ""
for cat in CATS:
    for f in sorted(glob.glob(cat + "/*.jsfx")):
        name = os.path.basename(f)[:-5]
        s = open(f, encoding="utf-8").read()
        desc = re.search(r"^desc:(.*)$", s, re.M).group(1).strip()
        ver = tag(s, "version") or "1.0"
        info = "%s\nVersion %s\n\n%s\n\nNouveautés : %s\n\nInstallé dans Effects/%s/%s/ ; dans REAPER : navigateur d'effets, chercher « %s » (F5 pour rafraîchir).\nhttps://github.com/%s/%s\n" % (
            desc, ver, tag(s, "about"), tag(s, "changelog"), repo, cat, name, user, repo)
        doc = "Docs/ReNo Mellow/%s.txt" % name
        meta = 'NAME "%s - ReNo Mellow"\nAUTHOR "ReNo Mellow"\nVERSION "%s"\nURL "https://github.com/%s/%s"\nINFO "%s"\n' % (name, ver, user, repo, doc)
        rdir = os.path.join(cat, name + ".res")
        if os.path.isdir(rdir):   # ressources : chemins relatifs à la racine REAPER
            if os.path.isfile(os.path.join(rdir, "Data", "RMIRIndex", "index.txt")):
                meta += "NO_OVERWRITE Data/RMIRIndex/index.txt\n"
            for root_, _, files_ in os.walk(rdir):
                for fn_ in files_:
                    rp = os.path.relpath(os.path.join(root_, fn_), rdir).replace(os.sep, "/")
                    if rp.startswith("Scripts/") and (rp.endswith("_index.lua") or rp.endswith("_lib.lua")):
                        meta += "SCRIPT_NO_REG %s\n" % rp
        out = "packages/%s.ReaperPkg" % name
        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr("reaper-package-info.txt", meta)
            z.writestr(doc, info)
            z.write(f, "Effects/%s/%s/%s.jsfx" % (repo, cat, name))
            if os.path.isfile(f + ".rpl"):   # presets d'usine
                z.write(f + ".rpl", "Effects/%s/%s/%s.jsfx.rpl" % (repo, cat, name))
            ddir = os.path.join(cat, name)
            if os.path.isdir(ddir):
                for root, _, files in os.walk(ddir):
                    for fn in sorted(files):
                        p = os.path.join(root, fn)
                        z.write(p, "Data/%s/%s" % (name, os.path.relpath(p, ddir).replace(os.sep, "/")))
            if os.path.isdir(rdir):
                for root_, _, files_ in os.walk(rdir):
                    for fn_ in sorted(files_):
                        p = os.path.join(root_, fn_)
                        z.write(p, os.path.relpath(p, rdir).replace(os.sep, "/"))
        rows.append((cat, name, ver, out))
# paquets de scripts (dossier Scripts/<Nom>/) -> Scripts/ReNo_Mellow/<Nom>/ ; bibliothèques non enregistrées comme actions
for sd in sorted(d for d in glob.glob("Scripts/*") if os.path.isdir(d)):
    dn = os.path.basename(sd)
    luas = sorted(glob.glob(os.path.join(sd, "*.lua")))
    mainf = next((l for l in luas if re.search(r"^--\s*@version", open(l, encoding="utf-8").read(), re.M)), None)
    if not mainf:
        continue
    src = open(mainf, encoding="utf-8").read()
    def ltag(k):
        m = re.search(r"^--\s*@%s[ \t]+(.*)$" % k, src, re.M); return m.group(1).strip() if m else ""
    ver = ltag("version") or "1.0"
    title = os.path.basename(mainf)[:-4]
    if title.startswith("ReNo Mellow - "): title = title[len("ReNo Mellow - "):]
    doc = "Docs/ReNo Mellow/%s.txt" % title
    info = "%s\nVersion %s\n\n%s\n\nNouveautés : %s\n\nActions installées dans Scripts/ReNo_Mellow/%s/ (liste d'actions : chercher « %s »).\nhttps://github.com/%s/%s\n" % (
        ltag("description"), ver, ltag("about"), ltag("changelog"), dn, title, user, repo)
    meta = 'NAME "%s - ReNo Mellow"\nAUTHOR "ReNo Mellow"\nVERSION "%s"\nURL "https://github.com/%s/%s"\nINFO "%s"\n' % (title, ver, user, repo, doc)
    for l in luas:
        if not os.path.basename(l).startswith("ReNo Mellow - "):
            meta += "SCRIPT_NO_REG Scripts/ReNo_Mellow/%s/%s\n" % (dn, os.path.basename(l))
    out = "packages/%s.ReaperPkg" % title
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("reaper-package-info.txt", meta)
        z.writestr(doc, info)
        for l in luas:
            z.write(l, "Scripts/ReNo_Mellow/%s/%s" % (dn, os.path.basename(l)))
    rows.append(("Scripts", title, ver, out))
url = "https://github.com/%s/%s/raw/%s/" % (user, repo, branch)
with open("packages/LIENS.md", "w", encoding="utf-8") as fo:
    fo.write("# Téléchargement individuel (.ReaperPkg)\n\nGlisser le fichier dans la fenêtre de REAPER pour l'installer.\n\n| Catégorie | Plugin | Version | Lien |\n|---|---|---|---|\n")
    for cat, name, ver, out in rows:
        fo.write("| %s | %s | %s | [%s.ReaperPkg](%s%s) |\n" % (cat, name, ver, name, url, out.replace(" ", "%20")))
print("%d paquets dans packages/ ; liens dans packages/LIENS.md" % len(rows))
