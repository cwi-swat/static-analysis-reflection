module summarize::Productions

import String;
import ValueIO;
import Set;
import Map;
import lang::csv::IO;
import IO;
import util::CLI;
import model::reflection::Grammar;
import model::reflection::Categories;

data ReflectionProduction = noReflection();
data ReflectionCategory = noReflectionGroup();

alias ReflectionCounts = lrel[str project, ReflectionProduction production, int count];

void calculateCounts(loc root = |compressed+project://reflections-on-reflection/data/reflections|, loc target = |compressed+project://reflections-on-reflection/data/results/|, int stopIndex = 40) {
    ReflectionCounts result = [];
    <progress, finished> = progressReporter("");
    for (gf <- root.ls, /^productions-<name:.*>\.bin\.xz/ := gf.file) {
        if (/^[0]*<sid:[1-9][0-9]*>[^0-9]/ := name, id := toInt(sid), id > stopIndex) {
            continue;
        }
        progress("Project <name>: Reading");
        prods = readBinaryValueFile(#lrel[loc src, ReflectionProduction prod], gf);
        progress("Project <name>: Counting");
        map[ReflectionProduction, int] counts = ();
        for (<_,p> <- prods) {
            counts[p] ? 0 += 1;
        }
        result += [<name, p, counts[p]> | p <- counts];
        if (counts == ()) {
            result += <name, noReflection(), 1>;
        }
    }
    finished();
    println("Writing files");
    writeBinaryValueFile(target + "production-counts-<root.file>-<stopIndex>.bin.xz", result);
}

void calculateCSVs(loc target = |project://reflections-on-reflection/data/results/|) {
    counts = readBinaryValueFile(#ReflectionCounts, target[scheme="compressed+"+target.scheme] + "production-counts-reflections-500.bin.xz");
    lookupCategory2 = lookupCategory + (noReflection() : noReflectionGroup());
    projectCategories = toMap({<lookupCategory2[prod], p> | <p, prod,_> <-  counts});
    lrel[str productionCategory, int inHowManyProjects, real ratio] result = [];
    int projects = size({*(counts<0>)});
    println("Projects: <projects>");
    for (<catName, cat> <- catNames) {
        cnt = size(projectCategories[cat]);
        result += <catName, cnt, 100*(cnt/(1.*projects))>;
    }
    writeCSV(result, target + "project-production-hist.csv");
    cnt = size(projectCategories[noReflectionGroup()]);
    writeFile(target + "no-reflection-projects.tex", "<cnt> projects (\\percentage{<100* (cnt / (1. * projects))>})");
    projectsWithHarmful = size({ *projectCategories[c] | c <- harmfullCategories });
    writeFile(target + "harmful-reflection-projects.tex", "\\percentage{<100* (projectsWithHarmful / (1. * projects))>}");
    writeFile(target + "harmful-reflection-projects-full.tex", "<projectsWithHarmful> projects (\\percentage{<100* (projectsWithHarmful / (1. * projects))>})");
}

lrel[str, ReflectionCategory] catNames = [
    <"Lookup Class \\bnfCategory{LC}", lookupClass()>,
    <"Lookup Meta Object \\bnfCategory{LM}", lookupMetaObject()>,
    <"Traverse Meta Object \\bnfCategory{TM}", traverseMetaObject()>,
    <"Construct Object \\bnfCategory{C}", constructObject()>,
    <"Proxy \\bnfCategory{P}", proxy()>,
    <"Access Object \\bnfCategory{A}", accessObject()>,
    <"Manipulate Object \\bnfCategory{M}", manipulateObject ()>,
    <"Manipulate Meta Object \\bnfCategory{MM}", manipulateMetaObject()>,
    <"Invoke Method \\bnfCategory{I}", invokeMethod()>,
    <"Array \\bnfCategory{AR}", array()>,
    <"Cast \\bnfCategory{DC}", casts()>,
    <"Signature \\bnfCategory{SG}", signature()>,
    <"Assertions \\bnfCategory{AS}", assertions()>,
    <"Annotations \\bnfCategory{AN}", annotations()>,
    <"String representation \\bnfCategory{ST}", stringRepresentations()>,
    <"Resource \\bnfCategory{RS}", resources()>,
    <"Security \\bnfCategory{S}", security()>
];

loc fixLoc(loc l)
    = l[scheme="project"][authority="reflections-on-reflection"][path = replaceFirst(l.path, "/export/scratch3/landman/reflections-on-reflection", "")];
void takeSamples(int howMany, ReflectionCategory cat, loc root = |compressed+project://reflections-on-reflection/data/reflections|) {
    println("Reading");
    set[loc] candidates = {};
    interestedProductions = lookupCategory<1,0>[cat];
    for (gf <- root.ls, /^productions-<name:.*>\.bin\.xz/ := gf.file) {
        prods = readBinaryValueFile(#lrel[loc src, ReflectionProduction prod], gf);
        for (<src, prod> <- prods, prod in interestedProductions) {
            candidates += src;
        } 
    }
    println("Sampling");
    seen = {};
    for (i <- [0..howMany]) {
        c = getOneFrom(candidates);
        while (c in seen) {
            c = getOneFrom(candidates);
        }
        seen += c;
        println(fixLoc(c));
    }
}


