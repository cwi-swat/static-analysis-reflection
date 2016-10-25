module build::slr::Scrape

import lang::html::IO;
import IO;
import String;
import ValueIO;


lrel[loc source, str title, loc mainlink, loc otherVersionLink, loc directLink] scrapeFolder(loc sourceFolder, str extension = ".html.xz") 
    = [ <l, t, m, v, d>  | l <- sourceFolder.ls, endsWith(l.file, extension), <t,m,v,d> <- scrapePage(l) ];
  
  
lrel[str title, loc mainlink, loc otherVersionLink, loc directLink] scrapePage(loc page) 
    = [ <title(art), mainLink(art), otherVersionLink(art), directLink(art)> | /"div"(art,class="gs_r") := readHTMLFile(page), /text("[CITATION]") !:= art ];
    
str title(list[node] n)
    = flatten(cont)
    when /"h3"(cont) := n;
    
    
loc toLoc(str s) {
    if (startsWith(s, "/")) {
        s = "https://scholar.google.com" + s;
    }
    s = replaceAll(s, "[", "%5B");
    s = replaceAll(s, "]", "%5D");
    return readTextValueString(#loc, "|<s>|");
}
    
loc mainLink(list[node] n) 
    = toLoc(l)
    when /"h3"([*_,"a"(_,href=str l)]) := n
    ;
default loc mainLink(list[node] n) = |invalid:///|;

loc otherVersionLink(list[node] n) 
    = toLoc(l)
    when /"a"([text(str cap)], href=str l, class="gs_nph") := n
    && /All [0-9]* version/ := cap
    ;
default loc otherVersionLink(list[node] n) = |invalid:///|;

loc directLink(list[node] n)
    = toLoc(l)
    when /"a"(["span"(_,class="gs_ggsL"),*_], href=str l) := n
    ;
default loc directLink(list[node] n) = |invalid:///|;
    
str flatten(value n) {
    result = "";
    visit(n) {
        case "text"(st) :
            if (!(startsWith(st, "[")  && endsWith(st, "]"))) {
                result += st;
            }
    }
    return trim(result);
}