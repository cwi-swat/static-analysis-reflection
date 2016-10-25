module analyze::GatherASTs

import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::ClassPaths;
import Set;
import Map;
import IO;
import List;
import ValueIO;
import Exception;
import String;
import util::FileSystem;

set[loc] findFiles(loc root, str extension) 
    = { p | p <- find(root, extension), isFile(p)};

map[loc, list[loc]] removeParents(map[loc, list[loc]] input) {
    parents = { p.parent | p <- input, p.path != "/" };
    solve(parents) {
        parents += { p.parent | p <- parents, p.path != "/" };
    }
    return domainR(input, domain(input) - parents);
}

@memo
set[str] getAndroidProjects(loc corpusRoot) = {*readFileLines(corpusRoot.parent + "android-projects.txt")};

list[loc] enrichClassPaths(list[loc] currentPaths, loc currentDir, loc corpusRoot) {
    isAndroidProject = /[\/]<name:[0-9]*-[^\/]*>/ := currentDir.path && ("<name>/" in getAndroidProjects(corpusRoot));
    return currentPaths + [ lib | lib <- (corpusRoot.parent + "libs/").ls, lib.extension == "jar",  (lib.file != "android.jar" || isAndroidProject)];
}

set[loc] keepRooted(set[loc] origins, loc root) 
	= { l | l <- origins, startsWith(l.path, root.path)};
	
	
tuple[M3 model, set[Declaration] asts] collectWithMaven(loc oneDir, loc corpusRoot, loc mavenPath = |file:///usr/local/bin/mvn|) {
    try {
        println("\tGetting maven paths");
        classPaths = getClassPath(oneDir, mavenExecutable = mavenPath);
        if (classPaths != ()) {
            println("\tMaven gave us <size(classPaths)> paths");
            asts = {};
            models = {};
            for (p <- classPaths) {
                println("\tGetting ASTs for <p>");
                srcPaths = {p};

                for (cp <- classPaths[p], isDirectory(cp), endsWith(cp.path, "/target/classes")) {
                    mavenModuleSourcePath = cp.parent.parent;
                    if (exists(mavenModuleSourcePath + "/src/")) {
                        srcPaths += mavenModuleSourcePath + "/src/";
                    }
                    else {
                        srcPaths += mavenModuleSourcePath;
                    }
                }
                javaFiles = findFiles(p, "java");
                if (javaFiles != {}) {
                    <m3s, newasts> = createM3sAndAstsFromFiles(javaFiles, errorRecovery = false, sourcePath = [*findRoots(srcPaths)], classPath = classPaths[p]);
                    if (newasts == {}) {
                        println("Getting asts for <p> failed since it returned no asts");
                        return <m3(|error:///|), {}>;
                    }
                    asts += newasts;
                    models += m3s;
                }
            }
            return <composeJavaM3(oneDir, models), asts>;
        }
        return <m3(|error:///|), {}>;
    }
    catch RuntimeException e: {
        println("\tMaven failed with <e>");
        return <m3(|error:///|), {}>;
    }
}

tuple[M3 model, set[Declaration] asts] collectGuessing(loc oneDir, loc corpusRoot, loc mavenPath = |file:///usr/local/bin/mvn|) {
    try {
        println("\tGetting ASTs for full dir in once <oneDir>");
        javaFiles = findFiles(oneDir, "java");
        if (javaFiles == {}) {
            println("Getting asts for <oneDir> failed since there are no java files");
            return <m3(|error:///|), {}>;
        }
        jars = enrichClassPaths([*findFiles(oneDir, "jar")], oneDir, corpusRoot);
        <m3s, asts> = createM3sAndAstsFromFiles(javaFiles, errorRecovery = false, sourcePath = [*findRoots({oneDir})], classPath = jars);
        if (asts == {} && javaFiles != {}) {
            println("Getting asts for <oneDir> failed since it returned no asts");
        }
        return <composeJavaM3(oneDir, m3s), asts>;
    }
    catch RuntimeException e: {
       println("Getting asts for <oneDir> failed: <e>");
       return <m3(|error:///|), {}>;
    }
}

tuple[M3 model, set[Declaration] asts] collectDataNetbeans(loc rootDir, loc corpusRoot) {
    subDirs = { d | d <- rootDir.ls, isDirectory(d)};
    m3s = {};
    asts = {};
    try {
        for (d <- subDirs) {
            println("\tProcessing netbeans: <d>");
            sourceDirs = { sd | dd <- d.ls, sd := dd + "src", exists(sd) };
            javaFiles = { *findFiles(sd, "java") | sd <- sourceDirs };
            if (javaFiles == {}) {
                continue;
            }
            libs = enrichClassPaths([*findFiles(d, "jar")], rootDir, corpusRoot);
            <newM3s,newASTs> = createM3sAndAstsFromFiles(javaFiles, errorRecovery = false, sourcePath = [*sourceDirs], classPath = libs);
            if (newASTs == {}) {
               println("No asts returned in <d> exiting");
               return <m3(|error:///|), {}>;
            }
            m3s += newM3s;
            asts += newASTs;
        }
        return <composeJavaM3(rootDir, m3s), asts>;
    }
    catch RuntimeException e: {
       println("Getting asts for <rootDir> failed: <e>");
       return <m3(|error:///|), {}>;
    }
}

tuple[M3 model, set[Declaration] asts] collectDataOpenJDK(loc rootDir, loc corpusRoot) {
    subDirs = { d | d <- rootDir.ls, isDirectory(d)};
    m3s = {};
    asts = {};
    try {
        for (d <- subDirs, d.file != "jdk8") {
            println("\tProcessing OpenJDK: <d>");
            javaFiles = findFiles(d + "src/", "java");
            if (javaFiles == {}) {
                continue;
            }
            libs = enrichClassPaths([*findFiles(d, "jar")], rootDir, corpusRoot);
            sourceDirs = [*findRoots({d + "src/"})];
            <newM3s,newASTs> = createM3sAndAstsFromFiles(javaFiles, errorRecovery = false, sourcePath = sourceDirs, classPath = libs);
            if (newASTs == {}) {
               println("No asts returned in <d> exiting");
               return <m3(|error:///|), {}>;
            }
            m3s += newM3s;
            asts += newASTs;
        }
        return <composeJavaM3(rootDir, m3s), asts>;
    }
    catch RuntimeException e: {
       println("Getting asts for <rootDir> failed: <e>");
       return <m3(|error:///|), {}>;
    }
}

tuple[M3 model, set[Declaration] asts] collectDataPentaho(loc rootDir, loc corpusRoot) {
    rootDir += "pentaho-reporting/";
    subDirs = { d | d <- rootDir.ls, isDirectory(d)};
    m3s = {};
    asts = {};
    try {
        for (d <- subDirs) {
            println("\tProcessing penthaho: <d>");
            subs = {};
            if (d.file == "libraries" || d.file == "engine") {
                subs = {sd | dd <- d.ls, sd := dd + "src/", exists(sd), isDirectory(sd)};
            }
            javaFiles = { *findFiles(dd, "java") | dd <- subs };
            if (javaFiles == {}) {
                continue;
            }
            libs = enrichClassPaths([*findFiles(d, "jar")], rootDir, corpusRoot);
            sourceDirs = [*findRoots(subs)];
            <newM3s,newASTs> = createM3sAndAstsFromFiles(javaFiles, errorRecovery = false, sourcePath = sourceDirs, classPath = libs);
            if (newASTs == {}) {
               println("No asts returned in <d> exiting");
               return <m3(|error:///|), {}>;
            }
            m3s += newM3s;
            asts += newASTs;
        }
        return <composeJavaM3(rootDir.parent, m3s), asts>;
    }
    catch RuntimeException e: {
       println("Getting asts for <rootDir> failed: <e>");
       return <m3(|error:///|), {}>;
    }

}

tuple[M3 model, set[Declaration] asts] collectDataStarPound(loc rootDir, loc corpusRoot) {
    rootDir += "starpound/";
    subDirs = { d | d <- rootDir.ls, isDirectory(d)};
    m3s = {};
    asts = {};
    try {
        for (d <- subDirs) {
            println("\tProcessing starpound: <d>");
            javaFiles = findFiles(d, "java");
            if (javaFiles == {}) {
                continue;
            }
            libs = enrichClassPaths([*findFiles(d, "jar")], rootDir, corpusRoot);
            sourceDirs = [*findRoots({d})];
            <newM3s,newASTs> = createM3sAndAstsFromFiles(javaFiles, errorRecovery = false, sourcePath = sourceDirs, classPath = libs);
            if (newASTs == {}) {
               println("No asts returned in <d> exiting");
               return <m3(|error:///|), {}>;
            }
            m3s += newM3s;
            asts += newASTs;
        }
        return <composeJavaM3(rootDir.parent, m3s), asts>;
    }
    catch RuntimeException e: {
       println("Getting asts for <rootDir> failed: <e>");
       return <m3(|error:///|), {}>;
    }

}

tuple[M3 model, set[Declaration] asts] collectDataJDT(loc rootDir, loc corpusRoot) {
    subDirs = { d | d <- rootDir.ls, isDirectory(d)};
    m3s = {};
    asts = {};
    try {
        for (d <- subDirs, d.file != "jdk8") {
            println("\tProcessing JDT: <d>");
            subs = {dd + "src/" | dd <- d.ls, exists(dd + "src/"), isDirectory(dd + "src/")};
            javaFiles = { *findFiles(dd, "java") | dd <- subs };
            if (javaFiles == {}) {
                continue;
            }
            libs = enrichClassPaths([*findFiles(d, "jar")], rootDir, corpusRoot);
            sourceDirs = [*findRoots(subs)];
            <newM3s,newASTs> = createM3sAndAstsFromFiles(javaFiles, errorRecovery = false, sourcePath = sourceDirs, classPath = libs);
            if (newASTs == {}) {
               println("No asts returned in <d> exiting");
               return <m3(|error:///|), {}>;
            }
            m3s += newM3s;
            asts += newASTs;
        }
        return <composeJavaM3(rootDir, m3s), asts>;
    }
    catch RuntimeException e: {
       println("Getting asts for <rootDir> failed: <e>");
       return <m3(|error:///|), {}>;
    }

}
tuple[M3 model, set[Declaration] asts] tryIfMaven(loc dir, loc corpusRoot, loc mavenPath = |file:///usr/local/bin/mvn|) {
    if (l <- dir.ls, l.file == "pom.xml" || l.file == ".project") {
        // there is a root pom or eclipse project file, let's try that
        <newModel, newAsts> = collectWithMaven(dir, corpusRoot, mavenPath = mavenPath);
        if (newAsts != {}) {
            return <newModel, newAsts>;
        }
    }
    return <m3(|empty:///|), {}>;
}

tuple[M3 model, set[Declaration] asts] tryGetInformation(loc rootDir, loc corpusRoot, loc mavenPath = |file:///usr/local/bin/mvn|) {
    if (rootDir.file == "399-NetBeans_IDE") {
    return <m3(|error:///|), {}>;
        return collectDataNetbeans(rootDir, corpusRoot);
    }
    if (rootDir.file == "225-OpenJDK" || rootDir.file == "374-OpenJDK_6") {
        return collectDataOpenJDK(rootDir, corpusRoot);
    }
    if (rootDir.file == "098-Eclipse_Java_Development_Tools_JDT_") {
        return collectDataJDT(rootDir, corpusRoot);
    }
    if (rootDir.file == "401-Pentaho_Reporting") {
        return collectDataPentaho(rootDir, corpusRoot);
    }
    if (rootDir.file == "408-StarPound") {
        return <m3(|error:///|), {}>;
    
        return collectDataStarPound(rootDir, corpusRoot);
    }
    // directories are checkouts from git
    asts = {};
    models = {};
    failed = false;
    for (d <- rootDir.ls, !failed, isDirectory(d)) {
        // perhaps we are a kind of nested project going on
        <newModel, newAsts> = tryIfMaven(d, corpusRoot, mavenPath = mavenPath);
        if (newAsts != {}) {
            asts += newAsts;
            models += newModel;
            continue;
        }

        if (de <- d.ls, de.file == "src" || de.file == "code" || de.file == "java") {
            // either we are a root dir, or we are already calling ourself recursivly
            <newModel, newAsts> = collectGuessing(d, corpusRoot, mavenPath = mavenPath);
            if (newAsts != {}) {
                asts += newAsts;
                models += newModel;
                continue;
            }
        }
        // could be that there is a set of sub projects without a common maven file
        allMaven = true;
        mavenAsts = {};
        mavenModels = {};
        for (p <- d.ls, allMaven, isDirectory(p)) {
            <newModel, newAsts> = tryIfMaven(p, corpusRoot, mavenPath = mavenPath);
            allMaven = newAsts != {};
            mavenAsts += newAsts;
            mavenModels += newModel;
        }
        if (allMaven) {
            asts += mavenAsts;
            models += mavenModels;
            continue;
        }
        else {
            failed = true; // failed to handle this sub dir in itself
        }
    }
    if (failed) {
        return collectGuessing(rootDir, corpusRoot, mavenPath = mavenPath);
    }
    return <composeJavaM3(rootDir, models), asts>;
}


int main(str corpus = "/Users/davy/PhD/papers/reflections-on-reflection/data/corpus/contents/", str target= "/Users/davy/PhD/papers/reflections-on-reflection/data/corpus/parsed/", str mavenPath = "/usr/local/bin/mvn") {
    corpusRoot = |file:///| + corpus; 
    targetRoot = |compressed+file:///| + target; 
    for (d <- sort(corpusRoot.ls), isDirectory(d), /\/<name:[^\/]*>[\/]*$/ := d.path) {
        targetName = targetRoot + "<name>.bin.xz";
        if (!exists(targetName)) {
            println("Trying to get ASTs for: <d>");
            result = tryGetInformation(d, corpusRoot, mavenPath = |file:///| + mavenPath);
            if (result.asts != {}) {
                println("\tWriting results");
                writeBinaryValueFile(targetName, result, compression= false);
            }
        }
    }
	return 0;
}
