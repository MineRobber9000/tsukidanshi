-- this is admittedly a little hard to do without for loops but i'll try it
-- anyways

-- eventually this is going to be an actual, like, demo or something of the
-- system's capabilities but until then: hello world!

-- tile 01: H
-- tile 02: E
-- tile 03: L
-- tile 04: O
-- tile 05: W
-- tile 06: R
-- tile 07: D
-- tile 08: !
charmap[16]=0xCC
charmap[17]=0xCC
charmap[18]=0xCC
charmap[19]=0xCC
charmap[20]=0xCC
charmap[21]=0xCC
charmap[22]=0xFC
charmap[23]=0xFC
charmap[24]=0xCC
charmap[25]=0xCC
charmap[26]=0xCC
charmap[27]=0xCC
charmap[28]=0xCC
charmap[29]=0xCC
charmap[30]=0x00
charmap[31]=0x00
charmap[32]=0xFE
charmap[33]=0xFE
charmap[34]=0x62
charmap[35]=0x62
charmap[36]=0x68
charmap[37]=0x68
charmap[38]=0x78
charmap[39]=0x78
charmap[40]=0x68
charmap[41]=0x68
charmap[42]=0x62
charmap[43]=0x62
charmap[44]=0xFE
charmap[45]=0xFE
charmap[46]=0x00
charmap[47]=0x00
charmap[48]=0xF0
charmap[49]=0xF0
charmap[50]=0x60
charmap[51]=0x60
charmap[52]=0x60
charmap[53]=0x60
charmap[54]=0x60
charmap[55]=0x60
charmap[56]=0x62
charmap[57]=0x62
charmap[58]=0x66
charmap[59]=0x66
charmap[60]=0xFE
charmap[61]=0xFE
charmap[62]=0x00
charmap[63]=0x00
charmap[64]=0x38
charmap[65]=0x38
charmap[66]=0x6C
charmap[67]=0x6C
charmap[68]=0xC6
charmap[69]=0xC6
charmap[70]=0xC6
charmap[71]=0xC6
charmap[72]=0xC6
charmap[73]=0xC6
charmap[74]=0x6C
charmap[75]=0x6C
charmap[76]=0x38
charmap[77]=0x38
charmap[78]=0x00
charmap[79]=0x00
charmap[80]=0xC6
charmap[81]=0xC6
charmap[82]=0xC6
charmap[83]=0xC6
charmap[84]=0xC6
charmap[85]=0xC6
charmap[86]=0xD6
charmap[87]=0xD6
charmap[88]=0xFE
charmap[89]=0xFE
charmap[90]=0xEE
charmap[91]=0xEE
charmap[92]=0xC6
charmap[93]=0xC6
charmap[94]=0x00
charmap[95]=0x00
charmap[96]=0xFC
charmap[97]=0xFC
charmap[98]=0x66
charmap[99]=0x66
charmap[100]=0x66
charmap[101]=0x66
charmap[102]=0x7C
charmap[103]=0x7C
charmap[104]=0x6C
charmap[105]=0x6C
charmap[106]=0x66
charmap[107]=0x66
charmap[108]=0xE6
charmap[109]=0xE6
charmap[110]=0x00
charmap[111]=0x00
charmap[112]=0xF8
charmap[113]=0xF8
charmap[114]=0x6C
charmap[115]=0x6C
charmap[116]=0x66
charmap[117]=0x66
charmap[118]=0x66
charmap[119]=0x66
charmap[120]=0x66
charmap[121]=0x66
charmap[122]=0x6C
charmap[123]=0x6C
charmap[124]=0xF8
charmap[125]=0xF8
charmap[126]=0x00
charmap[127]=0x00
charmap[128]=0x18
charmap[129]=0x18
charmap[130]=0x3C
charmap[131]=0x3C
charmap[132]=0x3C
charmap[133]=0x3C
charmap[134]=0x18
charmap[135]=0x18
charmap[136]=0x18
charmap[137]=0x18
charmap[138]=0x00
charmap[139]=0x00
charmap[140]=0x18
charmap[141]=0x18
charmap[142]=0x00
charmap[143]=0x00
-- whew!

tileset[65]=1  -- h
tileset[66]=2  -- e
tileset[67]=3  -- l
tileset[68]=3  -- l
tileset[69]=4  -- o
tileset[70]=0  --
tileset[71]=5  -- w
tileset[72]=4  -- o
tileset[73]=6  -- r
tileset[74]=3  -- l
tileset[75]=7 -- d
tileset[76]=8 -- !

function vblank() end
