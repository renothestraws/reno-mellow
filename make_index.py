#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Génère index.xml (dépôt ReaPack) pour les plugins ReNo Mellow.

Usage :   python3 make_index.py PSEUDO_GITHUB [NOM_DU_DEPOT] [BRANCHE]
Exemple : python3 make_index.py renomellow reno-mellow main

Le script lit chaque fichier Dynamics/, EQ/, Color/, Utility/ et Instruments/ (*.jsfx ; un dossier du même nom = fichiers Data) et récupère dans son en-tête :
  desc:        -> nom affiché dans ReaPack
  //@version   -> version (à augmenter à chaque mise à jour)
  //@author    -> auteur
  //@about     -> description (fenêtre "About" de ReaPack)
  //@changelog -> nouveautés de la version
Aucune installation n'est nécessaire (Python 3 seul).
"""
import os, re, sys, glob, datetime
from xml.sax.saxutils import escape, quoteattr

REPO_NAME = "ReNo Mellow"
CATEGORIES = ["Dynamics", "EQ", "Color", "Utility", "Instruments", "Reverb", "Amp", "Modulation", "MIDI"]          # un dossier = une catégorie ReaPack


def rtf(text):
    """Texte simple -> RTF minimal (ReaPack affiche le 'About' en RTF)."""
    out = []
    for ch in text:
        if ch in "\\{}":
            out.append("\\" + ch)
        elif ch == "\n":
            out.append("\\par\n")
        elif ord(ch) < 128:
            out.append(ch)
        else:
            out.append("\\u%d?" % (ord(ch) if ord(ch) < 32768 else ord(ch) - 65536))
    return "{\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 \\fswiss Helvetica;}}\\f0\\fs20 " + "".join(out) + "}"


def header(path):
    tags = {}
    with open(path, encoding="utf-8") as f:
        for i, line in enumerate(f):
            if i > 60:
                break
            m = re.match(r"\s*desc:\s*(.+)", line)
            if m and "desc" not in tags:
                tags["desc"] = m.group(1).strip()
            m = re.match(r"\s*//\s*@(\w+)\s+(.+)", line)
            if m:
                tags[m.group(1).lower()] = m.group(2).strip()
    for k in ("desc", "version", "author"):
        if k not in tags:
            sys.exit("%s : balise '%s' manquante" % (path, k))
    return tags


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    user = sys.argv[1]
    repo = sys.argv[2] if len(sys.argv) > 2 else "reno-mellow"
    branch = sys.argv[3] if len(sys.argv) > 3 else "main"
    raw = "https://raw.githubusercontent.com/%s/%s/%s/" % (user, repo, branch)
    site = "https://github.com/%s/%s" % (user, repo)
    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    root = os.path.dirname(os.path.abspath(__file__))

    x = ['<?xml version="1.0" encoding="utf-8"?>',
         '<index version="1" name=%s>' % quoteattr(REPO_NAME)]
    n = 0
    for cat in CATEGORIES:
        files = sorted(glob.glob(os.path.join(root, cat, "*.jsfx")))
        if not files:
            continue
        x.append('  <category name=%s>' % quoteattr(cat))
        for p in files:
            t = header(p)
            fn = os.path.basename(p)
            x.append('    <reapack name=%s type="effect" desc=%s>' % (quoteattr(fn), quoteattr(t["desc"])))
            if "about" in t:
                x.append('      <metadata>')
                x.append('        <description><![CDATA[%s]]></description>' % rtf(t["about"]))
                x.append('        <link rel="website" href=%s>GitHub</link>' % quoteattr(site))
                x.append('      </metadata>')
            x.append('      <version name=%s author=%s time=%s>' % (quoteattr(t["version"]), quoteattr(t["author"]), quoteattr(now)))
            if "changelog" in t:
                x.append('        <changelog><![CDATA[%s]]></changelog>' % t["changelog"])
            x.append('        <source>%s</source>' % escape(raw + cat + "/" + fn))
            # presets d'usine : <plugin>.jsfx.rpl à côté du plugin -> installé dans le même dossier
            if os.path.isfile(os.path.join(root, cat, fn + ".rpl")):
                x.append('        <source file=%s>%s</source>' % (quoteattr(fn + ".rpl"), escape(raw + cat + "/" + fn + ".rpl")))
            # fichiers de données (dossier du même nom que le plugin) -> REAPER/Data/<nom>/
            ddir = os.path.join(root, cat, fn[:-5])
            if os.path.isdir(ddir):
                for dp in sorted(glob.glob(os.path.join(ddir, "**", "*"), recursive=True)):
                    if not os.path.isfile(dp):
                        continue
                    dn = os.path.relpath(dp, ddir).replace(os.sep, "/")
                    x.append('        <source type="data" file=%s>%s</source>' % (quoteattr(fn[:-5] + "/" + dn), escape(raw + cat + "/" + fn[:-5] + "/" + dn)))
            # ressources installées ailleurs (dossier <nom>.res/ = racine des ressources REAPER) :
            #   Data/...    -> fichiers de données (REAPER/Data/...) ; Data/RMIRIndex/ exclu (index local, paquet .ReaperPkg seulement)
            #   Scripts/... -> scripts Lua (actions [main], sauf les bibliothèques *_index.lua / *_lib.lua)
            rdir = os.path.join(root, cat, fn[:-5] + ".res")
            if os.path.isdir(rdir):
                for dp in sorted(glob.glob(os.path.join(rdir, "**", "*"), recursive=True)):
                    if not os.path.isfile(dp):
                        continue
                    rel = os.path.relpath(dp, rdir).replace(os.sep, "/")
                    url = escape(raw + cat + "/" + fn[:-5] + ".res/" + rel).replace(" ", "%20")
                    if rel.startswith("Data/") and not rel.startswith("Data/RMIRIndex/"):
                        x.append('        <source type="data" file=%s>%s</source>' % (quoteattr(rel[5:]), url))
                    elif rel.startswith("Scripts/") and rel.endswith(".lua"):
                        sub = "/".join(rel.split("/")[-2:])
                        lib = rel.endswith("_index.lua") or rel.endswith("_lib.lua")
                        x.append('        <source type="script" file=%s%s>%s</source>' % (quoteattr(sub), "" if lib else ' main="main"', url))
            x.append('      </version>')
            x.append('    </reapack>')
            n += 1
        x.append('  </category>')
    # paquets de scripts Lua (dossier Scripts/<Nom>/) : le fichier qui porte « -- @version » donne l'en-tête ;
    # tous les .lua du dossier sont installés, actions [main] = fichiers « ReNo Mellow - … », les autres sont des bibliothèques
    sdirs = sorted(d for d in glob.glob(os.path.join(root, "Scripts", "*")) if os.path.isdir(d))
    if sdirs:
        x.append('  <category name="Scripts">')
        for sd in sdirs:
            luas = sorted(glob.glob(os.path.join(sd, "*.lua")))
            mainf, t = None, {}
            for lp in luas:
                src = open(lp, encoding="utf-8").read()
                if re.search(r"^--\s*@version", src, re.M):
                    mainf = lp
                    for k in ("description", "author", "version", "about", "changelog"):
                        m = re.search(r"^--\s*@%s[ \t]+(.*)$" % k, src, re.M)
                        if m: t[k] = m.group(1).strip()
                    break
            if not mainf:
                continue
            dn = os.path.basename(sd)
            x.append('    <reapack name=%s type="script" desc=%s>' % (quoteattr(os.path.basename(mainf)), quoteattr(t.get("description", dn))))
            if "about" in t:
                x.append('      <metadata>')
                x.append('        <description><![CDATA[%s]]></description>' % rtf(t["about"]))
                x.append('        <link rel="website" href=%s>GitHub</link>' % quoteattr(site))
                x.append('      </metadata>')
            x.append('      <version name=%s author=%s time=%s>' % (quoteattr(t.get("version", "1.0")), quoteattr(t.get("author", "ReNo Mellow")), quoteattr(now)))
            if "changelog" in t:
                x.append('        <changelog><![CDATA[%s]]></changelog>' % t["changelog"])
            for lp in luas:
                fn_ = os.path.basename(lp)
                lib = not fn_.startswith("ReNo Mellow - ")
                url = escape(raw + "Scripts/" + dn + "/" + fn_).replace(" ", "%20")
                x.append('        <source type="script" file=%s%s>%s</source>' % (quoteattr(dn + "/" + fn_), "" if lib else ' main="main"', url))
            x.append('      </version>')
            x.append('    </reapack>')
            n += 1
        x.append('  </category>')
    x.append('  <metadata>')
    x.append('    <description><![CDATA[%s]]></description>' % rtf(
        "ReNo Mellow : compresseurs, processeurs de dynamique, égaliseurs, couleur, utilitaires et instruments gratuits pour REAPER (JSFX).\n"
        "Calibration commune : 0 VU = +4 dBu = -18 dBFS."))
    x.append('    <link rel="website" href=%s>GitHub</link>' % quoteattr(site))
    x.append('  </metadata>')
    x.append('</index>')
    with open(os.path.join(root, "index.xml"), "w", encoding="utf-8") as f:
        f.write("\n".join(x) + "\n")
    print("index.xml : %d plugins, adresse du dépôt ReaPack :" % n)
    print("  " + raw + "index.xml")


if __name__ == "__main__":
    main()
