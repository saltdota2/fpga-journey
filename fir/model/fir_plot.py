"""Plot input vs RTL output (time and spectrum) from data/fir_in.hex and data/fir_out_rtl.hex."""
import numpy as np
import matplotlib.pyplot as plt

FS = 8000

def read_hex(name):
    v = np.array([int(l, 16) for l in open(name) if l.strip()])
    return np.where(v >= 32768, v - 65536, v) / 32768.0

x = read_hex("data/fir_in.hex")
y = read_hex("data/fir_out_rtl.hex")
n = len(y)
t = np.arange(n) / FS

def spec(s):
    s = s[1000:] * np.hanning(len(s) - 1000)
    a = np.abs(np.fft.rfft(s)) * 2 / np.sum(np.hanning(len(s)))
    return np.fft.rfftfreq(len(s), 1 / FS), a

fig, (a1, a2) = plt.subplots(2, 1, figsize=(9.5, 7))
m = slice(400, 560)
a1.plot(t[m] * 1e3, x[m], color="0.6", lw=1, label="вход: 200 Гц + помеха 2500 Гц + шум")
a1.plot(t[m] * 1e3, y[m], color="C3", lw=2, label="выход FIR на ПЛИС (RTL, Verilator)")
a1.set_xlabel("время, мс")
a1.set_ylabel("уровень")
a1.set_title("Во времени")
a1.legend(fontsize=8, loc="upper right")
a1.grid(alpha=0.3)

fx, ax_ = spec(x)
fy, ay = spec(y)
a2.plot(fx, ax_, color="0.6", label="вход")
a2.plot(fy, ay, color="C3", label="выход FIR")
a2.set_xlim(0, 4000)
a2.set_xlabel("частота, Гц")
a2.set_ylabel("амплитуда")
a2.set_title("Спектр: помеха 2500 Гц исчезла, сигнал 200 Гц остался")
a2.legend(fontsize=8)
a2.grid(alpha=0.3)
plt.tight_layout()
plt.savefig("fir_before_after.png", dpi=110, bbox_inches="tight")
print("saved fir_before_after.png")
