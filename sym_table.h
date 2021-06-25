#ifndef SYM_TABLE_H
#define SYM_TABLE_H

typedef struct{
  int type;
  int dim;
} symbol_type;

typedef struct sym_entry{
  char const *name;
  symbol_type *type;
  struct sym_entry *next; /* Next node */
} sym_entry;

extern sym_entry *sym_table;

sym_entry *sym_table_put(char const *name, symbol_type *type);
symbol_type *sym_table_get(char const *name);
void free_sym_table(void);
#endif
