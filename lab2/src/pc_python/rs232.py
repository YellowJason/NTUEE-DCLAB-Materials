#!/usr/bin/env python
from serial import Serial, EIGHTBITS, PARITY_NONE, STOPBITS_ONE
from sys import argv

assert len(argv) == 2
s = Serial(
    port=argv[1],
    baudrate=115200,
    bytesize=EIGHTBITS,
    parity=PARITY_NONE,
    stopbits=STOPBITS_ONE,
    xonxoff=False,
    rtscts=False
)
fp_key = open('key.bin', 'rb')
enc_l = ['cipher_20220325.bin', 'golden/enc1.bin', 'golden/enc2.bin', 'golden/enc3.bin']

fp_enc = open('cipher_20220325.bin', 'rb')
fp_dec = open('dec.bin', 'wb')
assert fp_key and fp_enc and fp_dec
print("Open file success")

key = fp_key.read(64)
enc = fp_enc.read()
assert len(enc) % 32 == 0
print("Data read success")

s.write(key)
for i in range(0, len(enc), 32):
    s.write(enc[i:i+32])
    dec = s.read(31)
    print(str(dec, encoding = "utf-8"), end = "")
    fp_dec.write(dec)

fp_key.close()
fp_enc.close()
fp_dec.close()
