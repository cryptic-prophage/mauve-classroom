# LESSON_DEBUG.md — Bugs, Failures, and Hard-Won Lessons
## Mauve Classroom Dataset Build — Cryptic Prophage Lab, UTEP

This document records every significant bug, data format failure, and workflow error
encountered while building the 5-panel classroom alignment dataset. Each entry includes
the symptom, root cause, failed fix attempts (where applicable), and the correct resolution.
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
whether the organism matched the intent.

### Resolution
Verified every accession individually using:
```bash
datasets summary genome accession GCF_XXXXXXX.X | python3 -m json.tool | grep -E "organism|assembly_name"
```
All 7 wrong accessions were corrected. The corrected set:

| Panel | Strain | Wrong accession | Correct accession |
|-------|--------|----------------|-------------------|
| S. aureus | MW2 (USA400) | (bad GCF) | GCF_000011265.1 |
| S. aureus | MSSA476 | (bad GCF) | GCF_000011525.1 |
| S. aureus | Mu50 | (bad GCF) | GCF_000009665.1 |
| P. aeruginosa | PAK | (bad GCF) | GCF_000408865.1 |
| P. aeruginosa | DK2 | (bad GCF) | GCF_000271365.1 |
| Salmonella | Gallinarum 287/9 | (bad GCF) | *not in RefSeq — see §2* |
| S. epidermidis | 1457 | (bad GCF) | GCF_000705075.1 |

### Lesson
**Never trust accession numbers copied from a draft script or literature without
independently verifying against the NCBI assembly record.** Always run
`datasets summary genome accession` on every accession before the download step
and check the returned organism name.

---

## 2. *Salmonella* Gallinarum 287/91 Not in NCBI RefSeq

### Symptom
`datasets download genome accession GCF_000026645.1` returned the wrong organism.
After correcting, no complete RefSeq assembly for *S.* Gallinarum 287/91 could be found.

### Root Cause
The *S.* Gallinarum 287/91 reference genome (AM933173) was deposited in EMBL only
and was never accessioned into NCBI RefSeq or GenBank as a complete assembly. It exists
as a primary EMBL record with no corresponding GCF/GCA identifier.

### Resolution
Substituted *Salmonella* Dublin CT_02021853 (GCF_000020925.1) — a complete RefSeq genome
of a cattle-adapted, invasive serovar. Pedagogical value is equivalent: Dublin and
Gallinarum are both host-adapted serovars and the contrast with broad-host-range
Typhimurium is preserved.

### Lesson
**Verify that a complete RefSeq assembly exists before committing a strain to a pipeline.**
When a landmark strain (widely cited in literature) is not in RefSeq, find the closest
scientifically equivalent substitute that *is* available. Document the substitution
explicitly in the dataset notes so instructors are aware.

---

## 3. `--assembly-source` Flag Required for GCA Accessions

### Symptom
`datasets download genome accession GCA_XXXXXXX.X` returned an error or empty result.

### Root Cause
By default, `datasets` only searches RefSeq (GCF) sources. GCA accessions (GenBank
depositions without RefSeq curation) require the `--assembly-source all` flag.

### Resolution
```bash
datasets download genome accession "$ACC" \
  --include genome,gff3,protein \
  --assembly-source all \
  --filename "${ORG_DIR}/${LABEL}.zip"
```

### Lesson
Always include `--assembly-source all` in `datasets` calls unless you are certain
every accession is a GCF. It is harmless for GCF accessions and required for GCA.

---

## 4. Windows progressiveMauve Binary — Broken `--output` Flag

### Symptom
`progressiveMauve.exe --output=alignment.xmfa genome1.fna genome2.fna` produced a
0-byte XMFA file. When piped to stdout, the binary segfaulted (exit 139). When run
interactively with a TTY, it exited 0 but wrote nothing.

### Root Cause
The official Windows progressiveMauve binary (2014 build, distributed from darlinglab.org)
has a broken `--output` flag. It does not write output regardless of the path given.
This is a known but undocumented regression in the Windows build — the Linux binary from
the same era (2009, included in the Mauve Java distribution) also fails on large genomes.

### What Was Tried (and failed)
- Using `--output` with absolute Windows path: `C:\...\alignment.xmfa` — 0 bytes
- Using `--output` with Unix path under Git Bash: `/c/.../alignment.xmfa` — 0 bytes
- Redirecting stdout: `progressiveMauve ... > alignment.xmfa` — exit 139 (segfault)
- Running without `--output` to check stdout: empty
- Using the bundled Linux binary from the Mauve Java package: crashes on all 5-genome inputs

### Resolution
Used the WSL bioconda progressiveMauve (2022 build):
```
/home/japodaca15/miniconda3/envs/mauve/bin/progressiveMauve
```
Called from Git Bash via `wsl.exe`:
```bash
WSL_OUT=$(echo "$OUT_PATH" | sed 's|^/c/|/mnt/c/|')
wsl.exe bash -c "${PMAUVE_WSL} --output='${WSL_OUT}' ... ${WSL_GENOME_ARGS}"
```

### Lesson
**Do not use the official Windows progressiveMauve binary (2014) for any serious
alignment work.** It is broken. The correct approach on Windows is to install
progressiveMauve in WSL via bioconda (`conda install -c bioconda mauve`) and call
it through `wsl.exe`. The 2022 bioconda build is stable and handles multi-megabase
microbial genomes reliably.

---

## 5. WSL Base Conda Environment — Boost ABI Conflict

### Symptom
Running progressiveMauve from the WSL base conda environment produced:
```
undefined symbol: _ZNK5boost10filesystem4path8filenameEv
```
Alignment failed immediately on startup.

### Root Cause
The WSL base conda environment had a newer version of the `boost` library that
introduced a C++ ABI break. The progressiveMauve binary was compiled against the
older ABI and cannot link against the new one.

### Resolution
Created a dedicated conda environment:
```bash
conda create -n mauve -c bioconda mauve
conda activate mauve
```
The `mauve` environment pins all dependencies including boost to compatible versions.
The working binary lives at:
```
/home/japodaca15/miniconda3/envs/mauve/bin/progressiveMauve
```

### Lesson
**Always install bioinformatics tools in isolated conda environments, never in base.**
The base environment is frequently updated and will eventually break ABI-sensitive
compiled binaries. A dedicated environment with pinned dependencies is stable
across conda updates.

---

## 6. `--min-scaled-penalty` Is Not a Valid progressiveMauve Flag

### Symptom
```
Error: unknown option '--min-scaled-penalty'
```
Pipeline exited immediately.

### Root Cause
The flag was copied from an older Mauve tutorial or MUSCLE documentation and was
never a valid progressiveMauve option.

### Resolution
Removed the flag. The valid progressiveMauve alignment flags for this use case are:
```
--output=<path>
--output-guide-tree=<path>
--seed-weight=<int>      # 15 works well for microbial genomes
```

### Lesson
Cross-reference flags against `progressiveMauve --help` output before scripting.
Do not trust undocumented flags from blog posts or old tutorials.

---

## 7. Git Bash PATH Format Breaks `.exe` Resolution

### Symptom
Running `powershell.exe` or `gh.exe` in Git Bash produced "command not found" even
though the binary was on the Windows PATH.

### Root Cause
Git Bash maps Windows drive letters to Unix-style paths (`C:\` → `/c/`). When
constructing paths to Windows binaries using Git Bash variables, the `/c/` prefix
works for file I/O but does not resolve `.exe` binaries on the `PATH`. Windows
`PATH` entries like `C:\Windows\System32` are not always automatically translated.

### Resolution
Use bare binary names without path for system binaries (`powershell.exe`, `gh`),
or use `/c/Windows/System32/WindowsPowerShell/v1/powershell.exe` with the full
translated path. For `gh`, routing through `powershell.exe -Command "gh ..."` was
more reliable.

### Lesson
In Git Bash, prefer bare command names for Windows system tools and let `PATH`
resolution handle the rest. Only use explicit paths when `PATH` lookup fails.

---

## 8. `gh` Auth Not Accessible from Git Bash

### Symptom
`gh release upload ...` from Git Bash produced an authentication error even though
`gh auth login` had been run successfully in PowerShell.

### Root Cause
`gh` stores credentials in the Windows Credential Manager (keyring), which is
accessible from PowerShell sessions but not from Git Bash's POSIX emulation layer.
The auth token is there; Git Bash simply cannot read from the Windows keyring.

### Resolution
Route all `gh` commands through PowerShell:
```bash
powershell.exe -Command "gh release upload v2.4.7 '$zip' --repo org/repo --clobber"
```
Or write a `.ps1` script and execute it:
```bash
powershell.exe -ExecutionPolicy Bypass -File "C:\\path\\to\\upload_zips.ps1"
```

### Lesson
**On Windows, `gh` must be called from PowerShell (or CMD), not Git Bash.**
This is not a `gh` bug — it is a credential store architecture difference.
Always write upload/release scripts as `.ps1` files and execute them via
`powershell.exe -ExecutionPolicy Bypass -File`.

---

## 9. `zip` Command Not Available in Git Bash

### Symptom
`zip -r output.zip dir/` — "command not found"

### Root Cause
Git Bash (MinGW) does not include the `zip` utility by default. `tar` is available
but produces `.tar.gz`, not `.zip`.

### Resolution
Used PowerShell `Compress-Archive`:
```powershell
Compress-Archive -Path $files -DestinationPath $zip
```
Written into `make_zips.ps1` and called from Git Bash via:
```bash
powershell.exe -ExecutionPolicy Bypass -File "make_zips.ps1"
```

### Lesson
Do not assume Unix utilities are available in Git Bash. For zip packaging on Windows,
use PowerShell `Compress-Archive`. For tarballs, `tar` works. Check for the tool
with `which zip` before scripting it.

---

## 10. PowerShell Variable Interpolation Broken in Bash Heredoc

### Symptom
When writing a PowerShell command inline using a bash heredoc, `${panel}` was not
expanding — the literal string `{panel}` appeared in the PowerShell command.

### Root Cause
PowerShell uses `$variable` and `${variable}` syntax identically to bash. When
embedding a PowerShell one-liner inside a bash `$()` or heredoc, bash interprets
`${panel}` first and PowerShell never sees it. If the expansion fails (wrong context),
the result is empty or literal curly-brace text.

### Failed Attempt
```bash
powershell.exe -Command "
\$panels = @('saureus','paeruginosa')
foreach (\$panel in \$panels) {
    \$src = \"\$base\\{\$panel}_mauve\"   # ← {panel} not expanding
"
```

### Resolution
Write PowerShell logic to a `.ps1` file from bash, then execute the file. The `.ps1`
file is read by PowerShell natively, so `${panel}` expands correctly with no bash
interference:
```bash
cat > /c/path/to/script.ps1 << 'PSEOF'
$panels = @("saureus","paeruginosa")
foreach ($panel in $panels) {
    $src = "$base\${panel}_mauve"
}
PSEOF
powershell.exe -ExecutionPolicy Bypass -File "C:\\path\\to\\script.ps1"
```

### Lesson
**Never embed non-trivial PowerShell logic inline in bash.** Always write PowerShell
scripts to `.ps1` files and execute them. Use `'PSEOF'` (single-quoted heredoc
delimiter) to prevent bash from interpreting `$` characters in the script body.

---

## 11. GFF3 Sequence IDs Must Match FASTA Sequence IDs Exactly

### Symptom
After running the alignment and loading the XMFA in Mauve, no annotation features
appeared on any genome track. Tracks loaded without error but were empty.

### Root Cause
Mauve matches GFF3 features to genome sequences by comparing **column 1 of the GFF3
file** (the sequence ID field) to **the first whitespace-delimited token of each
FASTA `>` header line**. They must be identical strings.

The pipeline's `sed` command had prepended a readable label to each FASTA header:
```
>Saureus_USA300_FPR3757_CA-MRSA NC_007793.1 Staphylococcus aureus ...
```
But the GFF3 column 1 still contained the original NCBI accession:
```
NC_007793.1    CDS    ...
```
First token of FASTA = `Saureus_USA300_FPR3757_CA-MRSA`
GFF3 column 1 = `NC_007793.1`
→ No match → no annotations displayed.

### Wrong Fix Attempted
The first attempted fix merged label and accession with an underscore:
```
>Saureus_USA300_FPR3757_CA-MRSA_NC_007793.1 description
```
and updated GFF3 col 1 to `Saureus_USA300_FPR3757_CA-MRSA_NC_007793.1`.

This was **still wrong** because for multi-sequence genomes (chromosome + plasmids),
all sequences got the same `LABEL_` prefix, producing ambiguous IDs. More importantly,
this approach contradicted the pattern used by the known-working reference dataset.

### Correct Resolution (from working CYP121_archive reference)
The correct FASTA/GFF3 pattern — confirmed from the working `CYP121_archive/mauve_input/`
reference data — is:

**FASTA:**
- **First sequence in each file:** `>LABEL ACCESSION description` (label + space + accession)
- **All subsequent sequences (plasmids, contigs):** `>ACCESSION description` (original, unmodified)

**GFF3:** Column 1 is **never modified** — it stays as the original NCBI accession.

This works because:
- Mauve uses `LABEL` (first token) as the display name for the genome lane
- For chromosome features: GFF3 col 1 = `NC_007793.1` = second token of first FASTA header = Mauve matches by scanning all sequence headers for a token match
- For plasmid features: GFF3 col 1 = `NC_007790.1` = first token of the plasmid FASTA header (unchanged) = exact match

The fix was implemented in `fix_fasta_gff3.py` (Python script, called via PowerShell).

### Lesson
**Study a known-working example before attempting any FASTA/GFF3 format fix.**
The matching rule in Mauve is: GFF3 col 1 must match *any* token in the corresponding
FASTA header, not necessarily the first. The correct labeling strategy is to prepend
the display name only to the first header line of each `.fna` file and leave all
downstream sequence headers and the GFF3 untouched.

---

## 12. XMFA File Must Contain `#AnnotationNFile` Headers for Auto-Loading

### Symptom
Even after fixing FASTA/GFF3 sequence ID matching, annotations still did not appear
when the XMFA was opened in Mauve.

### Root Cause
Mauve loads annotation tracks automatically only if the XMFA file itself contains
`#AnnotationNFile` and `#AnnotationNFormat` header lines pointing to the GFF3 files.
Without these entries, Mauve has no knowledge that GFF3 files exist — the student
would need to manually add each annotation track via right-click → "Add Sequence
Feature Track", which is error-prone and undocumented in classroom contexts.

The progressiveMauve binary (both Windows and Linux) does **not** write annotation
headers into the XMFA automatically — it only writes `#SequenceNFile` entries.
The annotation headers must be injected post-alignment.

### Discovery
The working `CYP121_archive` reference dataset contained `add-annotations.sh`, a
post-processing script that injected `#AnnotationNFile` entries into the XMFA.
This script was not part of the classroom pipeline.

### Resolution
Added XMFA annotation injection to the fix pipeline (`fix_xmfa.py`):
```python
# For each #SequenceNFile entry, find matching GFF3 and add:
anno_block.append(f'#Annotation{n}File\t{gff_filename}\n')
anno_block.append(f'#Annotation{n}Format\tGFF3\n')
# Insert before #BackboneFile
```

The correct XMFA header structure is:
```
#FormatVersion Mauve1
#Sequence1File    Saureus_MRSA252_HA-MRSA.fna
#Sequence1Format  FastA
...
#Annotation1File  Saureus_MRSA252_HA-MRSA.gff3
#Annotation1Format  GFF3
...
#BackboneFile     alignment.xmfa.bbcols
```

### Lesson
**progressiveMauve never writes annotation headers.** Annotation auto-loading in
Mauve depends entirely on `#AnnotationNFile` entries in the XMFA, which must be
injected as a post-processing step. Any pipeline producing classroom or shareable
alignment files must include this injection step. Bake it into the pipeline — do
not leave it as a manual student step.

---

## 13. XMFA `#SequenceNFile` Paths Are Absolute and Environment-Specific

### Symptom
After extracting the classroom zip on a student machine, Mauve opened the XMFA
but could not find the sequence files, showing a "file not found" warning.

### Root Cause
progressiveMauve writes the absolute path of each input genome into the XMFA header
at alignment time:
```
#Sequence1File    C:\Users\japodaca15\projectsClaude\mauve-classroom\saureus_mauve\mauve_input\Saureus_MRSA252_HA-MRSA.fna
```
This path does not exist on any student machine. Mauve then falls back to looking
for the file relative to the XMFA's current location, but only if the header path
fails AND the filename (without directory) is present in the same folder.

### Resolution
Updated all `#SequenceNFile` paths to just the filename:
```
#Sequence1File    Saureus_MRSA252_HA-MRSA.fna
```
Implemented in `fix_xmfa.py`:
```python
fname = os.path.basename(raw_path.replace('\\', '/'))
new_lines.append(f'#Sequence{n}File\t{fname}\n')
```
The zip packages all `.fna`, `.gff3`, and `alignment.xmfa*` files flat in one folder,
so bare filenames resolve correctly on any machine.

### Lesson
**Always strip absolute paths from XMFA headers before distribution.** progressiveMauve
bakes in the build machine's absolute paths. For any shared or distributed dataset,
post-process the XMFA to replace all `#SequenceNFile` paths with bare filenames, and
package all files flat (no subdirectories) in the distribution zip.

---

## 14. `#BackboneFile` Path Also Needs Updating

### Symptom
Related to §13 — the backbone coloring (block boundary colors) was not applied
correctly on student machines.

### Root Cause
Same issue: progressiveMauve writes an absolute path for `#BackboneFile`:
```
#BackboneFile    saureus_mauve/mauve_output/alignment.xmfa.bbcols
```
On a student machine the relative subdirectory `saureus_mauve/mauve_output/` does
not exist (the zip is flat).

### Resolution
Strip to bare filename in `fix_xmfa.py` and via sed:
```bash
sed -i 's|#BackboneFile\t.*[\\/]\([^\\/]*\)$|#BackboneFile\t\1|' "$xmfa"
```
Result:
```
#BackboneFile    alignment.xmfa.bbcols
```

### Lesson
Every file reference in the XMFA (`#SequenceNFile`, `#BackboneFile`, `#AnnotationNFile`)
must use bare filenames for portable distribution. Treat the XMFA as a manifest file
and audit every path in it before packaging.

---

## 15. Python Not Available as `python3` in Git Bash

### Symptom
`python3 fix_fasta_gff3.py` in Git Bash:
```
Python was not found; run without arguments to install from the Microsoft Store
```

### Root Cause
On this Windows setup, Python 3 is installed and on the Windows PATH as `python`
(not `python3`). Git Bash's `python3` shim redirects to the Microsoft Store stub
rather than the installed Python.

### Resolution
Use PowerShell to run Python scripts:
```bash
powershell.exe -Command "python C:\path\to\script.py"
```

### Lesson
On Windows, always test `python3 --version` vs `python --version` in the shell
you are using. In Git Bash, if `python3` fails, try `python`, or call Python
through `powershell.exe -Command "python ..."`.

---

## 16. WSL Path Mangling When Calling Python Directly

### Symptom
```bash
wsl.exe python3 /mnt/c/Users/japodaca15/projectsClaude/mauve-classroom/fix_fasta_gff3.py
```
Produced:
```
python3: can't open file '/mnt/c/Users/japodaca15/Downloads/mauve-master/.claude/C:/Program Files/Git/mnt/c/...'
```

### Root Cause
The Git Bash working directory's `.claude/` context was prepended to the path by
the shell before WSL received it. Git Bash's path translation was mangling the
argument before `wsl.exe` could process it.

### Resolution
Use PowerShell to call Python instead of WSL for Windows-filesystem Python scripts.
WSL Python is appropriate for scripts that live on the WSL filesystem (`~/`), not
for scripts on the Windows filesystem called from Git Bash via `wsl.exe`.

### Lesson
Do not use `wsl.exe python3 /mnt/c/...` from Git Bash for Windows-resident scripts —
path mangling is unpredictable. Either: (a) copy the script to the WSL home directory
and call it from there, or (b) use `powershell.exe -Command "python C:\..."` for
Windows-side scripts.

---

## Summary Table

| # | Issue | Where it hit | Fix |
|---|-------|-------------|-----|
| 1 | 7 wrong NCBI accessions | Download | Verify each with `datasets summary` before use |
| 2 | Gallinarum not in RefSeq | Download | Substitute Dublin CT_02021853 |
| 3 | `--assembly-source` missing | Download | Always add `--assembly-source all` |
| 4 | Windows progressiveMauve broken | Alignment | Use WSL bioconda binary (2022) |
| 5 | WSL base env boost ABI conflict | Alignment | Use dedicated `mauve` conda env |
| 6 | Invalid `--min-scaled-penalty` flag | Alignment | Remove flag; check `--help` |
| 7 | Git Bash PATH / .exe resolution | Shell | Use bare names; route via PowerShell |
| 8 | `gh` auth not in Git Bash keyring | Upload | Use `powershell.exe -Command "gh ..."` |
| 9 | `zip` not in Git Bash | Packaging | Use PowerShell `Compress-Archive` |
| 10 | PowerShell `$var` eaten by bash | Scripting | Write `.ps1` files; never inline PS in bash |
| 11 | GFF3 col 1 ≠ FASTA first token | Annotations | First header only gets label prepended; GFF3 unchanged |
| 12 | XMFA missing `#AnnotationNFile` | Annotations | Inject annotation headers post-alignment |
| 13 | XMFA `#SequenceNFile` absolute paths | Portability | Strip to bare filenames before distribution |
| 14 | XMFA `#BackboneFile` absolute path | Portability | Strip to bare filename |
| 15 | `python3` unavailable in Git Bash | Scripting | Use `powershell.exe -Command "python ..."` |
| 16 | WSL path mangling via Git Bash | Scripting | Don't call `wsl.exe python3 /mnt/c/...` from Git Bash |

---

*Document compiled from the Mauve classroom dataset build sprint, March 2026.
Cryptic Prophage Lab, UTEP.*
