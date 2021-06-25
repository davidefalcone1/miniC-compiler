%code requires {
  /* In this section there are dependencies for YYSTYPE (%union option at line 90).
  You cannot put them in the code section below because in the parser
  implementation file that code goes after the declaration of YYSTYPE. */
  #include "sym_table.h"
  #define BUFFSIZE 4096
  typedef struct {
    char value[BUFFSIZE];
    symbol_type *type;
  } expr;
}

%code {
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  extern int yylex();
  extern int yyerror();
  int sem_enabled = 1; /* True if semantics is enabled. */
  int label = 0;
  char buffer[BUFFSIZE];
  char tempBuff[BUFFSIZE];

  /*
  -----------
  Functions devoted to update the buffer
  -----------
  */

  void dumpln(char *s){
    strcat(buffer, s);
    strcat(buffer, "\n");
  }
  void dump(char *s){
    strcat(buffer, s);
  }

  /*
  -----------
  Error & warning output
  -----------
  */

  void print_error(char *m){
    printf("\033[0;31mError\033[0m "); /* Write in red */
    printf("%s\n", m);
  }

  void print_warning(char *m){
    printf("\033[0;33mWarning\033[0m "); /* Write in yellow */
    printf("%s\n", m);
  }

  /*
  -----------
  Type checking
  -----------
  */

  symbol_type *check_type(expr *e1, expr *e2){
    int type1 = e1->type->type;
    int type2 = e2->type->type;
    if(type1 == type2){
      symbol_type *s = (symbol_type *) malloc(sizeof(symbol_type));
      s->type = type1;
      s->dim = e1->type->dim;
      return s;
    }
    else if(type1 != -1 && type2!= -1){
      print_warning("Operation between int and double, int number casted to double");
      symbol_type *s = (symbol_type *) malloc(sizeof(symbol_type));
      s->type = 1;
      s->dim = 1;
      return s;
    }
    else{
      symbol_type *s = (symbol_type *) malloc(sizeof(symbol_type));
      s->type = -1;
      s->dim = -1;
      return s;
    }
  }
  void check_assignment(expr *e1, expr *e2){
    int type1 = e1->type->type;
    int type2 = e2->type->type;
    if(type1 == 0 && type2 == 1)
      print_warning("Assignment of a double value to an int variable");
    else if(type1 == 1 && type2 == 0)
      print_warning("Assignment of an int value to an double variable");
  }

}

%union {
  int int_value;
  float real_value;
  int *array;
  char string[BUFFSIZE];
  expr *expr;
}

%type <string>  type statement_list statement while
                    if print assignment declaration_list vl declaration
                    while_condition if_condition
%type <expr> expr id
%type <int_value> nt0_if nt1_if
%type <array> nt0_while

%debug
%locations
%expect 2 /* Dandling else */

%token OB CB OP CP OS CS PLUS MINUS STAR DIV ASS_OP SC COMMA
       EQUAL NOT_EQ GT_EQ GT LT_EQ LT WHILE IF ELSE PRINT
       INTEGER_TYPE DOUBLE_TYPE NOT AND OR UMINUS
%token <string> ID
%token <int_value> INTEGER
%token <real_value> DOUBLE

/* Precedence rules */
%left OR
%left AND
%left NOT
%left GT LT GT_EQ LT_EQ EQUAL NOT_EQ
%left PLUS MINUS
%left STAR DIV
%left UMINUS

%%

program: declaration_list statement_list
      {
        if(yynerrs)
          printf("Program not parsed. Number of errors: %d.\n", yynerrs);
        else{
          dumpln("\tEND");
          printf("%s", buffer);
        }
      }

/* Declarations */
declaration_list: declaration_list declaration | {;};

declaration: type vl SC
          | type error SC {print_error("Error in declaration.");};

type: DOUBLE_TYPE {sprintf($$, "DOUBLE");}
    | INTEGER_TYPE {sprintf($$, "INT");};

vl: v {/* The default action in Bison is $$ = $1 */;}
  | vl COMMA {strcpy($<string>$, $<string>0); /* This is a marker */} v;

v: ID
  {
    if(sem_enabled){
      dump("\t");
      dump($<string>0);
      dump(" ");
      dumpln($1);
      if(!strcmp($<string>0, "INT")){
        symbol_type *type = (symbol_type *) malloc(sizeof(symbol_type));
        type->type = 0;
        type->dim = 1;
        sym_table_put(strdup($1), type);
      }
      else if(!strcmp($<string>0, "DOUBLE")){
        symbol_type *type = (symbol_type *) malloc(sizeof(symbol_type));
        type->type = 1;
        type->dim = 1;
        sym_table_put(strdup($1), type);
      }
    }
  }
  | ID OS INTEGER CS
  {
    if (sem_enabled) {
      sprintf(tempBuff, "%d", $3);
      dump("\t");
      dump($<string>0);
      dump(" ");
      dump($1);
      dump("[");
      dump(tempBuff);
      dumpln("]");
      if(!strcmp($<string>0, "INT")){
        symbol_type *type = (symbol_type *) malloc(sizeof(symbol_type));
        type->type = 0;
        type->dim = $3;
        sym_table_put(strdup($1), type);
      }
      else if(!strcmp($<string>0, "DOUBLE")){
        symbol_type *type = (symbol_type *) malloc(sizeof(symbol_type));
        type->type = 1;
        type->dim = $3;
        sym_table_put(strdup($1), type);
      }
    }
  };

/* Statements */
statement_list: statement_list statement
              | statement
              | error statement {print_error("Error in statement");};

statement : if | while | assignment | print | OB statement_list CB {/* The default action in Bison is $$ = $1 */;}
    | OB statement_list error CB {print_error("Missing ; before }");}
    | OB error CB {print_error("Missing ; before }");}
    | error SC {print_error("Error in statement");};

/* Assignments */
assignment: id ASS_OP expr SC
          {
            if (sem_enabled) {
              check_assignment($1, $3);
              dump("\t");
              dump("EVAL ");
              dumpln($3->value);
              dump("\t");
              dump("ASS ");
              dumpln($1->value);
              free($1->type);
              free($3->type);
              free($3);
              free($1);
            }
          }
          | id ASS_OP error SC {print_error("Error in expression"); free($1->type); free($1);}
          | error ASS_OP expr SC {print_error("Error in assignment"); free($3->type); free($3);};

/* Print */
print : PRINT id SC {
                      if(sem_enabled){
                        dump("\t");
                        dump("PRINT ");
                        dumpln($2->value);
                        free($2->type);
                        free($2);
                      }
                    }
      | PRINT error SC {print_error("Error in 'print' instruction");};

/* While */
while : WHILE while_condition nt0_while statement
        {
          if (sem_enabled){
              sprintf(tempBuff, "%d", $<array>3[0]);
              dump("\t");
              dump("GOTO L");
              dumpln(tempBuff);
              sprintf(tempBuff, "%d", $<array>3[1]);
              dump("L");
              dump(tempBuff);
              dump(":");
          }
        };

while_condition : OP expr CP {strcpy($<string>$, $2->value); free($2->type); free($2);}
                | OP error CP {print_error("Error in 'while' condition");}
                | error expr CP {print_error("Error '(' expected in 'while' instruction"); free($2->type); free($2);}
                | OP expr error {print_error("Error ')' expected in 'while' instruction"); free($2->type); free($2);};

nt0_while : /* Empty */
          {
            if (sem_enabled){
               $$ = (int *) malloc(sizeof(int) * 2);
               $$[0] = label++;
               $$[1] = label++;
               dump("L");
               sprintf(tempBuff, "%d", $$[0]);
               dump(tempBuff);
               dump(":\tEVAL ");
               dump($<string>0);
               dump(" \\* while (line ");
               sprintf(tempBuff, "%d", yyloc.first_line);
               dump(tempBuff);
               dumpln(") */");
               dump("\tGOTOF L");
               sprintf(tempBuff, "%d", $$[1]);
               dumpln(tempBuff);
            }
          };

/* If */
if: IF if_condition nt0_if statement
  {
    if (sem_enabled){
      dump("L");
      sprintf(tempBuff, "%d", $<int_value>-1);
      dump(tempBuff);
      dump(":");
    }
  }
  | IF if_condition nt0_if statement ELSE nt1_if statement
  {
    if(sem_enabled){
      dump("L");
      sprintf(tempBuff, "%d", $<int_value>-1);
      dump(tempBuff);
      dump(":");
    }
  }
  | IF if_condition nt0_if statement error nt1_if statement
  {
    print_error("Error 'else' expected after 'if'");
  };

nt0_if : /* Empty */
        {
          if (sem_enabled){
            $$ = label++;
            dump("\tEVAL ");
            dumpln($<string>0);
            dump("\tGOTOF L");
            sprintf(tempBuff, "%d", $$);
            dump(tempBuff);
            dump(" /* if line ");
            sprintf(tempBuff, "%d", yyloc.first_line);
            dump(tempBuff);
            dumpln("*/");
          }
        };

nt1_if : /* Empty */
        {
          if (sem_enabled){
            $$ = label++;
            sprintf(tempBuff, "%d", $$);
            dump("\tGOTO L");
            dumpln(tempBuff);
            dump("L");
            sprintf(tempBuff, "%d", $<int_value>-2);
            dump(tempBuff);
            dump(":");
          }
        };

if_condition: OP expr CP {strcpy($<string>$, $2->value); free($2->type); free($2);}
    | OP error CP {print_error("Error in 'if' condition");}
    | error expr CP {print_error("Error '(' expected in 'if' instruction"); free($2->type); free($2);}
    | OP expr error  {print_error("Error ')' expected in 'if' instruction"); free($2->type); free($2);};

/* Expressions */
expr: /* Boolean operators */
      expr AND expr
      {
        if (sem_enabled)
        {
          $$ = (expr *) malloc(sizeof(expr));
          bzero($$, sizeof(expr));
          sprintf($$->value, "%s %s &", $1->value, $3->value);
          $$->type = check_type($1, $3);
          free($1->type); /* Free symbol type */
          free($3->type);
          free($1); /* Free expression */
          free($3);
        }
      }
    | expr OR expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s |", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type); /* Free symbol type */
        free($3->type);
        free($1); /* Free expression */
        free($3);
      }
    }
    | NOT expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s !", $2->value);
        $$->type = $2->type;
        free($2);
      }
    }
    /* Comparison operators */
    | expr EQUAL expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s ==", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type); /* Free symbol type */
        free($3->type);
        free($1); /* Free expression */
        free($3);
      }
    }
    | expr GT expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s >", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type); /* Free symbol type */
        free($3->type);
        free($1); /* Free expression */
        free($3);
      }
    }
    | expr GT_EQ expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s >=", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type); /* Free symbol type */
        free($3->type);
        free($1); /* Free expression */
        free($3);
      }
    }
    | expr LT expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s <", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type); /* Free symbol type */
        free($3->type);
        free($1); /* Free expression */
        free($3);
      }
    }
    | expr LT_EQ expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s <=", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type); /* Free symbol type */
        free($3->type);
        free($1); /* Free expression */
        free($3);
      }
    }
    | expr NOT_EQ expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s !=", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type); /* Free symbol type */
        free($3->type);
        free($1); /* Free expression */
        free($3);
      }
    }
    /* Math operators */
    | expr PLUS expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s +", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type);
        free($3->type);
        free($1);
        free($3);
      }
    }
    | expr MINUS expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s -", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type); /* Free symbol type */
        free($3->type);
        free($1); /* Free expression */
        free($3);
      }
    }
    | expr STAR expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s *", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type); /* Free symbol type */
        free($3->type);
        free($1); /* Free expression */
        free($3);
      }
    }
    | expr DIV expr
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%s %s /", $1->value, $3->value);
        $$->type = check_type($1, $3);
        free($1->type); /* Free symbol type */
        free($3->type);
        free($1); /* Free expression */
        free($3);
      }
    }
    | OP expr CP {if (sem_enabled) $$ = $2;}
    | id {if (sem_enabled) $$ = $1;}
    | INTEGER
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%d", $1);
        $$->type = (symbol_type *) malloc(sizeof(symbol_type));
        $$->type->type = 0;
        $$->type->dim = 1;
      }
    }
    | DOUBLE
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "%0.1f", $1);
        $$->type = (symbol_type *) malloc(sizeof(symbol_type));
        $$->type->type = 1;
        $$->type->dim = 1;
      }
    }
    | MINUS INTEGER
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "-%d", $2);
        $$->type = (symbol_type *) malloc(sizeof(symbol_type));
        $$->type->type = 0;
        $$->type->dim = 1;
      }
    }
    | MINUS DOUBLE
    {
      if (sem_enabled)
      {
        $$ = (expr *) malloc(sizeof(expr));
        bzero($$, sizeof(expr));
        sprintf($$->value, "-%0.1f", $2);
        $$->type = (symbol_type *) malloc(sizeof(symbol_type));
        $$->type->type = 1;
        $$->type->dim = 1;
      }
    }
    | OP error CP {print_error("Error in expression.");};

id: ID {
          $$ = (expr *) malloc(sizeof(expr));
          bzero($$, sizeof(expr));
          strcpy($$->value, $1);
          $$->type = malloc(sizeof(symbol_type));
          $$->type->dim = sym_table_get($1)->dim;
          $$->type->type = sym_table_get($1)->type;
        }
    |ID OS INTEGER CS
    {
      $$ = (expr *) malloc(sizeof(expr));
      bzero($$, sizeof(expr));
      sprintf(tempBuff, "%d", $3);
      strcat($$->value, $1);
      strcat($$->value, "[");
      strcat($$->value, tempBuff);
      strcat($$->value, "]");
      $$->type = (symbol_type *) malloc(sizeof(symbol_type));
      $$->type->type = sym_table_get($1)->type;
      $$->type->dim = sym_table_get($1)->dim;
      if($3 >= $$->type->dim && $$->type->dim != -1)
        print_error("Array index exceed array size");
    }
    |ID OS ID CS
    {
      $$ = (expr *) malloc(sizeof(expr));
      bzero($$, sizeof(expr));
      strcat($$->value, $1);
      strcat($$->value, "[");
      strcat($$->value, $3);
      strcat($$->value, "]");
      $$->type = (symbol_type *) malloc(sizeof(symbol_type));
      $$->type->type = sym_table_get($1)->type;
      $$->type->dim = sym_table_get($1)->dim;
    }
    | error SC {print_error("Error in vector");};
