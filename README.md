# Communication System Simulations

MATLAB simulations for basic digital communications, spread-spectrum links (DSSS, FHSS), OFDM, and interference-signal generation/analysis.

## Overview

This repository collects teaching and research scripts for end-to-end communication-system experiments. Top-level `Sys_*.m` entry points provide simplified runs; `src/` and `systems/` hold modular building blocks.

## Scope

- Basic communication system simulation
- DSSS (direct-sequence spread spectrum)
- FHSS (frequency-hopping spread spectrum)
- OFDM
- Interference generation and analysis (single-tone, comb, noise-modulated, multi-tone, partial-band, sweep)

## Requirements

- MATLAB
- Signal Processing Toolbox
- Communications Toolbox (recommended for modulation / channel helpers)

## Getting started

Clone the repository, open MATLAB at the project root, and run a top-level script, for example:

```matlab
run('Sys_OFDM_SimpleSimulation.m')
run('Sys_DSSS_SimpleSimulation.m')
run('Sys_FHSS_SimpleSimulation.m')
run('Sys_SimpleSimulation.m')
```

Add `src/` to the path if a script expects modular helpers:

```matlab
addpath(genpath('src'));
addpath(genpath('systems'));
```

## Project layout

```text
.
├── Sys_SimpleSimulation.m
├── Sys_OFDM_SimpleSimulation.m
├── Sys_DSSS_SimpleSimulation.m
├── Sys_FHSS_SimpleSimulation.m
├── src/
│   ├── modulation/
│   ├── interference/
│   └── utils/
├── systems/
│   ├── basic/
│   └── anti_jamming/
├── test/
├── docs/
└── RefCode/
```

## Interference dataset notes

When interference samples are exported as CSV, the documented conventions are:

| Folder | Type |
|--------|------|
| `single_tone/` | Single-tone |
| `comb/` | Comb spectrum |
| `noise_mod/` | Noise-modulated |
| `multi_tone/` | Multi-tone |
| `partial_band/` | Partial-band noise |
| `sweep/` | Frequency sweep |

- Filename pattern: `sample_XXXX.csv`
- First row: parameter metadata (type-specific; see original notes for field order)
- Remaining rows: real and imaginary parts of the sample
- Typical sampling: 1 MHz for 1 ms; about 1000 samples per class when a full set is generated

Confirm paths and whether datasets are committed or regenerated locally before assuming files exist on disk.

## Status / limitations

Academic simulation code. There is no open-source LICENSE file in this repository. The author retains copyright; intended use is academic research and education. Commercial use requires explicit written permission. The author is not liable for damages arising from use of this code.

## Author

Asaqe Lee
