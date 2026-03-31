# LESSON_DEBUG.md — Bugs, Failures, and Hard-Won Lessons
## Mauve Classroom Dataset Build — Cryptic Prophage Lab, UTEP

This document records every significant bug, data format failure, and workflow error
encountered while building the 5-panel classroom alignment dataset. Each entry includes
the symptom, root cause, how the investigation unfolded, every failed fix attempt, and
the correct resolution with the exact commands that worked.
Intended as a reference for future pipeline builds and for training new lab members.

---

## 1. Seven Wrong NCBI Accessions

### Symptom
The original `download_mauve_panels.sh` script ran to completion without error, but the
downloaded genomes were completely wrong organisms. NCBI returned:
- *Bacteroides thetaiotaomicron* instead of *S. aureus* MW2
- *Prochlorococcus marinus* instead of *P. aeruginosa* PAK
- *Haloquadratum walsbyi* instead of *Salmonella* Gallinarum
- *Shigella sonnei* instead of *S. epidermidis* 1457
- *Buchnera aphidicola* instead of *E. coli* Sakai

### Root Cause
The accession numbers in the script were wrong — copy-paste errors from an earlier
draft that mixed up GCF/GCA identifiers across different organisms. NCBI `datasets`
did not error out; it simply returned whatever matched the accession, regardless of
whether the organism matched the intent. The download step produced no warnings,
which made this easy to miss until the genome sizes and GC content looked wrong
during alignment inspection.

### How It Was Found
The error surfaced when the alignments looked biologically implausible — the
*S. aureus* panel showed near-zero synteny between some "strains," which is
impossible for members of the same species. Running `grep "^>"` on the downloaded
`.fna` files immediately revealed the organism names embedded in the FASTA headers
were completely wrong.

### How It Was Solved
Each accession was verified individually against the NCBI assembly database before
any further work:
```bash
datasets summary genome accession GCF_XXXXXXX.X \
  | python3 -m json.tool \
  | grep -E "organism_name|assembly_name|assembly_accession"
```
This returns a JSON summary with the organism name, assembly name, and accession,
making it immediately obvious whether the accession matches the intended strain.
All 7 wrong accessions were looked up and replaced with correct ones sourced from
NCBI Assembly by searching the organism name and strain designation directly in
the web interface, then cross-checking with the `datasets summary` command.

**Corrected accessions:**

| Panel | Strain | Correct accession |
|-------|--------|-------------------|
| S. aureus | MW2 (USA400) | GCF_000011265.1 |
| S. aureus | MSSA476 | GCF_000011525.1 |
| S. aureus | Mu50 | GCF_000009665.1 |
| P. aeruginosa | PAK | GCF_000408865.1 |
| P. aeruginosa | DK2 | GCF_000271365.1 |
| Salmonella | Gallinarum 287/9 | *not in RefSeq — see §2* |
| S. epidermidis | 1457 | GCF_000705075.1 |

### Lesson
**Never trust accession numbers copied from a draft script or literature without
independently verifying against the NCBI assembly record.** Always run
`datasets summary genome accession` on every accession before the download step
and check the returned organism name. Add this as an explicit verification step
at the top of any genome download script.

---

## 2. *Salmonella* Gallinarum 287/91 Not in NCBI RefSeq

### Symptom
After correcting the Gallinarum accession per §1, no valid GCF or GCA accession
for *Salmonella* Gallinarum 287/91 could be found in NCBI. Searching the assembly
database returned no results for the strain designation.

### Root Cause
The *S.* Gallinarum 287/91 reference genome (primary accession AM933173) was
deposited in EMBL-EBI only and was never submitted to NCBI GenBank or RefSeq.
It exists as a primary European Nucleotide Archive (ENA) record with no
corresponding GCF or GCA identifier — NCBI simply does not have it.

### How It Was Solved

**Step 1 — Confirmed absence.** Searched NCBI Assembly at
`https://www.ncbi.nlm.nih.gov/assembly/?term=Salmonella+Gallinarum+287` and
`datasets summary genome taxon "Salmonella gallinarum"` — both returned zero
complete assemblies with a GCF/GCA accession for strain 287/91.

**Step 2 — Evaluated options.** Three paths were considered:
1. Use the ENA accession (AM933173) directly — ruled out because `datasets` cannot
   fetch ENA-only records and manually parsing raw EMBL format adds fragility.
2. Find an NCBI-mirrored version — none exists; EMBL records for this strain were
   never mirrored to GenBank.
3. Substitute a scientifically equivalent strain from RefSeq.

**Step 3 — Chose the substitute.** *Salmonella* Dublin CT_02021853
(GCF_000020925.1) was selected because:
- It is a host-adapted serovar (cattle-adapted, invasive in immunocompromised humans)
- It provides the same pedagogical contrast with broad-host-range Typhimurium
  that Gallinarum would have provided (host restriction vs. broad range)
- It is a complete, closed RefSeq genome with full GFF3 annotation
- Confirmed via `datasets summary genome accession GCF_000020925.1` before use

The substitution was documented in `ANALYSIS_NOTEBOOK.md` so instructors are
aware the panel uses Dublin rather than Gallinarum.

### Lesson
**Verify that a complete RefSeq assembly exists before committing a strain to a
pipeline.** High-profile strains widely cited in literature are not always in NCBI.
When a landmark strain is unavailable, choose the closest scientifically equivalent
substitute and document the change explicitly. Never silently use a different strain.

---

## 3. `--assembly-source` Flag Required for GCA Accessions

### Symptom
`datasets download genome accession GCA_XXXXXXX.X` returned an error with the
message that the accession could not be found, even though the accession was
confirmed valid in the NCBI Assembly web interface.

### Root Cause
By default, `datasets download genome accession` only searches RefSeq (GCF-prefixed)
assemblies. GCA-prefixed accessions are GenBank submissions that have not gone through
RefSeq curation. Without the `--assembly-source all` flag, the tool ignores them.

### How It Was Solved
The NCBI `datasets` help page (`datasets download genome accession --help`) listed
`--assembly-source` as an option with values `refseq`, `genbank`, or `all`. Adding
`--assembly-source all` to every download call resolved the issue immediately:

```bash
datasets download genome accession "$ACC" \
  --include genome,gff3,protein \
  --assembly-source all \
  --filename "${ORG_DIR}/${LABEL}.zip"
```

This flag is harmless for GCF accessions (RefSeq is a subset of `all`) and necessary
for GCA accessions, so it was added permanently to the download function rather than
conditionally applying it only to GCA accessions.

### Lesson
Always include `--assembly-source all` in `datasets` calls unless you are certain
every accession is a GCF. It costs nothing for RefSeq assemblies and prevents
silent failures on GenBank-only depositions.

---

## 4. Windows progressiveMauve Binary — Broken `--output` Flag

### Symptom
`progressiveMauve.exe --output=alignment.xmfa genome1.fna genome2.fna` produced a
0-byte XMFA file. When stdout was redirected (`>`), the binary segfaulted (exit 139).
When run interactively with a TTY, it exited 0 and printed alignment progress to the
terminal but wrote nothing to disk.

### Root Cause
The official Windows progressiveMauve binary (2014 build, distributed from
`darlinglab.org/mauve/`) has a broken `--output` flag — a regression in the Windows
port that was never fixed. The `--output` path is parsed but the file handle is never
opened. The Linux binary bundled in the same Mauve Java distribution package (2009
build) was also tested and crashes on inputs larger than ~2 MB per genome.

### How the Investigation Unfolded

**Attempt 1 — Absolute Windows path:**
```bash
progressiveMauve.exe --output=C:\\Users\\japodaca15\\test\\alignment.xmfa *.fna
# Result: exits 0, alignment.xmfa = 0 bytes
```

**Attempt 2 — Unix-style path under Git Bash:**
```bash
progressiveMauve --output=/c/Users/japodaca15/test/alignment.xmfa *.fna
# Result: exits 0, alignment.xmfa = 0 bytes
```

**Attempt 3 — Stdout redirect:**
```bash
progressiveMauve *.fna > alignment.xmfa
# Result: exit 139 (SIGSEGV — segmentation fault)
```

**Attempt 4 — No output flag, TTY only:**
```bash
progressiveMauve *.fna
# Result: prints progress to terminal, exits 0, no file written anywhere
```

**Attempt 5 — Bundled Linux binary via WSL:**
```bash
wsl.exe /path/to/linux/progressiveMauve --output=... *.fna
# Result: crashes with memory error on all inputs over 1 MB per genome
```

At this point the user mentioned that progressiveMauve had been made to work
previously using a copy in `Downloads\mauve-master_original\`. This prompted
checking WSL for a bioconda installation:
```bash
wsl.exe which progressiveMauve
wsl.exe progressiveMauve --version
```
Found: `/home/japodaca15/miniconda3/envs/mauve/bin/progressiveMauve` (2022 build).

**Attempt 6 — WSL bioconda binary, direct call:**
```bash
wsl.exe /home/japodaca15/miniconda3/envs/mauve/bin/progressiveMauve \
  --output=/mnt/c/Users/japodaca15/.../alignment.xmfa \
  /mnt/c/Users/.../genome1.fna /mnt/c/Users/.../genome2.fna
# Result: SUCCESS — full XMFA written, correct size
```

**Path conversion detail:** Git Bash paths (`/c/Users/...`) must be converted to WSL
mount paths (`/mnt/c/Users/...`) before passing to WSL binaries:
```bash
WSL_OUT=$(echo "$OUT_PATH" | sed 's|^/c/|/mnt/c/|')
WSL_GENOME_ARGS=$(echo "$GENOME_ARGS" | sed 's|/c/|/mnt/c/|g')
wsl.exe bash -c "${PMAUVE_WSL} --output='${WSL_OUT}' ${WSL_GENOME_ARGS}"
```

### Lesson
**Do not use the official Windows progressiveMauve binary (2014) for any alignment
work.** It is broken in ways that produce silent failures (0-byte output) rather than
error messages — the worst kind of bug to diagnose. The correct approach on Windows
is to install progressiveMauve in WSL via bioconda and call it through `wsl.exe`.
The 2022 bioconda build is stable on multi-megabase microbial genomes.

---

## 5. WSL Base Conda Environment — Boost ABI Conflict

### Symptom
After finding the WSL progressiveMauve (§4), the first test used the `base` conda
environment binary. It crashed immediately on startup:
```
progressiveMauve: /lib/x86_64-linux-gnu/libboost_filesystem.so.1.74.0: version
`BOOST_1_74_0' not found (required by progressiveMauve)
undefined symbol: _ZNK5boost10filesystem4path8filenameEv
```

### Root Cause
The WSL `base` conda environment had received a `conda update --all` at some point
that pulled in a newer version of the `boost` C++ libraries. The progressiveMauve
binary in `base` was compiled against an older boost ABI, and the new library is
not backwards-compatible at the symbol level (`filename()` method signature changed).

### How It Was Solved

**Step 1 — Confirmed the base env was broken:**
```bash
wsl.exe bash -c "conda activate base && progressiveMauve --version"
# → undefined symbol error
```

**Step 2 — Checked for other conda environments:**
```bash
wsl.exe bash -c "conda env list"
# Output included: mauve   /home/japodaca15/miniconda3/envs/mauve
```

**Step 3 — Tested the `mauve` environment:**
```bash
wsl.exe bash -c "/home/japodaca15/miniconda3/envs/mauve/bin/progressiveMauve --version"
# Output: progressiveMauve version 2.0.0 date 2014-09-12  (bioconda 2022 package)
# No error — binary linked correctly against pinned boost version
```

The `mauve` environment's `progressiveMauve` at
`/home/japodaca15/miniconda3/envs/mauve/bin/progressiveMauve` became the fixed
binary for all subsequent alignment work. It was hardcoded into `run_panels.sh`:
```bash
PMAUVE_WSL="/home/japodaca15/miniconda3/envs/mauve/bin/progressiveMauve"
```

### Lesson
**Always install bioinformatics tools in isolated conda environments, never in
`base`.** The `base` environment receives updates that break ABI-sensitive compiled
binaries. A dedicated environment pins all dependencies including system libraries
at the time of installation. Use the full absolute path to the environment binary
rather than activating the environment (activation is unreliable in `wsl.exe bash -c`
one-liners).

---

## 6. `--min-scaled-penalty` Is Not a Valid progressiveMauve Flag

### Symptom
The pipeline exited immediately on the first alignment attempt:
```
Error: unknown option '--min-scaled-penalty'
progressiveMauve: unrecognized option '--min-scaled-penalty=1000'
```

### Root Cause
The flag `--min-scaled-penalty` was included in the original script, apparently
copied from an older Mauve GUI tutorial or confused with an MUSCLE/MAFFT parameter.
It is not and has never been a valid progressiveMauve command-line flag.

### How It Was Solved
Ran `progressiveMauve --help` via WSL to get the actual list of valid flags:
```bash
wsl.exe /home/japodaca15/miniconda3/envs/mauve/bin/progressiveMauve --help 2>&1 | head -40
```
The valid flags relevant to this pipeline are:
```
--output=<path>            path to write XMFA alignment output
--output-guide-tree=<path> path to write Newick guide tree
--seed-weight=<int>        k-mer seed size (default 11; 15 is better for microbial)
```
`--min-scaled-penalty` was not listed. It was removed from the script and the
pipeline ran without error.

### Lesson
Cross-reference every flag against `--help` output before scripting. Do not trust
flags copied from tutorials, blog posts, or documentation that doesn't cite a specific
version of the tool. When a flag is rejected, `--help` is faster to consult than
any web search.

---

## 7. Git Bash PATH Format Breaks `.exe` Resolution

### Symptom
Attempting to call `powershell.exe` using a constructed path in Git Bash:
```bash
PS_PATH="/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
"$PS_PATH" -Command "echo hello"
# bash: /c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe: No such file or directory
```

### Root Cause
Git Bash (MinGW) translates `/c/` to `C:\` for most file operations, but this
translation does not work reliably when the path is used to directly invoke a binary.
Windows API calls for process creation expect native `C:\` paths, not POSIX-style
paths. The shell's path translation layer does not apply to all contexts equally.

### How It Was Solved
Stopped constructing paths to system binaries and used bare command names instead,
relying on the Windows `PATH` that Git Bash inherits:
```bash
powershell.exe -Command "echo hello"   # works — found via PATH
gh release upload ...                   # works — found via PATH
```
For cases where a specific binary needed to be called and `PATH` lookup was failing,
the full Windows-style path with backslashes was used inside a quoted string:
```bash
powershell.exe -ExecutionPolicy Bypass -File "C:\\Users\\japodaca15\\...\\script.ps1"
```

### Lesson
In Git Bash, prefer bare command names for Windows system tools and let `PATH`
resolution handle location. Only use explicit paths when bare names fail, and when
you do, use Windows-style backslash paths inside quoted strings rather than POSIX
`/c/` paths.

---

## 8. `gh` Auth Not Accessible from Git Bash

### Symptom
Running `gh release upload ...` from Git Bash after authenticating with
`gh auth login` in a separate PowerShell session:
```
error connecting to api.github.com
You are not logged into any GitHub hosts. Run gh auth login to authenticate.
```
Running `gh auth status` from Git Bash also showed no authenticated hosts,
even though `gh auth status` in PowerShell showed the account as authenticated.

### Root Cause
`gh` stores OAuth tokens in the Windows Credential Manager (Windows keyring).
This keyring is accessible from native Windows processes (PowerShell, CMD) but
not from Git Bash's POSIX emulation layer (MinGW), which does not have access
to the Windows Credential Manager API. The token exists; Git Bash simply cannot
read it.

### How It Was Solved

**Step 1 — Confirmed auth was present in PowerShell:**
```powershell
gh auth status
# ✓ Logged in to github.com as japodaca15
```

**Step 2 — Confirmed auth was absent in Git Bash:**
```bash
gh auth status
# You are not logged into any GitHub hosts
```

**Step 3 — Tried setting `GH_TOKEN` env var in Git Bash** (reading the token from
`gh auth token` in PowerShell and exporting it) — this worked for some commands but
was fragile and insecure.

**Step 4 — Correct solution:** Route all `gh` commands through `powershell.exe`.
Wrote all upload logic as a `.ps1` script (`upload_zips.ps1`) and called it from
Git Bash:
```bash
powershell.exe -ExecutionPolicy Bypass -File "C:\\Users\\japodaca15\\projectsClaude\\mauve-classroom\\upload_zips.ps1"
```
Inside `upload_zips.ps1`, `gh` runs natively in the PowerShell process and has full
access to the Windows Credential Manager.

### Lesson
**On Windows, all `gh` CLI calls must originate from PowerShell or CMD, not Git
Bash.** This is a credential store architecture limitation, not a `gh` bug. Any
pipeline step that uses `gh` (releases, issue creation, PR management) should be
written as a `.ps1` script executed via `powershell.exe -ExecutionPolicy Bypass -File`.

---

## 9. `zip` Command Not Available in Git Bash

### Symptom
```bash
zip -r saureus_classroom_dataset.zip saureus_mauve/
# bash: zip: command not found
```

### Root Cause
Git Bash (MinGW) ships with a limited set of Unix utilities. `tar`, `gzip`, and
`bzip2` are present, but `zip` (for `.zip` format archives) is not included. The
Mauve classroom dataset needed `.zip` format because that is what Windows users
can double-click to extract without installing anything.

### How It Was Solved

**Tried — `tar` with zip compression:** Not a `.zip` file, produces `.tar.gz`.
Students on Windows cannot open these without additional software.

**Tried — installing `zip` via Git Bash:** No package manager available in MinGW
without additional setup (Chocolatey, etc.) — too much overhead.

**Correct solution — PowerShell `Compress-Archive`:**
```powershell
$files = @("alignment.xmfa", "alignment.xmfa.backbone", ..., "Saureus_USA300.fna", ...)
Compress-Archive -Path $files -DestinationPath "saureus_classroom_dataset.zip"
```
This was written into `make_zips.ps1` using an explicit file list (to avoid
accidentally including large intermediate files like `.sslist` index files)
and called from Git Bash:
```bash
powershell.exe -ExecutionPolicy Bypass -File "C:\\...\\make_zips.ps1"
```

### Lesson
Do not assume Unix utilities are available in Git Bash. Test with `which zip`
before scripting. For Windows-native `.zip` packaging, PowerShell `Compress-Archive`
is the correct tool — it is available on all modern Windows systems and produces
standard zip files. Use an explicit file list in `Compress-Archive` to control
exactly what ends up in the archive.

---

## 10. PowerShell Variable Interpolation Broken in Bash Heredoc

### Symptom
When writing a multi-panel loop as an inline PowerShell command from Git Bash, the
panel name was not expanding — the zip files were named `{saureus}_classroom_dataset.zip`
(literal curly braces) instead of `saureus_classroom_dataset.zip`:
```
no matches found for `C:\...\zips\{saureus}_classroom_dataset.zip`
```

### Root Cause
Both bash and PowerShell use `$variable` and `${variable}` for variable interpolation.
When a PowerShell script is passed inline to `powershell.exe -Command "..."` from bash,
bash processes `${panel}` first — and since `panel` is not set in the PowerShell
context at that point in bash's parsing, it either expands to empty or leaves literal
`{panel}`. The resulting string that PowerShell receives has the variable name stripped.

### How the Investigation Unfolded

**Attempt 1 — Inline `-Command` with escaped dollars:**
```bash
powershell.exe -Command "
\$panels = @('saureus','paeruginosa')
foreach (\$panel in \$panels) {
    \$src = \"\$base\\{\$panel}_mauve\"
}
"
# Result: {saureus} appears literally — \$ worked for top-level vars but not ${panel}
```

**Attempt 2 — Single-quoted heredoc to prevent bash expansion:**
```bash
powershell.exe -Command "$(cat << 'PSEOF'
$panels = @("saureus")
foreach ($panel in $panels) { ... }
PSEOF
)"
# Result: exit code 49 — PowerShell received mangled input
```

**Correct solution:** Write the PowerShell script to a `.ps1` file using a
single-quoted bash heredoc (prevents all bash interpolation), then execute the file:
```bash
cat > /c/Users/.../upload_zips.ps1 << 'PSEOF'
$base = "C:\Users\japodaca15\projectsClaude\mauve-classroom\zips"
$panels = @("saureus","paeruginosa","ecoli","salmonella","epidermidis")
foreach ($panel in $panels) {
    $zip = "$base\${panel}_classroom_dataset.zip"
    gh release upload v2.4.7 "$zip" --repo cryptic-prophage/mauve-classroom --clobber
}
PSEOF
powershell.exe -ExecutionPolicy Bypass -File "C:\\Users\\...\\upload_zips.ps1"
```
The single-quoted `'PSEOF'` delimiter tells bash not to interpolate anything in the
heredoc body. PowerShell then reads the file and `${panel}` expands correctly within
the `foreach` loop.

### Lesson
**Never embed non-trivial PowerShell logic inline in bash.** The `$variable` syntax
collision between bash and PowerShell makes inline embedding unreliable and hard to
debug. Always write PowerShell scripts to `.ps1` files using `cat > file << 'DELIMITER'`
(single-quoted delimiter = no bash interpolation), then execute via
`powershell.exe -ExecutionPolicy Bypass -File`.

---

## 11. GFF3 Sequence IDs Must Match FASTA Sequence IDs Exactly

### Symptom
After running the alignment and loading the XMFA in Mauve, annotation tracks appeared
as empty lanes — the colored feature bars were completely absent even though the GFF3
files loaded without error messages.

### Root Cause
Mauve matches GFF3 feature records to genome sequences by comparing **column 1 of
each GFF3 data line** to **the tokens in each FASTA `>` header line**. The match
must be exact (case-sensitive string equality).

The pipeline's `sed` command had prepended a readable label to every FASTA header:
```
Before: >NC_007793.1 Staphylococcus aureus subsp. aureus USA300_FPR3757, complete sequence
After:  >Saureus_USA300_FPR3757_CA-MRSA NC_007793.1 Staphylococcus aureus ...
```
First token of modified FASTA header = `Saureus_USA300_FPR3757_CA-MRSA`
GFF3 column 1 = `NC_007793.1`
→ No match → Mauve silently skips all features for this sequence.

### How the Investigation Unfolded

The problem was confirmed by manually inspecting the FASTA and GFF3 files:
```bash
grep "^>" saureus_mauve/mauve_input/Saureus_USA300_FPR3757_CA-MRSA.fna | head -1
# >Saureus_USA300_FPR3757_CA-MRSA NC_007793.1 Staphylococcus aureus ...

awk '!/^#/{print $1}' saureus_mauve/mauve_input/Saureus_USA300_FPR3757_CA-MRSA.gff3 | sort -u
# NC_007790.1
# NC_007791.1
# NC_007792.1
# NC_007793.1
```
First FASTA token (`Saureus_USA300_FPR3757_CA-MRSA`) ≠ GFF3 column 1 (`NC_007793.1`).

### Wrong Fix Attempted — Round 1

The first attempted fix merged label and accession with an underscore in both FASTA
and GFF3:
```
FASTA: >Saureus_USA300_FPR3757_CA-MRSA_NC_007793.1 description
GFF3 col 1: Saureus_USA300_FPR3757_CA-MRSA_NC_007793.1
```
Implemented with `fix_gff3_ids.sh` using `sed`. This ran and produced matching IDs,
but annotations still did not appear. Further investigation (see §12) revealed a
second independent problem (missing `#AnnotationNFile` headers in the XMFA). At
this point both problems needed fixing, and the underscore approach was also
discovered to be wrong.

### Correct Resolution — Guided by Working Reference

The user pointed to `C:\Users\japodaca15\Documents\CYP121_archive\mauve_input\` as
a known-working Mauve dataset with functioning annotations. Inspecting that dataset
revealed the correct pattern:

```bash
# CYP121 reference — Mmarinum (has chromosome + plasmid)
grep "^>" CYP121_archive/mauve_input/8_Mmarinum_M.fna
# >M.marinum_M NC_010612.1 Mycobacterium marinum M, complete sequence
# >NC_010604.1 Mycobacterium marinum M plasmid pMM23, complete sequence
#   ↑ first seq gets label prepended    ↑ second seq is UNCHANGED

awk '!/^#/{print $1}' CYP121_archive/mauve_input/8_Mmarinum_M.gff3 | sort -u
# NC_010604.1
# NC_010612.1
#   ↑ GFF3 col 1 is NEVER modified — stays as original NCBI accessions
```

**The correct rule:**
- First `>` header in each `.fna` file: prepend label → `>LABEL ACCESSION description`
- All subsequent `>` headers (plasmids, contigs): leave completely unchanged → `>ACCESSION description`
- GFF3 column 1: never touch — leave as original NCBI accessions throughout

Mauve's internal matching scans all tokens in a FASTA header line, not just the first.
So for the chromosome:
- FASTA first header: `>Saureus_USA300_FPR3757_CA-MRSA NC_007793.1 ...`
- GFF3 col 1: `NC_007793.1` — this is token 2 of the header, and Mauve finds it
- Display name shown in Mauve: `Saureus_USA300_FPR3757_CA-MRSA` (token 1)

For plasmids:
- FASTA second header: `>NC_007790.1 Staphylococcus aureus ...`
- GFF3 col 1: `NC_007790.1` — this is token 1, exact match

The fix was implemented in `fix_fasta_gff3.py` (called via
`powershell.exe -Command "python fix_fasta_gff3.py"`):
```python
# For each .fna file:
for line in lines:
    if line.startswith('>'):
        # Parse: current token 1 may be LABEL_ACCESSION (from bad fix) or ACCESSION
        # Strip LABEL_ prefix if present, recover bare accession
        # First sequence: write ">LABEL ACCESSION description"
        # All others: write ">ACCESSION description" (unchanged)
```

### Lesson
**Study a known-working example before attempting any FASTA/GFF3 format fix.**
The matching rule in Mauve is not "first token must match" — it is "any token in the
header line must match GFF3 col 1." The correct labeling strategy is to prepend the
display name only to the first header line of each `.fna` file (separated by a space,
not an underscore) and leave all other sequence headers and all GFF3 files completely
untouched. Never modify GFF3 column 1.

---

## 12. XMFA File Must Contain `#AnnotationNFile` Headers for Auto-Loading

### Symptom
Even after correctly fixing FASTA/GFF3 sequence ID matching (§11), annotations
still did not appear when the XMFA was opened in Mauve. No error was shown; the
annotation tracks simply were not present at all.

### Root Cause
Mauve loads annotation tracks from GFF3 files automatically **only if** the XMFA
file itself contains `#AnnotationNFile` and `#AnnotationNFormat` header lines. These
lines tell Mauve which GFF3 file to associate with each numbered genome sequence.
Without these entries, Mauve has no way of knowing GFF3 files exist — it does not
scan the directory for them automatically.

The progressiveMauve binary writes only `#SequenceNFile` entries into the XMFA
header at alignment time. It never writes annotation entries. Our pipeline's XMFA
contained:
```
#Sequence1File    Saureus_MRSA252_HA-MRSA.fna
#Sequence1Format  FastA
...
#BackboneFile     alignment.xmfa.bbcols
```
No `#Annotation` lines anywhere.

### How It Was Found
After the §11 fix still failed to show annotations, the working CYP121 reference
XMFA was inspected:
```bash
head -40 CYP121_archive/mauve_input/9way_alignment | grep -E "^#"
```
Output:
```
#Sequence1File    1_Mtb_H37Rv.fna
...
#Annotation1File  1_Mtb_H37Rv.gff3
#Annotation1Format  GFF3
#Annotation2File  2_Mtb_Erdman.gff3
#Annotation2Format  GFF3
...
#BackboneFile     9way_alignment.bbcols
```
The `#Annotation` entries were entirely absent from the classroom XMFAs.

The CYP121 reference also contained `add-annotations.sh`, a post-processing script
that injected these entries after alignment. This script was never part of the
classroom pipeline — it had been a manual step that was never ported.

### How It Was Solved
A Python script (`fix_xmfa.py`) was written to:
1. Parse the existing `#SequenceNFile` entries to determine the genome numbering
2. For each genome number `N`, check whether a matching `.gff3` file exists in `mauve_input/`
3. Build the annotation block in sequence order
4. Insert it into the XMFA before `#BackboneFile`

```python
for n in sorted(anno_map):
    anno_block.append(f'#Annotation{n}File\t{anno_map[n]}\n')
    anno_block.append(f'#Annotation{n}Format\tGFF3\n')

# Insert before #BackboneFile
for i, line in enumerate(new_lines):
    if line.startswith('#BackboneFile'):
        insert_at = i
        break
final = new_lines[:insert_at] + anno_block + new_lines[insert_at:]
```

After running `fix_xmfa.py`, the classroom XMFA headers matched the working CYP121
structure, and annotations loaded automatically on XMFA open.

### Lesson
**progressiveMauve never writes annotation headers — this is a permanent feature gap,
not a version issue.** Any pipeline that produces shareable or classroom Mauve files
must include a post-alignment step to inject `#AnnotationNFile` / `#AnnotationNFormat`
entries into the XMFA. This step should be automated and part of the core pipeline,
not a manual afterthought. The canonical post-processing script is `add-annotations.sh`
(or its Python equivalent `fix_xmfa.py` in this project).

---

## 13. XMFA `#SequenceNFile` Paths Are Absolute and Environment-Specific

### Symptom
After a student extracted the dataset zip and opened `alignment.xmfa`, Mauve showed
a dialog: "Cannot find file: C:\Users\japodaca15\projectsClaude\mauve-classroom\
saureus_mauve\mauve_input\Saureus_MRSA252_HA-MRSA.fna". The genome track appeared
but was blank — no sequence data loaded.

### Root Cause
progressiveMauve writes the **absolute path** of each input genome file into the
`#SequenceNFile` header at alignment time, using the build machine's directory structure.
These paths do not exist on any other machine. The classroom zip extracts to a flat
folder — the nested `saureus_mauve/mauve_input/` subdirectory structure only exists
on the build machine.

### How It Was Solved

**Step 1 — Confirmed the problem by inspecting the XMFA header:**
```bash
grep "^#Sequence" saureus_mauve/mauve_output/alignment.xmfa
# #Sequence1File    C:\Users\japodaca15\projectsClaude\mauve-classroom\saureus_mauve\mauve_input\Saureus_MRSA252_HA-MRSA.fna
```

**Step 2 — Determined what Mauve needs.** Mauve first tries the literal path in the
header. If that fails, it looks for the bare filename in the same directory as the
XMFA file. Since the zip packages `.fna` files alongside `alignment.xmfa` in a flat
folder, bare filenames will always resolve correctly.

**Step 3 — Updated paths in `fix_xmfa.py`** using `os.path.basename()` to strip
everything before the filename:
```python
raw_path = m.group(3)   # e.g. C:\Users\...\Saureus_MRSA252_HA-MRSA.fna
fname = os.path.basename(raw_path.replace('\\', '/'))  # → Saureus_MRSA252_HA-MRSA.fna
new_lines.append(f'#Sequence{n}File\t{fname}\n')
```

After this fix, the XMFA headers read:
```
#Sequence1File    Saureus_MRSA252_HA-MRSA.fna
```
This resolves correctly on any machine where `alignment.xmfa` and `Saureus_MRSA252_HA-MRSA.fna`
are in the same directory.

### Lesson
**progressiveMauve bakes in absolute build-machine paths.** These must always be
stripped to bare filenames before distribution. Package all genome files, GFF3 files,
and the XMFA flat in one directory — no subdirectories — and use bare filenames in
all XMFA path headers. Treat the XMFA as a manifest: audit every `#...File` line
before zipping.

---

## 14. `#BackboneFile` Path Also Needs Updating

### Symptom
After §13 fixed the genome file paths, backbone coloring (the colored borders
around LCB blocks) was missing or wrong. Mauve opened cleanly but LCBs had no
color-coded borders.

### Root Cause
The same absolute-path problem from §13 affected `#BackboneFile`:
```
#BackboneFile    saureus_mauve/mauve_output/alignment.xmfa.bbcols
```
The path `saureus_mauve/mauve_output/alignment.xmfa.bbcols` is relative to the
build machine's working directory, which doesn't exist in the extracted zip.
The `.bbcols` file was present in the zip (in the same flat folder as the XMFA)
but Mauve couldn't find it via the stale path.

### How It Was Solved
`fix_xmfa.py` was extended to also process the `#BackboneFile` line, stripping
it to a bare filename. Additionally a `sed` one-liner was used as a quick check:
```bash
sed -i 's|#BackboneFile\t.*[\\/]\([^\\/]*\)$|#BackboneFile\t\1|' alignment.xmfa
```
Result:
```
#BackboneFile    alignment.xmfa.bbcols
```

### Lesson
Every file reference in the XMFA header must use a bare filename for portable
distribution: `#SequenceNFile`, `#BackboneFile`, and `#AnnotationNFile` (which
was injected with bare filenames from the start). After any XMFA post-processing,
run `grep "^#.*File" alignment.xmfa` and verify that no entry contains a slash,
backslash, or colon.

---

## 15. Python Not Available as `python3` in Git Bash

### Symptom
```bash
python3 fix_fasta_gff3.py
# Python was not found; run without arguments to install from the Microsoft Store,
# or disable this shortcut from Settings > Apps > Advanced app settings > App execution aliases.
```

### Root Cause
On this machine, Python 3.12 is installed and available on the Windows PATH as
`python` (not `python3`). Git Bash includes a `python3` stub that redirects to
the Windows Store app installation prompt rather than the installed Python binary.
This stub was set up by Windows "App execution aliases" and intercepts the `python3`
command before Git Bash's PATH lookup reaches the real interpreter.

### How It Was Solved

**Step 1 — Confirmed `python` works but `python3` doesn't:**
```bash
python --version
# Python 3.12.10  ← works

python3 --version
# Windows Store redirect message  ← broken stub
```

**Step 2 — Tried calling Python from WSL** (see §16 for why this also failed).

**Step 3 — Correct solution:** Route Python calls through PowerShell:
```bash
powershell.exe -Command "python C:\Users\japodaca15\projectsClaude\mauve-classroom\fix_fasta_gff3.py"
```
PowerShell finds the correct `python.exe` via its own PATH resolution, which is
not affected by the Git Bash stub.

### Lesson
On Windows, always test `python3 --version` **and** `python --version` in the
specific shell being used. If `python3` fails in Git Bash, use `python` — or,
more reliably for complex scripts, call Python through
`powershell.exe -Command "python ..."` which uses Windows-native PATH resolution.

---

## 16. WSL Path Mangling When Calling Python via `wsl.exe` from Git Bash

### Symptom
```bash
wsl.exe python3 /mnt/c/Users/japodaca15/projectsClaude/mauve-classroom/fix_fasta_gff3.py
```
Produced:
```
python3: can't open file
'/mnt/c/Users/japodaca15/Downloads/mauve-master/.claude/C:/Program Files/Git/mnt/c/Users/japodaca15/projectsClaude/mauve-classroom/fix_fasta_gff3.py':
[Errno 2] No such file or directory
```
The path is corrupted — the Git Bash `.claude/` working directory and Git installation
path are prepended to the intended path.

### Root Cause
When Git Bash passes arguments to `wsl.exe`, it applies its own path translation
heuristics before the argument reaches WSL. The Git Bash working directory context
(`.claude/`) and the Git installation prefix (`C:/Program Files/Git`) were being
prepended to the `/mnt/c/...` path because Git Bash's MinGW layer attempted to
interpret `/mnt/c/` as a relative path to its own file system root.

### How the Investigation Unfolded

**Attempt 1 — Quoted path:**
```bash
wsl.exe python3 "/mnt/c/Users/japodaca15/projectsClaude/mauve-classroom/fix_fasta_gff3.py"
# Same mangled path error
```

**Attempt 2 — Double-escaped path:**
```bash
wsl.exe python3 "//mnt/c/Users/..."
# Different mangling — still wrong
```

**Attempt 3 — Windows path passed to WSL:**
```bash
wsl.exe python3 "C:\\Users\\japodaca15\\..."
# WSL doesn't accept Windows paths directly for python3 script argument
```

**Correct solution:** Use PowerShell to run Windows-resident Python scripts.
PowerShell passes paths to processes without any MinGW path translation:
```bash
powershell.exe -Command "python C:\Users\japodaca15\projectsClaude\mauve-classroom\fix_fasta_gff3.py"
# Works correctly — no path mangling
```

If WSL Python is genuinely needed, copy the script to the WSL home directory first:
```bash
cp /c/Users/japodaca15/projectsClaude/mauve-classroom/fix_fasta_gff3.py ~/fix_fasta_gff3.py
wsl.exe python3 ~/fix_fasta_gff3.py   # WSL-native path, no mangling
```

### Lesson
Do not call `wsl.exe python3 /mnt/c/...` from Git Bash — path mangling is
unpredictable and produces paths that are wrong in ways that are hard to diagnose.
For scripts that live on the Windows filesystem, use `powershell.exe -Command "python C:\..."`.
Reserve `wsl.exe` Python calls for scripts that reside on the WSL filesystem (`~/`).

---

## Summary Table

| # | Issue | Stage | How Found | Fix |
|---|-------|-------|-----------|-----|
| 1 | 7 wrong NCBI accessions | Download | Wrong organism names in FASTA headers | Verify each with `datasets summary` before download |
| 2 | Gallinarum not in RefSeq | Download | No GCF/GCA found for strain 287/91 | Substitute Dublin CT_02021853 (GCF_000020925.1) |
| 3 | `--assembly-source` missing | Download | `datasets` returned "not found" for GCA accessions | Add `--assembly-source all` to all download calls |
| 4 | Windows progressiveMauve broken `--output` | Alignment | 0-byte XMFA; segfault on stdout redirect | Use WSL bioconda binary (2022) via `wsl.exe` |
| 5 | WSL base env boost ABI conflict | Alignment | `undefined symbol` crash on startup | Use dedicated `mauve` conda env; hardcode full binary path |
| 6 | Invalid `--min-scaled-penalty` flag | Alignment | "unknown option" error on launch | Remove flag; verify all flags against `--help` |
| 7 | Git Bash PATH / `.exe` resolution | Shell | "command not found" for system binaries | Use bare command names; route via PowerShell |
| 8 | `gh` auth invisible to Git Bash | Upload | "not logged in" despite PowerShell auth | Write `.ps1` upload scripts; call via `powershell.exe -File` |
| 9 | `zip` not in Git Bash | Packaging | "command not found" | Use PowerShell `Compress-Archive` in `.ps1` script |
| 10 | PowerShell `$var` eaten by bash | Scripting | Literal `{panel}` in generated paths | Write `.ps1` files with `'HEREDOC'`; never inline PS in bash |
| 11 | GFF3 col 1 ≠ FASTA first token | Annotations | Empty annotation tracks in Mauve | First FASTA header gets label; rest unchanged; GFF3 never modified |
| 12 | XMFA missing `#AnnotationNFile` | Annotations | Annotations absent even after §11 fix; found by comparing to CYP121 reference | Inject annotation headers post-alignment via `fix_xmfa.py` |
| 13 | XMFA `#SequenceNFile` absolute paths | Portability | Mauve "cannot find file" on student machine | Strip to bare filenames; package zip flat |
| 14 | XMFA `#BackboneFile` stale path | Portability | Backbone coloring absent on student machine | Strip to bare filename; audit all `#...File` lines before zipping |
| 15 | `python3` unavailable in Git Bash | Scripting | Windows Store redirect instead of Python | Use `powershell.exe -Command "python ..."` |
| 16 | WSL path mangling from Git Bash | Scripting | Garbled path with `.claude/` and Git prefix | Use PowerShell for Windows-resident scripts; WSL only for `~/` scripts |

---

*Document compiled from the Mauve classroom dataset build sprint, March 2026.
Cryptic Prophage Lab, UTEP.*
