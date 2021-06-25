%option header-file="lex.yy.h"
%option noyywrap
%s COMMENT

comment "/*"
endComment "*/"
openBracket \{
closeBracket \}
openParentesis \(
closeParentesis \)
openSquare \[
closeSquare \]
plus \+
minus \-
star \*
div \/
equal \=
semicolon \;
dot \.
comma \,
GT \<
LT \>
AND \&
OR \|
NOT \!
integer_type int
double_type double
if if
else else
while while
print print
digit [0-9]
integer {digit}{digit}*
double {integer}\.{integer}
letter [a-zA-Z]
id {letter}({letter}|"_"|{digit})*
newLine "\n"|"\r"|("\r\n")


%top{
  /* This goes at the top of the generated file */
  #include "parser.tab.h"
  #include "string.h"
  extern YYLTYPE yyloc;
  extern YYSTYPE yylval;
  extern int yynerrs;

  #define YY_USER_ACTION \
    yylloc.first_line = yylloc.last_line; \
    yylloc.first_column = yylloc.last_column; \
    for(int i = 0; yytext[i] != '\0'; i++) { \
        if(yytext[i] == '\n') { \
            yylloc.last_line++; \
            yylloc.last_column = 0; \
        } \
        else { \
            yylloc.last_column++; \
        } \
    }
}

%%

<INITIAL>{
  {openBracket} {
    return(OB);
  }
  {closeBracket} {
    return(CB);
  }
  {openParentesis} {
    return(OP);
  }
  {closeParentesis} {
    return(CP);
  }
  {openSquare} {
    return(OS);
  }
  {closeSquare} {
    return(CS);
  }
  {plus} {
    return(PLUS);
  }
  {minus} {
    return(MINUS);
  }
  {star} {
    return(STAR);
  }
  {div} {
    return(DIV);
  }
  {equal} {
    return(ASS_OP);
  }
  {semicolon} {
    return(SC);
  }
  {comma} {
    return(COMMA);
  }
  {GT} {
    return(GT);
  }
  {LT} {
    return(LT);
  }
  {equal}{2} {
    return(EQUAL);
  }
  {LT}{equal} {
    return(LT_EQ);
  }
  {GT}{equal} {
    return(GT_EQ);
  }
  {NOT}{equal} {
    return(NOT_EQ);
  }
  {AND} {
    return(AND);
  }
  {OR} {
    return(OR);
  }
  {NOT} {
    return(NOT);
  }
  {integer_type} {
    return(INTEGER_TYPE);
  }
  {double_type} {
    return(DOUBLE_TYPE);
  }
  {if} {
    return(IF);
  }
  {else} {
    return(ELSE);
  }
  {while} {
    return(WHILE);
  }
  {print} {
    return(PRINT);
  }
  {integer} {
    yylval.int_value = atoi(yytext);
    return(INTEGER);
  }
  {double} {
    yylval.real_value = atof(yytext);
    return(DOUBLE);
  }
  {newLine} {
    ;
  }
  {id} {
    strcpy(yylval.string, yytext);
    return(ID);
  }
  {comment} {
    BEGIN(COMMENT);
  }
  " " {;}
  . {
    {printf("Scanner error at line %d:%d.\n", yylloc.first_line, yylloc.first_column); yynerrs++;};
  }
}

<COMMENT>{
  . {
    ;
  }
  {newLine} {
    ;
  }
  {endComment} {
    BEGIN(INITIAL);
  }
}
