# Neitz Lab - Retinal Stimulus Pipeline (Stage-VSS)

Master Control Panel and optimized stimulus scripts for Retinal Ganglion Cell experiments using the [Stage-VSS](https://github.com/Stage-VSS/stage) toolbox.

## Features
- **Master Control Panel (MCP)**: 4-tab GUI for Flicker, Full-Field Noise, Checkerboard, and Jittering Circle stimuli.
- **Clampex Integration**: Built-in toggle for automated gap-free recording start/stop via SendKeys (Ctrl+Shift+1).
- **Multi-Trial Support**: Configurable trial count, pre/post delays, and inter-trial intervals.
- **Stage-VSS Optimization**: All callbacks use precomputed lookup tables for reliable client/server serialization.
- **MATLAB 2016b Compatible**: Built using classic `figure`/`uicontrol` (no uifigure/App Designer).
- **Python Analysis**: Receptive field mapping via `CheckerboardSTA.py`.

## File Overview
| File | Description |
|------|-------------|
| `MasterControlPanel.m` | Main GUI application (4 tabs + Clampex controls) |
| `StartStageServer.m` | Launches Stage server on the projector monitor |
| `LaunchControlPanel.bat` | Windows shortcut to launch the GUI |
| `Experimenter5000.m` | Standalone trial-loop script (no GUI) |
| `AAGreyScaleFullFieldNoiseFinal2026.m` | Greyscale full-field flicker |
| `AASConeIsoFullFieldNoiseStimFinal2026.m` | S-cone isolating full-field flicker |
| `AASeededGaussianGreyScaleStimFinal2026.m` | Full-field greyscale Gaussian noise |
| `AASeededGaussianSConeIsoStimFinal2026.m` | Full-field S-cone iso Gaussian noise |
| `AASeededGaussianCheckerboardGreyScaleStimFinal.m` | Checkerboard greyscale noise |
| `AASeededGaussianCheckerboardSConeIsoStimFinal.m` | Checkerboard S-cone iso noise |
| `AAJitteringCircleStimulusFinal.m` | Jittering circle (Ornstein-Uhlenbeck walk) |
| `saveCheckerboardNoiseForAnalysis.m` | Exports noise sequence to .mat for Python |
| `CheckerboardSTA.py` | STA-based receptive field analysis |

## Quick Start
1. **Server MATLAB instance**: Run `StartStageServer` (Stage window opens on projector).
2. **Client MATLAB instance**: Run `MasterControlPanel` (or double-click `LaunchControlPanel.bat`).
3. Select a tab, adjust parameters, click **RUN**.

## Requirements
- MATLAB R2016b or later
- [Stage-VSS Toolbox](https://github.com/Stage-VSS/stage)
- Python 3.9+ with `numpy`, `scipy`, `neo` (for RF analysis only)
