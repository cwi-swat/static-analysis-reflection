module model::limitations::DifficultCases


import String;
import Set;
import Map;
import Node;
import IO;
import Relation;
import List;
import util::Benchmark;
import \data::Utils;
import \data::JREs;
import lang::java::m3::Core;
import lang::java::m3::TypeSymbol;
import lang::java::m3::keywords::AST;
import model::reflection::Grammar;
import model::reflection::Categories;
import model::limitations::Collections;

bool isHarmfullReflection(Expression n) 
    = n.decl in harmfullReflectionMethods();

data HarmfullPattern
    = incorrectCast()
    | exceptionControlFlow()
    | exceptionControlFlowLoop()
    | metaObjectsInRandomIndexedCollections()
    | metaObjectsInHashBasedCollections()
    | metaObjectArrayResultingMethods()
    | externalLibraries()
    | stringsFromEnvironment()
    | loopOverCandidates()
    ;
    
alias PatternResults = lrel[loc src, HarmfullPattern pattern];
    


// from: Improving static resolution of dynamic class loading in Java using dynamically gathered environment information
// by Jason Sawin and Atanas Rountev
// more APIs added
set[loc] environmentMethods = {
    |java+method:///java/lang/System/getenv(java.lang.String)|,
    |java+method:///java/lang/System/getenv()|,
    |java+method:///java/lang/System/getProperty(java.lang.String)|,
    |java+method:///java/lang/System/getProperties()|,
    |java+method:///java/lang/System/getProperty(java.lang.String,java.lang.String)|,
    |java+method:///java/security/Security/getProperty(java.lang.String)|,
    |java+method:///sun/security/action/GetPropertyAction(java.lang.String)|,
    |java+method:///sun/security/action/GetPropertyAction(java.lang.String,java.lang.String)|,
    |java+method:///java/awt/Toolki/getProperty(java.lang.String)|
};

loc classCastException = |java+class:///java/lang/ClassCastException|;
set[loc] interestingReflectionMethods = lookupReflectionProductions<1,0>[(toRel(lookupCategory)<1,0>)[harmfullCategories]];
set[loc] getMetaObjectArrayMethods = lookupReflectionProductions<1,0>[{getClassAndClasses(), getMethods(), getMethods(isSun=true), getConstructors(), getFields(), getInterfaces()}];
//set[loc] checkSignatureMethods = lookupReflectionProductions<1,0>[{getType(), getDeclaringClass(), isAssignableFrom(), isInstance(),  getName(), isSignature() }];
set[loc] checkSignatureMethods = lookupReflectionProductions<1,0>[(toRel(lookupCategory)<1,0>)[{traverseMetaObject(),signature()}] - {getClassLoader()}];
set[loc] castableMethods = lookupReflectionProductions<1,0>[{ invoke(), invoke(isSun=true), newInstance(), fieldGet(), constructorNewInstance() }];
set[loc] stringToMetaObjectMethods = lookupReflectionProductions<1,0>[{getMethod(), getMethod(isSun=true), getField(), forName(), forNameClassLoader() }];

@memo
private bool containsReflection(Statement st) {
    for (/Expression e := st) {
        if (e.decl in interestingReflectionMethods) {
            return true;
        }
    }
    return false;
}
private bool containsReflection(list[Statement] stms) {
    for (s <- stms) {
        if (containsReflection(s)) {
            return true;
        }
    }
    return false;
}

private bool containsCastableReflection(Statement st) {
    for (/m:methodCall(_,_,_,_) := st) {
        if (m.decl in castableMethods) {
            return true;
        }
    }
    return false;
}


bool anyNonThrowingCatch(list[Statement] catches) {
    for (\catch(_,cb) <- catches, /\throw(_) !:= cb) {
        if (/str s := cb, contains(toLowerCase(s), "log") || contains(toLowerCase(s), "err")) {
            continue;
        }
        return true;
    }
    return false;
}
private bool hasTryWithReflectionCatchWithoutThrowOrLog(Statement body) {
    for (/t:\try(bd,catches,_) := body, containsReflection(bd), anyNonThrowingCatch(catches)) {
        return true;
    }
    return false;
}

@memo
private set[loc] jreEntities(loc root) = (getJRE7(root = root)@containment)<1>;



loc javaEquals = |java+method:///java/lang/Object/equals(java.lang.Object)|;

PatternResults detect(M3 model, set[Declaration] asts, loc root) {
    <randomGetters, otherGetters> = getCollectionGettersMethods(root = root);
    bothGetters = randomGetters + otherGetters;
    ownAndJREMethods = (model@declarations)<0> + jreEntities(root);
    PatternResults result = [];
    visit(asts) {
        case m:methodCall(_,recv,_,args) : {
            if (m.decl in bothGetters, /\class(cl,_) := m.typ, cl in metaObjectClasses) {
                if (m.decl in randomGetters) {
                    result += <m.src, metaObjectsInRandomIndexedCollections()>;
                }
                else {
                    result += <m.src, metaObjectsInHashBasedCollections()>;
                }
            }
            if (m.decl in getMetaObjectArrayMethods, /array(_,1) := m.typ) {
                result += <m.src, metaObjectArrayResultingMethods()>;
            }
            if (m.decl in stringToMetaObjectMethods) {
                for (/m2:methodCall(_,_,_,_) := args, m2.decl in environmentMethods) {
                    result += <m.src, stringsFromEnvironment()>;
                    break;
                }
            }

        }
        case a:arrayAccess(_,_) : {
            if (/class(cl,_) := a.typ, cl in metaObjectClasses) {
                result += <a.src, metaObjectsInRandomIndexedCollections()>;
            }
        }

        case t:\try(body, catches, _): {
            if (containsReflection(body) && containsReflection(catches)) {
                result += <t.src, exceptionControlFlow()>;
            }
            for (c:\catch(excep, bod) <- catches, /class(classCastException, _) := excep.typ, containsCastableReflection(body), anyNonThrowingCatch([c])) {
                result += <c.src, incorrectCast()>;
            }
        }
        case Statement s: 
            if ((s is \do || s is \while || s is \for || s is \foreach)) {
                if (hasTryWithReflectionCatchWithoutThrowOrLog(s.body)) {
                    result += <s.src, exceptionControlFlowLoop()>;
                }
                for (/m:methodCall(recv,_,name,_) := s.body, m.decl in checkSignatureMethods || (name == "equals" && m.decl == javaEquals && (/class(tp,_) := recv && tp in metaObjectClasses))) {
                    if (containsReflection(s.body)) {
                        result += <m.src, loopOverCandidates()>;
                        break;
                    }
                }
            }
            else 
                fail;

    }
    return result;
}


public void testDetectors(loc home=|home:///PhD/papers/reflections-on-reflection/|) {
    targetFile = home + "/reflections-on-reflection/test/patterns/Difficult.java";
    model = createM3FromFile(targetFile, errorRecovery = true);
    ast = simplifyAST(replaceAnnotations(createAstFromFile(targetFile, true, errorRecovery = true)));
    //iprintln(ast);
    result = detect(model, {ast}, home[scheme = "compressed+" + home.scheme] + "/reflections-on-reflection/data/");
    iprintln(sort(result));
}
