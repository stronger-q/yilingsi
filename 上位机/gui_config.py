#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import tkinter as tk
from tkinter import ttk, messagebox
import threading
import time

try:
    import serial
    import serial.tools.list_ports as list_ports
except Exception as e:
    raise SystemExit("pyserial is required: pip install pyserial")


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
    def s16(x):
        return (x >> 8) & 0xFF, x & 0xFF
    w_h, w_l = s16(width)
    h_h, h_l = s16(height)
    l0_h, l0_l = s16(left0)
    l1_h, l1_l = s16(left1)
    return bytes([0xAA, 0x55, w_h, w_l, h_h, h_l, l0_h, l0_l, l1_h, l1_l, alpha & 0xFF])


def auto_left(width: int) -> int:
    return max(0, (SENSOR_W - width) // 2)


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("双目拼接配置 (UART)")
        self.geometry("520x360")
        self.resizable(False, False)

        self.ser = None
        self._build_ui()
        self._refresh_ports()

    def _build_ui(self):
        pad = dict(padx=6, pady=4)

        frm_top = ttk.LabelFrame(self, text="串口")
        frm_top.pack(fill="x", **pad)

        ttk.Label(frm_top, text="端口:").grid(row=0, column=0, sticky="w", **pad)
        self.port_var = tk.StringVar()
        self.cmb_port = ttk.Combobox(frm_top, textvariable=self.port_var, width=20, state="readonly")
        self.cmb_port.grid(row=0, column=1, **pad)
        ttk.Button(frm_top, text="刷新", command=self._refresh_ports).grid(row=0, column=2, **pad)

        ttk.Label(frm_top, text="波特率:").grid(row=0, column=3, sticky="w", **pad)
        self.baud_var = tk.StringVar(value="115200")
        self.cmb_baud = ttk.Combobox(frm_top, textvariable=self.baud_var, width=10, values=["115200","230400","460800","921600"], state="readonly")
        self.cmb_baud.grid(row=0, column=4, **pad)

        self.btn_connect = ttk.Button(frm_top, text="连接", command=self._toggle_connect)
        self.btn_connect.grid(row=0, column=5, **pad)

        frm_set = ttk.LabelFrame(self, text="分辨率/裁剪")
        frm_set.pack(fill="x", **pad)

        ttk.Label(frm_set, text="宽度 (每路)").grid(row=0, column=0, sticky="e", **pad)
        self.var_w = tk.IntVar(value=ROI_DEFAULT_W)
        ttk.Entry(frm_set, textvariable=self.var_w, width=8).grid(row=0, column=1, **pad)

        ttk.Label(frm_set, text="高度").grid(row=0, column=2, sticky="e", **pad)
        self.var_h = tk.IntVar(value=ROI_DEFAULT_H)
        ttk.Entry(frm_set, textvariable=self.var_h, width=8).grid(row=0, column=3, **pad)

        self.var_center = tk.BooleanVar(value=True)
        chk_center = ttk.Checkbutton(frm_set, text="自动居中", variable=self.var_center, command=self._on_center_toggle)
        chk_center.grid(row=0, column=4, **pad)

        ttk.Label(frm_set, text="Left0 起点").grid(row=1, column=0, sticky="e", **pad)
        self.var_l0 = tk.IntVar(value=auto_left(ROI_DEFAULT_W))
        self.ent_l0 = ttk.Entry(frm_set, textvariable=self.var_l0, width=8)
        self.ent_l0.grid(row=1, column=1, **pad)

        ttk.Label(frm_set, text="Left1 起点").grid(row=1, column=2, sticky="e", **pad)
        self.var_l1 = tk.IntVar(value=auto_left(ROI_DEFAULT_W))
        self.ent_l1 = ttk.Entry(frm_set, textvariable=self.var_l1, width=8)
        self.ent_l1.grid(row=1, column=3, **pad)

        ttk.Label(frm_set, text="透明度").grid(row=2, column=0, sticky="e", **pad)
        self.var_alpha = tk.IntVar(value=ALPHA_DEFAULT)
        self.scale_alpha = tk.Scale(frm_set, from_=0, to=100, orient="horizontal", variable=self.var_alpha, length=180)
        self.scale_alpha.grid(row=2, column=1, columnspan=2, sticky="we", **pad)
        self.spin_alpha = tk.Spinbox(frm_set, from_=0, to=100, textvariable=self.var_alpha, width=6)
        self.spin_alpha.grid(row=2, column=3, **pad)
        self.lbl_alpha = ttk.Label(frm_set, text=f"{ALPHA_DEFAULT:3d}")
        self.lbl_alpha.grid(row=2, column=4, sticky="w", **pad)

        self._on_center_toggle()
        self.var_alpha.trace_add("write", self._on_alpha_var)
        self._on_alpha_var()

        frm_act = ttk.Frame(self)
        frm_act.pack(fill="x", **pad)

        self.btn_apply = ttk.Button(frm_act, text="配置并重启", command=self._apply)
        self.btn_apply.pack(side="left", padx=8)

        self.var_autocenter_runtime = tk.BooleanVar(value=True)
        ttk.Checkbutton(frm_act, text="宽度改变时自动更新居中", variable=self.var_autocenter_runtime).pack(side="left")

        frm_log = ttk.LabelFrame(self, text="状态")
        frm_log.pack(fill="both", expand=True, **pad)
        self.txt_status = tk.Text(frm_log, height=8, wrap="word")
        self.txt_status.pack(fill="both", expand=True)

        # update center on width change (simple polling)
        self._poll_width_last = self.var_w.get()
        self.after(200, self._poll_width_change)

    def _poll_width_change(self):
        w = self.var_w.get()
        if self.var_center.get() and self.var_autocenter_runtime.get() and w != self._poll_width_last:
            self._update_centered_lefts(w)
        self._poll_width_last = w
        self.after(200, self._poll_width_change)

    def _log(self, s: str):
        ts = time.strftime("%H:%M:%S")
        self.txt_status.insert("end", f"[{ts}] {s}\n")
        self.txt_status.see("end")

    def _refresh_ports(self):
        ports = [p.device for p in list_ports.comports()]
        self.cmb_port["values"] = ports
        if ports and not self.port_var.get():
            self.port_var.set(ports[0])
        self._log("串口列表: " + ", ".join(ports) if ports else "未发现串口")

    def _toggle_connect(self):
        if self.ser and self.ser.is_open:
            try:
                self.ser.close()
            finally:
                self.ser = None
                self.btn_connect.config(text="连接")
                self._log("串口已断开")
            return

        port = self.port_var.get()
        if not port:
            messagebox.showerror("错误", "请选择串口")
            return
        try:
            baud = int(self.baud_var.get())
        except ValueError:
            messagebox.showerror("错误", "波特率无效")
            return
        try:
            self.ser = serial.Serial(port, baud, timeout=0.2)
            self.btn_connect.config(text="断开")
            self._log(f"已连接 {port} @ {baud}")
        except Exception as e:
            self.ser = None
            messagebox.showerror("连接失败", str(e))

    def _on_center_toggle(self):
        centered = self.var_center.get()
        state = "disabled" if centered else "normal"
        self.ent_l0.configure(state=state)
        self.ent_l1.configure(state=state)
        if centered:
            self._update_centered_lefts(self.var_w.get())

    def _update_centered_lefts(self, w: int):
        self.var_l0.set(auto_left(w))
        self.var_l1.set(auto_left(w))

    def _on_alpha_var(self, *args):
        val = clamp(int(self.var_alpha.get()), 0, 100)
        if val != self.var_alpha.get():
            self.var_alpha.set(val)
            return
        self.lbl_alpha.config(text=f"{val:3d}")

    def _apply(self):
        if not (self.ser and self.ser.is_open):
            messagebox.showerror("错误", "请先连接串口")
            return
        try:
            w = int(self.var_w.get())
            h = int(self.var_h.get())
            l0 = int(self.var_l0.get())
            l1 = int(self.var_l1.get())
        except ValueError:
            messagebox.showerror("错误", "请输入有效的数字")
            return

        # Clamp per HDL
        w = clamp(w, 16, min(SENSOR_W, HDMI_W // 2))
        h = clamp(h, 16, min(SENSOR_H, HDMI_H))
        l0 = clamp(l0, 0, SENSOR_W - w)
        l1 = clamp(l1, 0, SENSOR_W - w)
        alpha = clamp(int(self.var_alpha.get()), 0, 100)

        pkt = build_packet(w, h, l0, l1, alpha)
        self._log(f"发送: W={w} H={h} L0={l0} L1={l1} Alpha={alpha} -> " + " ".join(f"{b:02X}" for b in pkt))

        def _send():
            try:
                self.ser.reset_output_buffer()
                self.ser.write(pkt)
                self.ser.flush()
                time.sleep(0.1)
                leftover = self.ser.read(64)
                if leftover:
                    self._log("返回: " + leftover.hex())
                self._log("完成，系统将按设计进行软重启")
            except Exception as e:
                self._log("发送失败: " + str(e))

        threading.Thread(target=_send, daemon=True).start()


if __name__ == "__main__":
    App().mainloop()
