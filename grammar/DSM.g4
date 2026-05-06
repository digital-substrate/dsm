grammar DSM;

// All Definitions
definitions: definition* EOF;

definition: namespace | functionPool | attachmentFunctionPool;

// Namespace
namespace: 'namespace' IDENTIFIER UUID '{' namespaceDefinitions '}' ';' ;
namespaceDefinitions: namespaceDefinition* ;
namespaceDefinition: concept | club | membership | structure | enumeration | attachment;

// Concept
concept: DOCSTR? 'concept' IDENTIFIER isa? ';' ;
isa: 'is a' IDENTIFIER;

// Club
club: DOCSTR? 'club' IDENTIFIER ';' ;
membership: 'membership' IDENTIFIER IDENTIFIER ';' ;

// Enumeration
enumeration: DOCSTR? 'enum' IDENTIFIER '{' enumerationCases '}' ';' ;
enumerationCases: enumerationCase (',' enumerationCase)* ;
enumerationCase: DOCSTR? IDENTIFIER ;

// Structure
structure: DOCSTR? 'struct' IDENTIFIER '{' structureFields '}' ';' ;
structureFields: (structureField ';')* ;
structureField: DOCSTR? type IDENTIFIER defaultValue? ;

// Attachment
attachment: DOCSTR? 'attachment<' IDENTIFIER ',' type '>' IDENTIFIER ';' ;

// Function Pool
functionPool: DOCSTR? 'function_pool' IDENTIFIER UUID '{' functions '}' ';' ;
functions: (function ';')* ;
function: DOCSTR? functionReturnType IDENTIFIER '(' functionParameters ')' ;

// Attachment Function Pool
attachmentFunctionPool: DOCSTR? 'attachment_function_pool' IDENTIFIER UUID '{' attachmentFunctions '}' ';' ;
attachmentFunctions: (attachmentFunction ';')* ;
attachmentFunction: DOCSTR? attachmentMutable? functionReturnType IDENTIFIER '(' functionParameters ')' ;
attachmentMutable: 'mutable';

// Function
functionReturnType: type ;
functionParameters: functionParameter? (',' functionParameter)* ;
functionParameter: type IDENTIFIER ;

// Types
types: type (',' type)* ;
type: 'key<' IDENTIFIER '>'                         # TypeKey
    | 'vec<' IDENTIFIER ',' NUMBER '>'              # TypeVec
    | 'mat<' IDENTIFIER ',' NUMBER ',' NUMBER '>'   # TypeMat
    | 'variant<' types '>'                          # TypeVariant
    | 'optional<' type '>'                          # TypeOptional
    | 'tuple<' types '>'                            # TypeTuple
    | 'vector<' type '>'                            # TypeVector
    | 'set<' type '>'                               # TypeSet
    | 'map<' type ',' type '>'                      # TypeMap
    | 'xarray<' type '>'                            # TypeXArray
    | IDENTIFIER                                    # TypeReference
    ;

// Default value
defaultValue: '=' literal;
literal: literalList
       | literalValue
       ;

literalList: '{' literalListMembers '}' ;
literalListMembers: literal (',' literal)* ;

literalValue : CASE    # LiteralCase
             | STRING  # LiteralString
             | NUMBER  # LiteralNumber
             | UUID    # LiteralUUID
             | 'true'  # LiteralTrue
             | 'false' # LiteralFalse
             ;

IDENTIFIER
    : LETTER (LETTER | [0-9] | '_')*
    | LETTER (LETTER | [0-9] | '_')* '::' LETTER (LETTER | [0-9] | '_')*;

fragment LETTER: [a-zA-Z] ;

CASE: '.' LETTER (LETTER | [0-9] | '_')* ;

DOCSTR : '"""' (ESC | ~["\\])*? '"""' ;
STRING : '"' (ESC | ~["\\])*? '"' ;
fragment ESC : '\\' (["\\/bfnrt] | UNICODE) ;
fragment UNICODE : 'u' HEX HEX HEX HEX ;
fragment HEX : [0-9a-fA-F] ;

NUMBER
    :   '-'? INT '.' [0-9]+ EXP? // 1.35, 1.35E-9, 0.3, -4.5
    |   '-'? INT EXP             // 1e10 -3e4
    |   '-'? INT                 // -3, 45
    ;

UUID: '{' HEX HEX HEX HEX HEX HEX HEX HEX '-' HEX HEX HEX HEX '-' HEX HEX HEX HEX '-' HEX HEX HEX HEX '-' HEX HEX HEX HEX HEX HEX HEX HEX HEX HEX HEX HEX '}';
fragment INT :   '0' | [1-9] [0-9]* ; // no leading zeros
fragment EXP :   [Ee] [+\-]? INT ; // \- since - means "range" inside [...]

WS: [ \t\n\r]+ -> skip ;
COMMENT: '//' .*? '\n' -> skip ;
