#!/usr/bin/env bash
# ============================================================
# PATHOGENIC MICRO LAB — GENOME DOWNLOAD + MAUVE ALIGNMENT
# J. Apodaca | Undergraduate Microbiology Laboratory
# Cryptic Prophage Lab, University of Texas at El Paso
# ============================================================
#
# PIPELINE OVERVIEW (per panel):
#   1. download_panel  — fetch genome + GFF3 + protein from NCBI
#                        via `datasets`, unzip, copy to mauve_input/
#                        Prepend readable label to FIRST FASTA header only
#                        (subsequent plasmid/contig headers left as-is)
#   2. run_mauve       — align all .fna files in mauve_input/ using
#                        progressiveMauve (WSL bioconda 2022 binary)
#                        Produces alignment.xmfa + backbone files
#   3. post_process    — fix the XMFA for portable distribution:
#                          a) strip absolute #SequenceNFile paths → bare filenames
#                          b) inject #AnnotationNFile/#AnnotationNFormat entries
#                             so Mauve auto-loads GFF3 on open (no manual loading)
#                          c) strip #BackboneFile path → bare filename
#
# NOTE: post_process calls fix_xmfa.py via PowerShell (gh auth + python live
#       in the Windows credential store / PATH, not the Git Bash POSIX layer).
#
# Usage:
#   bash run_panels.sh              # all 5 panels
#   bash run_panels.sh saureus
#   bash run_panels.sh pseudomonas
#   bash run_panels.sh ecoli
#   bash run_panels.sh salmonella
#   bash run_panels.sh epidermidis
# ============================================================

set -e

# ─── Tool paths ──────────────────────────────────────────────
# datasets CLI: bundled with mauve-master
MAUVE_TOOLS="/c/Users/japodaca15/projectsClaude/mauve-master"
export PATH="${MAUVE_TOOLS}:${PATH}"

# progressiveMauve: run via WSL (Windows binary has a broken --output flag;
#   WSL bioconda 2022 build is stable. Base conda env has boost ABI conflict —
#   use the dedicated 'mauve' env by hardcoding the full binary path.)
PMAUVE_WSL="/home/japodaca15/miniconda3/envs/mauve/bin/progressiveMauve"

# fix_xmfa.py: post-alignment XMFA cleanup script (same directory as this script)
SCRIPT_DIR="/c/Users/japodaca15/projectsClaude/mauve-classroom"
FIX_XMFA_PY="${SCRIPT_DIR}/fix_xmfa.py"

PANEL="${1:-all}"

# ─── Helper: download one panel ─────────────────────────────
download_panel() {
  local ORG_DIR="$1"
  shift
  local -n STRAINS_REF="$1"

  mkdir -p "${ORG_DIR}/mauve_input"
  echo ""
  echo "======================================"
  echo " Downloading: $ORG_DIR"
  echo "======================================"

  for GCF in "${!STRAINS_REF[@]}"; do
    LABEL="${STRAINS_REF[$GCF]}"
    echo ""
    echo "  --> $LABEL  ($GCF)"

    if [ -f "${ORG_DIR}/mauve_input/${LABEL}.fna" ]; then
      echo "      Already exists — skipping."
      continue
    fi

    datasets download genome accession "$GCF" \
      --include genome,gff3,protein \
      --assembly-source all \
      --filename "${ORG_DIR}/${LABEL}.zip"

    # unzip exits 1 on harmless warnings — guard against set -e
    unzip -o "${ORG_DIR}/${LABEL}.zip" -d "${ORG_DIR}/${LABEL}_dir" >/dev/null || true

    FASTA=$(find "${ORG_DIR}/${LABEL}_dir" -name '*.fna' | head -1)
    GFF=$(find   "${ORG_DIR}/${LABEL}_dir" -name '*.gff' | head -1)
    FAA=$(find   "${ORG_DIR}/${LABEL}_dir" -name '*.faa' | head -1)

    if [ -n "$FASTA" ]; then
      cp "$FASTA" "${ORG_DIR}/mauve_input/${LABEL}.fna"
      # Prepend readable label to the FIRST sequence header only.
      # Subsequent headers (plasmids, contigs) keep their original NCBI
      # accession as the first token so GFF3 col-1 matching works in Mauve.
      # (sed "s/^>//" would wrongly relabel ALL sequences in multi-seq files.)
      awk -v lbl="${LABEL}" \
        '/^>/ && !done { sub(/^>/, ">" lbl " "); done=1 } { print }' \
        "${ORG_DIR}/mauve_input/${LABEL}.fna" \
        > "${ORG_DIR}/mauve_input/${LABEL}.fna.tmp" \
        && mv "${ORG_DIR}/mauve_input/${LABEL}.fna.tmp" "${ORG_DIR}/mauve_input/${LABEL}.fna"
    else
      echo "      WARNING: no .fna found for $GCF — check accession or try efetch fallback"
    fi
    [ -n "$GFF" ] && cp "$GFF" "${ORG_DIR}/mauve_input/${LABEL}.gff3"
    [ -n "$FAA" ] && cp "$FAA" "${ORG_DIR}/mauve_input/${LABEL}.faa"

    # Clean up zip and extracted dir to save space
    rm -rf "${ORG_DIR}/${LABEL}.zip" "${ORG_DIR}/${LABEL}_dir"

    echo "      Saved: ${LABEL}.fna | .gff3 | .faa"
  done

  echo ""
  echo "  Done: $ORG_DIR/mauve_input/"
}

# ─── Run Mauve on a panel ────────────────────────────────────
run_mauve() {
  local ORG_DIR="$1"
  local MAUVE_OUT="${ORG_DIR}/mauve_output"
  mkdir -p "$MAUVE_OUT"

  GENOMES=($(ls "${ORG_DIR}/mauve_input/"*.fna 2>/dev/null | sort))
  if [ ${#GENOMES[@]} -eq 0 ]; then
    echo "  No .fna files found in ${ORG_DIR}/mauve_input/ — skipping Mauve."
    return
  fi

  echo ""
  echo "  Running progressiveMauve via WSL: ${#GENOMES[@]} genomes..."

  # Convert Git Bash C:/... paths to WSL /mnt/c/... for the Linux binary
  WSL_OUT=$(echo "${MAUVE_OUT}/alignment.xmfa" | sed 's|^C:/|/mnt/c/|; s|^/c/|/mnt/c/|')
  WSL_TREE=$(echo "${MAUVE_OUT}/guide.tree"    | sed 's|^C:/|/mnt/c/|; s|^/c/|/mnt/c/|')
  WSL_GENOME_ARGS=""
  for g in "${GENOMES[@]}"; do
    wg=$(echo "$g" | sed 's|^C:/|/mnt/c/|; s|^/c/|/mnt/c/|')
    WSL_GENOME_ARGS="${WSL_GENOME_ARGS} ${wg}"
  done

  wsl.exe bash -c "${PMAUVE_WSL} --output='${WSL_OUT}' --output-guide-tree='${WSL_TREE}' --seed-weight=15 ${WSL_GENOME_ARGS}"

  echo ""
  echo "  Mauve done! Output: ${MAUVE_OUT}/alignment.xmfa"
  echo "  Open in Mauve GUI: File > Open > ${MAUVE_OUT}/alignment.xmfa"
  echo "  Then add GFF3 tracks: right-click each genome > Add Sequence Feature Track"
  echo "  Load matching .gff3 from ${ORG_DIR}/mauve_input/"
}

# ─── Post-process XMFA after alignment ──────────────────────
# Fixes three portability problems that progressiveMauve leaves behind:
#   1. #SequenceNFile has absolute build-machine paths  → stripped to bare filenames
#   2. No #AnnotationNFile entries written by aligner   → injected from mauve_input/*.gff3
#   3. #BackboneFile has stale subdirectory path        → stripped to bare filename
#
# After this step the XMFA is self-contained: open it in Mauve from any directory
# where the .fna, .gff3, and .xmfa* files are co-located (as in the student zip).
#
# Implementation note: called via powershell.exe because Python and gh credentials
# live in the Windows PATH/keyring, which is not visible to Git Bash's POSIX layer.
post_process() {
  local ORG_DIR="$1"
  local ABS_PANEL="${SCRIPT_DIR}/${ORG_DIR}"

  # Convert Git Bash /c/... path to Windows C:/... for PowerShell
  local WIN_PANEL WIN_SCRIPT
  WIN_PANEL=$(echo "$ABS_PANEL"   | sed 's|^/c/|C:/|')
  WIN_SCRIPT=$(echo "$FIX_XMFA_PY" | sed 's|^/c/|C:/|')

  echo ""
  echo "  Post-processing XMFA for $ORG_DIR ..."
  powershell.exe -Command "python '$WIN_SCRIPT' '$WIN_PANEL'"
}

# ─── PANELS ──────────────────────────────────────────────────

# S. aureus panel (5 strains + S. epidermidis outgroup)
declare -A SA_STRAINS=(
  ["GCF_000013465.1"]="Saureus_USA300_FPR3757_CA-MRSA"
  ["GCF_000011505.1"]="Saureus_MRSA252_HA-MRSA"
  ["GCF_000011525.1"]="Saureus_MSSA476_MSSA"
  ["GCF_000009665.1"]="Saureus_Mu50_VISA"
  ["GCF_000011265.1"]="Saureus_MW2_USA400"
  ["GCF_000011925.1"]="Sepidermidis_RP62A_outgroup"
)

# P. aeruginosa panel (5 strains + P. putida outgroup)
declare -A PA_STRAINS=(
  ["GCF_000006765.1"]="Paeruginosa_PAO1_reference"
  ["GCF_000014625.1"]="Paeruginosa_PA14_hypervirulent"
  ["GCF_000408865.1"]="Paeruginosa_PAK_CF"
  ["GCF_000026645.1"]="Paeruginosa_LESB58_epidemic"
  ["GCF_000271365.1"]="Paeruginosa_DK2_evolved"
  ["GCF_000007565.2"]="Pputida_KT2440_outgroup"
)

# E. coli panel (4 pathotypes + K-12 reference; EDL933 preferred over Sakai)
declare -A EC_STRAINS=(
  ["GCF_000732965.1"]="Ecoli_O157H7_EDL933_STEC"
  ["GCF_000021125.1"]="Ecoli_O157H7_EC4115_spinach"
  ["GCF_000005845.2"]="Ecoli_K12_MG1655_lab"
  ["GCF_000007445.1"]="Ecoli_CFT073_UPEC"
  ["GCF_000026545.1"]="Ecoli_E2348_EPEC"
)

# Salmonella panel (7 strains, 5+ serovars; Gallinarum 287/9 not in NCBI RefSeq — using Dublin as host-restricted substitute)
declare -A SAL_STRAINS=(
  ["GCF_000006945.2"]="Salm_Typhimurium_LT2"
  ["GCF_000022165.1"]="Salm_Typhimurium_14028s_virulent"
  ["GCF_000009505.1"]="Salm_Enteritidis_PT4_P125109"
  ["GCF_000195995.1"]="Salm_Typhi_CT18"
  ["GCF_000007545.1"]="Salm_Typhi_Ty2"
  ["GCF_000020925.1"]="Salm_Dublin_CT02021853_host-restricted"
  ["GCF_000011885.1"]="Salm_Paratyphi_A_ATCC9150"
)

# S. epidermidis panel (3 strains + 2 S. aureus outgroups)
declare -A SE_STRAINS=(
  ["GCA_000007645.1"]="Sepidermidis_ATCC12228_commensal"
  ["GCF_000011925.1"]="Sepidermidis_RP62A_biofilm"
  ["GCF_000705075.1"]="Sepidermidis_1457_clinical"
  ["GCF_000011525.1"]="Saureus_MSSA476_outgroup"
  ["GCF_000013465.1"]="Saureus_USA300_outgroup"
)

# ─── Run based on argument ───────────────────────────────────
case "$PANEL" in
  saureus)
    download_panel "saureus_mauve" SA_STRAINS
    run_mauve      "saureus_mauve"
    post_process   "saureus_mauve"
    ;;
  pseudomonas)
    download_panel "paeruginosa_mauve" PA_STRAINS
    run_mauve      "paeruginosa_mauve"
    post_process   "paeruginosa_mauve"
    ;;
  ecoli)
    download_panel "ecoli_mauve" EC_STRAINS
    run_mauve      "ecoli_mauve"
    post_process   "ecoli_mauve"
    ;;
  salmonella)
    download_panel "salmonella_mauve" SAL_STRAINS
    run_mauve      "salmonella_mauve"
    post_process   "salmonella_mauve"
    ;;
  epidermidis)
    download_panel "epidermidis_mauve" SE_STRAINS
    run_mauve      "epidermidis_mauve"
    post_process   "epidermidis_mauve"
    ;;
  all)
    download_panel "saureus_mauve"     SA_STRAINS
    run_mauve      "saureus_mauve"
    post_process   "saureus_mauve"
    download_panel "paeruginosa_mauve" PA_STRAINS
    run_mauve      "paeruginosa_mauve"
    post_process   "paeruginosa_mauve"
    download_panel "ecoli_mauve"       EC_STRAINS
    run_mauve      "ecoli_mauve"
    post_process   "ecoli_mauve"
    download_panel "salmonella_mauve"  SAL_STRAINS
    run_mauve      "salmonella_mauve"
    post_process   "salmonella_mauve"
    download_panel "epidermidis_mauve" SE_STRAINS
    run_mauve      "epidermidis_mauve"
    post_process   "epidermidis_mauve"
    ;;
  *)
    echo "Unknown panel: $PANEL"
    echo "Usage: bash $0 [saureus|pseudomonas|ecoli|salmonella|epidermidis|all]"
    exit 1
    ;;
esac

echo ""
echo "========================================================"
echo " Pipeline complete."
echo ""
echo " For each panel the following steps ran:"
echo "   1. download_panel  — genomes fetched from NCBI, FASTA"
echo "                        headers labelled (first seq only)"
echo "   2. run_mauve       — progressiveMauve alignment via WSL"
echo "   3. post_process    — XMFA paths stripped + annotation"
echo "                        headers injected (fix_xmfa.py)"
echo ""
echo " Alignment files ready:"
echo "   saureus_mauve/mauve_output/alignment.xmfa"
echo "   paeruginosa_mauve/mauve_output/alignment.xmfa"
echo "   ecoli_mauve/mauve_output/alignment.xmfa"
echo "   salmonella_mauve/mauve_output/alignment.xmfa"
echo "   epidermidis_mauve/mauve_output/alignment.xmfa"
echo ""
echo " In Mauve GUI:"
echo "   File > Open > <org>_mauve/mauve_output/alignment.xmfa"
echo "   Annotation tracks load automatically — no manual .gff3"
echo "   loading required."
echo ""
echo " To package for distribution:"
echo "   powershell.exe -ExecutionPolicy Bypass -File make_zips.ps1"
echo "   powershell.exe -ExecutionPolicy Bypass -File upload_zips.ps1"
echo "========================================================"
