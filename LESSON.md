# Comparative Genomics with Mauve — Undergraduate Microbiology Lab

**Course context:** Microbial Genomics / Introductory Microbiology
**Format:** Computer lab, ~2 hours
**Tool:** [Mauve](http://darlinglab.org/mauve/) (progressiveMauve, free download)
**Prepared by:** Cryptic Prophage Lab, UTEP

---

## Learning Objectives

By the end of this lab, students will be able to:

1. Open a pre-computed whole-genome alignment in Mauve and interpret the color-coded block display
2. Distinguish core genome (conserved LCBs) from accessory genome (unique or rearranged blocks)
3. Identify genomic signatures of pathogenicity — pathogenicity islands, toxin loci, resistance cassettes — using GFF3 annotation tracks
4. Explain how genomic rearrangement, insertion, and deletion relate to niche adaptation and host range
5. Interpret an outgroup genome to define genus-level conservation vs. species-specific content

---

## Background

### What is Mauve doing?
Mauve uses **progressiveMauve**, a multiple whole-genome aligner that identifies conserved regions (locally collinear blocks, LCBs) shared across all input genomes. Each colored block represents a segment that is:
- **Present in that strain** (colored = present, white gap = absent)
- **In a consistent orientation** (block above the center line = same strand as reference; below = inverted)
- **At a conserved chromosomal position relative to other blocks of the same color**

### Reading the display
| Display element | Meaning |
|----------------|---------|
| Tall colored blocks spanning all genomes | Core genome — conserved across all strains |
| Colored block present in only some genomes | Accessory genome — horizontally transferred or deleted |
| Block below the center line | Chromosomal inversion relative to reference |
| White/empty space | Sequence unique to that genome OR a deletion |
| Annotation track (thin colored bar below sequence) | Gene features from GFF3 (CDS, rRNA, tRNA, etc.) |

### The core / accessory genome concept
Bacterial genomes consist of:
- **Core genome** — genes in every strain of a species; essential housekeeping functions
- **Accessory (pan-genome)** — genes present in some but not all strains; often mobile elements, virulence factors, resistance genes
- **Unique genome** — genes found in only one strain

Mauve makes this visible at the whole-genome scale in a single view.

---

## Datasets

Six alignment panels are available as independent lab exercises. Each zip contains the pre-computed alignment and all input genome + annotation files. Students can work through any one panel in a 2-hour lab; all six can be assigned across lab sections or used progressively throughout a course.

### Panel 1 — *Staphylococcus aureus*: Antibiotic Resistance and Virulence
**Theme:** How do community MRSA, hospital MRSA, and vancomycin-intermediate strains compare genomically?

| Strain | Key feature |
|--------|------------|
| USA300 FPR3757 | Community-acquired MRSA (CA-MRSA), PVL+ |
| MRSA252 | Hospital-acquired MRSA (HA-MRSA) |
| MSSA476 | Methicillin-susceptible *S. aureus* |
| Mu50 | Vancomycin-intermediate (VISA) |
| MW2 | CA-MRSA USA400, PVL+ |
| *S. epidermidis* RP62A | Outgroup |

**Key concepts:** SCCmec cassettes, Panton-Valentine Leukocidin (PVL), pathogenicity islands (SaPI), vancomycin resistance mechanism, community vs. nosocomial evolution

---

### Panel 2 — *Pseudomonas aeruginosa*: Chronic Infection and Genomic Adaptation
**Theme:** How does an opportunistic pathogen evolve during long-term colonization of the cystic fibrosis lung?

| Strain | Key feature |
|--------|------------|
| PAO1 | Laboratory reference |
| PA14 | Hypervirulent clinical isolate |
| PAK | Cystic fibrosis clinical isolate |
| LESB58 | Liverpool CF epidemic clone |
| DK2 | Chronic CF-adapted, heavily evolved |
| *P. putida* KT2440 | Outgroup |

**Key concepts:** Genomic reduction during chronic infection, accessory genome and pan-genome size, epidemic clone evolution, virulence island diversity, *Pseudomonas* genus core

---

### Panel 3 — *Escherichia coli*: From Lab Strain to Deadly Pathogen
**Theme:** What genomic differences separate a harmless lab K-12 strain from strains that cause hemorrhagic colitis, urinary tract infections, and infant diarrhea?

| Strain | Key feature |
|--------|------------|
| MG1655 | Non-pathogenic K-12 lab strain |
| EDL933 | O157:H7 STEC — hemorrhagic colitis |
| EC4115 | O157:H7 — 2006 spinach outbreak |
| CFT073 | Uropathogenic *E. coli* (UPEC) |
| E2348/69 | Enteropathogenic *E. coli* (EPEC) |

**Key concepts:** Horizontal gene transfer and pathoadaptation, Shiga toxin phage islands, type III secretion (LEE), pathogenicity island diversity, *E. coli* pan-genome

> **Note:** EDL933 (O157:H7) was part of the original sequencing effort that established many of the landmark findings about *E. coli* pathogenomics.

---

### Panel 4 — *Salmonella enterica*: Serovars, Host Range, and Vaccine Biology
**Theme:** How do closely related *Salmonella* serovars differ in host range — from the human-restricted typhoid agent to broad-host-range food-borne serovars?

| Strain | Key feature |
|--------|------------|
| Typhimurium LT2 | Reference broad-host-range serovar |
| Typhimurium 14028S | Virulent murine typhoid model |
| Enteritidis P125109 | Poultry/egg-associated food-borne pathogen |
| Typhi CT18 | Human-restricted, causes typhoid fever |
| Typhi Ty2 | Basis of Ty21a oral vaccine |
| Dublin CT_02021853 | Cattle-adapted, invasive in humans |
| Paratyphi A ATCC9150 | Human-restricted, paratyphoid fever |

**Key concepts:** Salmonella pathogenicity islands (SPI-1, SPI-2), genomic degradation and host restriction, convergent evolution, vaccine strain attenuation, serovar diversity

---

### Panel 5 — *Staphylococcus epidermidis*: Commensal vs. Opportunistic Pathogen
**Theme:** What genomic features distinguish a harmless skin commensal from the same species causing device-associated infections?

| Strain | Key feature |
|--------|------------|
| ATCC 12228 | Skin commensal, non-biofilm former |
| RP62A | Biofilm-forming, prosthetic infection |
| 1457 | Clinical biofilm strain |
| *S. aureus* MSSA476 | Outgroup |
| *S. aureus* USA300 | Outgroup |

**Key concepts:** Biofilm biology (*ica* operon, PIA), commensal vs. pathogen genomics, device-associated infection, species-level vs. strain-level gene content, *Staphylococcus* genus core

---

### Panel 6 — *Acinetobacter*: Environmental Survivor vs. Hospital Superbug
**Theme:** How does a radiation-resistant soil bacterium relate to one of the most drug-resistant hospital pathogens?

| Strain | Key feature |
|--------|------------|
| NBRC 102413 | *A. radioresistens* type strain |
| DD78 | *A. radioresistens* environmental isolate |
| LH6 | *A. radioresistens*, poultry manure (USA) |
| NIPH 2130 | *A. radioresistens*, urine/clinical (Norway); scaffold-level assembly |
| *A. baumannii* ATCC 19606 | *A. baumannii* type strain (outgroup) |
| *A. baumannii* AB5075-UW | MDR wound isolate, Walter Reed 2008 (outgroup) |

**Key concepts:** Environmental vs. clinical niche adaptation, multidrug resistance islands (carbapenemases, OXA-type β-lactamases, efflux pumps), radiation and desiccation tolerance, scaffold-level assembly in whole-genome alignment, *Acinetobacter* genus core

> **Assembly note:** NIPH 2130 is a scaffold-level assembly (6 scaffolds, N50 ~3.08 Mb). Its genome track will appear as multiple fragments in Mauve — this is expected and provides a useful teaching moment about assembly quality and its effect on alignment visualization.

---

## Lab Procedure

### Before the lab
- Download and install [Mauve](http://darlinglab.org/mauve/) (Windows/Mac/Linux, free)
- Download the zip for your assigned panel from the course repository
- Extract the zip — **keep all files in the same folder**

### Opening the alignment
1. Launch Mauve
2. **File → Open** → navigate to the extracted folder → select `alignment.xmfa`
3. Mauve will load the alignment with annotation tracks pre-configured
4. Resize genome tracks by dragging the track borders for a better view

### Navigation tips
| Action | How |
|--------|-----|
| Zoom in/out | Mouse scroll wheel or View menu |
| Pan left/right | Click and drag, or arrow keys |
| Jump to a coordinate | View → Go to position |
| Reorder genomes | Drag genome track labels |
| Inspect an LCB | Click a colored block — details appear in status bar |
| View a gene feature | Hover over an annotation track feature |

### Guided observations (all panels)
Work through these in order before answering the panel-specific discussion questions:

1. **Count the core genome blocks.** How many large colored blocks span every genome? These represent conserved housekeeping functions.
2. **Find a strain-specific block.** Identify at least one colored region present in only one or two strains. Hover over the annotation track — what genes are there?
3. **Look for inversions.** Do any strains have blocks below the center line? Which strains show the most rearrangement?
4. **Examine the outgroup.** What fraction of the alignment is shared with the outgroup? What does this say about genus-level vs. species-level conservation?
5. **Compare genome sizes.** Are all tracks the same width? Size differences visible in the tracks reflect differences in genome length — usually driven by the accessory genome.

---

## Discussion Questions (Universal)

Answer these after working through your panel, then address the panel-specific questions in your QUICKSTART guide.

1. In your panel, which strain has the largest genome? Which has the smallest? What types of genetic elements account for the size difference?

2. Select one accessory genomic island and research what it encodes. Is it associated with a transposon, phage, or integrative conjugative element? What does this say about its evolutionary origin?

3. The outgroup genome is included in every panel. Based on the alignment, approximately what percentage of the pathogen's genome is shared with the outgroup? What percentage is unique to the pathogen species?

4. Genomic rearrangements (inversions, translocations) are visible in Mauve as blocks below the baseline. Do rearrangements tend to cluster near pathogenicity islands or in the core genome? Propose an explanation.

5. If you were designing a live-attenuated vaccine from one of the strains in your panel, which strain would you start with and what genomic features would you target for deletion?

---

## Connecting to Course Themes

| Topic covered in lecture | Where to find it in Mauve |
|--------------------------|---------------------------|
| Horizontal gene transfer | Unique accessory blocks absent from most strains |
| Pathogenicity islands | Annotation tracks: large gene clusters with virulence functions |
| Antibiotic resistance | Unique blocks in resistant strains (SCCmec, etc.) |
| Mobile genetic elements | Blocks with IS elements, phage integrases in annotation tracks |
| Genomic reduction / host adaptation | Smaller genome + gaps in host-restricted strains (e.g., *S.* Typhi) |
| Convergent evolution | Same function (biofilm, toxin) appearing in unrelated genomic locations |
| Core vs. pan-genome | Large conserved blocks vs. strain-specific colored regions |

---

## Dataset Notes

All genomes were downloaded from NCBI and aligned using progressiveMauve (2022 bioconda build, seed weight 15). Annotation tracks (GFF3) are automatically loaded when the XMFA is opened — no manual loading required.

| Panel | Accessions |
|-------|-----------|
| *S. aureus* | GCF_000011265.1, GCF_000011525.1, GCF_000009665.1, GCF_000013425.1, GCF_000408865.1 (outgroup) |
| *P. aeruginosa* | GCF_000006765.1, GCF_000014625.1, GCF_000271365.1, GCF_000116565.1, GCF_000408865.1 (outgroup) |
| *E. coli* | GCF_000005845.2, GCF_000732965.1, GCF_000175675.1, GCF_000007405.1, GCF_000026545.1 |
| *Salmonella* | GCF_000006945.2, GCF_000020705.1, GCF_000195995.1, GCF_000020925.1, GCF_000020765.1, GCF_000006925.2 |
| *S. epidermidis* | GCF_000007645.1, GCF_000006285.1, GCF_000705075.1 + *S. aureus* outgroups |
| *Acinetobacter* | GCF_006757745.1, GCF_005519305.1, GCF_003258335.1, GCF_000368885.1 + GCF_009759685.1, GCF_000963815.1 (outgroups) |

---

*Alignments generated and curated by Cryptic Prophage Lab, UTEP. For questions or corrections, open an issue at github.com/cryptic-prophage/mauve-classroom.*
