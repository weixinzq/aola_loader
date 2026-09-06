"""ActionScript-compatible signed integer operations."""


def to_int32(value: int) -> int:
    value &= 0xFFFFFFFF
    return value - 0x100000000 if value >= 0x80000000 else value


def as3_remainder(dividend: int, divisor: int) -> int:
    if divisor == 0:
        raise ZeroDivisionError("integer remainder by zero")
    quotient = abs(dividend) // abs(divisor)
    if (dividend < 0) != (divisor < 0):
        quotient = -quotient
    return dividend - quotient * divisor


def hash_as3_string(value: str) -> int:
    result = 0
    encoded = value.encode("utf-16-be", errors="surrogatepass")
    for offset in range(0, len(encoded), 2):
        code_unit = int.from_bytes(encoded[offset : offset + 2], "big")
        result = to_int32(result * 31 + code_unit)
    return result

