# Vending Machine Controller (Verilog RTL)

This project implements a configurable vending machine controller using Verilog RTL, based on an industry-style IP specification.  
It models real vending machine behavior with dynamic item configuration, asynchronous user inputs, and cycle-accurate dispensing operations.  
The architecture is modular, parameterized, and designed for efficient integration and expansion.

---

## Features

- Supports up to **1024 configurable items**
- **APB-style configuration interface** operating on a 50 MHz configuration clock
- Main controller runs on a **100 MHz system clock** for real-time decision making
- Handles **asynchronous currency and item selections** (10 kHz – 50 MHz input rates)
- **Dispense latency < 10 clock cycles** after valid currency insertion
- **Returns change** for overpaid transactions
- Modular, scalable, and clean RTL architecture

---

## Operating Modes

### Reset Mode
- Initializes internal memories and registers to default reset values

### Configuration Mode
- Loads item data via APB-style interface:
  - Item count
  - Item price
  - Available quantity
- Clears dispensed history and updates configuration memory

### Operation Mode
- Accepts item selection and currency inputs
- Computes total inserted value and compares with item price
- Dispenses the item and returns change when applicable
- Ensures vending decision in under 10 system clock cycles

---

## Module Overview

| Module Name            | Description                                                                 |
|------------------------|-----------------------------------------------------------------------------|
| `main_controller`      | Finite State Machine managing mode transitions and overall vending sequence |
| `config_module`        | APB-style configuration loader handling item setup and availability init    |
| `currency_input`       | Tracks and accumulates inserted currency, validates inputs, resets post-dispense |
| `item_selection`       | Captures selected item and quantity, ensures valid selection and availability |
| `output_info`          | Generates dispense signals, calculates change, and reports status            |
| `pulse_sync`           | Synchronizes asynchronous external inputs to the system clock                |
| `vending_machine_top`  | Integrates all submodules and coordinates memory and signaling paths         |

---
