module build::corpus::Stats

import IO;
import lang::csv::IO;
import build::corpus::Worklist;

void calculateStats() {
    int i = 0;
    int projectsSeen() { i += 1; return i; }
    lrel[int nthProject, real covered, real coveredPercentage] result
        = [ <projectsSeen(), dt.score, dt.score * 100> | dt <- getData3()];
    
    writeCSV(result, |project://reflections-on-reflection/data/results/corpus-coverage.csv|);
    
    str getAnno(int project) {
        perc = result[project - 1].coveredPercentage;
        return "\\annotatePos{<project> = \\percentage{<perc>}}{<project>}{<perc>}";
    
    }
    writeFile(|project://reflections-on-reflection/data/results/corpus-coverage-callouts.tex|,
        "<getAnno(50)>%
        '<getAnno(100)>%
        '<getAnno(200)>%
        ");
}