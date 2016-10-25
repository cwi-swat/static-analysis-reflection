module \data::Corpus

import IO;
import ValueIO;
import \data::Utils;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::keywords::AST;

alias ASTData = rel[str project, M3 model, set[Declaration] asts, rel[Declaration origin, Statement body] codeblocks];
alias ASTDataSingle = tuple[M3 model, set[Declaration] asts, rel[Declaration origin, Statement body] codeblocks];

ASTData getFirst(int n) {
    dtFile = |compressed+project://reflections-on-reflection/data/ast-sets/joined-1-<"<n>">.bin.xz|;
    if (!exists(dtFile)) {
        println("Calculating subset of corpus 1-<n>");
        result = getData(n);
        writeBinaryValueFile(dtFile, result, compression=false);
        return result;
    }
    return readBinaryValueFile(#ASTData, dtFile);
}

ASTDataSingle getData(loc prj) {
    cachedFile = prj[file = (prj[extension=""][extension=""].file) + "-cached.xz"];
    if (exists(cachedFile)) {
        return readBinaryValueFile(#ASTDataSingle, cachedFile);
    }
    <model, asts> = readBinaryValueFile(#tuple[M3,set[Declaration]], prj);
    asts = { simplifyAST(replaceAnnotations(d)) | d <- asts};
    codeBlocks = findCodeBlocks(asts);
    projectName = prj[extension=""][extension=""].file;
    ASTDataSingle result = <model, asts, codeBlocks>;
    writeBinaryValueFile(cachedFile, result, compression=false);
    return result;
}

private ASTData getData(int n) {
    ASTData result = {};
    validProjects = { "<i>" | i <- [1..n+1]};
    for (prj <- |compressed+project://reflections-on-reflection/data/corpus/parsed|.ls, /\/[0]*<id:[1-9][0-9]*>-/ := prj.path, id in validProjects) {
        <model, asts, codeBlocks> = getData(prj);
        projectName = prj[extension=""][extension=""].file;
        result += <projectName, model, asts, codeBlocks>;
    }
    return result;
}

public rel[Declaration origin, Statement body] findCodeBlocks(set[Declaration] astData) 
  = { <m, body> | /m:method(_,_,_,_, Statement body) := astData }
  + { <c, body> | /c:constructor(_,_,_, Statement body) := astData }
  + { <i, body> | /i:initializer(Statement body) := astData }
  + { <keepKW(fr, field(n,[fr])), keepKW(fr, expressionStatement(fr))> | /field(n, fragments) := astData, fr <- fragments }
  ;
