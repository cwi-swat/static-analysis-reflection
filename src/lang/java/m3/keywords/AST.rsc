module lang::java::m3::keywords::AST

import Message;
import lang::java::m3::TypeSymbol;
extend lang::java::m3::AST;

public loc unknownSource = |unknown:///|;
public loc unresolvedDecl = |unresolved:///|;
public loc unresolvedType = |unresolved:///|;


data Declaration(
    loc src = unknownSource, 
    loc decl = unresolvedDecl,
    TypeSymbol typ = unresolved(),
    list[Modifier] modifiers = [],
    list[Message] messages = []
);

data Statement(
    loc src = unknownSource, 
    loc decl = unresolvedDecl
);

data Expression(
    loc src = unknownSource, 
    loc decl = unresolvedDecl,
    TypeSymbol typ = unresolved() 
);

data Type(
    loc name = unresolvedType, 
    TypeSymbol typ = unresolved() 
);

@javaClass{lang.java.m3.keywords.Replacer}
public java Declaration replaceAnnotations(Declaration d);