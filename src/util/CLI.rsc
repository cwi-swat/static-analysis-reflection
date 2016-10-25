module util::CLI
import IO;
import String;

tuple[void(str) reporter, void() finished] progressReporter(str prefix) {
    lastSize = 0;
    println();
    return <void (str msg) {
        // clear line
        print("\r<("" | it + " " | _ <- [0..lastSize])>");
        newMsg = prefix + msg;
        lastSize = size(newMsg);
        print("\r" + newMsg);
    }, void () { println(); }>;
}