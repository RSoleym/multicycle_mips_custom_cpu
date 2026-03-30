# Quartus datapath bring-up

This folder contains an earlier datapath-only bring-up package that predates the full CPU integration. It is useful as a milestone artifact showing subsystem-level verification before the complete CPU project.

## Layout
- `src/` : datapath and supporting RTL
- `project/` : Quartus project files
- `waveforms/` : waveform-based checks for individual operations
- `docs/` : datapath control spreadsheet
- `reports/` : selected Quartus summary reports

## Device info from the Quartus project file
- Family: Cyclone V
- Top-level entity: `datapath_top`
