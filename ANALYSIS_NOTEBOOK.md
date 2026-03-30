# Mauve Classroom Alignments — Analysis Notebook
**Cryptic Prophage Lab, University of Texas at El Paso**
**Date:** 2026-03-30
**Analyst:** J. Apodaca

---

## Purpose

Five multi-genome Mauve alignments prepared for use in the undergraduate microbiology laboratory. Each panel targets a different pathogen group and is designed to illustrate distinct concepts in comparative microbial genomics: genomic rearrangements, virulence gene acquisition, horizontal gene transfer, host adaptation, and niche specialization.

---

## Environment

| Tool | Version | Source |
|------|---------|--------|
| NCBI datasets CLI | 18.21.0 | `mauve-master/datasets.exe` (Windows) |
| progressiveMauve | 2022-08-13 build | WSL: `~/miniconda3/envs/mauve/bin/progressiveMauve` |
| WSL | 2.6.3.0 | Ubuntu 24.04.4 LTS |
| Script | `run_panels.sh` | `mauve-classroom/` |

**Note on aligner:** The Windows progressiveMauve binary bundled in `mauve-master/win64/` has a bug where `--output` does not write the XMFA file (alignment stage silently fails). All alignments were run via WSL using the bioconda `mauvealigner` build (2022), which resolves the issue.

---

## Panel 1 — *Staphylococcus aureus*

**Directory:** `saureus_mauve/`
**Output:** `mauve_output/alignment.xmfa` (25 MB)

### Strains

| Label | Strain | Phenotype | Accession |
|-------|--------|-----------|-----------|
| Saureus_USA300_FPR3757_CA-MRSA | USA300 | CA-MRSA, PVL+ | GCF_000013465.1 |
| Saureus_MRSA252_HA-MRSA | MRSA252 | HA-MRSA | GCF_000011505.1 |
| Saureus_MSSA476_MSSA | MSSA476 | MSSA | GCF_000011525.1 |
| Saureus_Mu50_VISA | Mu50 | VISA/VRSA | GCF_000009665.1 |
| Saureus_MW2_USA400 | MW2 | USA400, PVL+ | GCF_000011265.1 |
| Sepidermidis_RP62A_outgroup | RP62A | Outgroup | GCF_000011925.1 |

### Teaching Points
- LCB conservation shows the conserved core genome shared across all MRSA/MSSA strains
- Unique blocks in USA300 and MW2 mark the pathogenicity islands carrying PVL (*lukS/lukF*)
- Mu50 rearrangements reflect genome plasticity associated with vancomycin resistance
- S. epidermidis outgroup makes cross-species conservation immediately visible

### Accession Corrections Made
> Original script had GCF_000011065.1 (→ *Bacteroides thetaiotaomicron*), GCF_000011465.1 (→ *Prochlorococcus*), and GCF_000011825.1 (→ *Thermosynechococcus*) for MW2, MSSA476, and Mu50 respectively. Correct accessions verified against NCBI organism names before download.

---

## Panel 2 — *Pseudomonas aeruginosa*

**Directory:** `paeruginosa_mauve/`
**Output:** `mauve_output/alignment.xmfa` (53 MB)

### Strains

| Label | Strain | Phenotype | Accession |
|-------|--------|-----------|-----------|
| Paeruginosa_PAO1_reference | PAO1 | Lab reference | GCF_000006765.1 |
| Paeruginosa_PA14_hypervirulent | PA14 | Hypervirulent | GCF_000014625.1 |
| Paeruginosa_PAK_CF | PAK | CF clinical | GCF_000408865.1 |
| Paeruginosa_LESB58_epidemic | LESB58 | CF epidemic clone | GCF_000026645.1 |
| Paeruginosa_DK2_evolved | DK2 | Chronic CF adapted | GCF_000271365.1 |
| Pputida_KT2440_outgroup | KT2440 | Outgroup | GCF_000007565.2 |

### Teaching Points
- P. aeruginosa has one of the largest accessory genomes of any pathogen; the XMFA makes this immediately visible
- LESB58 and DK2 show extensive genomic reduction relative to PAO1/PA14 — classic chronic-infection adaptation
- PAK blocks highlight CF-specific virulence loci
- P. putida outgroup shows how much core genome is truly conserved across the *Pseudomonas* genus

### Accession Corrections Made
> GCF_000237865.1 mapped to *Haloquadratum walsbyi* (halophilic archaea); replaced with GCF_000408865.1 (PAK). GCF_000283715.1 mapped to *Shigella sonnei*; replaced with GCF_000271365.1 (DK2).

---

## Panel 3 — *Escherichia coli*

**Directory:** `ecoli_mauve/`
**Output:** `mauve_output/alignment.xmfa` (35 MB)

### Strains

| Label | Strain | Pathotype | Accession |
|-------|--------|-----------|-----------|
| Ecoli_O157H7_EDL933_STEC | EDL933 | STEC O157:H7 | GCF_000732965.1 |
| Ecoli_O157H7_EC4115_spinach | EC4115 | STEC, spinach outbreak | GCF_000021125.1 |
| Ecoli_K12_MG1655_lab | MG1655 | Lab K-12 | GCF_000005845.2 |
| Ecoli_CFT073_UPEC | CFT073 | UPEC | GCF_000007445.1 |
| Ecoli_E2348_EPEC | E2348/69 | EPEC | GCF_000026545.1 |

### Teaching Points
- EDL933 vs. K-12 MG1655: the "O-islands" (Shiga toxin, intimin, T3SS) are visible as unique colored LCBs absent in the commensal strain
- EC4115 vs. EDL933: near-identical STEC strains; fine-scale rearrangements and phage insertions between outbreak strains
- CFT073 and E2348 show pathotype-specific islands (PAI I-IV, LEE) in genomic context
- This panel uses EDL933, a genome J. Apodaca contributed to sequencing

### Panel Note
> *S.* Typhimurium Sakai removed at PI request; EDL933 preferred as the primary O157:H7 representative.

---

## Panel 4 — *Salmonella enterica*

**Directory:** `salmonella_mauve/`
**Output:** `mauve_output/alignment.xmfa` (40 MB)

### Strains

| Label | Strain | Serovar / Host range | Accession |
|-------|--------|----------------------|-----------|
| Salm_Typhimurium_LT2 | LT2 | Typhimurium, broad | GCF_000006945.2 |
| Salm_Typhimurium_14028s_virulent | 14028S | Typhimurium, virulent | GCF_000022165.1 |
| Salm_Enteritidis_PT4_P125109 | P125109 | Enteritidis | GCF_000009505.1 |
| Salm_Typhi_CT18 | CT18 | Typhi, human-restricted | GCF_000195995.1 |
| Salm_Typhi_Ty2 | Ty2 | Typhi, vaccine strain | GCF_000007545.1 |
| Salm_Dublin_CT02021853_host-restricted | CT_02021853 | Dublin, cattle-adapted | GCF_000020925.1 |
| Salm_Paratyphi_A_ATCC9150 | ATCC 9150 | Paratyphi A, human | GCF_000011885.1 |

### Teaching Points
- SPI-1 and SPI-2 pathogenicity islands visible as conserved blocks across all serovars
- Typhi CT18 vs. Typhimurium LT2: genomic degradation (pseudogenes, rearrangements) associated with human host restriction
- Dublin shows cattle-specific accessory genome compared to broad-host Typhimurium
- Ty2 vs. CT18: minimal variation between the wild-type and vaccine strain

### Accession Corrections Made
> GCF_000009605.1 mapped to *Buchnera aphidicola* APS (aphid endosymbiont). Salmonella Gallinarum 287/9 is not deposited in NCBI RefSeq (EMBL-only, AM933173). Substituted *S.* Dublin CT_02021853 (GCF_000020925.1), a complete genome representing the cattle-adapted clade — equivalent pedagogical value for teaching host restriction.

---

## Panel 5 — *Staphylococcus epidermidis*

**Directory:** `epidermidis_mauve/`
**Output:** `mauve_output/alignment.xmfa` (20 MB)

### Strains

| Label | Strain | Phenotype | Accession |
|-------|--------|-----------|-----------|
| Sepidermidis_ATCC12228_commensal | ATCC 12228 | Commensal, non-biofilm | GCA_000007645.1 |
| Sepidermidis_RP62A_biofilm | RP62A | Biofilm-forming, clinical | GCF_000011925.1 |
| Sepidermidis_1457_clinical | 1457 | Clinical, biofilm | GCF_000705075.1 |
| Saureus_MSSA476_outgroup | MSSA476 | Outgroup | GCF_000011525.1 |
| Saureus_USA300_outgroup | USA300 | Outgroup | GCF_000013465.1 |

### Teaching Points
- ATCC 12228 (commensal) vs. RP62A/1457 (clinical): loss of biofilm genes (*ica* locus) in the non-pathogenic strain
- The S. aureus outgroup pair makes it immediately clear which LCBs are shared across the genus vs. species-specific
- Demonstrates that opportunistic pathogens diverge from commensals through acquisition — not just mutation — of virulence loci

### Note on GCA Accession
> ATCC 12228 is deposited as GCA_000007645.1 (GenBank). Downloaded with `--assembly-source all` flag to ensure retrieval.

---

## Alignment Parameters

```
progressiveMauve \
  --seed-weight=15 \
  --output=<panel>/mauve_output/alignment.xmfa \
  --output-guide-tree=<panel>/mauve_output/guide.tree \
  <genomes sorted alphabetically>
```

Default scoring applied (no manual penalty override). Backbone detection enabled.

---

## Loading in Mauve GUI

1. **File → Open** → navigate to `<panel>_mauve/mauve_output/alignment.xmfa`
2. Right-click any genome track → **Add Sequence Feature Track** → load matching `.gff3` from `<panel>_mauve/mauve_input/`
3. Use **View → Show Backbone** to highlight core genome blocks

---

## Known Issues / Decisions

| Item | Decision |
|------|----------|
| Windows progressiveMauve (`win64/`) has broken `--output` flag | Run via WSL `~/miniconda3/envs/mauve/bin/progressiveMauve` |
| Salmonella Gallinarum 287/9 not in NCBI RefSeq | Replaced with *S.* Dublin CT_02021853 |
| 7 original script accessions mapped to wrong organisms | All corrected and verified via `datasets summary genome accession` |
| Sakai removed from E. coli panel | PI preference; EDL933 retained as primary O157:H7 |
