module build::corpus::Worklist

import IO;
import Set;
import List;
import String;
import lang::csv::IO;
import lang::xml::IO;

alias CorpusData = lrel[int \id,str \name,str \homepageurl,str \downloadurl,str \urlname,
    int \usercount,num \averagerating,int \ratingcount,
    datetime \updatedat,datetime \loggedat,str \minmonth,str \maxmonth,
    int \twelvemonthcontributorcount,int \totalcodelines,
    int \mainlanguageid,str \mainlanguagename, // always the same, namely java
    int \codeadded12months,int \coderemoved12months,int \commentsadded12months,int \commentsremoved12months,int \blanksadded12months,int \blanksremoved12months,int \commits12months,
    int \codeaddedlastmonth,int \coderemovedlastmonth,int \commentsaddedlastmonth,int \commentsremovedlastmonth,int \blanksaddedlastmonth,int \blanksremovedlastmonth,int \commitslastmonth,int \contributorslastmonth,
    bool \FactoidGplConflict,bool \FactoidTeamSizeZero,bool \FactoidTeamSizeOne,bool \FactoidTeamSizeSmall,bool \FactoidTeamSizeLarge,bool \FactoidTeamSizeVeryLarge,bool \FactoidCommentsVeryLow,bool \FactoidCommentsLow,bool \FactoidCommentsHigh,bool \FactoidCommentsVeryHigh,bool \FactoidAgeYoung,bool \FactoidAgeOld,bool \FactoidAgeVeryOld,bool \FactoidActivityIncreasing,bool \FactoidActivityDecreasing,
    int \codechurn12months,str \FactoidActivity,str \FactoidAge,
    real \scoreincrease, real \score];
    
CorpusData getData()
    = readCSV(#CorpusData, |project://reflections-on-reflection/data/corpus/project-full-corpus.csv|);

CorpusData getData2()
    = readCSV(#CorpusData, |project://reflections-on-reflection/data/corpus/project-full-corpus-2.csv|);

CorpusData getData3()
    = readCSV(#CorpusData, |project://reflections-on-reflection/data/corpus/project-full-corpus-3.csv|);
    
node getEnlistmentData()
    = readXML(|compressed+project://reflections-on-reflection/data/corpus/corpus-enlistment.xml.xz|);
    
data SourceSystem(str username = "", str password = "")
    = hg(str url)
    | git(str url, str branch)
    | svn(str url)
    | bzr(str url)
    | cvs(str url, str moduleName)
    ; 

rel[int id, SourceSystem src] getSourceSystems()
    = { *translate(e) | /e:"enlistment"(_) := getEnlistmentData() };
    
set[int] getManualRepos()
    = {*getData().id} - getSourceSystems().id;
    
set[int] getPluralRepos() {
    mapped = toMap(getSourceSystems());
    return { i | i <- mapped, size(mapped[i]) > 3} + { id | <id, src> <- getSourceSystems(), src.username != "", src.username != "anonymous"};
}    

void writeManualWorklist() {
    lrel[int id, str name, str url, str ohlohUrl, str ohlohEnlistments] result = [];
    manuals = getManualRepos() + getPluralRepos();
    for (cd <- getData(), cd.id in manuals) {
        result += <cd.id, cd.name,
            "=HYPERLINK(\"<cd.homepageurl>\", \"Homepage\")",
            "=HYPERLINK(\"https://www.openhub.net/p/<cd.id>/\", \"Ohloh <cd.id>\")", 
            "=HYPERLINK(\"https://www.openhub.net/p/<cd.id>/enlistments\", \"Enlistmens <cd.id>\")">;
    }
    writeCSV(result, |project://reflections-on-reflection/corpus-construction/manual-phase1-list.csv|);
} 

void writeManualWorklist2() {
    lrel[int id, str name, str url, str ohlohUrl, str ohlohEnlistments] result = [];
    failures = readCSV(#rel[int id, str repo, str branch, str rev], |project://reflections-on-reflection/corpus-construction/downloader/failed-checkouts-global.csv|).id;
    failures -= getManualRepos() + getPluralRepos();
    for (cd <- getData(), cd.id in failures) {
        result += <cd.id, cd.name,
            "=HYPERLINK(\"<cd.homepageurl>\", \"Homepage\")",
            "=HYPERLINK(\"https://www.openhub.net/p/<cd.id>/\", \"Ohloh <cd.id>\")", 
            "=HYPERLINK(\"https://www.openhub.net/p/<cd.id>/enlistments\", \"Enlistmens <cd.id>\")">;
    }
    writeCSV(result, |project://reflections-on-reflection/corpus-construction/manual-phase2-list.csv|);
} 

void writeManualWorklist3() {
    lrel[int id, str name, str url, str ohlohUrl, str ohlohEnlistments] result = [];
    alreadyDone = { *(getData().id) };
    for (cd <- getData2(), !(cd.id in alreadyDone)) {
        result += <cd.id, cd.name,
            "=HYPERLINK(\"<cd.homepageurl>\", \"Homepage\")",
            "=HYPERLINK(\"https://www.openhub.net/p/<cd.id>/\", \"Ohloh <cd.id>\")", 
            "=HYPERLINK(\"https://www.openhub.net/p/<cd.id>/enlistments\", \"Enlistmens <cd.id>\")">;
    }
    writeCSV(result, |project://reflections-on-reflection/corpus-construction/manual-phase3-list.csv|);
} 

void writeManualWorklist4() {
    lrel[int id, str name, str url, str ohlohUrl, str ohlohEnlistments] result = [];
    alreadyDone = { *(getData2().id) };
    for (cd <- getData3(), !(cd.id in alreadyDone)) {
        result += <cd.id, cd.name,
            "=HYPERLINK(\"<cd.homepageurl>\", \"Homepage\")",
            "=HYPERLINK(\"https://www.openhub.net/p/<cd.id>/\", \"Ohloh <cd.id>\")", 
            "=HYPERLINK(\"https://www.openhub.net/p/<cd.id>/enlistments\", \"Enlistmens <cd.id>\")">;
    }
    writeCSV(result, |project://reflections-on-reflection/corpus-construction/manual-phase4-list.csv|);
} 

void deleteScript() {
    writeFile(|project://reflections-on-reflection/corpus-construction/delete.sh|, "#!/bin/bash
        '<for (id <- {*getData().id} - {*getData2().id}) {>
            rm ../data/corpus/projects/<id>-*
        '<}>
        ");
}

void writeManualSVNCheckList() {
    skips = getPluralRepos();
    svns = toMap({ <id, src> | <id, src:svn(_)> <- getSourceSystems(), !(id in skips)});

    lrel[int id, str name, str url, str ohlohUrl, str ohlohEnlistments] result = [];
    for (cd <- getData(), svns[cd.id]?, size(svns[cd.id]) > 1) {
        result += <cd.id, cd.name,
            "=HYPERLINK(\"<cd.homepageurl>\", \"Homepage\")",
            "=HYPERLINK(\"https://www.openhub.net/p/<cd.id>/\", \"Ohloh <cd.id>\")", 
            "=HYPERLINK(\"https://www.openhub.net/p/<cd.id>/enlistments\", \"Enlistmens <cd.id>\")">;
    }
    writeCSV(result, |project://reflections-on-reflection/corpus-construction/manual-svns-check-list.csv|);
}
    
void constructDownloadScript() {
    skips = getPluralRepos();
    int i = 0;
    int nextI() {
        i += 1;
        return i;
    }
    writeFile(|project://reflections-on-reflection/corpus-construction/download.sh|, "#!/bin/bash
        '<for (<id, src> <- getSourceSystems(), !(id in skips)) {>
            'echo \"---- <nextI()> : <id> ----\"
            '<call(id,src)> || echo \"<id>,<src.url>,,\" \>\> failed-checkouts-global.csv
        '<}>
        ");
}    

str call(int id, hg(url)) 
    = "./hg-downloader.sh <id> <url>";

str call(int id, bzr(url)) 
    = "./bzr-downloader.sh <id> <url>";

    
str call(int id, svn(url)) 
    = "./svn-downloader.sh <id> <url>";
    
str call(int id, cvs(url, modu)) 
    = "./cvs-downloader.sh <id> <url> <modu>";

str call(int id, git(url, br)) 
    = "./git-downloader.sh <id> <url> <br>";
    
    
rel[int id, SourceSystem src] translate("enlistment"([*_,"project_id"([pid]),*_, r:"repository"(_),*_]))
    = {<toInt(pid), translateRepo(r)>};
    
SourceSystem translateRepo("repository"(list[node] r))
    = repo(r, t, intercalate("/", url))[username = usr == [] ? "" : usr[0]][password = pwd == [] ? "" : pwd[0]]
    when "type"([t]) <- r, "url"(url) <- r, "username"(usr) <- r, "password"(pwd) <- r;
  
SourceSystem repo(list[node] r, "SvnRepository", str url)
    = svn(url);
SourceSystem repo(list[node] r, "SvnSyncRepository", str url)
    = svn(url);
SourceSystem repo(list[node] r, "BzrRepository", str url)
    = bzr(url);
SourceSystem repo(list[node] r, "HgRepository", str url)
    = hg(url);
SourceSystem repo(list[node] r, "GitRepository", str url)
    = git(url, "master"); // TODO: Ohloh appears to lack the branch information.
SourceSystem repo(list[node] r, "CvsRepository", str url)
    = cvs(url, moduleName)
    when "module_name"([moduleName]) <- r;
    
SourceSystem repo(list[node] r, str tp, str url) { throw "you forgot: <r> <tp> <url>"; }
default rel[int id, SourceSystem src] translate(node n) { throw "not matching: <n>";}
default SourceSystem translateRepo(node n) { throw "not matching: <n>";}