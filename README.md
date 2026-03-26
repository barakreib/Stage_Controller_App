# Neitz Lab - Retinal Stimulus Pipeline (Stage-VSS)

This repository contains the Master Control Panel and optimized stimulus scripts for Retinal Ganglion Cell experiments using the Stage-VSS toolbox.

## Features
- **Master Control Panel (MCP)**: Unified GUI for triggering Flicker, Full Field Noise, and Checkerboard stimuli.
- **Stage-VSS Optimization**: All scripts use precomputed lookup tables to ensure reliable serialization and playback on remote Stage servers.
- **MATLAB 2016b Compatible**: Built using classic `figure`/`uicontrol` for stability.
- **Python Integration**: Built-in support for Receptive Field (RF) analysis using `CheckerboardSTA.py`.

## Contents
- `MasterControlPanel.m`: Main GUI application.
- `StartStageServer.m`: Automates server launch on the projector monitor.
- `AA*Stim*.m`: Parameterized stimulus scripts (Flicker, Noise, Checkerboard).
- `CheckerboardSTA.py`: Python script for STA-based RF analysis.
- `LaunchControlPanel.bat`: Shortcut to launch the GUI from Windows.

## Installation & Setup
Please refer to the [Deployment Guide](deploy_guide.md) for detailed instructions on setting up a new computer.

## Requirements
- MATLAB R2016b or later
- Stage-VSS Toolbox
- Python 3.9+ (for analysis)
