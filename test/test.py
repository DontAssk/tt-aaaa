import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    dut._log.info("Starting U C L 2 0 2 7 sequence simulation...")

    # Start a 100 kHz clock (10 us period)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Apply initial reset condition
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    
    # Release reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # Expected 7-segment output bitmasks for: U, C, L, (blank), 2, 0, 2, 7
    expected_sequence = [0x3E, 0x39, 0x38, 0x00, 0x5B, 0x3F, 0x5B, 0x07]

    # Step through each sequence item and verify output
    for i, expected in enumerate(expected_sequence):
        actual = int(dut.uo_out.value)
        dut._log.info(f"State {i} | Output: {hex(actual)} | Expected: {hex(expected)}")
        assert actual == expected, f"Mismatch at state {i}! Expected {hex(expected)}, got {hex(actual)}"
        await ClockCycles(dut.clk, 1)
