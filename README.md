
<!-- ============================================================
     APB Module — README.md
     Dark-theme optimised · GitHub Markdown
     ============================================================ -->

<div align="center">

# 🔌 APB Master–Slave Module

[![License: MIT](https://img.shields.io/badge/License-MIT-7c3aed?style=for-the-badge)](LICENSE)
[![Protocol](https://img.shields.io/badge/Protocol-AMBA%20APB-06b6d4?style=for-the-badge)](https://developer.arm.com/documentation/ihi0024)
[![Bus Width](https://img.shields.io/badge/Bus%20Width-32--bit-22c55e?style=for-the-badge)](#signal-reference)
[![Status](https://img.shields.io/badge/Status-Stable-f59e0b?style=for-the-badge)](#)

**A fully compliant AMBA APB (Advanced Peripheral Bus) Master–Slave implementation in RTL.**  
Supports single read/write transactions with a 4-state FSM controller and zero-wait-state slave response.

</div>

---

## 📐 Architecture Overview

```
                        ┌─────────────────────┐
                        │   System Clock/Reset │
                        │    PCLK / PRESETn    │
                        └────────┬─────┬───────┘
                     PCLK/PRESETn│     │PCLK/PRESETn
                ┌────────────────▼─┐ ┌─▼────────────────────┐
                │    APB MASTER    │ │      APB SLAVE        │
                │   (apb_master)   │ │     (apb_slave)       │
                │                  │ │                       │
  Inputs ──────►│ PCLK    PRESETn  │ │ PCLK     PRESETn ◄── │
  PRDATA[31:0] ►│ PRDATA[31:0]     │ │ PSEL               ◄─┤◄── PSEL
  PREADY ──────►│ PREADY           │ │ PENABLE            ◄─┤◄── PENABLE
                │                  │ │ PWRITE             ◄─┤◄── PWRITE
                │  ┌─────────────┐ │ │ PADDR[31:0]        ◄─┤◄── PADDR
                │  │     FSM     │ │ │ PWDATA[31:0]       ◄─┤◄── PWDATA
                │  │IDLE→SETUP   │ │ │                       │
                │  │→ACCESS→DONE │ │ │  ┌───────────────┐   │
                │  └─────────────┘ │ │  │ DATA[31:0]    │   │
                │                  │ │  │  (register)   │   │
  Outputs ◄─────┤ PSEL             │ │  └───────────────┘   │
  PENABLE ◄─────┤ PENABLE          │ │                       │
  PWRITE  ◄─────┤ PWRITE      ────►│►── PRDATA[31:0]        │──► PRDATA
  PADDR   ◄─────┤ PADDR[31:0] ────►│►── PREADY=1            │──► PREADY
  PWDATA  ◄─────┤ PWDATA[31:0]     │ │  PSLVERR=0           │──► PSLVERR
                └──────────────────┘ └───────────────────────┘
```

---

## 📦 Modules

### `apb_master`

The APB Master drives all bus transactions. It contains a 4-state FSM that orchestrates the AMBA APB protocol handshake — asserting `PSEL` in SETUP and `PENABLE` in ACCESS, then waiting for `PREADY` before completing the transfer.

### `apb_slave`

The APB Slave contains a single 32-bit internal data register (`DATA[31:0]`). It responds immediately with `PREADY = 1` (zero wait states) and asserts `PSLVERR = 0` indicating no bus error.

---

## 🔄 Master FSM

The master implements a classic 4-state AMBA APB state machine:

```
             ┌────────────────────────────────────────────────┐
  reset ───► │                                                │
             ▼                                                │
          ┌──────┐   PSEL=1, PWRITE=1     ┌───────┐          │
          │ IDLE │ ──────────────────────► │ SETUP │          │
          └──────┘   PADDR=0, PWDATA=10   └───┬───┘          │
                                              │               │
                                  PENABLE=1   │               │
                                              ▼               │
          ┌──────┐   PREADY & PWRITE=0   ┌────────┐          │
          │ DONE │ ◄───────────────────── │ ACCESS │          │
          └──┬───┘                        └────┬───┘          │
             │                                │               │
             │  PSEL=0, PENABLE=0 (self-loop) │ PREADY &      │
             └────────────────────────────────┘ PWRITE=1      │
                                               │               │
                                               └──────────────►┘
                                            (write → read, back to SETUP)
```

| State | Description |
|-------|-------------|
| **IDLE** | Bus idle. Waiting for a transaction request. |
| **SETUP** | `PSEL` asserted. Address, write data, and direction placed on bus. |
| **ACCESS** | `PENABLE` asserted. Transfer in progress. Awaiting `PREADY`. |
| **DONE** | Transaction complete. `PSEL` and `PENABLE` de-asserted. |

---

## 📡 Signal Reference

### APB Master

#### Inputs

| Signal | Width | Description |
|--------|-------|-------------|
| `PCLK` | 1-bit | Bus clock — all signals synchronous to rising edge |
| `PRESETn` | 1-bit | Active-low synchronous reset |
| `PRDATA` | 32-bit | Read data returned by the slave |
| `PREADY` | 1-bit | Slave ready signal — extends the ACCESS phase when low |

#### Outputs

| Signal | Width | Description |
|--------|-------|-------------|
| `PSEL` | 1-bit | Slave select — asserted in SETUP and ACCESS phases |
| `PENABLE` | 1-bit | Enable — asserted only in the ACCESS phase |
| `PWRITE` | 1-bit | Transfer direction: `1` = Write, `0` = Read |
| `PADDR` | 32-bit | Target address on the peripheral bus |
| `PWDATA` | 32-bit | Write data driven by the master |

---

### APB Slave

#### Inputs

| Signal | Width | Description |
|--------|-------|-------------|
| `PCLK` | 1-bit | Bus clock |
| `PRESETn` | 1-bit | Active-low synchronous reset |
| `PSEL` | 1-bit | Slave selected when high |
| `PENABLE` | 1-bit | Second-phase enable signal |
| `PWRITE` | 1-bit | `1` = Write, `0` = Read |
| `PADDR` | 32-bit | Address from master |
| `PWDATA` | 32-bit | Write data from master |

#### Outputs

| Signal | Width | Description |
|--------|-------|-------------|
| `PRDATA` | 32-bit | Read data returned to master |
| `PREADY` | 1-bit | Always `1` — zero wait-state slave |
| `PSLVERR` | 1-bit | Always `0` — no bus error |

#### Internal

| Register | Width | Description |
|----------|-------|-------------|
| `DATA` | 32-bit | General-purpose data register (read/write via APB) |

---

## ⚡ Transaction Timing

### Write Transaction

```
         ──┬──────────────┬──────────────┬──────────────┬──
  PCLK  ___│‾‾‾‾‾‾‾‾‾‾‾‾‾│‾‾‾‾‾‾‾‾‾‾‾‾‾│‾‾‾‾‾‾‾‾‾‾‾‾‾│__
           │   (IDLE)     │   (SETUP)    │   (ACCESS)   │(DONE)
  PSEL  ___│______________│‾‾‾‾‾‾‾‾‾‾‾‾‾│‾‾‾‾‾‾‾‾‾‾‾‾‾│___
  PENABLE _│______________│_____________│‾‾‾‾‾‾‾‾‾‾‾‾‾│___
  PWRITE __│______________│‾‾‾‾‾‾‾‾‾‾‾‾‾│‾‾‾‾‾‾‾‾‾‾‾‾‾│___
  PADDR  __│______________│════ADDR═════│════ADDR═════│___
  PWDATA __│______________│════DATA═════│════DATA═════│___
  PREADY __│______________│_____________│‾‾‾‾‾‾‾‾‾‾‾‾‾│___
```

### Read Transaction

```
         ──┬──────────────┬──────────────┬──────────────┬──
  PCLK  ___│‾‾‾‾‾‾‾‾‾‾‾‾‾│‾‾‾‾‾‾‾‾‾‾‾‾‾│‾‾‾‾‾‾‾‾‾‾‾‾‾│__
           │   (IDLE)     │   (SETUP)    │   (ACCESS)   │(DONE)
  PSEL  ___│______________│‾‾‾‾‾‾‾‾‾‾‾‾‾│‾‾‾‾‾‾‾‾‾‾‾‾‾│___
  PENABLE _│______________│_____________│‾‾‾‾‾‾‾‾‾‾‾‾‾│___
  PWRITE __│______________│_____________│_____________│___
  PADDR  __│______________│════ADDR═════│════ADDR═════│___
  PREADY __│______________│_____________│‾‾‾‾‾‾‾‾‾‾‾‾‾│___
  PRDATA __│______________│_____________│════DATA═════│___
```

---

## 🗂️ File Structure

```
apb_module/
├── rtl/
│   ├── apb_master.v        # APB Master — FSM + signal driver
│   └── apb_slave.v         # APB Slave  — register + ready logic
├── tb/
│   ├── apb_tb.v            # Top-level testbench
│   └── apb_monitor.v       # Bus monitor / assertions
├── docs/
│   └── apb_diagram.drawio  # Block diagram source
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- Any IEEE 1364-2001 / SystemVerilog compatible simulator (ModelSim, VCS, Verilator, Icarus Verilog)
- GTKWave (optional, for waveform viewing)

### Simulation (Icarus Verilog)

```bash
# Compile
iverilog -o apb_sim rtl/apb_master.v rtl/apb_slave.v tb/apb_tb.v

# Run simulation
vvp apb_sim

# View waveforms
gtkwave dump.vcd
```

---

## 📏 Protocol Compliance

This module is designed to comply with the **ARM AMBA APB Protocol Specification (IHI0024)**.

| Rule | Compliance |
|------|-----------|
| PSEL asserted one cycle before PENABLE | ✅ |
| PENABLE held until PREADY is sampled | ✅ |
| Address/data stable throughout SETUP + ACCESS | ✅ |
| PREADY = 1 (zero wait states) | ✅ |
| PSLVERR = 0 (no error response) | ✅ |

---

## 📜 License

This project is released under the [MIT License](LICENSE).

---

<div align="center">
<sub>Built with ❤️ for hardware designers · AMBA APB Protocol · 32-bit Bus</sub>
</div>
