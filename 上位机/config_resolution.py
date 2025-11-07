#!/usr/bin/env python3
"""
Host tool to configure binocular stitching ROI over UART.

Protocol (11 bytes total):
    0: 0xAA
    1: 0x55
    2: width  MSB
    3: width  LSB
    4: height MSB
    5: height LSB
    6: left0  MSB   (crop start for left sensor)
    7: left0  LSB
    8: left1  MSB   (crop start for right sensor)
    9: left1  LSB
   10: alpha  (0=black, 50=original, 100=white)

Default timing expects 115200-8-N-1.

Examples:
  python tools/config_resolution.py --port COM7 --width 960 --height 720 --left0 160 --left1 593
  python tools/config_resolution.py --port /dev/ttyUSB0 --center --width 960 --height 720
"""

import argparse
import sys
import time

try:
    import serial
    import serial.tools.list_ports as list_ports
except Exception as e:
    print("pyserial is required: pip install pyserial", file=sys.stderr)
    raise


SENSOR_W = 1280
SENSOR_H = 720
HDMI_W = 1920
HDMI_H = 1080
ROI_DEFAULT_W = 960
ROI_DEFAULT_H = 720
ALPHA_DEFAULT = 50


def clamp(val: int, lo: int, hi: int) -> int:
    return max(lo, min(hi, val))


def build_packet(width: int, height: int, left0: int, left1: int, alpha: int) -> bytes:
    def split16(x: int):
        return (x >> 8) & 0xFF, x & 0xFF

    w_msb, w_lsb = split16(width)
    h_msb, h_lsb = split16(height)
    l0_msb, l0_lsb = split16(left0)
    l1_msb, l1_lsb = split16(left1)
    return bytes([0xAA, 0x55, w_msb, w_lsb, h_msb, h_lsb, l0_msb, l0_lsb, l1_msb, l1_lsb, alpha & 0xFF])


def auto_left(width: int) -> int:
    # Center inside sensor width by default
    return max(0, (SENSOR_W - width) // 2)


def main():
    parser = argparse.ArgumentParser(description="Configure binocular ROI over UART")
    parser.add_argument("--port", required=False, help="Serial port, e.g., COM7 or /dev/ttyUSB0")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate (default: 115200)")
    parser.add_argument("--width", type=int, required=False, help=f"ROI width per eye (pixels, default: {ROI_DEFAULT_W})")
    parser.add_argument("--height", type=int, required=False, help=f"ROI height (pixels, default: {ROI_DEFAULT_H})")
    parser.add_argument("--left0", type=int, help="Left sensor crop start X")
    parser.add_argument("--left1", type=int, help="Right sensor crop start X")
    parser.add_argument("--alpha", type=int, default=ALPHA_DEFAULT, help="Alpha mix (0=black, 50=original, 100=white)")
    parser.add_argument("--center", action="store_true", help="Auto-center both crops inside sensor")
    parser.add_argument("--list", action="store_true", help="List serial ports and exit")
    parser.add_argument("--dry-run", action="store_true", help="Print packet bytes only")
    args = parser.parse_args()

    if args.list:
        for p in list_ports.comports():
            print(f"{p.device}: {p.description}")
        return 0

    if not args.port:
        print("--port is required (use --list to enumerate)", file=sys.stderr)
        return 2

    # Fill defaults if omitted, then range check (consistent with HDL guards)
    width = ROI_DEFAULT_W if args.width is None else args.width
    height = ROI_DEFAULT_H if args.height is None else args.height
    width = clamp(width, 16, min(SENSOR_W, HDMI_W // 2))
    height = clamp(height, 16, min(SENSOR_H, HDMI_H))

    if args.center:
        left0 = auto_left(width)
        left1 = auto_left(width)
    else:
        # default to centered if not provided
        left0 = args.left0 if args.left0 is not None else auto_left(width)
        left1 = args.left1 if args.left1 is not None else auto_left(width)

    # Keep crops within sensor width
    left0 = clamp(left0, 0, SENSOR_W - width)
    left1 = clamp(left1, 0, SENSOR_W - width)

    alpha = clamp(args.alpha, 0, 100)

    pkt = build_packet(width, height, left0, left1, alpha)

    print(f"Port={args.port} Baud={args.baud}")
    print(f"Width={width} Height={height} Left0={left0} Left1={left1} Alpha={alpha}")
    print("Packet:", " ".join(f"{b:02X}" for b in pkt))

    if args.dry_run:
        return 0

    # Send once; the FPGA auto-applies and soft-resets logic
    with serial.Serial(args.port, args.baud, timeout=0.2) as ser:
        # Small settle in case of adapter coming up
        time.sleep(0.05)
        ser.reset_input_buffer()
        ser.reset_output_buffer()
        ser.write(pkt)
        ser.flush()
        # Optional: read any stray status bytes for a short period
        time.sleep(0.1)
        leftover = ser.read(64)
        if leftover:
            print("Read:", leftover.hex())

    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
