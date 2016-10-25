module analyze::Productions

import String;
import IO;
import Set;
import List;
import ValueIO;
import \data::Corpus;
import util::Benchmark;
import lang::java::m3::keywords::AST;
import lang::java::m3::Core;
import patterns::ReflectionGrammar;
import Exception;

&T printTime(&T () block) {
   now = cpuTime();
   result = block();
   took = cpuTime() - now;
   println(": <(took / (1000*1000))>ms");
   return result;
}


set[str] ignoredFiles = {};

void main(int startIndex, int stopIndex, loc root = |compressed+project://reflections-on-reflection/data/corpus/parsed/|, loc targetRoot = |compressed+project://reflections-on-reflection/data/reflections/|) {
    for (proj <- sort(root.ls), !(proj.file in ignoredFiles), !endsWith(proj.file, "-cached.xz")) {
        if (/^[0]*<sid:[1-9][0-9]*>-/ := proj.file, id := toInt(sid), id < startIndex || id > stopIndex) {
            continue;
        }
        target = targetRoot + "productions-<proj.file>";
        try {
            if (!exists(target)) {
                print("Reading <proj.file>");
                <model, asts, bodies> = printTime(ASTDataSingle () { return getData(proj); });
                println("\tSize: <size(asts)> asts");
                print("\tDetecting reflection calls");
                productions = printTime(ReflectionCalls () { return [*detectReflectionProductions(bod) | <dec, bod> <- bodies ]; });
                println("\tSize: <size(productions)> reflected calls");
                print("\tSaving result");
                printTime(int () { writeBinaryValueFile(target, [<d.src, prod> | <d,prod> <- productions]); return 0; });
            }
        }
        catch value e: {
            println(": crashed <e>");
        }
    }
}

void mainHyuga(int startIndex, int stopIndex) {
    main(startIndex, stopIndex, root = |compressed+home:///scratch3/reflections-on-reflection/data/corpus/parsed|, targetRoot = |compressed+home:///scratch3/reflections-on-reflection/data/reflections|);
}
void mainSwat(int startIndex, int stopIndex) {
    main(startIndex, stopIndex, root = |compressed+home:///scratch2/reflections-on-reflection/data/corpus/parsed|, targetRoot = |compressed+home:///scratch2/reflections-on-reflection/data/reflections|);
}
