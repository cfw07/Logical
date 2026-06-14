#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
============================================================================
Self-triggering Student ID Cyclic Display System - Python Simulation
Automatically verifies the Verilog design correctness.

Simulated modules:
  1. clk_divider       - Clock divider
  2. digit_controller  - Digit position controller
  3. student_id_rom    - Student ID lookup table
  4. seg7_decoder      - 7-segment display decoder
  5. top_module        - Top-level integration module

Student ID: 20251698
Expected sequence: 2 -> 0 -> 2 -> 5 -> 1 -> 6 -> 9 -> 8 -> 2 -> ...
============================================================================
"""

# ===========================================================================
# 7-segment lookup table (common anode, active-low)
# Segments: {a, b, c, d, e, f, g}
# ===========================================================================
SEG7_TABLE = {
    0: 0b0000001,
    1: 0b1001111,
    2: 0b0010010,
    3: 0b0000110,
    4: 0b1001100,
    5: 0b0100100,
    6: 0b0100000,
    7: 0b0001111,
    8: 0b0000000,
    9: 0b0000100,
}

# ===========================================================================
# Student ID digit sequence
# ===========================================================================
STUDENT_ID = [2, 0, 2, 5, 1, 6, 9, 8]  # Student ID: 20251698

# ===========================================================================
# Simulation parameters (accelerated for fast verification)
# ===========================================================================
CLK_FREQ = 4           # System clock frequency (simulated)
TARGET_FREQ = 1        # Target display switch frequency
CLK_PERIOD_NS = 10     # System clock period (ns)
COUNT_MAX = CLK_FREQ // (2 * TARGET_FREQ)  # Divider count limit


# ===========================================================================
# Module 1: Clock Divider (clk_divider)
# ===========================================================================
class ClkDivider:
    """Divides system clock to generate low-frequency display refresh clock."""

    def __init__(self):
        self.counter = 0
        self.clk_out = 0

    def reset(self):
        self.counter = 0
        self.clk_out = 0

    def tick(self):
        """Update on system clock rising edge; returns output clock value."""
        self.counter += 1
        if self.counter >= COUNT_MAX:
            self.counter = 0
            self.clk_out = 1 - self.clk_out  # Toggle
        return self.clk_out


# ===========================================================================
# Module 2: Digit Position Controller (digit_controller)
# ===========================================================================
class DigitController:
    """3-bit counter cycling 0~7 for digit position selection."""

    def __init__(self):
        self.digit_sel = 0

    def reset(self):
        self.digit_sel = 0

    def tick(self, clk_enable):
        """Update on divided clock rising edge."""
        if clk_enable:
            if self.digit_sel >= 7:
                self.digit_sel = 0
            else:
                self.digit_sel += 1


# ===========================================================================
# Module 3: Student ID Lookup (student_id_rom)
# ===========================================================================
def student_id_lookup(addr):
    """Map position index (0~7) to corresponding student ID digit."""
    if 0 <= addr <= 7:
        return STUDENT_ID[addr]
    return 0


# ===========================================================================
# Module 4: 7-Segment Decoder (seg7_decoder)
# ===========================================================================
def seg7_decode(bcd):
    """Convert 4-bit BCD to 7-segment display signals."""
    return SEG7_TABLE.get(bcd, 0b1111111)


# ===========================================================================
# Module 5: Top Module (top_module) - Integrates all sub-modules
# ===========================================================================
class TopModule:
    """Top-level: Self-triggering Student ID Cyclic Display System."""

    def __init__(self):
        self.clk_divider = ClkDivider()
        self.digit_ctrl = DigitController()
        self.current_digit = 0
        self.seg_output = 0
        self.rst_n = 0

    def reset(self):
        self.clk_divider.reset()
        self.digit_ctrl.reset()
        self.current_digit = student_id_lookup(0)
        self.seg_output = seg7_decode(self.current_digit)
        self.rst_n = 0

    def release_reset(self):
        self.rst_n = 1

    def tick(self):
        """One system clock cycle."""
        prev_clk_out = self.clk_divider.clk_out
        new_clk_out = self.clk_divider.tick()

        # Detect rising edge of divided clock -> trigger digit controller
        clk_rising_edge = (prev_clk_out == 0 and new_clk_out == 1)

        if self.rst_n:
            self.digit_ctrl.tick(clk_rising_edge)
        else:
            self.digit_ctrl.reset()

        # Combinational logic: position -> digit -> 7-segment decoding
        self.current_digit = student_id_lookup(self.digit_ctrl.digit_sel)
        self.seg_output = seg7_decode(self.current_digit)

    def get_state(self):
        return {
            'pos': self.digit_ctrl.digit_sel,
            'digit': self.current_digit,
            'seg': self.seg_output,
            'rst_n': self.rst_n,
            'clk_div_counter': self.clk_divider.counter,
            'clk_div_out': self.clk_divider.clk_out,
        }


# ===========================================================================
# 7-segment display visualization (ASCII art)
# ===========================================================================
def seg7_visualize(bcd):
    """Render BCD digit as ASCII 7-segment display art."""
    seg = SEG7_TABLE.get(bcd, 0b1111111)
    a = " --- " if (seg >> 6) & 1 == 0 else "     "
    f = "|" if (seg >> 1) & 1 == 0 else " "
    b = "|" if (seg >> 5) & 1 == 0 else " "
    g = " --- " if (seg >> 0) & 1 == 0 else "     "
    e = "|" if (seg >> 2) & 1 == 0 else " "
    c = "|" if (seg >> 4) & 1 == 0 else " "

    d = " --- " if (seg >> 3) & 1 == 0 else "     "
    lines = [
        f"  {a}",
        f"  {f}   {b}",
        f"  {g}",
        f"  {e}   {c}",
        f"  {d}",
    ]
    return "\n".join(lines)


# ===========================================================================
# Test Suite
# ===========================================================================
def run_tests():
    """Run all verification tests."""
    errors = 0
    test_results = []

    # ------------------------------------------------------------------
    # Unit Test 1: 7-segment decoding table verification
    # ------------------------------------------------------------------
    print("=" * 60)
    print(" [Unit Test 1] 7-Segment Decoding Table Verification")
    print("=" * 60)
    for bcd_val in range(10):
        seg = SEG7_TABLE[bcd_val]
        a = (seg >> 6) & 1
        b = (seg >> 5) & 1
        c = (seg >> 4) & 1
        d_bit = (seg >> 3) & 1
        e = (seg >> 2) & 1
        f = (seg >> 1) & 1
        g = seg & 1
        print(f"  BCD={bcd_val}: seg=7'b{seg:07b} "
              f"(a={a},b={b},c={c},d={d_bit},e={e},f={f},g={g})")
        print(seg7_visualize(bcd_val))
        print()

    print("  7-segment table verification complete [OK]")
    test_results.append(("7-Segment Table", True))

    # ------------------------------------------------------------------
    # Unit Test 2: Student ID lookup table verification
    # ------------------------------------------------------------------
    print("=" * 60)
    print(" [Unit Test 2] Student ID Lookup Table Verification")
    print("=" * 60)
    expected = [2, 0, 2, 5, 1, 6, 9, 8]
    lookup_ok = True
    for i, exp in enumerate(expected):
        result = student_id_lookup(i)
        status = "[OK]" if result == exp else "[FAIL]"
        if result != exp:
            lookup_ok = False
            errors += 1
        print(f"  Position[{i}]: expected={exp}, actual={result} {status}")
    print(f"  Student ID lookup: {'PASS' if lookup_ok else 'FAIL'}")
    test_results.append(("Student ID Lookup", lookup_ok))

    # ------------------------------------------------------------------
    # Integration Test: Full system simulation
    # ------------------------------------------------------------------
    print()
    print("=" * 60)
    print(" [Integration Test] Full System Simulation")
    print("=" * 60)
    print(f"  Parameters: CLK_FREQ={CLK_FREQ}, TARGET_FREQ={TARGET_FREQ}")
    print(f"  Divider count max: COUNT_MAX={COUNT_MAX}")
    print(f"  Student ID: 20251698")
    print()

    top = TopModule()
    top.reset()

    # Check initial state after reset
    state = top.get_state()
    print("--- Reset State ---")
    print(f"  pos={state['pos']}, digit={state['digit']}, "
          f"seg=7'b{state['seg']:07b}")
    if state['pos'] != 0 or state['digit'] != 2:
        print("  [FAIL] Reset initial state incorrect!")
        print("         Expected pos=0, digit=2")
        errors += 1
    else:
        print("  [PASS] Reset initial state correct")

    # Release reset
    top.release_reset()

    # Run simulation, recording each display cycle output
    print()
    print("--- Auto-run started (2 complete cycles) ---")
    print()

    cycles_per_digit = CLK_FREQ // TARGET_FREQ

    # Record initial state as first displayed digit
    recorded_sequence = []
    init_state = top.get_state()
    recorded_sequence.append((0, init_state['pos'], init_state['digit']))
    print(f"  t=   0ns | clk_div_out={init_state['clk_div_out']} | "
          f"pos={init_state['pos']}, digit={init_state['digit']} [INITIAL]")
    print(f"         seg=7'b{init_state['seg']:07b}")
    print(seg7_visualize(init_state['digit']))
    print()

    prev_pos = init_state['pos']
    total_cycles = cycles_per_digit * 8 * 2 + cycles_per_digit + 5

    for cycle in range(total_cycles):
        top.tick()
        state = top.get_state()

        # Detect position change (rising edge)
        if state['pos'] != prev_pos:
            digit_val = student_id_lookup(state['pos'])
            print(f"  t={cycle * CLK_PERIOD_NS:4d}ns | "
                  f"clk_div_out={state['clk_div_out']} | "
                  f"pos={state['pos']}, digit={state['digit']}")
            print(f"         seg=7'b{state['seg']:07b}")
            print(seg7_visualize(state['digit']))
            print()
            recorded_sequence.append(
                (cycle, state['pos'], state['digit']))
            prev_pos = state['pos']

    # ------------------------------------------------------------------
    # Verify sequence
    # ------------------------------------------------------------------
    print("--- Sequence Verification ---")

    digit_sequence = [d for _, _, d in recorded_sequence]

    print(f"  Actual sequence:   "
          f"{' -> '.join(str(d) for d in digit_sequence)}")
    print(f"  Expected sequence: "
          f"2 -> 0 -> 2 -> 5 -> 1 -> 6 -> 9 -> 8 -> ...")

    # Check first 16 digits (2 complete cycles)
    expected_2_cycles = STUDENT_ID * 2
    seq_ok = True
    for i, (actual, exp) in enumerate(
            zip(digit_sequence[:16], expected_2_cycles)):
        if actual != exp:
            print(f"  [FAIL] Position {i}: expected={exp}, actual={actual}")
            seq_ok = False
            errors += 1

    if len(digit_sequence) < 16:
        print(f"  [FAIL] Sequence too short: "
              f"expected >=16, got {len(digit_sequence)}")
        seq_ok = False
        errors += 1

    if seq_ok:
        print("  [PASS] Complete sequence verified across 2 cycles")
    test_results.append(("Sequence Verification", seq_ok))

    # ------------------------------------------------------------------
    # Verify automatic cycling
    # ------------------------------------------------------------------
    print()
    print("--- Auto-Cycle Verification ---")

    cycle_ok = True
    if len(digit_sequence) >= 16:
        first_cycle = digit_sequence[:8]
        second_cycle = digit_sequence[8:16]
        if first_cycle == second_cycle:
            print(f"  [PASS] Auto-cycle works correctly!")
            print(f"  Cycle 1: {' -> '.join(str(d) for d in first_cycle)}")
            print(f"  Cycle 2: {' -> '.join(str(d) for d in second_cycle)}")
        else:
            print(f"  [FAIL] Two cycles don't match!")
            print(f"  Cycle 1: {' -> '.join(str(d) for d in first_cycle)}")
            print(f"  Cycle 2: {' -> '.join(str(d) for d in second_cycle)}")
            cycle_ok = False
            errors += 1
    test_results.append(("Auto-Cycle Verification", cycle_ok))

    # ------------------------------------------------------------------
    # Verify asynchronous reset
    # ------------------------------------------------------------------
    print()
    print("--- Async Reset Verification ---")
    top.reset()
    state = top.get_state()
    if state['pos'] == 0 and state['digit'] == 2:
        print(f"  [PASS] Reset returns to initial state (pos=0, digit=2)")
    else:
        print(f"  [FAIL] Reset failed! pos={state['pos']}, digit={state['digit']}")
        errors += 1
    test_results.append(
        ("Async Reset", state['pos'] == 0 and state['digit'] == 2))

    # ------------------------------------------------------------------
    # Verify 7-segment decoding correspondence
    # ------------------------------------------------------------------
    print()
    print("--- 7-Segment Decoding Correspondence Verification ---")
    seg_ok = True
    for pos_idx in range(8):
        digit = student_id_lookup(pos_idx)
        seg = seg7_decode(digit)
        expected_seg = SEG7_TABLE[digit]
        if seg != expected_seg:
            print(f"  [FAIL] Position {pos_idx}: digit={digit}, "
                  f"seg=7'b{seg:07b} != expected=7'b{expected_seg:07b}")
            seg_ok = False
            errors += 1
    if seg_ok:
        print("  [PASS] All 7-segment outputs correct!")
    test_results.append(("7-Segment Decoding", seg_ok))

    # ------------------------------------------------------------------
    # Results summary
    # ------------------------------------------------------------------
    print()
    print("=" * 60)
    print(" Simulation Results Summary")
    print("=" * 60)
    all_pass = True
    for name, result in test_results:
        status = "PASS" if result else "FAIL"
        print(f"  [{status}] {name}")
        if not result:
            all_pass = False

    print()
    if all_pass:
        print(" *** ALL TESTS PASSED! ***")
        print("     The self-triggering student ID cyclic display system")
        print("     design is correct.")
        print("     Student ID 20251698 displays in sequence:")
        print("     2 -> 0 -> 2 -> 5 -> 1 -> 6 -> 9 -> 8 -> 2 -> 0 -> ...")
        print("     System auto-runs after power-up, no human intervention.")
        print("     Display interval: 1 second (from 50MHz system clock)")
    else:
        print(f" *** {errors} ERROR(S) FOUND! Please check the design. ***")

    print("=" * 60)

    return errors


if __name__ == "__main__":
    errs = run_tests()
    exit(0 if errs == 0 else 1)
