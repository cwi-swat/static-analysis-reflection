module \data::Utils

import Node;
import util::Math;
import Set;
import lang::java::m3::Core;
import lang::java::m3::keywords::AST;

public loc unknownSource = |unknown:///|;
public loc unresolvedDecl = |unresolved:///|;
data Expression 
    = implicitReceiver()
    | implicitContext()
    ;
    
    
@reflect
@javaClass{data.Utils}
public java Declaration pushThroughImplicits(Declaration decl);

public Declaration simplifyAST(Declaration decl) {
    decl = visit(decl) {
        // brackets are a bit annoying to think about every time
        case \bracket(e) => e

        // reduce the overloads:
        // by adding the implicit receiber
        case m:methodCall(bool isSuper, str name, list[Expression] arguments) => keepKW(m, methodCall(isSuper, implicitReceiver(src=m.src), name, arguments))
        case f:fieldAccess(bool isSuper, str name) => keepKW(f, fieldAccess(isSuper, implicitReceiver(src=f.src), name))
        // adding true condition in the infinite for loop
        case f:\for(list[Expression] initializers, list[Expression] updaters, Statement bd) => keepKW(f, \for(initializers, booleanLiteral(true), updaters, bd))
        // adding empty else branch
        case i:\if(Expression condition, Statement thenBranch) => keepKW(i, \if(condition, thenBranch, Statement::empty()))
        // adding empty finally
        case t:\try(Statement bd, list[Statement] catchClauses) => keepKW(t, \try(bd, catchClauses, Statement::empty()))
        // add implicit context
        case n:newObject(Type tp, list[Expression] args, Declaration class) => keepKW(n, newObject(implicitContext(src=n.src), tp, args, class)) 
        case n:newObject(Type tp, list[Expression] args) => keepKW(n, newObject(implicitContext(src=n.src), tp, args))
        case c:constructorCall(bool isSuper, list[Expression] arguments) => keepKW(c, constructorCall(isSuper, implicitContext(src = c.src), arguments))
        
    };
    
    return pushThroughImplicits(decl);
}

public Expression getSpecialReturnVariable(loc decl, TypeSymbol typ)
    = simpleName("$$$return$$$", decl=(decl + "$$$return$$$")[scheme="java+variable"], typ = typ);

public Declaration addReturnVariables(Declaration root) {
    returnVariable = getSpecialReturnVariable(root.decl, root.typ);
    return top-down-break visit (root) {
        case r:\return(v) : {
            // first handle nested declarations
            v = top-down-break visit (v) {
                case Declaration d => addReturnVariables(d)
            };
            insert block([
                expressionStatement(assignment(returnVariable[src = src(r)], "=", v, src = src(r), decl = returnVariable.decl)),
                r[expression = returnVariable[src=src(r)]]
            ]);
        }
        case Declaration d => addReturnVariables(d)
            when d != root
    }

}

loc src(&T <: node n) = res 
  when n has src && loc res := n.src && res != unknownSource;
default loc src(&T <: node n) {
  allsrc = { res | /node c := n, c has src, loc res := c.src, res != unknownSource};
  startOffset = min({l.offset | l <- allsrc, l.offset?});
  endOffset = max({l.offset + l.length | l <- allsrc, l.offset?});
  l = getOneFrom(allsrc).top;
  return l[offset=startOffset][length=endOffset-startOffset];
}

public &T <: node keepKW(node from, &T <: node to) 
    = setKeywordParameters(to, getKeywordParameters(from));
