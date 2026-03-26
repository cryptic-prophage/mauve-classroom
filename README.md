# Mauve Genome Alignment Viewer — Classroom Edition

> A modernized desktop application for visualizing and comparing microbial genome alignments,
> built for use in bioinformatics coursework.

---

## What is Mauve?

Mauve is a genome alignment visualization tool originally developed at the University of
Wisconsin–Madison. It aligns multiple genome sequences and displays conserved regions —
called **Locally Collinear Blocks (LCBs)** — as colored ribbons across genomes, making it
easy to see rearrangements, insertions, deletions, and conserved gene order at a glance.

This classroom edition packages Mauve as a self-contained desktop installer for all major
platforms — no manual Java setup or command-line experience required.

---

## Downloads

Go to the **[Releases page](../../releases/latest)** to download the installer for your platform.

| Platform | File to download | Notes |
|----------|-----------------|-------|
| **Windows 10 / 11** | `Mauve-windows.zip` | Extract the zip, then run `Mauve\Mauve.exe` |
| **macOS — Apple Silicon** (M1/M2/M3 · 2020 and later) | `Mauve-X.X.X-AppleSilicon.dmg` | Right-click → Open on first launch |
| **macOS — Intel** (pre-2020) | `Mauve-X.X.X-Intel.dmg` | Right-click → Open on first launch |
| **Linux (Debian / Ubuntu)** | `mauve_X.X.X_amd64.deb` | `sudo dpkg -i mauve_*.deb` |
| **Linux (Universal)** | `Mauve-X.X.X-linux.tar.gz` | Extract and run `Mauve/bin/Mauve` |

> **Not sure which Mac you have?**
> Apple menu → **About This Mac**
> - "Chip" shows **Apple M1 / M2 / M3** → download **AppleSilicon**
> - "Processor" shows **Intel** → download **Intel**

---

## Sample Data

Pre-aligned genome datasets are provided as separate downloads on the Releases page.
Each zip contains:
- `.xmfa` — the Mauve alignment file (open this in the app)
- `.fasta` — the genome sequences
- `.gff3` — gene annotations
- `QUICKSTART.md` — step-by-step instructions for that dataset

**To use:** download a dataset zip, extract it, and open the `.xmfa` file in Mauve.
Keep all files from the zip in the same folder.

---

## What We Built

Starting from the original Mauve source code, this release modernizes the application
for contemporary classroom use:

- **Native installers** for Windows, macOS (Apple Silicon + Intel), and Linux —
  students double-click to install, no terminal required
- **Modern UI** — FlatLaf dark theme with HiDPI / Retina display support
- **Right-click LCB extraction** — select any alignment block and export FASTA sequences
  and GFF3 annotations with configurable upstream/downstream flanking regions
- **Core / Shell / Cloud color coding** — blocks colored by conservation level across genomes
  (blue = core → teal → amber → red = unique)
- **GC% deviation track** — sliding-window GC% visualized relative to genome mean
- **Bundled aligner binaries** — progressiveMauve and mauveAligner included for all platforms
- **Sample datasets** — pre-aligned comparisons ready to explore on day one

---

## System Requirements

| Platform | Minimum |
|----------|---------|
| Windows | Windows 10 or later (64-bit) |
| macOS | macOS 11 (Big Sur) or later |
| Linux | Ubuntu 20.04 / Debian 11 or equivalent |
| RAM | 4 GB recommended (8 GB for large alignments) |

Java is **bundled** — you do not need to install it separately.

---

## First Launch — macOS Note

macOS will show a security warning the first time you open the app because it is not
distributed through the App Store. To bypass this:

1. Right-click (or Control-click) the app icon
2. Select **Open** from the menu
3. Click **Open** in the dialog that appears

You only need to do this once.

---

## About

Mauve was originally developed by the **Darling Lab** at the University of Wisconsin–Madison.
This classroom edition was built and maintained by the **Cryptic Prophage Lab** for use in
microbial genomics coursework.

Original Mauve paper:
> Darling, A.E., Mau, B., Perna, N.T. (2010). progressiveMauve: Multiple Genome Alignment
> with Gene Gain, Loss, and Rearrangement. *PLOS ONE*, 5(6), e11147.
> https://doi.org/10.1371/journal.pone.0011147
