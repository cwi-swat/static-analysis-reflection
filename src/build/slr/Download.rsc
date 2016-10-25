module build::slr::Download

import lang::csv::IO;
import List;
import IO;
import lang::html5::DOM;

alias ProgressData = lrel[int id, bool downloaded, loc source, str title, loc mainlink, loc otherVersionLink, loc directLink] ;

ProgressData getData(loc path)
    = readCSV(#ProgressData, path);

public set[str] mostCommonDomains
    = {"link.springer.com","digital-library.theiet.org","www.diva-portal.org","www.sciencedirect.com","ieeexplore.ieee.org","drops.dagstuhl.de","repository.tudelft.nl","journals.cambridge.org","www.jot.fm","www.usenix.org","www.google.com","oai.dtic.mil","citeseerx.ist.psu.edu","arxiv.org","lib.dr.iastate.edu","www.researchgate.net","tel.archives-ouvertes.fr","uwspace.uwaterloo.ca","books.google.com","hal.inria.fr","onlinelibrary.wiley.com","dl.acm.org"};    
    
void prepareDownloadList(set[str] ignoreDomains, loc target = |project://reflections-on-reflection/data/slr/|) {
    resultFile = target[scheme = "compressed+<target.scheme>"] + "progress.csv.xz";
    lrel[int id, str link, str backup] result
        = [<id, m.uri, dl == |invalid:///| ? "" : (m == dl) ? "" : dl.uri> | <id, false, _, _, m, _, dl> <- getData(resultFile), !(m.authority in ignoreDomains)];
    println("Joblist: <size(result)>");
    result = [ <i, l, b> | <i,l,b> <- result
        , /books.google.com/ !:= l + b
        , /google.com\/patent/ !:= l + b
        ];
    println("After filtering: <size(result)>");
    writeCSV(result, target + "worklist.csv");
}

str defrag(/^<bef:.*>#.*$/) = bef;
default str defrag(str s) = s;


void createCustomHTMLPage(loc target = |project://reflections-on-reflection/data/slr/|) {
    processed = getData(target[scheme = "compressed+<target.scheme>"] + "progress.csv.xz");
    res = html(
        head(title("Download by hand")),
        body(
            [
                h2("<id>"),
                p(
                    a(title, href(mainlink.uri), html5attr("data-paper-id","<id>")), br(),
                    a("Direct Link", href(directLink.uri), html5attr("data-paper-id","<id>")), br(),
                    a("Other version", href(otherVersionLink.uri), html5attr("data-paper-id","<id>"))
                ) | <int id, false, _, str title, loc mainlink, loc otherVersionLink, loc directLink> <- processed
                    , /books.google.com/ !:= mainlink.authority
                    , /google.com\/patent/ !:= mainlink.uri
            ]
        )
    );
    notFoundLinks = {*readFileLines(target + "not-found-links.txt")};
    res = visit (res) {
        case html5node("a", [*_, str title, *_,html5attr("href", str linkTarget),*_]) => span(title)
            when defrag(linkTarget) in notFoundLinks || linkTarget == "invalid:///"
    }
    writeFile(target + "manual-download.html", toString(res));
}

void updateDownloaded(loc dataDir = |project://reflections-on-reflection/data/slr/|) {
    resultFile = dataDir[scheme = "compressed+<dataDir.scheme>"] + "progress.csv.xz";
    int newDone = 0;
    ProgressData result;
    result = for (t:<id, downloaded, _, _, _, _, _> <- getData(resultFile)) {
        t.downloaded = exists(dataDir + "downloaded/<id>.pdf");
        if (!downloaded && t.downloaded) {
            newDone += 1;
        }
        append t;
    };
    println("New downloaded: <newDone>");
    writeCSV(result, resultFile);
}