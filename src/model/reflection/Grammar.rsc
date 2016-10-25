module model::reflection::Grammar

import Set;
import String;
//import \data::Utils;
import lang::java::m3::keywords::AST;
import lang::java::m3::TypeSymbol;

data ReflectionProduction
    = getClassLoader()
    | getSystemClassLoader()
    | newClassLoader()
    | classLoaderGetParent()
    
    | forName()
    | forNameClassLoader()
    | loadClass()
    | staticClass()
    | objectGetClass()
    | getClassAndClasses()
    | getInterfaces()
    | getType()
    | asSubclass()
    | getDeclaringClass()
    
    | getMethods(bool isSun = false)  // sun has 1st arg instead of receiver
    | getMethod(bool isSun = false)
    | getEnclosingMethod()
    
    | getConstructors()
    | getConstructor()
    | getEnclosingConstructor()
    
    | getFields()
    | getField()
    
    | constructorNewInstance()
    | newInstance()
    | invoke(bool isSun = false)
    | fieldGet()
    | cast()
    | newProxyInstance()

    | fieldSet()
    
    
    // new non interesting ones
    | getInvocationHandler()
    | getProxyClass()
    | isAssignableFrom()
    | isInstance()
    | arrayGet()
    | arrayNewInstance()
    | arraySet()
    | desiredAssertionStatus()
    | getAnnotation()
    | getAnnotations()
    | getDefaultValue()
    | getEnumConstants()
    | getModifiers()
    | getName()
    | getPackage()
    | getProtectionDomain()
    | getResource()
    | getResourceCL()
    | getSigners()
    | isAccessible()
    | isAnnotationPresent()
    | isSignature()
    | metaObjectEquals()
    | setAccessible()
    | setAssertionStatusSpecific()
    | setclearAssertionStatus()
    | toString()
    ;
    

loc javaEquals = |java+method:///java/lang/Object/equals(java.lang.Object)|;

alias ReflectionCalls = lrel[Expression, ReflectionProduction];


public set[loc] metaObjectClasses = {
    |java+class:///java/lang/Class|,
    |java+class:///java/lang/reflect/Method|,
    |java+class:///java/lang/reflect/Field|,
    |java+class:///java/lang/reflect/Constructor|
};

ReflectionCalls detectReflectionProductions(Statement body) {
    ReflectionCalls result = [ <e, staticClass()> | /e:Expression::\type(_) := body ];
    for (/m:methodCall(_,r,name,_) := body) {
        if (m.decl in reflectionMethodLookup) {
            result += <m, reflectionMethodLookup[m.decl]>;
        }
        else if (m.decl == javaEquals && name == "equals") {
            if (class(tp,_) := r.typ && tp in metaObjectClasses) {
                result += <m, metaObjectEquals()>;
            }
        }
    }
    for (/i:infix(l, op, r) := body, op == "==" || op == "!=") {
        if (class(tp,_) := l.typ && tp in metaObjectClasses) {
            result += <l, metaObjectEquals()>;
        }
        else if (class(tp,_) := r.typ && tp in metaObjectClasses) {
            result += <l, metaObjectEquals()>;
        }
    }
    for (/i:infix(l, op, r) := body, op == "+") {
        if (class(tp,_) := l.typ && tp in metaObjectClasses) {
            result += <l, toString()>;
        }
        else if (class(tp,_) := r.typ && tp in metaObjectClasses) {
            result += <l, toString()>;
        }
    }
    return result;
}
    
@memo
public set[loc] harmfullReflectionMethods() = lookupReflectionProductions<1,0>[{forName(), forNameClassLoader(), loadClass(), 
    constructorNewInstance(), newInstance(), invoke(), invoke(isSun = true), fieldGet(), cast(), newProxyInstance(), fieldSet() }];
    
public set[ReflectionProduction] reflectionReceiverOnly = {
    getClassLoader(), classLoaderGetParent(),
    objectGetClass(), staticClass(),getClassAndClasses(), getInterfaces(), getType(), getDeclaringClass(), 
    getEnclosingConstructor(), getEnclosingMethod(), getMethods(), getMethods(isSun = true), getConstructors(), getFields(),
    constructorNewInstance(), newInstance(), invoke(), fieldGet(), fieldSet(), cast()
};

public set[ReflectionProduction] reflectionIgnoreReceiver = {
    getSystemClassLoader(), newClassLoader(),forName(), forNameClassLoader(), 
    getMethods(isSun = true), getMethod(isSun=true), 
    invoke(isSun=true),newProxyInstance()
};

public rel[ReflectionProduction,int] reflectionInterestingArgs = {
    <newClassLoader(), 0>,

    <forName(), 0>,
    <forNameClassLoader(), 0>,
    <forNameClassLoader(), 1>,
    <forNameClassLoader(), 2>,
    <loadClass(), 0>,

    <asSubclass(), 0>,

    <getMethod(), 0>,
    <getMethod(), 1>,
    <getMethods(isSun = true), 0>,
    <getMethod(isSun = true), 0>,
    <getMethod(isSun = true), 1>,
    <getMethod(isSun = true), 2>,

    <getConstructors(), 0>,
    
    <getField(), 0>,

    <newProxyInstance(), 0>,
    <newProxyInstance(), 1>,
    <invoke(isSun = true), 0>
};


public set[ReflectionProduction] returningMetaObjects = {
    getClassLoader(), getSystemClassLoader(), newClassLoader(), classLoaderGetParent(),
    forName(), forNameClassLoader(), loadClass(), staticClass(), objectGetClass(), getClassAndClasses(), getInterfaces(), getType(), asSubclass(), getDeclaringClass(),
    getMethods(), getMethods(isSun = true), getMethod(), getMethod(isSun = true), getEnclosingMethod(),
    getConstructors(), getConstructor(), getEnclosingConstructor(),
    getFields(), getField()
};



rel[loc, &T] expandDifference(rel[loc, &T] locs) 
    // sometimes the JDT dropped the <?> from a signature
    = { <l,e>, <l[path = replaceAll(l.path, "\<?\>", "")], e> | <l, e> <- locs }
    ;

public rel[loc, ReflectionProduction] lookupReflectionProductions = expandDifference({
    // asserts
    <|java+method:///java/lang/Class/desiredAssertionStatus()|, desiredAssertionStatus()>,
    <|java+method:///java/lang/ClassLoader/setClassAssertionStatus(java.lang.String,boolean)|, setAssertionStatusSpecific()>,
    <|java+method:///java/lang/ClassLoader/setPackageAssertionStatus(java.lang.String,boolean)|,setAssertionStatusSpecific()>,
    <|java+method:///java/lang/ClassLoader/setDefaultAssertionStatus(boolean)|, setclearAssertionStatus()>,
    <|java+method:///java/lang/ClassLoader/clearAssertionStatus()|, setclearAssertionStatus()>,

    // security
    <|java+method:///java/lang/Class/getSigners()|, getSigners()>,
    <|java+method:///java/lang/Class/getProtectionDomain()|, getProtectionDomain()>,

// annotations
    <|java+method:///java/lang/reflect/AccessibleObject/getAnnotation(java.lang.Class%3CT%3E)|, getAnnotation()>,
    <|java+method:///java/lang/Class/getAnnotation(java.lang.Class%3CA%3E)|, getAnnotation()>,
    <|java+method:///java/lang/reflect/Constructor/getAnnotation(java.lang.Class%3CT%3E)|, getAnnotation()>,
    <|java+method:///java/lang/reflect/Field/getAnnotation(java.lang.Class%3CT%3E)|, getAnnotation()>,
    <|java+method:///java/lang/reflect/Method/getAnnotation(java.lang.Class%3CT%3E)|, getAnnotation()>,
    <|java+method:///java/lang/reflect/AccessibleObject/isAnnotationPresent(java.lang.Class%3C%3Fextendsjava.lang.annotation.Annotation%3E)|, isAnnotationPresent()>,
    <|java+method:///java/lang/Class/isAnnotationPresent(java.lang.Class%3C%3Fextendsjava.lang.annotation.Annotation%3E)|, isAnnotationPresent()>,
    <|java+method:///java/lang/reflect/Constructor/isAnnotationPresent(java.lang.Class%3C%3Fextendsjava.lang.annotation.Annotation%3E)|, isAnnotationPresent()>,
    <|java+method:///java/lang/reflect/Method/isAnnotationPresent(java.lang.Class%3C%3Fextendsjava.lang.annotation.Annotation%3E)|, isAnnotationPresent()>,
    <|java+method:///java/lang/reflect/Field/isAnnotationPresent(java.lang.Class%3C%3Fextendsjava.lang.annotation.Annotation%3E)|, isAnnotationPresent()>,
    <|java+method:///java/lang/Class/getAnnotations()|, getAnnotations()>,
    <|java+method:///java/lang/Class/getDeclaredAnnotations()|, getAnnotations()>,
    <|java+method:///java/lang/reflect/AccessibleObject/getAnnotations()|, getAnnotations()>,
    <|java+method:///java/lang/reflect/AccessibleObject/getDeclaredAnnotations()|, getAnnotations()>,
    <|java+method:///java/lang/reflect/Constructor/getDeclaredAnnotations()|, getAnnotations()>,
    <|java+method:///java/lang/reflect/Constructor/getParameterAnnotations()|, getAnnotations()>,
    <|java+method:///java/lang/reflect/Field/getDeclaredAnnotations()|, getAnnotations()>,
    <|java+method:///java/lang/reflect/Method/getDeclaredAnnotations()|, getAnnotations()>,
    <|java+method:///java/lang/reflect/Method/getParameterAnnotations()|, getAnnotations()>,
    <|java+method:///java/lang/reflect/Method/getDefaultValue()|, getDefaultValue()>,

// strings
    <|java+method:///java/lang/Class/getCanonicalName()|, getName()>,
    <|java+method:///java/lang/Class/getName()|, getName()>,
    <|java+method:///java/lang/Class/getSimpleName()|, getName()>,
    <|java+method:///java/lang/reflect/Member/getName()|, getName()>,
    <|java+method:///java/lang/reflect/Constructor/getName()|, getName()>,
    <|java+method:///java/lang/reflect/Field/getName()|, getName()>,
    <|java+method:///java/lang/reflect/Method/getName()|, getName()>,
    <|java+method:///java/lang/Class/toGenericString()|, toString()>,
    <|java+method:///java/lang/Class/toString()|, toString()>,
    <|java+method:///java/lang/reflect/Constructor/toGenericString()|, toString()>,
    <|java+method:///java/lang/reflect/Constructor/toString()|, toString()>,
    <|java+method:///java/lang/reflect/Field/toGenericString()|, toString()>,
    <|java+method:///java/lang/reflect/Field/toString()|, toString()>,
    <|java+method:///java/lang/reflect/Method/toGenericString()|, toString()>,
    <|java+method:///java/lang/reflect/Method/toString()|, toString()>,
    <|java+method:///java/lang/Class/getPackage()|, getPackage()>,

// ?
    <|java+method:///java/lang/Class/getEnumConstants()|, getEnumConstants()>,

// modifiers
    <|java+method:///java/lang/Class/getModifiers()|, getModifiers()>,
    <|java+method:///java/lang/reflect/Member/getModifiers()|, getModifiers()>,
    <|java+method:///java/lang/reflect/Constructor/getModifiers()|, getModifiers()>,
    <|java+method:///java/lang/reflect/Field/getModifiers()|, getModifiers()>,
    <|java+method:///java/lang/reflect/Method/getModifiers()|, getModifiers()>,

// resources
    <|java+method:///java/lang/Class/getResource(java.lang.String)|, getResource()>,
    <|java+method:///java/lang/Class/getResourceAsStream(java.lang.String)|, getResource()>,
    <|java+method:///java/lang/ClassLoader/getResource(java.lang.String)|, getResourceCL()>,
    <|java+method:///java/lang/ClassLoader/getResourceAsStream(java.lang.String)|, getResourceCL()>,
    <|java+method:///java/lang/ClassLoader/getResources(java.lang.String)|, getResourceCL()>,
    <|java+method:///java/lang/ClassLoader/getSystemResource(java.lang.String)|, getResourceCL()>,
    <|java+method:///java/lang/ClassLoader/getSystemResourceAsStream(java.lang.String)|, getResourceCL()>,
    <|java+method:///java/lang/ClassLoader/getSystemResources(java.lang.String)|, getResourceCL()>,

    <|java+method:///java/lang/Class/isAnnotation()|, isSignature()>,
    <|java+method:///java/lang/Class/isAnonymousClass()|, isSignature()>,
    <|java+method:///java/lang/Class/isArray()|, isSignature()>,
    <|java+method:///java/lang/Class/isEnum()|, isSignature()>,
    <|java+method:///java/lang/Class/isInterface()|, isSignature()>,
    <|java+method:///java/lang/Class/isLocalClass()|, isSignature()>,
    <|java+method:///java/lang/Class/isMemberClass()|, isSignature()>,
    <|java+method:///java/lang/Class/isPrimitive()|, isSignature()>,
    <|java+method:///java/lang/Class/isSynthetic()|, isSignature()>,
    <|java+method:///java/lang/reflect/Member/isSynthetic()|, isSignature()>,
    <|java+method:///java/lang/reflect/Constructor/isSynthetic()|, isSignature()>,
    <|java+method:///java/lang/reflect/Constructor/isVarArgs()|, isSignature()>,
    <|java+method:///java/lang/reflect/Field/isEnumConstant()|, isSignature()>,
    <|java+method:///java/lang/reflect/Field/isSynthetic()|, isSignature()>,
    <|java+method:///java/lang/reflect/Method/isBridge()|, isSignature()>,
    <|java+method:///java/lang/reflect/Method/isSynthetic()|, isSignature()>,
    <|java+method:///java/lang/reflect/Method/isVarArgs()|, isSignature()>,

    <|java+method:///java/lang/Class/isAssignableFrom(java.lang.Class%3C%3F%3E)|, isAssignableFrom()>,
    <|java+method:///java/lang/Class/isInstance(java.lang.Object)|, isInstance()>,

    <|java+method:///java/lang/reflect/AccessibleObject/isAccessible()|, isAccessible()>,
    <|java+method:///java/lang/reflect/AccessibleObject/setAccessible(boolean)|, setAccessible()>,
    <|java+method:///java/lang/reflect/AccessibleObject/setAccessible(java.lang.reflect.AccessibleObject%5B%5D,boolean)|, setAccessible()>,

    <|java+method:///java/lang/reflect/Array/get(java.lang.Object,int)|, arrayGet()>,
    <|java+method:///java/lang/reflect/Array/getBoolean(java.lang.Object,int)|, arrayGet()>,
    <|java+method:///java/lang/reflect/Array/getByte(java.lang.Object,int)|, arrayGet()>,
    <|java+method:///java/lang/reflect/Array/getChar(java.lang.Object,int)|, arrayGet()>,
    <|java+method:///java/lang/reflect/Array/getDouble(java.lang.Object,int)|, arrayGet()>,
    <|java+method:///java/lang/reflect/Array/getFloat(java.lang.Object,int)|, arrayGet()>,
    <|java+method:///java/lang/reflect/Array/getInt(java.lang.Object,int)|, arrayGet()>,
    <|java+method:///java/lang/reflect/Array/getLength(java.lang.Object)|, arrayGet()>,
    <|java+method:///java/lang/reflect/Array/getLong(java.lang.Object,int)|, arrayGet()>,
    <|java+method:///java/lang/reflect/Array/getShort(java.lang.Object,int)|, arrayGet()>,

    <|java+method:///java/lang/reflect/Array/newInstance(java.lang.Class%3C%3F%3E,int%5B%5D)|, arrayNewInstance()>,
    <|java+method:///java/lang/reflect/Array/newInstance(java.lang.Class%3C%3F%3E,int)|, arrayNewInstance()>,

    <|java+method:///java/lang/reflect/Array/set(java.lang.Object,int,java.lang.Object)|, arraySet()>,
    <|java+method:///java/lang/reflect/Array/setBoolean(java.lang.Object,int,boolean)|, arraySet()>,
    <|java+method:///java/lang/reflect/Array/setByte(java.lang.Object,int,byte)|, arraySet()>,
    <|java+method:///java/lang/reflect/Array/setChar(java.lang.Object,int,char)|, arraySet()>,
    <|java+method:///java/lang/reflect/Array/setDouble(java.lang.Object,int,double)|, arraySet()>,
    <|java+method:///java/lang/reflect/Array/setFloat(java.lang.Object,int,float)|, arraySet()>,
    <|java+method:///java/lang/reflect/Array/setInt(java.lang.Object,int,int)|, arraySet()>,
    <|java+method:///java/lang/reflect/Array/setLong(java.lang.Object,int,long)|, arraySet()>,
    <|java+method:///java/lang/reflect/Array/setShort(java.lang.Object,int,short)|, arraySet()>,

    <|java+method:///java/lang/reflect/Constructor/equals(java.lang.Object)|, metaObjectEquals()>,
    <|java+method:///java/lang/reflect/Field/equals(java.lang.Object)|, metaObjectEquals()>,
    <|java+method:///java/lang/reflect/Method/equals(java.lang.Object)|, metaObjectEquals()>,

    <|java+method:///java/lang/reflect/Proxy/isProxyClass(java.lang.Class%3C%3F%3E)|, isSignature()>,
    <|java+method:///java/lang/reflect/Proxy/getInvocationHandler(java.lang.Object)|, getInvocationHandler()>,
    <|java+method:///java/lang/reflect/Proxy/getProxyClass(java.lang.ClassLoader,java.lang.Class%3C%3F%3E%5B%5D)|, getProxyClass()>,
  
    <|java+method:///java/lang/Object/getClass()|, objectGetClass()>,
    <|java+method:///java/lang/Class/asSubclass(java.lang.Class%3CU%3E)|, asSubclass()>,
    <|java+method:///java/lang/Class/cast(java.lang.Object)|, cast()>,
    <|java+method:///java/lang/Class/forName(java.lang.String)|, forName()>,
    <|java+method:///java/lang/Class/forName(java.lang.String,boolean,java.lang.ClassLoader)|, forNameClassLoader()>,
    <|java+method:///java/lang/Class/getClassLoader()|, getClassLoader()>,
    <|java+method:///java/lang/Class/getClasses()|, getClassAndClasses()>,
    <|java+method:///java/lang/Class/getComponentType()|, getType()>,
    <|java+method:///java/lang/Class/getConstructor(java.lang.Class%3C%3F%3E%5B%5D)|, getConstructor()>,
    <|java+method:///java/lang/Class/getConstructors()|, getConstructors()>,
    <|java+method:///java/lang/Class/getDeclaredClasses()|, getClassAndClasses()>,
    <|java+method:///java/lang/Class/getDeclaredConstructor(java.lang.Class%3C%3F%3E%5B%5D)|, getConstructor()>,
    <|java+method:///java/lang/Class/getDeclaredConstructors()|, getConstructors()>,
    <|java+method:///java/lang/Class/getDeclaredField(java.lang.String)|, getField()>,
    <|java+method:///java/lang/Class/getDeclaredFields()|, getFields()>,
    <|java+method:///java/lang/Class/getDeclaredMethod(java.lang.String,java.lang.Class%3C%3F%3E%5B%5D)|, getMethod()>,
    <|java+method:///java/lang/Class/getDeclaredMethods()|, getMethods()>,
    <|java+method:///java/lang/Class/getDeclaringClass()|, getClassAndClasses()>,
    <|java+method:///java/lang/Class/getEnclosingClass()|, getClassAndClasses()>,
    <|java+method:///java/lang/Class/getEnclosingConstructor()|, getEnclosingConstructor()>,
    <|java+method:///java/lang/Class/getEnclosingMethod()|, getEnclosingMethod()>,
    <|java+method:///java/lang/Class/getField(java.lang.String)|, getField()>,
    <|java+method:///java/lang/Class/getFields()|, getFields()>,
    <|java+method:///java/lang/Class/getGenericInterfaces()|, getInterfaces()>,
    <|java+method:///java/lang/Class/getGenericSuperclass()|, getClassAndClasses()>,
    <|java+method:///java/lang/Class/getInterfaces()|, getInterfaces()>,
    <|java+method:///java/lang/Class/getMethod(java.lang.String,java.lang.Class%3C%3F%3E%5B%5D)|, getMethod()>,
    <|java+method:///java/lang/Class/getMethods()|, getMethods()>,
    <|java+method:///java/lang/Class/getSuperclass()|, getClassAndClasses()>,
    <|java+method:///java/lang/Class/getTypeParameters()|, getType()>,
    <|java+method:///java/lang/Class/newInstance()|, newInstance()>,
    <|java+method:///java/lang/ClassLoader/getParent()|, classLoaderGetParent()>,
    <|java+constructor:///java/lang/ClassLoader/ClassLoader(java.lang.ClassLoader)|, newClassLoader()>,
    <|java+method:///java/lang/ClassLoader/getSystemClassLoader()|, getSystemClassLoader()>, 
    <|java+method:///java/lang/ClassLoader/loadClass(java.lang.String)|, loadClass()>,
    <|java+method:///java/lang/reflect/Constructor/getDeclaringClass()|, getDeclaringClass()>,
    <|java+method:///java/lang/reflect/Constructor/getExceptionTypes()|, getType()>,
    <|java+method:///java/lang/reflect/Constructor/getGenericExceptionTypes()|, getType()>,
    <|java+method:///java/lang/reflect/Constructor/getGenericParameterTypes()|, getType()>,
    <|java+method:///java/lang/reflect/Constructor/getParameterTypes()|, getType()>,
    <|java+method:///java/lang/reflect/Constructor/getTypeParameters()|, getType()>,
    <|java+method:///java/lang/reflect/Constructor/newInstance(java.lang.Object%5B%5D)|, constructorNewInstance()>,
    <|java+method:///java/lang/reflect/Field/get(java.lang.Object)|, fieldGet()>,
    <|java+method:///java/lang/reflect/Field/getBoolean(java.lang.Object)|, fieldGet()>,
    <|java+method:///java/lang/reflect/Field/getByte(java.lang.Object)|, fieldGet()>,
    <|java+method:///java/lang/reflect/Field/getChar(java.lang.Object)|, fieldGet()>,
    <|java+method:///java/lang/reflect/Field/getDeclaringClass()|, getDeclaringClass()>,
    <|java+method:///java/lang/reflect/Field/getDouble(java.lang.Object)|, fieldGet()>,
    <|java+method:///java/lang/reflect/Field/getFloat(java.lang.Object)|, fieldGet()>,
    <|java+method:///java/lang/reflect/Field/getGenericType()|, getType()>,
    <|java+method:///java/lang/reflect/Field/getInt(java.lang.Object)|, fieldGet()>,
    <|java+method:///java/lang/reflect/Field/getLong(java.lang.Object)|, fieldGet()>,
    <|java+method:///java/lang/reflect/Field/getShort(java.lang.Object)|, fieldGet()>,
    <|java+method:///java/lang/reflect/Field/getType()|, getType()>,
    <|java+method:///java/lang/reflect/Field/set(java.lang.Object,java.lang.Object)|, fieldSet()>,
    <|java+method:///java/lang/reflect/Field/setBoolean(java.lang.Object,boolean)|, fieldSet()>,
    <|java+method:///java/lang/reflect/Field/setByte(java.lang.Object,byte)|, fieldSet()>,
    <|java+method:///java/lang/reflect/Field/setChar(java.lang.Object,char)|, fieldSet()>,
    <|java+method:///java/lang/reflect/Field/setDouble(java.lang.Object,double)|, fieldSet()>,
    <|java+method:///java/lang/reflect/Field/setFloat(java.lang.Object,float)|, fieldSet()>,
    <|java+method:///java/lang/reflect/Field/setInt(java.lang.Object,int)|, fieldSet()>,
    <|java+method:///java/lang/reflect/Field/setLong(java.lang.Object,long)|, fieldSet()>,
    <|java+method:///java/lang/reflect/Field/setShort(java.lang.Object,short)|, fieldSet()>,
    <|java+method:///java/lang/reflect/Member/getDeclaringClass()|, getDeclaringClass()>,
    <|java+method:///java/lang/reflect/Method/getDeclaringClass()|, getDeclaringClass()>,
    <|java+method:///java/lang/reflect/Method/getExceptionTypes()|, getType()>,
    <|java+method:///java/lang/reflect/Method/getGenericExceptionTypes()|, getType()>,
    <|java+method:///java/lang/reflect/Method/getGenericParameterTypes()|, getType()>,
    <|java+method:///java/lang/reflect/Method/getGenericReturnType()|, getType()>,
    <|java+method:///java/lang/reflect/Method/getParameterTypes()|, getType()>,
    <|java+method:///java/lang/reflect/Method/getReturnType()|, getType()>,
    <|java+method:///java/lang/reflect/Method/getTypeParameters()|, getType()>,
    <|java+method:///java/lang/reflect/Method/invoke(java.lang.Object,java.lang.Object%5B%5D)|, invoke()>,
    <|java+method:///java/lang/reflect/Proxy/newProxyInstance(java.lang.ClassLoader,java.lang.Class%3C%3F%3E%5B%5D,java.lang.reflect.InvocationHandler)|, newProxyInstance()>,
    <|java+method:///sun/reflect/misc/MethodUtil/getMethod(java.lang.Class%3C%3F%3E,java.lang.String,java.lang.Class%5B%5D)|, getMethod(isSun = true)>,
    <|java+method:///sun/reflect/misc/MethodUtil/getMethod(java.lang.Class,java.lang.String,java.lang.Class%5B%5D)|, getMethod(isSun = true)>,
    <|java+method:///sun/reflect/misc/MethodUtil/getMethods(java.lang.Class)|, getMethods(isSun = true)>,
    <|java+method:///sun/reflect/misc/MethodUtil/getPublicMethods(java.lang.Class)|, getMethods(isSun = true)>,
    <|java+method:///sun/reflect/misc/MethodUtil/invoke(java.lang.reflect.Method,java.lang.Object,java.lang.Object%5B%5D)|, invoke(isSun = true)>
});

public map[loc, ReflectionProduction] reflectionMethodLookup = toMapUnique(lookupReflectionProductions);