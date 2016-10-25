package data;

import java.util.Deque;
import java.util.LinkedList;

import org.rascalmpl.interpreter.IEvaluatorContext;
import org.rascalmpl.uri.URIUtil;
import org.rascalmpl.value.IConstructor;
import org.rascalmpl.value.ISourceLocation;
import org.rascalmpl.value.IValue;
import org.rascalmpl.value.IValueFactory;
import org.rascalmpl.value.type.Type;
import org.rascalmpl.value.type.TypeFactory;
import org.rascalmpl.value.type.TypeStore;
import org.rascalmpl.value.visitors.BottomUpTransformer;
import org.rascalmpl.value.visitors.IdentityVisitor;

public class Utils {
    
    private final IValueFactory vf;

    public Utils(IValueFactory vf) {
        this.vf = vf;
    }
    

    public IConstructor pushThroughImplicits(IConstructor decl, IEvaluatorContext ctx) {
        IConstructor empty = getEmptyADT(ctx);
        return (IConstructor) decl.accept(new BottomUpTransformer<RuntimeException>(new IdentityVisitor<RuntimeException>() {}, vf) {

            final Deque<IConstructor> interestingParents = new LinkedList<>();

            @Override
            public IValue visitConstructor(IConstructor o) throws RuntimeException {
                boolean pushedParent = false;
                try {
                    switch (o.getName()) {
                        case "class":
                        case "enum":
                        case "interface":
                        case "initializer":
                            interestingParents.push(o);
                            pushedParent = true;
                            break;
                        case "implicitReceiver":
                            IConstructor parent = interestingParents.peek();
                            if (parent.getName().equals("initializer")) {
                                return empty;
                            }
                            else  {
                                IValue classDecl = parent.asWithKeywordParameters().getParameter("decl");
                                if (classDecl != null && classDecl instanceof ISourceLocation && !((ISourceLocation)classDecl).getScheme().equals("unresolved")) {
                                    ISourceLocation thisDecl = URIUtil.getChildLocation((ISourceLocation)classDecl, "this");
                                    thisDecl = URIUtil.correctLocation("java+field", thisDecl.getAuthority(), thisDecl.getPath());
                                    o = o.asWithKeywordParameters().setParameter("decl", thisDecl);
                                }
                            }
                            break;
                    }
                    return super.visitConstructor(o);
                }
                finally {
                    if (pushedParent) {
                        interestingParents.pop();
                    }
                }
            }
        });
        
    }


    private IConstructor getEmptyADT(IEvaluatorContext ctx) {
        TypeStore moduleStore = ctx.getHeap().getModule("lang::java::m3::keywords::AST").getStore();
        Type exprADT = moduleStore.lookupAbstractDataType("Expression");
        Type emptyConstructor = moduleStore.lookupConstructor(exprADT, "null", TypeFactory.getInstance().tupleEmpty());
        return vf.constructor(emptyConstructor);
    }
    

}
