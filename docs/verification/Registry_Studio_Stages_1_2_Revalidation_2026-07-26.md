# Registry Studio — Stage 1–2 Revalidation

Date:

```text
2026-07-26
```

Branch:

```text
registry-studio/translator-first-rebuild
```

Accepted Stage 1–2 source checkpoint:

```text
7acaac740f87b6e90f564c56e052f1a7032f9b77
```

Source tree:

```text
68fb74ae62be24167049f0276787f91cecc8b707
```

## Automated validation

Environment:

```text
Termux
Android ARM64 / aarch64
Flutter 3.41.4
Flutter bundled Dart 3.11.1
```

Results:

```text
flutter test:       132/132 PASS
flutter analyze:    PASS
git diff --check:   PASS
working tree:       CLEAN
```

Automated evidence archive:

```text
registry_studio_stage12_revalidation_20260726T051811Z.tar.gz
SHA-256:
ca6e4a4e7cdede0700b505116d671fb5346f4317660cf13d76f4e097d5f9bd1f
```

## APK validation

GitHub Actions:

```text
Workflow: Build APK
Run:      #381
Commit:   7acaac740f87b6e90f564c56e052f1a7032f9b77
Result:   PASS
```

The APK was installed as a clean application installation.

## Physical Android acceptance

Verified on the target Android device:

```text
application start:              PASS
Registry load:                  PASS
Registry nodes:                 534
terminal/content filter:        473
exact Registry search:          PASS
exact result opening:           PASS
RegistryPath display:           PASS
SourceEvidence display:         PASS
filter restore after restart:   PASS
search restore after restart:   PASS
open block restore:             PASS
refresh context preservation:   PASS
Translator tab switching:       PASS
ANR during acceptance scenario: NO
crash during acceptance:        NO
```

Verified search target:

```text
Architecture Freeze Decision
```

Verified exact location:

```text
Helpy Architecture Registry v1 Foundation
→ Architecture Freeze Decision
```

Verified evidence range:

```text
docs/architecture/Helpy_Architecture_Registry_v1.md
lines 198–257
```

## Decision

```text
STAGE_1=REVALIDATED_AND_ACCEPTED
STAGE_2=REVALIDATED_AND_ACCEPTED
TRANSLATOR_FIRST_REBUILD_BASELINE=APPROVED
```

Stage 1–2 production behavior must not be modified without a separate
evidence-backed requirement, explicit diff budget and regression validation.
