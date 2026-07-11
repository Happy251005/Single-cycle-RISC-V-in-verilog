# Single-cycle RISC-V in Verilog

A single-cycle RV32I processor implemented in Verilog, following the classic
Patterson–Hennessy datapath/control organization. One module per datapath
block, wired together in `top.v`, with a self-checking testbench covering
every supported instruction.

## Architecture

Follows the standard single-cycle RV32I datapath from *Computer
Organization and Design (RISC-V Edition)* by Patterson & Hennessy — one
module per datapath block, wired together in `top.v`.

Each block is its own module:

| File               | Block                                   |
|--------------------|------------------------------------------|
| `top.v`            | Top-level wiring                          |
| `program_counter.v`| PC register                               |
| `pcAdd4.v`          | PC + 4 adder                              |
| `addr.v`            | Branch target adder (PC + immediate)      |
| `instr_mem.v`       | Instruction memory                        |
| `reg_file.v`        | 32×32 register file, x0 hardwired to 0    |
| `immGen.v`          | Immediate generator (I/S/SB types)        |
| `control_unit.v`    | Main control (opcode → control signals)   |
| `ALU_control.v`     | ALU op decode (ALUop/funct3/funct7 → ALU control)|
| `ALU_unit.v`        | ALU (AND/OR/ADD/SUB + zero flag)          |
| `mux_2to1.v`         | Generic 2:1 mux (ALU src, PC src, WB src) |
| `and_gate.v`         | Branch-taken gate (zero & branch)         |
| `data_memory.v`      | Data memory (word-addressed)              |
| `tb_top.v`           | Self-checking testbench                   |

## Supported instructions

| Type | Instructions |
|------|--------------|
| R-type | `add`, `sub`, `and`, `or` |
| I-type ALU | `addi` |
| Load/Store | `lw`, `sw` |
| Branch | `beq` |

**Not yet implemented:** `jal`/`jalr`, `lui`/`auipc`, `slt`/`sltu`, shifts (`sll`/`srl`/`sra`), `xor`, `andi`/`ori`, and the other branch types (`bne`, `blt`, `bge`, `bltu`, `bgeu`). This is intentionally a minimal single-cycle core covering the base arithmetic/load-store/branch path, not a full RV32I implementation.

## Building and running the testbench

Requires [Icarus Verilog](http://bleyer.org/icarus/) (`iverilog`/`vvp` on your PATH).

```sh
iverilog -o sim.out top.v tb_top.v ALU_control.v ALU_unit.v addr.v and_gate.v control_unit.v data_memory.v immGen.v instr_mem.v mux_2to1.v pcAdd4.v program_counter.v reg_file.v
vvp sim.out
```

`tb_top.v` runs a 16-instruction program exercising every supported
instruction — including a negative-immediate `addi`, a taken `beq`, and a
not-taken `beq` — and checks the final register file and data memory
contents against expected values. Expect to see:

```
---- FINAL REGISTER / MEMORY CHECK ----
PASS:   x1 (x1) = 10
PASS:   x2 (x2) = 20
...
PASS:   m0 (mem[0]) = 30

RESULT: ALL TESTS PASSED
```

Any `FAIL` line names the register/memory location, the value the sim
produced, and what was expected.

## Notable fix

`ALU_control.v` originally used `instruction[30]` directly as a `funct7`
bit to distinguish `add` from `sub`. That's only valid for R-type
instructions — for I-type ALU ops (`addi`) bit 30 is actually
`immediate[10]`, not a funct7 field. As a result, any `addi` with a
negative immediate (or magnitude ≥ 1024) was silently executed as a
subtraction instead of an addition. Fixed by gating the funct7 check on
whether the instruction is actually R-type (`opcode[5]`, wired in from
`top.v` as `is_Rtype`). The testbench's negative-immediate `addi` test
case (`x6`) exists specifically to catch a regression of this bug.

## Known limitations

- Single-cycle only — no pipelining, no hazard/forwarding logic (not
  needed at single-cycle, but also not a stepping stone to a pipelined
  version as-is).
- Instruction/data memories are small simulation-only arrays (64 words),
  not intended to model real memory-mapped I/O or a full address space.
- Testbench covers one directed instruction sequence; not a randomized
  or coverage-driven verification environment.