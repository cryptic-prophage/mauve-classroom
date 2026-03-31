#!/usr/bin/env python3
"""
Update each panel's alignment.xmfa:
  1. Strip #SequenceNFile paths to bare filenames (zip is flat — no subdirs)
  2. Inject #AnnotationNFile / #AnnotationNFormat headers before #BackboneFile
  3. Strip #BackboneFile path to bare filename

Usage:
  python fix_xmfa.py                       # process all 5 panels (uses hardcoded BASE)
  python fix_xmfa.py <panel_dir> [...]     # process one or more specific panel directories
                                            # e.g.  python fix_xmfa.py C:/path/saureus_mauve
"""
import os
import re
import sys


def process_xmfa(panel_dir):
    panel_dir = panel_dir.replace('/', os.sep).rstrip(os.sep)
    input_dir = os.path.join(panel_dir, "mauve_input")
    xmfa_path = os.path.join(panel_dir, "mauve_output", "alignment.xmfa")

    if not os.path.exists(xmfa_path):
        print(f"  SKIP: XMFA not found at {xmfa_path}")
        return

    print(f"  Panel: {os.path.basename(panel_dir)}")

    with open(xmfa_path, encoding="utf-8") as f:
        lines = f.readlines()

    anno_map = {}   # seq_num -> gff3 filename
    new_lines = []

    for line in lines:
        # Fix #SequenceNFile paths
        m = re.match(r'(#Sequence(\d+)File)\t(.*)', line.rstrip('\n'))
        if m:
            n = int(m.group(2))
            raw_path = m.group(3)
            fname = os.path.basename(raw_path.replace('\\', '/'))
            stem = fname[:-4] if fname.endswith('.fna') else fname
            gff = stem + '.gff3'
            if os.path.exists(os.path.join(input_dir, gff)):
                anno_map[n] = gff
            new_lines.append(f'#Sequence{n}File\t{fname}\n')
            continue

        # Drop stale annotation entries (will be rebuilt)
        if re.match(r'#Annotation\d+(File|Format)\t', line):
            continue

        # Fix #BackboneFile path
        if re.match(r'#BackboneFile\t', line):
            fname = os.path.basename(line.rstrip('\n').split('\t')[1].replace('\\', '/'))
            new_lines.append(f'#BackboneFile\t{fname}\n')
            continue

        new_lines.append(line)

    # Build annotation block in genome-number order
    anno_block = []
    for n in sorted(anno_map):
        anno_block.append(f'#Annotation{n}File\t{anno_map[n]}\n')
        anno_block.append(f'#Annotation{n}Format\tGFF3\n')

    # Insert before #BackboneFile
    insert_at = next(
        (i for i, l in enumerate(new_lines) if l.startswith('#BackboneFile')),
        len(new_lines)
    )
    final = new_lines[:insert_at] + anno_block + new_lines[insert_at:]

    with open(xmfa_path, 'w', encoding='utf-8') as f:
        f.writelines(final)

    print(f"  Injected {len(anno_block)} annotation lines for {len(anno_map)} genomes — paths stripped.")


# ── Entry point ──────────────────────────────────────────────────────────────
if len(sys.argv) > 1:
    # Called with explicit panel directory arguments (e.g. from run_panels.sh)
    for panel_dir in sys.argv[1:]:
        process_xmfa(panel_dir)
else:
    # Default: process all 5 panels using hardcoded base (manual / bulk use)
    BASE = r"C:\Users\japodaca15\projectsClaude\mauve-classroom"
    PANELS = ["saureus", "paeruginosa", "ecoli", "salmonella", "epidermidis"]
    print("Processing all panels...")
    for panel in PANELS:
        process_xmfa(os.path.join(BASE, f"{panel}_mauve"))

print("\nDone.")
