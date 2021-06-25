#include <string.h>
#include <stdlib.h>
#include "sym_table.h"
#include "parser.tab.h"
/* Function used to push an entry in the symbol table */
sym_entry *sym_table_put(char const *name, symbol_type *type){
  sym_entry *new_node = (sym_entry *) malloc(sizeof(sym_entry));
  new_node->name = name;
  new_node->type = type;
  new_node->next = sym_table;
  sym_table = new_node;
  return new_node;
}
/* Function used to get an entry of the symbol table */
symbol_type *sym_table_get(char const *name){
  for (sym_entry *p = sym_table; p; p = p->next)
    if(strcmp (p->name, name) == 0)
      return p->type;
  return NULL;
}
/* Function used to free the symbol table */
void free_sym_table(){
  sym_entry *p = sym_table;
  sym_entry *n = NULL;
  while(p != NULL) {
    free(p->type);
    n = p->next;
    free(p);
    p = n;
  }
}
