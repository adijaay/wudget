"""OKLCH -> sRGB hex, with WCAG contrast, for porting design/*.dc.html tokens
into lib/design/tokens.dart. The mockups are authored in OKLCH; Flutter needs
0xAARRGGBB. Run: python tool/oklch.py"""
import math
import sys


def oklch_to_srgb(L, C, h_deg):
    h = math.radians(h_deg)
    a, b = C * math.cos(h), C * math.sin(h)
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    bb = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

    def enc(u):
        u = 12.92 * u if u <= 0.0031308 else 1.055 * (abs(u) ** (1 / 2.4)) - 0.055
        return max(0.0, min(1.0, u))

    return tuple(round(enc(u) * 255) for u in (r, g, bb))


def hexof(L, C, h):
    return "0xFF%02X%02X%02X" % oklch_to_srgb(L, C, h)


def lum(rgb):
    def ch(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(x) for x in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


if __name__ == "__main__":
    args = [float(x) for x in sys.argv[1:4]] if len(sys.argv) >= 4 else None
    if args:
        print(hexof(*args), oklch_to_srgb(*args))
