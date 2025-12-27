# AXI4-Lite MAC Accelerator

## Overview
This project implements a custom Multiply–Accumulate (MAC) hardware accelerator controlled through an AXI4-Lite interface. The design demonstrates how a processor or master can configure and trigger a hardware datapath using memory-mapped registers.

## Key Features
- AXI4-Lite master and slave implementation
- Custom MAC datapath with accumulation
- Self-clearing START command bit
- STATUS register for completion signaling
- Row-based register addressing for simplicity
- Fully verified using a SystemVerilog testbench

## Architecture
- AXI master issues single read/write transactions
- AXI slave exposes a register file
- MAC unit operates independently from AXI logic
- Control and datapath are cleanly separated

The RTL Schematic is available in `results/RTL Schematic.png`.
The MAC unit is not visible in the RTL Schematic screenshot since it is instantiated inside the axi4_lite_slave module.

## Register Map
See `docs/register_map.md`

## Verification
The testbench performs:
- Three consecutive MAC operations with accumulation
- Independent read/write tests on non-MAC registers

Waveform screenshots are available in `results/`.

The details about what each waveform screenshot shows is available in `results/Waveform Details.txt`.

## Tools Used
- SystemVerilog
- Vivado

## Notes
This design treats the AXI address as a register index (row-based addressing), which is suitable for custom RTL-controlled systems. Byte addressing can be added if CPU integration is required.
