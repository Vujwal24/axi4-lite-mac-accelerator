# Register Map

Addressing scheme: address = register index (row-based)

| Address | Register |             Description                |
|---------|----------|----------------------------------------|
|    0    |   CTRL   | bit0=start (self-clearing), bit1=clear |
|    1    |     A    |            MAC operand A               |
|    2    |     B    |            MAC operand B               |
|    3    |    ACC   |         Accumulator (read-only)        |
|    4    |   STATUS |      bit0=done (set by hardware)       |

All registers are 32-bit wide.
