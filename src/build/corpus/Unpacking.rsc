module build::corpus::Unpacking

import build::corpus::Worklist;
import IO;


str fixName(str s) {
    return visit(s) {
        case /[^A-Za-z0-9\-_.]+/ => "_"
    }
}

str formatCorpusID(int n) {
    if (n < 10) {
        return "00<n>";
    }
    if (n < 100) {
        return "0<n>";
    }
    return "<n>";
}

void makeUnpackingScript() {
    int i = 0;
    int getNextIndex() { i += 1; return i; }
    writeFile(|project://reflections-on-reflection/corpus-construction/unpack-all.sh|, "#!/bin/bash
        '<for (dr <- getData3()) {>
            'echo \"Unpacking: <dr.id>\"
            './unpacker.sh \"<dr.id>\" <formatCorpusID(getNextIndex())> \"<fixName(dr.name)>\" \"<dr.homepageurl>\" <dr.score> <dr.scoreincrease> || echo \"unpacking failed: <dr.id>\" \>\> global-unpacking-errors.log
        '<}>
    ");
}