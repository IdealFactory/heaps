package hxd.impl;

typedef Float32 = #if lime Float #elseif cpp cpp.Float32 #elseif hl hl.F32 #else Float #end;