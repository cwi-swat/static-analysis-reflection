package patterns;

import java.lang.reflect.Method;
import java.util.List;
import java.util.Map;

public class Difficult {
    public void incorrectCast1(Class<?> c) {
        try {
            Integer o = (Integer)c.newInstance();
            System.out.println(o);
        } catch (ClassCastException e) {
            e.printStackTrace();
        }
        catch (InstantiationException e) {
            e.printStackTrace();
        }
        catch (IllegalAccessException e) {
            e.printStackTrace();
        }
    }
    
    public Object exceptionControlFlow1(Class<?> c, Class<?> fallback) throws IllegalAccessException, InstantiationException {
        try {
           return c.newInstance(); 
        }
        catch (InstantiationException e) {
            return fallback.newInstance();
        }
    }
    
    public Object exceptionControlFlow2(Class<?>[] candidates) throws IllegalAccessException, InstantiationException {
        for (Class<?> c : candidates) {
            try {
               return c.newInstance(); 
            }
            catch (InstantiationException e) {
            }
        }
        return null;
    }
    
    public void metaObjectsInRandomIndexedCollections1(List<Method> methods) {
        System.out.println(methods.get(3));
    }
    public void metaObjectsInRandomIndexedCollections2(Method[] methods) {
        System.out.println(methods[3]);
    }

    public void metaObjectsInHashBasedCollections1(Map<String, Method> methods) {
        System.out.println(methods.get("Hello"));
    }
    
    
    public void metaObjectArrayResultingMethods1(Class<?> c) {
        for (Class<?> c1 : c.getClasses()) {
            if (c1.isAssignableFrom(this.getClass())) {
                System.out.println("Found it");
            }
        }
    }
    
    public void externalLibraries1(Class<?> c) {
        c.getField(ExternalStuff.callit()).getName();
    }
    
    public void loopOverCandidates1(Class<?>[] classes) {
        for (Class<?> c1 : classes) {
            if (c1.isInterface()) {
                System.out.println("Found it");
            }
        }
    }
    
    public Class<?> flowFromEnvironment(String s) throws ClassNotFoundException {
        return Class.forName(System.getenv(s));
    }

}
