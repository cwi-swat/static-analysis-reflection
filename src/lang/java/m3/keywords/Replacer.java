package lang.java.m3.keywords;

import java.util.Map;

import org.rascalmpl.value.IConstructor;
import org.rascalmpl.value.IValue;
import org.rascalmpl.value.IValueFactory;
import org.rascalmpl.value.visitors.BottomUpTransformer;
import org.rascalmpl.value.visitors.IdentityVisitor;

public class Replacer {
    private final class ReplaceAnnotations extends IdentityVisitor<RuntimeException> {
        @Override
        public IValue visitConstructor(IConstructor o) {
            if (o.isAnnotatable()) {
                Map<String, IValue> params = o.asAnnotatable().getAnnotations();
                return o.asAnnotatable().removeAnnotations().asWithKeywordParameters().setParameters(params);
            }
            return o;
        }
    }

    private final IValueFactory vf;

    public Replacer(IValueFactory vf) {
        this.vf = vf;
    }

    public IConstructor replaceAnnotations(IConstructor d) {
        return (IConstructor) d.accept(new BottomUpTransformer<RuntimeException>(new ReplaceAnnotations(), vf) {
            @Override
            public IValue visitConstructor(IConstructor o) throws RuntimeException {
                if (o.isAnnotatable() && o.getType().getName().equals("Declaration") && o.asAnnotatable().hasAnnotation("modifiers")) {
                    IValue mod = o.asAnnotatable().getAnnotation("modifiers");
                    if (mod != null) {
                        mod = mod.accept(this);
                        o = o.asAnnotatable().setAnnotation("modifiers", mod);
                    }
                }
                return super.visitConstructor(o);
            } 
        });
        
    }

}
