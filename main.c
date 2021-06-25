#include <stdio.h>
#include "lex.yy.h"
#include "sym_table.h"

extern int yyparse (void);
extern int yydebug;
extern int sem_enabled;

sym_entry *sym_table;

void yyerror(char const *message){
  sem_enabled = 0;
}

int main(int argc, char const *argv[]) {
  yyin = fopen(argv[1], "r");
  yydebug = 0;
  int result_code = yyparse();
  fclose(yyin);
  free_sym_table();
  return result_code;
}
