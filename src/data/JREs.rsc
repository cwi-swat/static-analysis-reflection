module \data::JREs

import ValueIO;
import lang::java::m3::Core;

M3 getJRE6() 
  = readBinaryValueFile(#M3, |compressed+project://reflections-on-reflection/data/m3_jre6.bin.xz|);

M3 getJRE7(loc root =|compressed+project://reflections-on-reflection/data/|) 
  = readBinaryValueFile(#M3, root + "m3_jre7.bin.xz");