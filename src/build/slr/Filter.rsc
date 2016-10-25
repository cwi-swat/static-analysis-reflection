module build::slr::Filter


import IO;
import Set;
import List;
import Relation;
import lang::csv::IO;
import build::slr::Download;

alias ReflectionCount
    = tuple[int id,str title,int pages,
        int proceeding5, int thesis5, int workPackage, int javascript, 
        int reflectionHead, int reflectionTail, int reflectionTailNoRefs, int reflectionFull,
        int langReflectHead, int langReflectFull,
        int accuracyHead, int accuracyTail, int accuracyFull];

    
set[ReflectionCount] get10PercentCounts()
    = readCSV(#set[ReflectionCount], |project://reflections-on-reflection/data/slr/reflection-counts-10percent.csv|);

set[ReflectionCount] get20PercentCounts()
    = readCSV(#set[ReflectionCount], |project://reflections-on-reflection/data/slr/reflection-counts-20percent.csv|);
    
    
set[ReflectionCount] getInterestingShortPapers(set[ReflectionCount] cnt)
    = { t | t <- cnt, 
        t.pages <= 80  // small papers
        && t.reflectionHead > 0 && (t.reflectionTail > 0 || t.reflectionTailNoRefs > 0) // reflection in both head an tail
        && t.accuracyFull > 0 // should at least contain the accuracy alike words
        && t.javascript < 5 // javascript papers tend to mention java reflection a few times, so if the paper contains a lot of javascript references, skip it
      }
    + { t | t <- cnt, 
        t.pages <= 40  // or the really small papers, almost certainly single papers
        && t.reflectionFull > 10  // with a lot of reflection in them
        && t.accuracyFull > 0 // should at least contain the accuracy alike words
        && t.javascript < 5 // javascript papers tend to mention java reflection a few times, so if the paper contains a lot of javascript references, skip it
      };

set[ReflectionCount] getInterestingThesis(set[ReflectionCount] cnt)
    = { t | t <- cnt, 
        t.pages > 50
        && t.thesis5 > 0
        && t.reflectionFull > 1 // must mention reflection at least 2 times
        && t.accuracyFull > 0 // should at least contain the accuracy alike words
        && t.langReflectFull > 0 // should have lang.reflect in there somewhere, else we get to many thesis that just mention reflection in passing, assumption is that a thesis about reflection must at least contain some example code
      };
      
set[ReflectionCount] getInterestingProceedings1(set[ReflectionCount] cnt)
    = { t | t <- cnt, 
        t.pages > 20
        && t.thesis5 == 0
        && t.proceeding5 > 0
        && t.reflectionFull > 0
        && t.langReflectFull > 0 //  this filters out a lot
      };  

set[ReflectionCount] getInterestingProceedings2(set[ReflectionCount] cnt)
    = { t | t <- cnt, 
        t.pages > 20
        && t.thesis5 == 0
        && t.proceeding5 > 0
        && t.reflectionFull > 5 // let's also read the proceedings with a lot of reflection mentions to be sure
      };  
      
set[ReflectionCount] getOtherReflectionPdfs(set[ReflectionCount] cnt)      
    = { t | t <- cnt, 
        t.pages > 80
        && t.thesis5 == 0
        && t.proceeding5 == 0
        && t.reflectionFull > 5 // let's also read the proceedings with a lot of reflection mentions to be sure
      };  
      
// .pdfs without a .txt
set[int] getNonOCRedPdfs() 
    = {
        1058,
        1358,
        1489,
        1849,
        1882,
        2209,
        2464,
        2696,
        2838,
        2918,
        3221,
        3247,
        3374,
        3544,
        3552,
        356,
        361,
        3710,
        3835,
        3843,
        3892,
        3898,
        3930,
        3956,
        3967,
        4052,
        4128,
        4280,
        44,
        50,
        560,
        65,
        706,
        795,
        804,
        927,
        976
    };

set[ReflectionCount] get10OrMore(set[ReflectionCount] cnt)      
     = { t | t <- cnt, 
        t.pages <= 40  // or the really small papers, almost certainly single papers
        && t.reflectionFull >= 10  // with a lot of reflection in them
        && t.accuracyFull > 0 // should at least contain the accuracy alike words
        && t.javascript < 5 // javascript papers tend to mention java reflection a few times, so if the paper contains a lot of javascript references, skip it
      };
    
    
void writeWorkList() {
    dt = get10PercentCounts();
    map[int id, str title] titles = toMapUnique(getData(|compressed+project://reflections-on-reflection/data/slr/progress.csv.xz|)<id, title>);
    lrel[int id, str title, str kind] result = [];
    seen = {};
    void add(set[int] ids, str label) {
        result += [<id, titles[id], label> | id <- sort([*(ids - seen)])];
        seen += ids;
    }
    add(getInterestingShortPapers(dt).id, "Normal paper");
    add(getInterestingThesis(dt).id, "Thesis pdf");
    add(getInterestingProceedings1(dt).id, "Multiple paper pdf");
    add(getInterestingProceedings2(dt).id, "Multiple paper pdf");
    add(getOtherReflectionPdfs(dt).id, "Leftover pdf");
    add(getNonOCRedPdfs(), "NON OCR pdf");
    
    str fourLong(int n) {
        if (n < 100) {
            return "00<n>";
        }
        if (n < 1000) {
            return "0<n>";
        }
        return "<n>";
    }
    for (id <- sort(get10OrMore(dt).id - seen)) {
        println("=HYPERLINK(\"http://homepages.cwi.nl/~landman/reflection/downloaded/<id>.pdf\",\"<fourLong(id)>\")");
    }
    for (id <- sort(get10OrMore(dt).id - seen)) {
        println(id);
    }
    println("sz: <size(get10OrMore(dt).id - seen)>");
    writeCSV(result, |project://reflections-on-reflection/data/slr/pdfs-to-read.csv|);
}

// what about smalltalk?