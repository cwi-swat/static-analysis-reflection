module summarize::DifficultCases

import lang::csv::IO;
import ValueIO;
import Set;
import IO;
import String;
import model::limitations::DifficultCases;
import util::CLI;
import util::Math;

void aggregateCases(loc root = |compressed+project://reflections-on-reflection/data/reflections|, loc target = |compressed+project://reflections-on-reflection/data/results/|, int startIndex = 0, int stopIndex = 500) {
    int projects = 0;
    map[HarmfullPattern, int] projectCount = ();
    <progress, finished> = progressReporter("");
    for (gf <- root.ls, /^difficult-cases-<name:.*>\.bin\.xz/ := gf.file) {
        if (/^[0]*<sid:[1-9][0-9]*>[^0-9]/ := name, id := toInt(sid), id < startIndex || id > stopIndex) {
            continue;
        }
        projects += 1;
        progress("Project <name>: Reading");
        patterns = readBinaryValueFile(#PatternResults, gf);
        progress("Project <name>: Aggregating sources");
        for (pat <- {*(patterns<1>)}) {
            projectCount[pat] ? 0 += 1;
        }
        for (<l, exceptionControlFlow()> <- patterns, projects < 20 ) {
            println(fixLoc(l));
            break;
        }
    }
    finished();
    println("Writing files");
    lrel[str pattern, int howManyProjects, real ratio] result 
        = [<name, projectCount[p], 100*(projectCount[p] / (projects * 1.0))> | <p, name> <- names];
    writeCSV(result, target[scheme = replaceFirst(target.scheme, "compressed+","")] + "difficult-patterns.csv");
}

lrel[HarmfullPattern, str] names = [
    <incorrectCast(), "CorrectCasts">,
    //<externalLibraries(), "ClosedWorld">,
    <exceptionControlFlow(), "NonExceptions">,
    <exceptionControlFlowLoop(), "NonExceptions-Loop">,
    <metaObjectsInRandomIndexedCollections(), "MetaObjectsInArrays">,
    <metaObjectsInHashBasedCollections(), "MetaObjectsInTables">,
    <metaObjectArrayResultingMethods(), "MultipleMetaObjects">,
    <stringsFromEnvironment(), "EnvironmentStrings">,
    <loopOverCandidates(), "ProgrammaticFiltering">
];

loc fixLoc(loc l)
    = l[scheme="project"][authority="reflections-on-reflection"][path = replaceFirst(l.path, "/export/scratch3/landman/reflections-on-reflection", "")];

void takeSamples(int sampleSize, loc root = |compressed+project://reflections-on-reflection/data/reflections|,  loc target = |compressed+project://reflections-on-reflection/data/results/|, int stopIndex= 500) {
    map[HarmfullPattern, set[loc]] candidates = ();
    println("Reading");
    for (gf <- root.ls, /^difficult-cases-<name:.*>\.bin\.xz/ := gf.file) {
        if (/^[0]*<sid:[1-9][0-9]*>[^0-9]/ := name, id := toInt(sid), id > stopIndex) {
            continue;
        }
        patterns = readBinaryValueFile(#PatternResults, gf);
        set[loc] emptySet = {};
        for (<l, p> <- patterns) {
            candidates[p]?emptySet += l;
        }
    }
    set[loc] seen = {};
    loc getRandomOne(set[loc] candidates) {
    	if (all(c <- candidates, c in seen)) {
    		throw "too little candidates <candidates>";
    	}
    	result = getOneFrom(candidates);
    	while (result in seen) {
    		result = getOneFrom(candidates);
    	}
    	seen += result;
    	return result;
    }
    println("Sampling");
    sampled = [
        <p, [
            fixLoc(getRandomOne(candidates[p]))
            | i <- [0.. sampleSize]
        ]>
        | <p, _> <- names, p in candidates,size(candidates[p]) > sampleSize
    ];
    writeBinaryValueFile(target + "difficult-patterns-sampled.bin.xz", sampled);
    iprintln(sampled);
}