simulation test results:
alu
<img width="637" height="384" alt="image" src="https://github.com/user-attachments/assets/aa548630-432f-42be-97e9-b1eaf5ddc7e5" />
[5000]                        AND lanes: opcode=0000 a=ffff0000f0f01234 b=0f0fffff00ffffff -> result=0f0f000000f01234
[10000]                         OR lanes: opcode=0001 a=0000f0f000001234 b=0f0f0000ffff0000 -> result=0f0ff0f0ffff1234
[15000]                        SUM lanes: opcode=0010 a=0004000300020001 b=0028001e0014000a -> result=002c00210016000b
[20000]                   SUM wrap lanes: opcode=0010 a=ffff000180007fff b=0001ffff00010001 -> result=0000000080018000
[25000]                        SUB lanes: opcode=0011 a=0064003200000001 b=005a000a00010002 -> result=000a0028ffffffff
[30000]                       XNOR lanes: opcode=0100 a=ffff0000a5a55a5a b=0f0ff0f05a5aa5a5 -> result=0f0f0f0f00000000
[35000]                 CMP signed lanes: opcode=0101 a=00040003fffeffff b=00050002fffe0000 -> result=ffff00000000ffff
[40000]                        MOV lanes: opcode=0111 a=deadbeef12345678 b=fedcba9876543210 -> result=fedcba9876543210

