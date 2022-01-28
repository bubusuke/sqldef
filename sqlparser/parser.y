/*
Copyright 2017 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

%{
package sqlparser

func setParseTree(yylex interface{}, stmt Statement) {
  yylex.(*Tokenizer).ParseTree = stmt
}

func setAllowComments(yylex interface{}, allow bool) {
  yylex.(*Tokenizer).AllowComments = allow
}

func setDDL(yylex interface{}, ddl *DDL) {
  yylex.(*Tokenizer).partialDDL = ddl
}

func incNesting(yylex interface{}) bool {
  yylex.(*Tokenizer).nesting++
  if yylex.(*Tokenizer).nesting == 200 {
    return true
  }
  return false
}

func decNesting(yylex interface{}) {
  yylex.(*Tokenizer).nesting--
}

// forceEOF forces the lexer to end prematurely. Not all SQL statements
// are supported by the Parser, thus calling forceEOF will make the lexer
// return EOF early.
func forceEOF(yylex interface{}) {
  yylex.(*Tokenizer).ForceEOF = true
}

%}

%union {
  empty         struct{}
  statement     Statement
  selStmt       SelectStatement
  ddl           *DDL
  ins           *Insert
  byt           byte
  bytes         []byte
  bytes2        [][]byte
  str           string
  strs          []string
  selectExprs   SelectExprs
  selectExpr    SelectExpr
  columns       Columns
  partitions    Partitions
  colName       *ColName
  newQualifierColName *NewQualifierColName
  tableExprs    TableExprs
  tableExpr     TableExpr
  joinCondition JoinCondition
  tableName     TableName
  tableNames    TableNames
  indexHints    *IndexHints
  expr          Expr
  exprs         Exprs
  boolVal       BoolVal
  colTuple      ColTuple
  values        Values
  valTuple      ValTuple
  subquery      *Subquery
  whens         []*When
  when          *When
  orderBy       OrderBy
  order         *Order
  limit         *Limit
  updateExprs   UpdateExprs
  setExprs      SetExprs
  updateExpr    *UpdateExpr
  setExpr       *SetExpr
  colIdent      ColIdent
  colIdents     []ColIdent
  tableIdent    TableIdent
  convertType   *ConvertType
  aliasedTableName *AliasedTableExpr
  TableSpec  *TableSpec
  columnType    ColumnType
  colKeyOpt     ColumnKeyOption
  optVal        *SQLVal
  LengthScaleOption LengthScaleOption
  columnDefinition *ColumnDefinition
  checkDefinition *CheckDefinition
  indexDefinition *IndexDefinition
  indexInfo     *IndexInfo
  indexOption   *IndexOption
  indexOptions  []*IndexOption
  indexPartition *IndexPartition
  indexColumn   IndexColumn
  indexColumns  []IndexColumn
  indexColumnsOrExpression IndexColumnsOrExpression
  foreignKeyDefinition *ForeignKeyDefinition
  partDefs      []*PartitionDefinition
  partDef       *PartitionDefinition
  partSpec      *PartitionSpec
  vindexParam   VindexParam
  vindexParams  []VindexParam
  showFilter    *ShowFilter
  sequence      *Sequence
  blockStatement []Statement
  localVariable *LocalVariable
  localVariables []*LocalVariable
  arrayConstructor *ArrayConstructor
  arrayElements ArrayElements
  arrayElement  ArrayElement
}

%token LEX_ERROR
%left <bytes> UNION
%token <bytes> SELECT STREAM INSERT UPDATE DELETE FROM WHERE GROUP HAVING ORDER BY LIMIT OFFSET FOR DECLARE
%token <bytes> ALL DISTINCT AS EXISTS ASC DESC INTO DUPLICATE DEFAULT SET LOCK KEYS
%token <bytes> VALUES LAST_INSERT_ID
%token <bytes> NEXT VALUE SHARE MODE
%token <bytes> SQL_NO_CACHE SQL_CACHE
%left <bytes> JOIN STRAIGHT_JOIN LEFT RIGHT INNER OUTER CROSS NATURAL USE FORCE
%left <bytes> ON USING
%token <empty> '(' ',' ')'
%token <bytes> ID HEX STRING INTEGRAL FLOAT HEXNUM VALUE_ARG LIST_ARG COMMENT COMMENT_KEYWORD BIT_LITERAL
%token <bytes> NULL TRUE FALSE
%token <bytes> OFF

// Precedence dictated by mysql. But the vitess grammar is simplified.
// Some of these operators don't conflict in our situation. Nevertheless,
// it's better to have these listed in the correct order. Also, we don't
// support all operators yet.
%left <bytes> OR
%left <bytes> AND
%right <bytes> NOT '!'
%left <bytes> BETWEEN CASE WHEN THEN ELSE END
%left <bytes> '=' '<' '>' LE GE NE NULL_SAFE_EQUAL IS LIKE REGEXP IN
%left <bytes> '|'
%left <bytes> '&'
%left <bytes> SHIFT_LEFT SHIFT_RIGHT
%left <bytes> '+' '-'
%left <bytes> '*' '/' DIV '%' MOD
%left <bytes> '^'
%right <bytes> '~' UNARY
%left <bytes> COLLATE
%right <bytes> BINARY UNDERSCORE_BINARY
%right <bytes> INTERVAL
%nonassoc <bytes> '.'

// There is no need to define precedence for the JSON
// operators because the syntax is restricted enough that
// they don't cause conflicts.
%token <empty> JSON_EXTRACT_OP JSON_UNQUOTE_EXTRACT_OP

// DDL Tokens
%token <bytes> CREATE ALTER DROP RENAME ANALYZE ADD
%token <bytes> SCHEMA TABLE INDEX VIEW TO IGNORE IF PRIMARY COLUMN CONSTRAINT REFERENCES SPATIAL FULLTEXT FOREIGN KEY_BLOCK_SIZE POLICY WHILE
%right <bytes> UNIQUE KEY
%token <bytes> SHOW DESCRIBE EXPLAIN DATE ESCAPE REPAIR OPTIMIZE TRUNCATE
%token <bytes> MAXVALUE PARTITION REORGANIZE LESS THAN PROCEDURE TRIGGER TYPE
%token <bytes> VINDEX VINDEXES
%token <bytes> STATUS VARIABLES
%token <bytes> RESTRICT CASCADE NO ACTION
%token <bytes> PERMISSIVE RESTRICTIVE PUBLIC CURRENT_USER SESSION_USER
%token <bytes> PAD_INDEX FILLFACTOR IGNORE_DUP_KEY STATISTICS_NORECOMPUTE STATISTICS_INCREMENTAL ALLOW_ROW_LOCKS ALLOW_PAGE_LOCKS
%token <bytes> BEFORE AFTER EACH ROW SCROLL CURSOR OPEN CLOSE FETCH PRIOR FIRST LAST DEALLOCATE
%token <bytes> DEFERRABLE INITIALLY IMMEDIATE DEFERRED

// Transaction Tokens
%token <bytes> BEGIN START TRANSACTION COMMIT ROLLBACK

// Type Tokens
%token <bytes> BIT TINYINT SMALLINT SMALLSERIAL MEDIUMINT INT INTEGER SERIAL BIGINT BIGSERIAL INTNUM
%token <bytes> REAL DOUBLE PRECISION FLOAT_TYPE DECIMAL NUMERIC SMALLMONEY MONEY
%token <bytes> TIME TIMESTAMP DATETIME YEAR DATETIMEOFFSET DATETIME2 SMALLDATETIME
%token <bytes> CHAR VARCHAR VARYING BOOL CHARACTER VARBINARY NCHAR NVARCHAR NTEXT UUID
%token <bytes> TEXT TINYTEXT MEDIUMTEXT LONGTEXT CITEXT
%token <bytes> BLOB TINYBLOB MEDIUMBLOB LONGBLOB JSON JSONB ENUM
%token <bytes> GEOMETRY POINT LINESTRING POLYGON GEOMETRYCOLLECTION MULTIPOINT MULTILINESTRING MULTIPOLYGON
%token <bytes> VARIADIC ARRAY
%token <bytes> NOW GETDATE
%token <bytes> BPCHAR

// Operator Class Tokens
%right <bytes> TEXT_PATTERN_OPS

// Type Modifiers
%token <bytes> NULLX AUTO_INCREMENT APPROXNUM SIGNED UNSIGNED ZEROFILL ZONE AUTOINCREMENT

// Supported SHOW tokens
%token <bytes> DATABASES TABLES VITESS_KEYSPACES VITESS_SHARDS VITESS_TABLETS VSCHEMA_TABLES EXTENDED FULL PROCESSLIST

// SET tokens
%token <bytes> NAMES CHARSET GLOBAL SESSION ISOLATION LEVEL READ WRITE ONLY REPEATABLE COMMITTED UNCOMMITTED SERIALIZABLE NEW

// Functions
%token <bytes> CURRENT_TIMESTAMP DATABASE CURRENT_DATE
%token <bytes> CURRENT_TIME LOCALTIME LOCALTIMESTAMP
%token <bytes> UTC_DATE UTC_TIME UTC_TIMESTAMP
%token <bytes> REPLACE
%token <bytes> CONVERT CAST
%token <bytes> SUBSTR SUBSTRING
%token <bytes> GROUP_CONCAT SEPARATOR
%token <bytes> INHERIT

// Match
%token <bytes> MATCH AGAINST BOOLEAN LANGUAGE WITH WITHOUT PARSER QUERY EXPANSION

// MySQL reserved words that are unused by this grammar will map to this token.
%token <bytes> UNUSED

// MySQL PostgreSQL GENERATED ALWAYS AS
%token <bytes> VIRTUAL STORED
// PostgreSQL GENERATED AS IDENTITY
%token <bytes> GENERATED ALWAYS IDENTITY
// sequence
%token <bytes> SEQUENCE INCREMENT MINVALUE CACHE CYCLE OWNED NONE

// SQL Server PRIMARY KEY CLUSTERED
%token <bytes> CLUSTERED NONCLUSTERED
// SQL Server NOT FOR REPLICATION
%token <bytes> REPLICATION
// index
%token <bytes> INCLUDE

// table hint
%token <bytes> HOLDLOCK NOLOCK NOWAIT PAGLOCK ROWLOCK TABLELOCK

%type <statement> command
%type <selStmt> select_statement base_select union_lhs union_rhs
%type <statement> stream_statement insert_statement update_statement delete_statement set_statement declare_statement cursor_statement while_statement if_statement
%type <statement> create_statement alter_statement rename_statement drop_statement truncate_statement
%type <ddl> create_table_prefix
%type <statement> analyze_statement show_statement use_statement other_statement
%type <statement> begin_statement commit_statement rollback_statement
%type <bytes2> comment_opt comment_list
%type <str> union_op insert_or_replace
%type <str> distinct_opt straight_join_opt cache_opt match_option separator_opt
%type <expr> like_escape_opt
%type <selectExprs> select_expression_list select_expression_list_opt
%type <selectExpr> select_expression
%type <expr> expression
%type <tableExprs> from_opt table_references
%type <tableExpr> table_reference table_factor join_table
%type <joinCondition> join_condition join_condition_opt on_expression_opt
%type <tableNames> table_name_list
%type <str> inner_join outer_join straight_join natural_join
%type <tableName> table_name into_table_name
%type <aliasedTableName> aliased_table_name
%type <indexHints> index_hint_list
%type <expr> where_expression_opt
%type <expr> condition
%type <boolVal> boolean_value
%type <str> compare
%type <ins> insert_data
%type <expr> value value_expression num_val
%type <expr> function_call_keyword function_call_nonkeyword function_call_generic function_call_conflict
%type <str> is_suffix
%type <colTuple> col_tuple
%type <exprs> expression_list
%type <values> tuple_list
%type <valTuple> row_tuple tuple_or_empty
%type <expr> tuple_expression
%type <subquery> subquery
%type <colName> column_name
%type <whens> when_expression_list
%type <when> when_expression
%type <expr> expression_opt else_expression_opt
%type <exprs> group_by_opt
%type <expr> having_opt
%type <orderBy> order_by_opt order_list
%type <order> order
%type <str> asc_desc_opt
%type <limit> limit_opt
%type <str> lock_opt
%type <columns> ins_column_list column_list
%type <columns> include_columns_opt
%type <partitions> opt_partition_clause partition_list
%type <updateExprs> on_dup_opt
%type <updateExprs> update_list
%type <setExprs> set_list transaction_chars
%type <bytes> charset_or_character_set
%type <updateExpr> update_expression
%type <setExpr> set_expression transaction_char isolation_level
%type <bytes> for_from
%type <str> ignore_opt default_opt
%type <str> extended_opt full_opt from_database_opt tables_or_processlist
%type <showFilter> like_or_where_opt
%type <byt> exists_opt
%type <empty> not_exists_opt non_add_drop_or_rename_operation to_opt index_opt
%type <bytes> reserved_keyword non_reserved_keyword
%type <colIdent> sql_id reserved_sql_id col_alias as_ci_opt
%type <boolVal> unique_opt
%type <expr> charset_value
%type <tableIdent> table_id reserved_table_id table_alias as_opt_id
%type <empty> as_opt
%type <empty> force_eof ddl_force_eof
%type <str> charset
%type <str> set_session_or_global show_session_or_global
%type <convertType> convert_type simple_convert_type
%type <columnType> column_type
%type <columnType> bool_type int_type decimal_type numeric_type time_type char_type spatial_type
%type <optVal> length_opt current_timestamp
%type <str> charset_opt collate_opt
%type <boolVal> unsigned_opt zero_fill_opt array_opt time_zone_opt
%type <LengthScaleOption> float_length_opt decimal_length_opt
%type <strs> enum_values
%type <columnDefinition> column_definition
%type <columnType> column_definition_type
%type <indexDefinition> index_definition primary_key_definition
%type <checkDefinition> check_definition
%type <foreignKeyDefinition> foreign_key_definition foreign_key_without_options
%type <colIdent> reference_option
%type <colIdent> sql_id_opt
%type <colIdents> sql_id_list
%type <str> index_or_key
%type <str> equal_opt
%type <TableSpec> table_spec table_column_list
%type <str> table_option_list table_option table_opt_value
%type <indexInfo> index_info
%type <indexColumn> index_column
%type <bytes> operator_class
%type <indexColumnsOrExpression> index_column_list_or_expression
%type <indexColumns> index_column_list
%type <indexPartition> index_partition_opt
%type <indexOptions> index_option_opt
%type <indexOption> index_option
%type <indexOptions> index_option_list mssql_index_option_list
%type <partDefs> partition_definitions
%type <partDef> partition_definition
%type <partSpec> partition_operation
%type <vindexParam> vindex_param
%type <vindexParams> vindex_param_list vindex_params_opt
%type <colIdent> vindex_type vindex_type_opt
%type <bytes> alter_object_type
%type <bytes> policy_as_opt policy_for_opt character_cast_opt
%type <expr> using_opt with_check_opt
%left <bytes> TYPECAST CHECK
%type <bytes> or_replace_opt
%type <boolVal> no_inherit_opt
%type <str> identity_behavior
%type <sequence> sequence_opt
%type <boolVal> clustered_opt not_for_replication_opt
%type <optVal> default_definition default_val
%type <optVal> on_off
%type <str> trigger_time trigger_event fetch_opt
%type <strs> trigger_event_list
%type <blockStatement> trigger_statements statement_block
%type <statement> trigger_statement trigger_statement_start
%type <localVariable> local_variable
%type <localVariables> declare_variable_list
%type <boolVal> scroll_opt
%type <strs> table_hint_list table_hint_opt
%type <str> table_hint
%type <newQualifierColName> new_qualifier_column_name
%type <boolVal> deferrable_opt initially_deferred_opt
%type <boolVal> variadic_opt
%type <arrayConstructor> array_constructor
%type <arrayElements> array_element_list
%type <arrayElement> array_element

%start any_command

%%

any_command:
  command semicolon_opt
  {
    setParseTree(yylex, $1)
  }

semicolon_opt:
/*empty*/ {}
| ';' {}

command:
  select_statement
  {
    $$ = $1
  }
| stream_statement
| insert_statement
| update_statement
| delete_statement
| set_statement
| create_statement
| alter_statement
| rename_statement
| drop_statement
| truncate_statement
| analyze_statement
| show_statement
| use_statement
| begin_statement
| commit_statement
| rollback_statement
| other_statement

select_statement:
  base_select order_by_opt limit_opt lock_opt
  {
    sel := $1.(*Select)
    sel.OrderBy = $2
    sel.Limit = $3
    sel.Lock = $4
    $$ = sel
  }
| union_lhs union_op union_rhs order_by_opt limit_opt lock_opt
  {
    $$ = &Union{Type: $2, Left: $1, Right: $3, OrderBy: $4, Limit: $5, Lock: $6}
  }
| SELECT comment_opt cache_opt NEXT num_val for_from table_name
  {
    $$ = &Select{Comments: Comments($2), Cache: $3, SelectExprs: SelectExprs{Nextval{Expr: $5}}, From: TableExprs{&AliasedTableExpr{Expr: $7}}}
  }

stream_statement:
  STREAM comment_opt select_expression FROM table_name
  {
    $$ = &Stream{Comments: Comments($2), SelectExpr: $3, Table: $5}
  }

// base_select is an unparenthesized SELECT with no order by clause or beyond.
base_select:
  SELECT comment_opt cache_opt distinct_opt straight_join_opt select_expression_list from_opt where_expression_opt group_by_opt having_opt
  {
    $$ = &Select{Comments: Comments($2), Cache: $3, Distinct: $4, Hints: $5, SelectExprs: $6, From: $7, Where: NewWhere(WhereStr, $8), GroupBy: GroupBy($9), Having: NewWhere(HavingStr, $10)}
  }

union_lhs:
  select_statement
  {
    $$ = $1
  }
| openb select_statement closeb
  {
    $$ = &ParenSelect{Select: $2}
  }

union_rhs:
  base_select
  {
    $$ = $1
  }
| openb select_statement closeb
  {
    $$ = &ParenSelect{Select: $2}
  }


insert_statement:
  insert_or_replace comment_opt ignore_opt into_table_name opt_partition_clause insert_data on_dup_opt
  {
    // insert_data returns a *Insert pre-filled with Columns & Values
    ins := $6
    ins.Action = $1
    ins.Comments = $2
    ins.Ignore = $3
    ins.Table = $4
    ins.Partitions = $5
    ins.OnDup = OnDup($7)
    $$ = ins
  }
| insert_or_replace comment_opt ignore_opt into_table_name opt_partition_clause SET update_list on_dup_opt
  {
    cols := make(Columns, 0, len($7))
    vals := make(ValTuple, 0, len($8))
    for _, updateList := range $7 {
      cols = append(cols, updateList.Name.Name)
      vals = append(vals, updateList.Expr)
    }
    $$ = &Insert{Action: $1, Comments: Comments($2), Ignore: $3, Table: $4, Partitions: $5, Columns: cols, Rows: Values{vals}, OnDup: OnDup($8)}
  }

insert_or_replace:
  INSERT
  {
    $$ = InsertStr
  }
| REPLACE
  {
    $$ = ReplaceStr
  }

update_statement:
  UPDATE comment_opt table_references SET update_list where_expression_opt order_by_opt limit_opt
  {
    $$ = &Update{Comments: Comments($2), TableExprs: $3, Exprs: $5, Where: NewWhere(WhereStr, $6), OrderBy: $7, Limit: $8}
  }

delete_statement:
  DELETE comment_opt FROM table_name opt_partition_clause where_expression_opt order_by_opt limit_opt
  {
    $$ = &Delete{Comments: Comments($2), TableExprs:  TableExprs{&AliasedTableExpr{Expr:$4}}, Partitions: $5, Where: NewWhere(WhereStr, $6), OrderBy: $7, Limit: $8}
  }
| DELETE comment_opt FROM table_name_list USING table_references where_expression_opt
  {
    $$ = &Delete{Comments: Comments($2), Targets: $4, TableExprs: $6, Where: NewWhere(WhereStr, $7)}
  }
| DELETE comment_opt table_name_list from_or_using table_references where_expression_opt
  {
    $$ = &Delete{Comments: Comments($2), Targets: $3, TableExprs: $5, Where: NewWhere(WhereStr, $6)}
  }

from_or_using:
  FROM {}
| USING {}

table_name_list:
  table_name
  {
    $$ = TableNames{$1}
  }
| table_name_list ',' table_name
  {
    $$ = append($$, $3)
  }

opt_partition_clause:
  {
    $$ = nil
  }
| PARTITION openb partition_list closeb
  {
  $$ = $3
  }

set_statement:
  SET comment_opt set_list
  {
    $$ = &Set{Comments: Comments($2), Exprs: $3}
  }
| SET comment_opt set_session_or_global set_list
  {
    $$ = &Set{Comments: Comments($2), Scope: $3, Exprs: $4}
  }
| SET comment_opt set_session_or_global TRANSACTION transaction_chars
  {
    $$ = &Set{Comments: Comments($2), Scope: $3, Exprs: $5}
  }
| SET comment_opt TRANSACTION transaction_chars
  {
    $$ = &Set{Comments: Comments($2), Exprs: $4}
  }

declare_statement:
  DECLARE declare_variable_list
  {
    $$ = &Declare{Type: declareVariable, Variables: $2}
  }
| DECLARE sql_id scroll_opt CURSOR FOR select_statement
  {
    $$ = &Declare{
      Type: declareCursor,
      Cursor: &CursorDefinition{
        Name: $2,
        Scroll: bool($3),
        Select: $6,
      },
    }
  }

declare_variable_list:
  local_variable
  {
    $$ = []*LocalVariable{$1}
  }
| declare_variable_list ',' local_variable
  {
    $$ = append($$, $3)
  }

local_variable:
  sql_id column_type
  {
    $$ = &LocalVariable{Name: $1, DataType: $2}
  }

scroll_opt:
  {
    $$ = BoolVal(false)
  }
| SCROLL
  {
    $$ = BoolVal(true)
  }

cursor_statement:
  OPEN sql_id
  {
    $$ = &Cursor{
      Action: OpenStr,
      CursorName: $2,
    }
  }
| CLOSE sql_id
  {
    $$ = &Cursor{
      Action: CloseStr,
      CursorName: $2,
    }
  }
| DEALLOCATE sql_id
  {
    $$ = &Cursor{
      Action: DeallocateStr,
      CursorName: $2,
    }
  }
| FETCH fetch_opt sql_id
  {
    $$ = &Cursor{
      Action: FetchStr,
      Fetch: $2,
      CursorName: $3,
    }
  }
| FETCH fetch_opt sql_id INTO sql_id
  {
    $$ = &Cursor{
      Action: FetchStr,
      Fetch: $2,
      CursorName: $3,
      Into: $5,
    }
  }

fetch_opt:
  {
    $$ = ""
  }
| NEXT FROM
  {
    $$ = string($1)
  }
| PRIOR FROM
  {
    $$ = string($1)
  }
| FIRST FROM
  {
    $$ = string($1)
  }
| LAST FROM
  {
    $$ = string($1)
  }

while_statement:
  WHILE condition trigger_statement
  {
    $$ = &While{
      Condition: $2,
      Statements: []Statement{$3},
    }
  }
| WHILE condition BEGIN statement_block END
  {
    $$ = &While{
      Condition: $2,
      Statements: $4,
      Keyword: string($3),
    }
  }

statement_block:
  trigger_statement
  {
    $$ = []Statement{$1}
  }
| statement_block trigger_statement
  {
    $$ = append($$, $2)
  }

if_statement:
  IF condition BEGIN statement_block END
  {
    $$ = &If{
      Condition: $2,
      IfStatements: $4,
      Keyword: string($3),
    }
  }
| IF condition BEGIN statement_block END ELSE BEGIN statement_block END
  {
    $$ = &If{
      Condition: $2,
      IfStatements: $4,
      ElseStatements: $8,
      Keyword: string($3),
    }
  }

transaction_chars:
  transaction_char
  {
    $$ = SetExprs{$1}
  }
| transaction_chars ',' transaction_char
  {
    $$ = append($$, $3)
  }

transaction_char:
  ISOLATION LEVEL isolation_level
  {
    $$ = $3
  }
| READ WRITE
  {
    $$ = &SetExpr{Name: NewColIdent("tx_read_only"), Expr: NewIntVal([]byte("0"))}
  }
| READ ONLY
  {
    $$ = &SetExpr{Name: NewColIdent("tx_read_only"), Expr: NewIntVal([]byte("1"))}
  }

isolation_level:
  REPEATABLE READ
  {
    $$ = &SetExpr{Name: NewColIdent("tx_isolation"), Expr: NewStrVal([]byte("repeatable read"))}
  }
| READ COMMITTED
  {
    $$ = &SetExpr{Name: NewColIdent("tx_isolation"), Expr: NewStrVal([]byte("read committed"))}
  }
| READ UNCOMMITTED
  {
    $$ = &SetExpr{Name: NewColIdent("tx_isolation"), Expr: NewStrVal([]byte("read uncommitted"))}
  }
| SERIALIZABLE
  {
    $$ = &SetExpr{Name: NewColIdent("tx_isolation"), Expr: NewStrVal([]byte("serializable"))}
  }

set_session_or_global:
  SESSION
  {
    $$ = SessionStr
  }
| GLOBAL
  {
    $$ = GlobalStr
  }

create_statement:
  create_table_prefix table_spec
  {
    $1.TableSpec = $2
    $$ = $1
  }
| CREATE unique_opt clustered_opt INDEX sql_id ON table_name '(' index_column_list_or_expression ')' include_columns_opt where_expression_opt index_option_opt index_partition_opt
  {
    $$ = &DDL{
        Action: CreateIndexStr,
        Table: $7,
        NewName: $7,
        IndexSpec: &IndexSpec{
          Name: $5,
          Type: NewColIdent(""),
          Unique: bool($2),
          Clustered: bool($3),
          Included: $11,
          Where: NewWhere(WhereStr, $12),
          Options: $13,
          Partition: $14,
        },
        IndexCols: $9.IndexCols,
        IndexExpr: $9.IndexExpr,
      }
  }
/* For MySQL */
| CREATE unique_opt clustered_opt INDEX sql_id USING sql_id ON table_name '(' index_column_list ')' index_option_opt
  {
    $$ = &DDL{
        Action: CreateIndexStr,
        Table: $9,
        NewName: $9,
        IndexSpec: &IndexSpec{
          Name: $5,
          Type: $7,
          Unique: bool($2),
          Options: $13,
        },
        IndexCols: $11,
      }
  }
/* For PostgreSQL */
| CREATE unique_opt clustered_opt INDEX sql_id ON table_name USING sql_id '(' index_column_list_or_expression ')' where_expression_opt index_option_opt
  {
    $$ = &DDL{
        Action: CreateIndexStr,
        Table: $7,
        NewName: $7,
        IndexSpec: &IndexSpec{
          Name: $5,
          Type: $9,
          Unique: bool($2),
          Where: NewWhere(WhereStr, $13),
        },
        IndexCols: $11.IndexCols,
        IndexExpr: $11.IndexExpr,
      }
  }
| CREATE or_replace_opt VIEW table_name AS select_statement
  {
    $$ = &DDL{Action: CreateViewStr, View: &View{
        Action: CreateViewStr,
        Name: $4.ToViewName(),
        Definition: $6,
    }}
  }
| CREATE VINDEX sql_id vindex_type_opt vindex_params_opt
  {
    $$ = &DDL{Action: CreateVindexStr, VindexSpec: &VindexSpec{
        Name: $3,
        Type: $4,
        Params: $5,
    }}
  }
| CREATE DATABASE not_exists_opt ID ddl_force_eof
  {
    $$ = &DBDDL{Action: CreateStr, DBName: string($4)}
  }
| CREATE SCHEMA not_exists_opt ID ddl_force_eof
  {
    $$ = &DBDDL{Action: CreateStr, DBName: string($4)}
  }
| CREATE POLICY sql_id ON table_name policy_as_opt policy_for_opt TO sql_id_list using_opt with_check_opt
  {
    $$ = &DDL{Action: CreatePolicyStr, Table: $5, Policy: &Policy{
        Name: $3,
        Permissive: Permissive($6),
        Scope: $7,
        To: $9,
        Using: NewWhere(WhereStr, $10),
        WithCheck: NewWhere(WhereStr, $11),
    }}
  }
/* For MySQL */
| CREATE TRIGGER sql_id trigger_time trigger_event_list ON table_name FOR EACH ROW trigger_statement_start
  {
    $$ = &DDL{Action: CreateTriggerStr, Trigger: &Trigger{
        Name: $3,
        TableName: $7,
        Time: $4,
        Event: $5,
        Body: []Statement{$11},
    }}
  }
/* For MSSQL */
| CREATE TRIGGER sql_id ON table_name trigger_time trigger_event_list AS trigger_statements
  {
    $$ = &DDL{Action: CreateTriggerStr, Trigger: &Trigger{
        Name: $3,
        TableName: $5,
        Time: $6,
        Event: $7,
        Body: $9,
    }}
  }
/* For PostgreSQL */
| CREATE TYPE table_name AS column_type
  {
    $$ = &DDL{
      Action: CreateTypeStr,
      Type: &Type{
        Name: $3,
        Type: $5,
      },
    }
  }

trigger_time:
  FOR
  {
    $$ = string($1)
  }
| BEFORE
  {
    $$ = string($1)
  }
| AFTER
  {
    $$ = string($1)
  }

trigger_event:
  INSERT
  {
    $$ = string($1)
  }
| UPDATE
  {
    $$ = string($1)
  }
| DELETE
  {
    $$ = string($1)
  }

trigger_event_list:
  trigger_event
  {
    $$ = []string{string($1)}
  }
| trigger_event_list ',' trigger_event
  {
    $$ = append($$, string($3))
  }

trigger_statements:
  trigger_statement
  {
    $$ = []Statement{$1}
  }
| trigger_statements trigger_statement
  {
    $$ = append($$, $2)
  }

trigger_statement:
  insert_statement
  {
    $$ = $1
  }
| delete_statement
| update_statement
| declare_statement
| set_statement
| cursor_statement
| while_statement
| if_statement
| base_select order_by_opt limit_opt lock_opt
  {
    sel := $1.(*Select)
    sel.OrderBy = $2
    sel.Limit = $3
    sel.Lock = $4
    $$ = sel
  }

/* TODO: should be a part of trigger_statement */
trigger_statement_start:
  trigger_statement
  | BEGIN trigger_statement ';' END
  {
    $$ = &BeginEnd{
      Statements: []Statement{$2},
    }
  }

policy_as_opt:
  {
    $$ = nil
  }
| AS PERMISSIVE
  {
    $$ = $2
  }
| AS RESTRICTIVE
  {
    $$ = $2
  }

policy_for_opt:
  {
    $$ = nil
  }
| FOR ALL
  {
    $$ = $2
  }
| FOR SELECT
  {
    $$ = $2
  }
| FOR INSERT
  {
    $$ = $2
  }
| FOR UPDATE
  {
    $$ = $2
  }
| FOR DELETE
  {
    $$ = $2
  }

using_opt:
  {
    $$ = nil
  }
| USING expression
  {
    $$ = $2
  }

with_check_opt:
  {
    $$ = nil
  }
| WITH CHECK expression
  {
    $$ = $3
  }

unique_opt:
  {
    $$ = BoolVal(false)
  }
| UNIQUE
  {
    $$ = BoolVal(true)
  }

vindex_type_opt:
  {
    $$ = NewColIdent("")
  }
| USING vindex_type
  {
    $$ = $2
  }

vindex_type:
  ID
  {
    $$ = NewColIdent(string($1))
  }

vindex_params_opt:
  {
    var v []VindexParam
    $$ = v
  }
| WITH vindex_param_list
  {
    $$ = $2
  }

vindex_param_list:
  vindex_param
  {
    $$ = make([]VindexParam, 0, 4)
    $$ = append($$, $1)
  }
| vindex_param_list ',' vindex_param
  {
    $$ = append($$, $3)
  }

vindex_param:
  reserved_sql_id '=' table_opt_value
  {
    $$ = VindexParam{Key: $1, Val: $3}
  }

or_replace_opt:
  {
    $$ = nil
  }
| OR REPLACE
  {
    $$ = nil
  }

create_table_prefix:
  CREATE TABLE not_exists_opt table_name
  {
    $$ = &DDL{Action: CreateStr, NewName: $4}
    setDDL(yylex, $$)
  }

table_spec:
  '(' table_column_list ')' table_option_list
  {
    $$ = $2
    $$.Options = $4
  }

table_column_list:
  {
    $$ = &TableSpec{}
  }
| column_definition
  {
    $$ = &TableSpec{}
    $$.AddColumn($1)
  }
| table_column_list ',' column_definition
  {
    $$.AddColumn($3)
  }
| table_column_list ',' index_definition
  {
    $$.AddIndex($3)
  }
| table_column_list ',' foreign_key_definition
  {
    $$.AddForeignKey($3)
  }
| table_column_list ',' primary_key_definition
  {
    $$.AddIndex($3)
  }
| table_column_list ',' check_definition
  {
    $$.AddCheck($3)
  }

column_definition:
  ID column_definition_type
  {
    $$ = &ColumnDefinition{Name: NewColIdent(string($1)), Type: $2}
  }

column_type:
  numeric_type unsigned_opt zero_fill_opt
  {
    $$ = $1
    $$.Unsigned = $2
    $$.Zerofill = $3
  }
| bool_type
| char_type
| time_type
| spatial_type
// TODO: avoid reduce-reduce conflicts here
| sql_id
  {
    $$ = ColumnType{Type: $1.val}
  }

column_definition_type:
  column_type array_opt
  {
    $1.NotNull = nil
    $1.Default = nil
    $1.OnUpdate = nil
    $1.Autoincrement = BoolVal(false)
    $1.KeyOpt = colKeyNone
    $1.Comment = nil
    $1.Identity = nil
    $1.Array = $2
    $$ = $1
  }
| column_definition_type NULL
  {
    $1.NotNull = NewBoolVal(false)
    $$ = $1
  }
| column_definition_type NOT NULL
  {
    $1.NotNull = NewBoolVal(true)
    $$ = $1
  }
| column_definition_type default_definition
  {
    $1.Default = &DefaultDefinition{Value: $2}
    $$ = $1
  }
| column_definition_type CONSTRAINT sql_id default_definition
  {
    $1.Default = &DefaultDefinition{ConstraintName: $3, Value: $4}
    $$ = $1
  }
| column_definition_type ON UPDATE current_timestamp
  {
    $1.OnUpdate = $4
    $$ = $1
  }
| column_definition_type AUTO_INCREMENT
  {
    $1.Autoincrement = BoolVal(true)
    $$ = $1
  }
| column_definition_type AUTOINCREMENT
  {
    $1.Autoincrement = BoolVal(true)
    $$ = $1
  }
| column_definition_type PRIMARY KEY
  {
    $1.KeyOpt = colKeyPrimary
    $$ = $1
  }
| column_definition_type KEY
  {
    $1.KeyOpt = colKey
    $$ = $1
  }
| column_definition_type UNIQUE KEY
  {
    $1.KeyOpt = colKeyUniqueKey
    $$ = $1
  }
| column_definition_type UNIQUE
  {
    $1.KeyOpt = colKeyUnique
    $$ = $1
  }
| column_definition_type CHECK not_for_replication_opt openb expression closeb no_inherit_opt
  {
    $1.Check = &CheckDefinition{
      Where: *NewWhere(WhereStr, $5),
      NotForReplication: bool($3),
      NoInherit: $7,
    }
    $$ = $1
  }
| column_definition_type CONSTRAINT sql_id CHECK not_for_replication_opt openb expression closeb no_inherit_opt
  {
    $1.Check = &CheckDefinition{
      ConstraintName: $3,
      Where: *NewWhere(WhereStr, $7),
      NotForReplication: bool($5),
      NoInherit: $9,
    }
    $$ = $1
  }
| column_definition_type COMMENT_KEYWORD STRING
  {
    $1.Comment = NewStrVal($3)
    $$ = $1
  }
| column_definition_type REFERENCES table_name
  {
    $1.References = String($3)
    $$ = $1
  }
| column_definition_type REFERENCES table_name '(' column_list ')'
  {
    $1.References     = String($3)
    $1.ReferenceNames = $5
    $$ = $1
  }
// TODO: avoid a shfit/reduce conflict here
| column_definition_type REFERENCES table_name '(' column_list ')' ON DELETE reference_option
  {
    $1.References     = String($3)
    $1.ReferenceNames = $5
    $1.ReferenceOnDelete = $9
    $$ = $1
  }
| column_definition_type REFERENCES table_name '(' column_list ')' ON UPDATE reference_option
  {
    $1.References     = String($3)
    $1.ReferenceNames = $5
    $1.ReferenceOnUpdate = $9
    $$ = $1
  }
// for MySQL and PostgreSQL (TODO: support abbreviation)
| column_definition_type GENERATED identity_behavior AS '(' expression ')' VIRTUAL
  {
    $1.Generated = &GeneratedColumn{Expr: $6}
    $$ = $1
  }
| column_definition_type GENERATED identity_behavior AS '(' expression ')' STORED
  {
    $1.Generated = &GeneratedColumn{Expr: $6}
    $$ = $1
  }
// for PostgreSQL
| column_definition_type GENERATED identity_behavior AS IDENTITY
  {
    $1.Identity = &IdentityOpt{Behavior: $3}
    $1.NotNull = NewBoolVal(true)
    $$ = $1
  }
| column_definition_type GENERATED identity_behavior AS IDENTITY '(' sequence_opt ')'
  {
    $1.Identity = &IdentityOpt{Behavior: $3, Sequence: $7}
    $1.NotNull = NewBoolVal(true)
    $$ = $1
  }
| column_definition_type IDENTITY '(' INTEGRAL ',' INTEGRAL ')'
  {
    $1.Identity = &IdentityOpt{Sequence: &Sequence{StartWith: NewIntVal($4), IncrementBy: NewIntVal($6)}, NotForReplication: false}
    $$ = $1
  }
// for MSSQL: IDENTITY(N,M) NOT FOR REPLICATION
| column_definition_type NOT FOR REPLICATION
  {
    $1.Identity.NotForReplication = true
    $$ = $1
  }

default_definition:
  DEFAULT default_val
  {
    $$ = $2
  }
| DEFAULT '(' default_val ')'
  {
    $$ = $3
  }
| DEFAULT '(' '(' default_val ')' ')'
  {
    $$ = $4
  }

default_val:
  STRING character_cast_opt
  {
    $$ = NewStrVal($1)
  }
| INTEGRAL
  {
    $$ = NewIntVal($1)
  }
| FLOAT
  {
    $$ = NewFloatVal($1)
  }
| NULL
  {
    $$ = NewValArg($1)
  }
| current_timestamp
  {
    $$ = $1
  }
| BIT_LITERAL
  {
    $$ = NewBitVal($1)
  }
| boolean_value
  {
    $$ = NewBoolSQLVal(bool($1))
  }
| NOW openb closeb
  {
    $$ = NewBitVal($1)
  }
| STRING TYPECAST sql_id
  {
    $$ = NewStrVal($1)
  }

identity_behavior:
  ALWAYS
  {
    $$ = string($1)
  }
| BY DEFAULT
  {
    $$ = string($1)+" "+string($2)
  }

sequence_opt:
  {
    $$ = &Sequence{}
  }
| sequence_opt START WITH INTEGRAL
  {
    $1.StartWith = NewIntVal($4)
    $$ = $1
  }
| sequence_opt START INTEGRAL
  {
    $1.StartWith = NewIntVal($3)
    $$ = $1
  }
| sequence_opt INCREMENT BY INTEGRAL
  {
    $1.IncrementBy = NewIntVal($4)
    $$ = $1
  }
| sequence_opt INCREMENT INTEGRAL
  {
    $1.IncrementBy = NewIntVal($3)
    $$ = $1
  }
| sequence_opt MINVALUE INTEGRAL
  {
    $1.MinValue = NewIntVal($3)
    $$ = $1
  }
| sequence_opt MAXVALUE INTEGRAL
  {
    $1.MaxValue = NewIntVal($3)
    $$ = $1
  }
| sequence_opt CACHE INTEGRAL
  {
    $1.Cache = NewIntVal($3)
    $$ = $1
  }
| sequence_opt NO MINVALUE
  {
    $1.NoMinValue = NewBoolVal(true)
    $$ = $1
  }
| sequence_opt NO MAXVALUE
  {
    $1.NoMaxValue = NewBoolVal(true)
    $$ = $1
  }
| sequence_opt NO CYCLE
  {
    $1.NoCycle = NewBoolVal(true)
    $$ = $1
  }
| sequence_opt CYCLE
  {
    $1.Cycle = NewBoolVal(true)
    $$ = $1
  }
| sequence_opt OWNED BY NONE
  {
    $1.OwnedBy = "NONE"
    $$ = $1
  }
| sequence_opt OWNED BY table_id '.' reserved_sql_id
  {
    $1.OwnedBy = string($4.v)+"."+string($6.val)
    $$ = $1
  }

current_timestamp:
  CURRENT_TIMESTAMP length_opt
  {
    $$ = NewValArgWithOpt($1, $2)
  }
| CURRENT_TIMESTAMP '(' ')'
  {
    $$ = NewValArgWithOpt($1, nil)
  }
| CURRENT_TIME length_opt
  {
    $$ = NewValArgWithOpt($1, $2)
  }
| CURRENT_TIME '(' ')'
  {
    $$ = NewValArgWithOpt($1, nil)
  }
| CURRENT_DATE
  {
    $$ = NewValArgWithOpt($1, nil)
  }
| GETDATE '(' ')'
  {
    $$ = NewValArgWithOpt($1, nil)
  }

no_inherit_opt:
  {
    $$ = BoolVal(false)
  }
| NO INHERIT
  {
    $$ = BoolVal(true)
  }

character_cast_opt:
  {
    $$ = nil
  }
| TYPECAST CHARACTER VARYING
| TYPECAST TIMESTAMP time_zone_opt
| TYPECAST BPCHAR
| TYPECAST TEXT
| TYPECAST JSON

numeric_type:
  int_type length_opt
  {
    $$ = $1
    $$.Length = $2
  }
| decimal_type
  {
    $$ = $1
  }

int_type:
  BIT
  {
    $$ = ColumnType{Type: string($1)}
  }
| TINYINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| SMALLINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| SMALLSERIAL
  {
    $$ = ColumnType{Type: string($1)}
  }
| MEDIUMINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| INT
  {
    $$ = ColumnType{Type: string($1)}
  }
| INTEGER
  {
    $$ = ColumnType{Type: string($1)}
  }
| SERIAL
  {
    $$ = ColumnType{Type: string($1)}
  }
| BIGINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| BIGSERIAL
  {
    $$ = ColumnType{Type: string($1)}
  }

decimal_type:
REAL float_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| DOUBLE PRECISION float_length_opt
  {
    $$ = ColumnType{Type: string($1)+" "+string($2)}
    $$.Length = $3.Length
    $$.Scale = $3.Scale
  }
| DOUBLE float_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| FLOAT_TYPE float_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| DECIMAL decimal_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| NUMERIC decimal_length_opt
  {
    $$ = ColumnType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| MONEY
  {
    $$ = ColumnType{Type: string($1)}
  }
| SMALLMONEY
  {
    $$ = ColumnType{Type: string($1)}
  }

time_type:
  DATE
  {
    $$ = ColumnType{Type: string($1)}
  }
| TIME length_opt time_zone_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2, Timezone: $3}
  }
| TIMESTAMP length_opt time_zone_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2, Timezone: $3}
  }
| DATETIME length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| DATETIME2
  {
    $$ = ColumnType{Type: string($1)}
  }
| DATETIMEOFFSET length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| SMALLDATETIME
  {
    $$ = ColumnType{Type: string($1)}
  }
| YEAR
  {
    $$ = ColumnType{Type: string($1)}
  }

bool_type:
  BOOL
  {
    $$ = ColumnType{Type: string($1)}
  }
| BOOLEAN
  {
    $$ = ColumnType{Type: string($1)}
  }

char_type:
  CHAR length_opt charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2, Charset: $3, Collate: $4}
  }
| CHARACTER length_opt charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2, Charset: $3, Collate: $4}
  }
| VARCHAR length_opt charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2, Charset: $3, Collate: $4}
  }
| NCHAR length_opt charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2, Charset: $3, Collate: $4}
  }
| NVARCHAR length_opt charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2, Charset: $3, Collate: $4}
  }
| NTEXT
  {
    $$ = ColumnType{Type: string($1)}
  }
| CHARACTER VARYING length_opt charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1)+" "+string($2), Length: $3, Charset: $4, Collate: $5}
  }
| BINARY length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| VARBINARY length_opt
  {
    $$ = ColumnType{Type: string($1), Length: $2}
  }
| TEXT charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Charset: $2, Collate: $3}
  }
| TINYTEXT charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Charset: $2, Collate: $3}
  }
| MEDIUMTEXT charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Charset: $2, Collate: $3}
  }
| LONGTEXT charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Charset: $2, Collate: $3}
  }
| CITEXT charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), Charset: $2, Collate: $3}
  }
| BLOB
  {
    $$ = ColumnType{Type: string($1)}
  }
| TINYBLOB
  {
    $$ = ColumnType{Type: string($1)}
  }
| MEDIUMBLOB
  {
    $$ = ColumnType{Type: string($1)}
  }
| LONGBLOB
  {
    $$ = ColumnType{Type: string($1)}
  }
| JSON
  {
    $$ = ColumnType{Type: string($1)}
  }
| JSONB
  {
    $$ = ColumnType{Type: string($1)}
  }
| UUID
  {
    $$ = ColumnType{Type: string($1)}
  }
| ENUM '(' enum_values ')' charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), EnumValues: $3, Charset: $5, Collate: $6}
  }
// need set_values / SetValues ?
| SET '(' enum_values ')' charset_opt collate_opt
  {
    $$ = ColumnType{Type: string($1), EnumValues: $3, Charset: $5, Collate: $6}
  }

spatial_type:
  GEOMETRY
  {
    $$ = ColumnType{Type: string($1)}
  }
| POINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| LINESTRING
  {
    $$ = ColumnType{Type: string($1)}
  }
| POLYGON
  {
    $$ = ColumnType{Type: string($1)}
  }
| GEOMETRYCOLLECTION
  {
    $$ = ColumnType{Type: string($1)}
  }
| MULTIPOINT
  {
    $$ = ColumnType{Type: string($1)}
  }
| MULTILINESTRING
  {
    $$ = ColumnType{Type: string($1)}
  }
| MULTIPOLYGON
  {
    $$ = ColumnType{Type: string($1)}
  }

enum_values:
  STRING
  {
    $$ = make([]string, 0, 4)
    $$ = append($$, "'" + string($1) + "'")
  }
| enum_values ',' STRING
  {
    $$ = append($1, "'" + string($3) + "'")
  }

length_opt:
  {
    $$ = nil
  }
| '(' INTEGRAL ')'
  {
    $$ = NewIntVal($2)
  }

float_length_opt:
  {
    $$ = LengthScaleOption{}
  }
| '(' INTEGRAL ',' INTEGRAL ')'
  {
    $$ = LengthScaleOption{
        Length: NewIntVal($2),
        Scale: NewIntVal($4),
    }
  }

decimal_length_opt:
  {
    $$ = LengthScaleOption{}
  }
| '(' INTEGRAL ')'
  {
    $$ = LengthScaleOption{
        Length: NewIntVal($2),
    }
  }
| '(' INTEGRAL ',' INTEGRAL ')'
  {
    $$ = LengthScaleOption{
        Length: NewIntVal($2),
        Scale: NewIntVal($4),
    }
  }

time_zone_opt:
  {
    $$ = BoolVal(false)
  }
| WITH TIME ZONE
  {
    $$ = BoolVal(true)
  }
| WITHOUT TIME ZONE
  {
    $$ = BoolVal(false)
  }

unsigned_opt:
  {
    $$ = BoolVal(false)
  }
| UNSIGNED
  {
    $$ = BoolVal(true)
  }

zero_fill_opt:
  {
    $$ = BoolVal(false)
  }
| ZEROFILL
  {
    $$ = BoolVal(true)
  }

array_opt:
  {
    $$ = BoolVal(false)
  }
| '[' ']'
  {
    $$ = BoolVal(true)
  }
| ARRAY
  {
    $$ = BoolVal(true)
  }

charset_opt:
  {
    $$ = ""
  }
| CHARACTER SET ID
  {
    $$ = string($3)
  }
| CHARACTER SET BINARY
  {
    $$ = string($3)
  }

collate_opt:
  {
    $$ = ""
  }
| BINARY
  {
    $$ = string($1) // Set pseudo collation "binary" for BINARY attribute (deprecated in future MySQL versions)
  }
| COLLATE ID
  {
    $$ = string($2)
  }

index_definition:
  index_info '(' index_column_list ')' index_option_opt index_partition_opt
  {
    $$ = &IndexDefinition{Info: $1, Columns: $3, Options: $5, Partition: $6}
  }

index_option_opt:
  {
    $$ = []*IndexOption{}
  }
| index_option_list
  {
    $$ = $1
  }
| WITH '(' mssql_index_option_list ')'
 {
   $$ = $3
 }

index_option_list:
  index_option
  {
    $$ = []*IndexOption{$1}
  }
| index_option_list index_option
  {
    $$ = append($$, $2)
  }

mssql_index_option_list:
  index_option
  {
    $$ = []*IndexOption{$1}
  }
| mssql_index_option_list ',' index_option
  {
    $$ = append($$, $3)
  }

index_option:
  USING ID
  {
    $$ = &IndexOption{Name: string($1), Value: NewStrVal($2)}
  }
| KEY_BLOCK_SIZE equal_opt INTEGRAL
  {
    // should not be string
    $$ = &IndexOption{Name: string($1), Value: NewIntVal($3)}
  }
| COMMENT_KEYWORD STRING
  {
    $$ = &IndexOption{Name: string($1), Value: NewStrVal($2)}
  }
| WITH PARSER sql_id
  {
    $$ = &IndexOption{Name: string($2), Value: NewStrVal([]byte($3.String()))}
  }
| PAD_INDEX '=' on_off
  {
    $$ = &IndexOption{Name: string($1), Value: $3}
  }
| FILLFACTOR '=' INTEGRAL
  {
    $$ = &IndexOption{Name: string($1), Value: NewIntVal($3)}
  }
| IGNORE_DUP_KEY '=' on_off
  {
    $$ = &IndexOption{Name: string($1), Value: $3}
  }
| STATISTICS_NORECOMPUTE '=' on_off
  {
    $$ = &IndexOption{Name: string($1), Value: $3}
  }
| STATISTICS_INCREMENTAL '=' on_off
  {
    $$ = &IndexOption{Name: string($1), Value: $3}
  }
| ALLOW_ROW_LOCKS '=' on_off
  {
    $$ = &IndexOption{Name: string($1), Value: $3}
  }
| ALLOW_PAGE_LOCKS '=' on_off
  {
    $$ = &IndexOption{Name: string($1), Value: $3}
  }

equal_opt:
  /* empty */
  {
    $$ = ""
  }
| '='
  {
    $$ = string($1)
  }

on_off:
  ON
  {
    $$ = NewBoolSQLVal(true)
  }
| OFF
  {
    $$ = NewBoolSQLVal(false)
  }

// for MSSQL
index_partition_opt:
  {
    $$ = nil
  }
| ON sql_id
 {
   $$ = &IndexPartition{Name: $2.String()}
 }
| ON sql_id openb sql_id closeb
 {
   $$ = &IndexPartition{Name: $2.String(), Column: $4.String()}
 }

index_info:
  PRIMARY KEY
  {
    $$ = &IndexInfo{Type: string($1) + " " + string($2), Name: NewColIdent("PRIMARY"), Primary: true, Unique: true}
  }
| SPATIAL index_or_key ID
  {
    $$ = &IndexInfo{Type: string($1) + " " + string($2), Name: NewColIdent(string($3)), Spatial: true, Unique: false}
  }
| FULLTEXT index_or_key ID
  {
    $$ = &IndexInfo{Type: string($1) + " " + string($2), Name: NewColIdent(string($3)), Fulltext: true}
  }
| FULLTEXT ID
  {
    $$ = &IndexInfo{Type: string($1), Name: NewColIdent(string($2)), Fulltext: true}
  }
| UNIQUE index_or_key ID
  {
    $$ = &IndexInfo{Type: string($1) + " " + string($2), Name: NewColIdent(string($3)), Unique: true}
  }
| UNIQUE ID
  {
    $$ = &IndexInfo{Type: string($1), Name: NewColIdent(string($2)), Unique: true}
  }
| index_or_key ID clustered_opt
  {
    $$ = &IndexInfo{Type: string($1), Name: NewColIdent(string($2)), Unique: false, Clustered: $3}
  }
| index_or_key ID UNIQUE clustered_opt
  {
    $$ = &IndexInfo{Type: string($1), Name: NewColIdent(string($2)), Unique: true, Clustered: $4}
  }

index_or_key:
    INDEX
  {
    $$ = string($1)
  }
  | KEY
  {
    $$ = string($1)
  }

index_column_list_or_expression:
  index_column_list
  {
    $$ = IndexColumnsOrExpression{IndexCols: $1}
  }
/* For PostgreSQL: https://www.postgresql.org/docs/14/indexes-expressional.html */
| function_call_generic
  {
    $$ = IndexColumnsOrExpression{IndexExpr: $1}
  }

index_column_list:
  index_column
  {
    $$ = []IndexColumn{$1}
  }
| index_column_list ',' index_column
  {
    $$ = append($$, $3)
  }

index_column:
  sql_id length_opt asc_desc_opt
  {
    $$ = IndexColumn{Column: $1, Length: $2, Direction: $3}
  }
/* For PostgreSQL */
| KEY length_opt
  {
    $$ = IndexColumn{Column: NewColIdent(string($1)), Length: $2}
  }
| sql_id operator_class
  {
    $$ = IndexColumn{Column: $1, OperatorClass: string($2)}
  }

// https://www.postgresql.org/docs/9.5/brin-builtin-opclasses.html
operator_class:
  TEXT_PATTERN_OPS

foreign_key_definition:
  foreign_key_without_options not_for_replication_opt
  {
    $1.NotForReplication = bool($2)
    $$ = $1
  }
| foreign_key_without_options ON DELETE reference_option not_for_replication_opt
  {
    $1.OnUpdate = NewColIdent("")
    $1.OnDelete = $4
    $1.NotForReplication = bool($5)
    $$ = $1
  }
| foreign_key_without_options ON UPDATE reference_option not_for_replication_opt
  {
    $1.OnUpdate = $4
    $1.OnDelete = NewColIdent("")
    $1.NotForReplication = bool($5)
    $$ = $1
  }
| foreign_key_without_options ON DELETE reference_option ON UPDATE reference_option not_for_replication_opt
  {
    $1.OnUpdate = $7
    $1.OnDelete = $4
    $1.NotForReplication = bool($8)
    $$ = $1
  }
| foreign_key_without_options ON UPDATE reference_option ON DELETE reference_option not_for_replication_opt
  {
    $1.OnUpdate = $4
    $1.OnDelete = $7
    $1.NotForReplication = bool($8)
    $$ = $1
  }

foreign_key_without_options:
  CONSTRAINT sql_id_opt FOREIGN KEY sql_id_opt '(' sql_id_list ')' REFERENCES table_name '(' sql_id_list ')'
  {
    $$ = &ForeignKeyDefinition{
      ConstraintName: $2,
      IndexName: $5,
      IndexColumns: $7,
      ReferenceName: NewColIdent(String($10)),
      ReferenceColumns: $12,
    }
  }

reference_option:
  RESTRICT
  {
    $$ = NewColIdent("RESTRICT")
  }
| CASCADE
  {
    $$ = NewColIdent("CASCADE")
  }
| SET NULL
  {
    $$ = NewColIdent("SET NULL")
  }
| NO ACTION
  {
    $$ = NewColIdent("NO ACTION")
  }

primary_key_definition:
  CONSTRAINT sql_id PRIMARY KEY clustered_opt '(' index_column_list ')' index_option_opt index_partition_opt
  {
    $$ = &IndexDefinition{
      Info: &IndexInfo{Type: string($3) + " " + string($4), Name: $2, Primary: true, Unique: true, Clustered: $5},
      Columns: $7,
      Options: $9,
      Partition: $10,
    }
  }

check_definition:
  CONSTRAINT sql_id CHECK openb expression closeb no_inherit_opt
  {
    $$ = &CheckDefinition{
      ConstraintName: $2,
      Where: *NewWhere(WhereStr, $5),
      NoInherit: $7,
    }
  }

/* For SQL Server */
clustered_opt:
  {
    $$ = BoolVal(true)
  }
| CLUSTERED
  {
    $$ = BoolVal(true)
  }
| NONCLUSTERED
  {
    $$ = BoolVal(false)
  }

/* For SQL Server */
not_for_replication_opt:
  {
    $$ = BoolVal(false)
  }
| NOT FOR REPLICATION
  {
    $$ = BoolVal(true)
  }

sql_id_opt:
  {
    $$ = NewColIdent("")
  }
| sql_id

sql_id_list:
  sql_id
  {
    $$ = []ColIdent{$1}
  }
| sql_id_list ',' sql_id
  {
    $$ = append($1, $3)
  }

table_option_list:
  {
    $$ = ""
  }
| table_option
  {
    $$ = " " + string($1)
  }
| table_option_list ',' table_option
  {
    $$ = string($1) + ", " + string($3)
  }

// rather than explicitly parsing the various keywords for table options,
// just accept any number of keywords, IDs, strings, numbers, and '='
table_option:
  table_opt_value
  {
    $$ = $1
  }
| table_option table_opt_value
  {
    $$ = $1 + " " + $2
  }
| table_option '=' table_opt_value
  {
    $$ = $1 + "=" + $3
  }

table_opt_value:
  reserved_sql_id
  {
    $$ = $1.String()
  }
| STRING
  {
    $$ = "'" + string($1) + "'"
  }
| INTEGRAL
  {
    $$ = string($1)
  }

alter_statement:
  ALTER ignore_opt TABLE table_name non_add_drop_or_rename_operation force_eof
  {
    $$ = &DDL{Action: AlterStr, Table: $4, NewName: $4}
  }
| ALTER ignore_opt TABLE table_name ADD unique_opt alter_object_type_index sql_id '(' index_column_list ')'
  {
    $$ = &DDL{
        Action: AddIndexStr,
        Table: $4,
        NewName: $4,
        IndexSpec: &IndexSpec{
          Name: $8,
          Unique: bool($6),
          Primary: false,
        },
        IndexCols: $10,
      }
  }
| ALTER ignore_opt TABLE ONLY table_name ADD CONSTRAINT sql_id PRIMARY KEY '(' index_column_list ')'
  {
    $$ = &DDL{
        Action: AddPrimaryKeyStr,
        Table: $5,
        NewName: $5,
        IndexSpec: &IndexSpec{
          Name: $8,
          Unique: false,
          Primary: true,
        },
        IndexCols: $12,
      }
  }
| ALTER ignore_opt TABLE table_name ADD CONSTRAINT sql_id UNIQUE '(' index_column_list ')' deferrable_opt initially_deferred_opt
  {
    $$ = &DDL{
        Action: AddIndexStr,
        Table: $4,
        NewName: $4,
        IndexSpec: &IndexSpec{
          Name: $7,
          Unique: true,
          Primary: false,
          Constraint: true,
          ConstraintOptions: &ConstraintOptions{
            Deferrable: bool($12),
            InitiallyDeferred: bool($13),
          },
        },
        IndexCols: $10,
      }
  }
| ALTER ignore_opt TABLE ONLY table_name ADD foreign_key_definition
  {
    $$ = &DDL{
        Action: AddForeignKeyStr,
        Table: $5,
        NewName: $5,
        ForeignKey: $7,
      }
  }
| ALTER ignore_opt TABLE table_name ADD alter_object_type_rest force_eof
  {
    $$ = &DDL{Action: AlterStr, Table: $4, NewName: $4}
  }
| ALTER ignore_opt TABLE table_name DROP alter_object_type force_eof
  {
    $$ = &DDL{Action: AlterStr, Table: $4, NewName: $4}
  }
| ALTER ignore_opt TABLE table_name ADD VINDEX sql_id '(' column_list ')' vindex_type_opt vindex_params_opt
  {
    $$ = &DDL{
        Action: AddColVindexStr,
        Table: $4,
        VindexSpec: &VindexSpec{
            Name: $7,
            Type: $11,
            Params: $12,
        },
        VindexCols: $9,
      }
  }
| ALTER ignore_opt TABLE table_name DROP VINDEX sql_id
  {
    $$ = &DDL{
        Action: DropColVindexStr,
        Table: $4,
        VindexSpec: &VindexSpec{
            Name: $7,
        },
      }
  }
| ALTER ignore_opt TABLE table_name RENAME to_opt table_name
  {
    // Change this to a rename statement
    $$ = &DDL{Action: RenameStr, Table: $4, NewName: $7}
  }
| ALTER ignore_opt TABLE table_name RENAME index_opt force_eof
  {
    // Rename an index can just be an alter
    $$ = &DDL{Action: AlterStr, Table: $4, NewName: $4}
  }
| ALTER VIEW table_name ddl_force_eof
  {
    $$ = &DDL{Action: AlterStr, Table: $3.ToViewName(), NewName: $3.ToViewName()}
  }
| ALTER ignore_opt TABLE table_name partition_operation
  {
    $$ = &DDL{Action: AlterStr, Table: $4, PartitionSpec: $5}
  }

alter_object_type:
  COLUMN
| CONSTRAINT
| FOREIGN
| FULLTEXT
| ID
| INDEX
| KEY
| PRIMARY
| SPATIAL
| PARTITION
| UNIQUE

alter_object_type_index:
  INDEX
| KEY

alter_object_type_rest:
  COLUMN
| FOREIGN
| FULLTEXT
| ID
| PRIMARY
| SPATIAL
| PARTITION

partition_operation:
  REORGANIZE PARTITION sql_id INTO openb partition_definitions closeb
  {
    $$ = &PartitionSpec{Action: ReorganizeStr, Name: $3, Definitions: $6}
  }

partition_definitions:
  partition_definition
  {
    $$ = []*PartitionDefinition{$1}
  }
| partition_definitions ',' partition_definition
  {
    $$ = append($1, $3)
  }

partition_definition:
  PARTITION sql_id VALUES LESS THAN openb value_expression closeb
  {
    $$ = &PartitionDefinition{Name: $2, Limit: $7}
  }
| PARTITION sql_id VALUES LESS THAN openb MAXVALUE closeb
  {
    $$ = &PartitionDefinition{Name: $2, Maxvalue: true}
  }

rename_statement:
  RENAME TABLE table_name TO table_name
  {
    $$ = &DDL{Action: RenameStr, Table: $3, NewName: $5}
  }

drop_statement:
  DROP TABLE exists_opt table_name
  {
    var exists bool
    if $3 != 0 {
      exists = true
    }
    $$ = &DDL{Action: DropStr, Table: $4, IfExists: exists}
  }
| DROP INDEX ID ON table_name ddl_force_eof
  {
    // Change this to an alter statement
    $$ = &DDL{Action: AlterStr, Table: $5, NewName: $5}
  }
| DROP VIEW exists_opt table_name ddl_force_eof
  {
    var exists bool
        if $3 != 0 {
          exists = true
        }
    $$ = &DDL{Action: DropStr, Table: $4.ToViewName(), IfExists: exists}
  }
| DROP DATABASE exists_opt ID
  {
    $$ = &DBDDL{Action: DropStr, DBName: string($4)}
  }
| DROP SCHEMA exists_opt ID
  {
    $$ = &DBDDL{Action: DropStr, DBName: string($4)}
  }

truncate_statement:
  TRUNCATE TABLE table_name
  {
    $$ = &DDL{Action: TruncateStr, Table: $3}
  }
| TRUNCATE table_name
  {
    $$ = &DDL{Action: TruncateStr, Table: $2}
  }
analyze_statement:
  ANALYZE TABLE table_name
  {
    $$ = &DDL{Action: AlterStr, Table: $3, NewName: $3}
  }

show_statement:
  SHOW BINARY ID ddl_force_eof /* SHOW BINARY LOGS */
  {
    $$ = &Show{Type: string($2) + " " + string($3)}
  }
| SHOW CHARACTER SET ddl_force_eof
  {
    $$ = &Show{Type: string($2) + " " + string($3)}
  }
| SHOW CREATE DATABASE ddl_force_eof
  {
    $$ = &Show{Type: string($2) + " " + string($3)}
  }
/* Rule to handle SHOW CREATE EVENT, SHOW CREATE FUNCTION, etc. */
| SHOW CREATE ID ddl_force_eof
  {
    $$ = &Show{Type: string($2) + " " + string($3)}
  }
| SHOW CREATE PROCEDURE ddl_force_eof
  {
    $$ = &Show{Type: string($2) + " " + string($3)}
  }
| SHOW CREATE TABLE ddl_force_eof
  {
    $$ = &Show{Type: string($2) + " " + string($3)}
  }
| SHOW CREATE TRIGGER ddl_force_eof
  {
    $$ = &Show{Type: string($2) + " " + string($3)}
  }
| SHOW CREATE VIEW ddl_force_eof
  {
    $$ = &Show{Type: string($2) + " " + string($3)}
  }
| SHOW DATABASES ddl_force_eof
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW INDEX ddl_force_eof
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW KEYS ddl_force_eof
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW PROCEDURE ddl_force_eof
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW show_session_or_global STATUS ddl_force_eof
  {
    $$ = &Show{Scope: $2, Type: string($3)}
  }
| SHOW TABLE ddl_force_eof
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW extended_opt full_opt tables_or_processlist from_database_opt like_or_where_opt
  {
    // this is ugly, but I couldn't find a better way for now
    if $4 == "processlist" {
      $$ = &Show{Type: $4}
    } else {
      showTablesOpt := &ShowTablesOpt{Extended: $2, Full:$3, DbName:$5, Filter:$6}
      $$ = &Show{Type: $4, ShowTablesOpt: showTablesOpt}
    }
  }
| SHOW show_session_or_global VARIABLES ddl_force_eof
  {
    $$ = &Show{Scope: $2, Type: string($3)}
  }
| SHOW VINDEXES
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW VINDEXES ON table_name
  {
    $$ = &Show{Type: string($2), OnTable: $4}
  }
| SHOW VITESS_KEYSPACES
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW VITESS_SHARDS
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW VITESS_TABLETS
  {
    $$ = &Show{Type: string($2)}
  }
| SHOW VSCHEMA_TABLES
  {
    $$ = &Show{Type: string($2)}
  }
/*
 * Catch-all for show statements without vitess keywords:
 *
 *  SHOW BINARY LOGS
 *  SHOW INVALID
 */
| SHOW ID ddl_force_eof
  {
    $$ = &Show{Type: string($2)}
  }

tables_or_processlist:
  TABLES
  {
    $$ = string($1)
  }
| PROCESSLIST
  {
    $$ = string($1)
  }

extended_opt:
  /* empty */
  {
    $$ = ""
  }
| EXTENDED
  {
    $$ = "extended "
  }

full_opt:
  /* empty */
  {
    $$ = ""
  }
| FULL
  {
    $$ = "full "
  }

from_database_opt:
  /* empty */
  {
    $$ = ""
  }
| FROM table_id
  {
    $$ = $2.v
  }
| IN table_id
  {
    $$ = $2.v
  }

like_or_where_opt:
  /* empty */
  {
    $$ = nil
  }
| LIKE STRING
  {
    $$ = &ShowFilter{Like:string($2)}
  }
| WHERE expression
  {
    $$ = &ShowFilter{Filter:$2}
  }

show_session_or_global:
  /* empty */
  {
    $$ = ""
  }
| SESSION
  {
    $$ = SessionStr
  }
| GLOBAL
  {
    $$ = GlobalStr
  }

use_statement:
  USE table_id
  {
    $$ = &Use{DBName: $2}
  }
| USE
  {
    $$ = &Use{DBName:TableIdent{v:""}}
  }

begin_statement:
  BEGIN
  {
    $$ = &Begin{}
  }
| START TRANSACTION
  {
    $$ = &Begin{}
  }

commit_statement:
  COMMIT
  {
    $$ = &Commit{}
  }

rollback_statement:
  ROLLBACK
  {
    $$ = &Rollback{}
  }

other_statement:
  DESC force_eof
  {
    $$ = &OtherRead{}
  }
| DESCRIBE force_eof
  {
    $$ = &OtherRead{}
  }
| EXPLAIN force_eof
  {
    $$ = &OtherRead{}
  }
| REPAIR force_eof
  {
    $$ = &OtherAdmin{}
  }
| OPTIMIZE force_eof
  {
    $$ = &OtherAdmin{}
  }

comment_opt:
  {
    setAllowComments(yylex, true)
  }
  comment_list
  {
    $$ = $2
    setAllowComments(yylex, false)
  }

comment_list:
  {
    $$ = nil
  }
| comment_list COMMENT
  {
    $$ = append($1, $2)
  }

union_op:
  UNION
  {
    $$ = UnionStr
  }
| UNION ALL
  {
    $$ = UnionAllStr
  }
| UNION DISTINCT
  {
    $$ = UnionDistinctStr
  }

cache_opt:
{
  $$ = ""
}
| SQL_NO_CACHE
{
  $$ = SQLNoCacheStr
}
| SQL_CACHE
{
  $$ = SQLCacheStr
}

distinct_opt:
  {
    $$ = ""
  }
| DISTINCT
  {
    $$ = DistinctStr
  }

straight_join_opt:
  {
    $$ = ""
  }
| STRAIGHT_JOIN
  {
    $$ = StraightJoinHint
  }

select_expression_list_opt:
  {
    $$ = nil
  }
| select_expression_list
  {
    $$ = $1
  }

select_expression_list:
  select_expression
  {
    $$ = SelectExprs{$1}
  }
| select_expression_list ',' select_expression
  {
    $$ = append($$, $3)
  }

select_expression:
  '*'
  {
    $$ = &StarExpr{}
  }
| expression as_ci_opt
  {
    $$ = &AliasedExpr{Expr: $1, As: $2}
  }
| table_id '.' '*'
  {
    $$ = &StarExpr{TableName: TableName{Name: $1}}
  }
| table_id '.' reserved_table_id '.' '*'
  {
    $$ = &StarExpr{TableName: TableName{Qualifier: $1, Name: $3}}
  }

as_ci_opt:
  {
    $$ = ColIdent{}
  }
| col_alias
  {
    $$ = $1
  }
| AS col_alias
  {
    $$ = $2
  }

col_alias:
  sql_id
| STRING
  {
    $$ = NewColIdent(string($1))
  }

from_opt:
  {
    $$ = TableExprs{&AliasedTableExpr{Expr:TableName{Name: NewTableIdent("dual")}}}
  }
| FROM table_references
  {
    $$ = $2
  }

table_references:
  table_reference
  {
    $$ = TableExprs{$1}
  }
| table_references ',' table_reference
  {
    $$ = append($$, $3)
  }

table_reference:
  table_factor
| join_table

table_factor:
  aliased_table_name
  {
    $$ = $1
  }
| subquery as_opt table_id
  {
    $$ = &AliasedTableExpr{Expr:$1, As: $3}
  }
| openb table_references closeb
  {
    $$ = &ParenTableExpr{Exprs: $2}
  }

table_hint_opt:
  {
    $$ = []string{}
  }
| WITH '(' table_hint_list ')'
  {
    $$ = $3
  }

table_hint_list:
  table_hint
  {
    $$ = []string{$1}
  }
| table_hint_list ',' table_hint
  {
    $$ = append($1, $3)
  }

table_hint:
  HOLDLOCK
  {
    $$ = string($1)
  }
| NOLOCK
  {
    $$ = string($1)
  }
| NOWAIT
  {
    $$ = string($1)
  }
| PAGLOCK
  {
    $$ = string($1)
  }
| ROWLOCK
  {
    $$ = string($1)
  }
| TABLELOCK
  {
    $$ = string($1)
  }

aliased_table_name:
table_name as_opt_id index_hint_list table_hint_opt
  {
    $$ = &AliasedTableExpr{Expr:$1, As: $2, IndexHints: $3, TableHints: $4}
  }
| table_name PARTITION openb partition_list closeb as_opt_id index_hint_list table_hint_opt
  {
    $$ = &AliasedTableExpr{Expr:$1, Partitions: $4, As: $6, IndexHints: $7, TableHints: $8}
  }

column_list:
  sql_id
  {
    $$ = Columns{$1}
  }
/* For PostgreSQL */
| KEY
  {
    $$ = Columns{NewColIdent(string($1))}
  }
| column_list ',' sql_id
  {
    $$ = append($$, $3)
  }

partition_list:
  sql_id
  {
    $$ = Partitions{$1}
  }
| partition_list ',' sql_id
  {
    $$ = append($$, $3)
  }

// There is a grammar conflict here:
// 1: INSERT INTO a SELECT * FROM b JOIN c ON b.i = c.i
// 2: INSERT INTO a SELECT * FROM b JOIN c ON DUPLICATE KEY UPDATE a.i = 1
// When yacc encounters the ON clause, it cannot determine which way to
// resolve. The %prec override below makes the parser choose the
// first construct, which automatically makes the second construct a
// syntax error. This is the same behavior as MySQL.
join_table:
  table_reference inner_join table_factor join_condition_opt
  {
    $$ = &JoinTableExpr{LeftExpr: $1, Join: $2, RightExpr: $3, Condition: $4}
  }
| table_reference straight_join table_factor on_expression_opt
  {
    $$ = &JoinTableExpr{LeftExpr: $1, Join: $2, RightExpr: $3, Condition: $4}
  }
| table_reference outer_join table_reference join_condition
  {
    $$ = &JoinTableExpr{LeftExpr: $1, Join: $2, RightExpr: $3, Condition: $4}
  }
| table_reference natural_join table_factor
  {
    $$ = &JoinTableExpr{LeftExpr: $1, Join: $2, RightExpr: $3}
  }

join_condition:
  ON expression
  { $$ = JoinCondition{On: $2} }
| USING '(' column_list ')'
  { $$ = JoinCondition{Using: $3} }

join_condition_opt:
%prec JOIN
  { $$ = JoinCondition{} }
| join_condition
  { $$ = $1 }

on_expression_opt:
%prec JOIN
  { $$ = JoinCondition{} }
| ON expression
  { $$ = JoinCondition{On: $2} }

as_opt:
  { $$ = struct{}{} }
| AS
  { $$ = struct{}{} }

as_opt_id:
  {
    $$ = NewTableIdent("")
  }
| table_alias
  {
    $$ = $1
  }
| AS table_alias
  {
    $$ = $2
  }

table_alias:
  table_id
| STRING
  {
    $$ = NewTableIdent(string($1))
  }

inner_join:
  JOIN
  {
    $$ = JoinStr
  }
| INNER JOIN
  {
    $$ = JoinStr
  }
| CROSS JOIN
  {
    $$ = JoinStr
  }

straight_join:
  STRAIGHT_JOIN
  {
    $$ = StraightJoinStr
  }

outer_join:
  LEFT JOIN
  {
    $$ = LeftJoinStr
  }
| LEFT OUTER JOIN
  {
    $$ = LeftJoinStr
  }
| RIGHT JOIN
  {
    $$ = RightJoinStr
  }
| RIGHT OUTER JOIN
  {
    $$ = RightJoinStr
  }

natural_join:
 NATURAL JOIN
  {
    $$ = NaturalJoinStr
  }
| NATURAL outer_join
  {
    if $2 == LeftJoinStr {
      $$ = NaturalLeftJoinStr
    } else {
      $$ = NaturalRightJoinStr
    }
  }

into_table_name:
  INTO table_name
  {
    $$ = $2
  }
| table_name
  {
    $$ = $1
  }

table_name:
  table_id
  {
    $$ = TableName{Name: $1}
  }
| table_id '.' reserved_table_id
  {
    $$ = TableName{Qualifier: $1, Name: $3}
  }

index_hint_list:
  {
    $$ = nil
  }
| USE INDEX openb column_list closeb
  {
    $$ = &IndexHints{Type: UseStr, Indexes: $4}
  }
| IGNORE INDEX openb column_list closeb
  {
    $$ = &IndexHints{Type: IgnoreStr, Indexes: $4}
  }
| FORCE INDEX openb column_list closeb
  {
    $$ = &IndexHints{Type: ForceStr, Indexes: $4}
  }

where_expression_opt:
  {
    $$ = nil
  }
| WHERE expression
  {
    $$ = $2
  }

include_columns_opt:
  {
    $$ = nil
  }
| INCLUDE '(' column_list ')'
  {
    $$ = $3
  }

expression:
  condition
  {
    $$ = $1
  }
| expression AND expression
  {
    $$ = &AndExpr{Left: $1, Right: $3}
  }
| expression OR expression
  {
    $$ = &OrExpr{Left: $1, Right: $3}
  }
| NOT expression
  {
    $$ = &NotExpr{Expr: $2}
  }
| expression IS is_suffix
  {
    $$ = &IsExpr{Operator: $3, Expr: $1}
  }
| value_expression
  {
    $$ = $1
  }
| DEFAULT default_opt
  {
    $$ = &Default{ColName: $2}
  }

default_opt:
  /* empty */
  {
    $$ = ""
  }
| openb ID closeb
  {
    $$ = string($2)
  }

boolean_value:
  TRUE
  {
    $$ = BoolVal(true)
  }
| FALSE
  {
    $$ = BoolVal(false)
  }

condition:
  value_expression compare value_expression
  {
    $$ = &ComparisonExpr{Left: $1, Operator: $2, Right: $3}
  }
| value_expression IN col_tuple
  {
    $$ = &ComparisonExpr{Left: $1, Operator: InStr, Right: $3}
  }
| value_expression NOT IN col_tuple
  {
    $$ = &ComparisonExpr{Left: $1, Operator: NotInStr, Right: $4}
  }
| value_expression LIKE value_expression like_escape_opt
  {
    $$ = &ComparisonExpr{Left: $1, Operator: LikeStr, Right: $3, Escape: $4}
  }
| value_expression NOT LIKE value_expression like_escape_opt
  {
    $$ = &ComparisonExpr{Left: $1, Operator: NotLikeStr, Right: $4, Escape: $5}
  }
| value_expression REGEXP value_expression
  {
    $$ = &ComparisonExpr{Left: $1, Operator: RegexpStr, Right: $3}
  }
| value_expression NOT REGEXP value_expression
  {
    $$ = &ComparisonExpr{Left: $1, Operator: NotRegexpStr, Right: $4}
  }
| value_expression BETWEEN value_expression AND value_expression
  {
    $$ = &RangeCond{Left: $1, Operator: BetweenStr, From: $3, To: $5}
  }
| value_expression NOT BETWEEN value_expression AND value_expression
  {
    $$ = &RangeCond{Left: $1, Operator: NotBetweenStr, From: $4, To: $6}
  }
| EXISTS subquery
  {
    $$ = &ExistsExpr{Subquery: $2}
  }

is_suffix:
  NULL
  {
    $$ = IsNullStr
  }
| NOT NULL
  {
    $$ = IsNotNullStr
  }
| TRUE
  {
    $$ = IsTrueStr
  }
| NOT TRUE
  {
    $$ = IsNotTrueStr
  }
| FALSE
  {
    $$ = IsFalseStr
  }
| NOT FALSE
  {
    $$ = IsNotFalseStr
  }

compare:
  '='
  {
    $$ = EqualStr
  }
| '<'
  {
    $$ = LessThanStr
  }
| '>'
  {
    $$ = GreaterThanStr
  }
| LE
  {
    $$ = LessEqualStr
  }
| GE
  {
    $$ = GreaterEqualStr
  }
| NE
  {
    $$ = NotEqualStr
  }
| NULL_SAFE_EQUAL
  {
    $$ = NullSafeEqualStr
  }

like_escape_opt:
  {
    $$ = nil
  }
| ESCAPE value_expression
  {
    $$ = $2
  }

col_tuple:
  row_tuple
  {
    $$ = $1
  }
| subquery
  {
    $$ = $1
  }
| LIST_ARG
  {
    $$ = ListArg($1)
  }

subquery:
  openb select_statement closeb
  {
    $$ = &Subquery{$2}
  }

expression_list:
  expression
  {
    $$ = Exprs{$1}
  }
| expression_list ',' expression
  {
    $$ = append($1, $3)
  }

value_expression:
  value
  {
    $$ = $1
  }
| boolean_value
  {
    $$ = $1
  }
| column_name
  {
    $$ = $1
  }
| new_qualifier_column_name
  {
    $$ = $1
  }
| tuple_expression
  {
    $$ = $1
  }
| subquery
  {
    $$ = $1
  }
| value_expression '&' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: BitAndStr, Right: $3}
  }
| value_expression '|' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: BitOrStr, Right: $3}
  }
| value_expression '^' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: BitXorStr, Right: $3}
  }
| value_expression '+' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: PlusStr, Right: $3}
  }
| value_expression '-' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: MinusStr, Right: $3}
  }
| value_expression '*' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: MultStr, Right: $3}
  }
| value_expression '/' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: DivStr, Right: $3}
  }
| value_expression DIV value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: IntDivStr, Right: $3}
  }
| value_expression '%' value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: ModStr, Right: $3}
  }
| value_expression MOD value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: ModStr, Right: $3}
  }
| value_expression SHIFT_LEFT value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: ShiftLeftStr, Right: $3}
  }
| value_expression SHIFT_RIGHT value_expression
  {
    $$ = &BinaryExpr{Left: $1, Operator: ShiftRightStr, Right: $3}
  }
| column_name JSON_EXTRACT_OP value
  {
    $$ = &BinaryExpr{Left: $1, Operator: JSONExtractOp, Right: $3}
  }
| column_name JSON_UNQUOTE_EXTRACT_OP value
  {
    $$ = &BinaryExpr{Left: $1, Operator: JSONUnquoteExtractOp, Right: $3}
  }
| value_expression COLLATE charset
  {
    $$ = &CollateExpr{Expr: $1, Charset: $3}
  }
| BINARY value_expression %prec UNARY
  {
    $$ = &UnaryExpr{Operator: BinaryStr, Expr: $2}
  }
| UNDERSCORE_BINARY value_expression %prec UNARY
  {
    $$ = &UnaryExpr{Operator: UBinaryStr, Expr: $2}
  }
| '+'  value_expression %prec UNARY
  {
    if num, ok := $2.(*SQLVal); ok && num.Type == IntVal {
      $$ = num
    } else {
      $$ = &UnaryExpr{Operator: UPlusStr, Expr: $2}
    }
  }
| '-'  value_expression %prec UNARY
  {
    if num, ok := $2.(*SQLVal); ok && num.Type == IntVal {
      // Handle double negative
      if num.Val[0] == '-' {
        num.Val = num.Val[1:]
        $$ = num
      } else {
        $$ = NewIntVal(append([]byte("-"), num.Val...))
      }
    } else {
      $$ = &UnaryExpr{Operator: UMinusStr, Expr: $2}
    }
  }
| '~'  value_expression
  {
    $$ = &UnaryExpr{Operator: TildaStr, Expr: $2}
  }
| '!' value_expression %prec UNARY
  {
    $$ = &UnaryExpr{Operator: BangStr, Expr: $2}
  }
| INTERVAL value_expression sql_id
  {
    // This rule prevents the usage of INTERVAL
    // as a function. If support is needed for that,
    // we'll need to revisit this. The solution
    // will be non-trivial because of grammar conflicts.
    $$ = &IntervalExpr{Expr: $2, Unit: $3.String()}
  }
| value_expression TYPECAST simple_convert_type
  {
    $$ = &ConvertExpr{Expr: $1, Type: $3}
  }
| function_call_generic
| function_call_keyword
| function_call_nonkeyword
| function_call_conflict
| variadic_opt array_constructor
  {
    $$ = $2
  }

/*
  Regular function calls without special token or syntax, guaranteed to not
  introduce side effects due to being a simple identifier
*/
function_call_generic:
  sql_id openb select_expression_list_opt closeb
  {
    $$ = &FuncExpr{Name: $1, Exprs: $3}
  }
| sql_id openb DISTINCT select_expression_list closeb
  {
    $$ = &FuncExpr{Name: $1, Distinct: true, Exprs: $4}
  }
| table_id '.' reserved_sql_id openb select_expression_list_opt closeb
  {
    $$ = &FuncExpr{Qualifier: $1, Name: $3, Exprs: $5}
  }

/*
  Function calls using reserved keywords, with dedicated grammar rules
  as a result
*/
function_call_keyword:
  LEFT openb select_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent("left"), Exprs: $3}
  }
| RIGHT openb select_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent("right"), Exprs: $3}
  }
| CONVERT openb expression ',' convert_type closeb
  {
    $$ = &ConvertExpr{Expr: $3, Type: $5}
  }
| CAST openb expression AS convert_type closeb
  {
    $$ = &ConvertExpr{Expr: $3, Type: $5}
  }
| CONVERT openb expression USING charset closeb
  {
    $$ = &ConvertUsingExpr{Expr: $3, Type: $5}
  }
| SUBSTR openb column_name ',' value_expression closeb
  {
    $$ = &SubstrExpr{Name: $3, From: $5, To: nil}
  }
| SUBSTR openb column_name ',' value_expression ',' value_expression closeb
  {
    $$ = &SubstrExpr{Name: $3, From: $5, To: $7}
  }
| SUBSTR openb column_name FROM value_expression FOR value_expression closeb
  {
    $$ = &SubstrExpr{Name: $3, From: $5, To: $7}
  }
| SUBSTRING openb column_name ',' value_expression closeb
  {
    $$ = &SubstrExpr{Name: $3, From: $5, To: nil}
  }
| SUBSTRING openb column_name ',' value_expression ',' value_expression closeb
  {
    $$ = &SubstrExpr{Name: $3, From: $5, To: $7}
  }
| SUBSTRING openb column_name FROM value_expression FOR value_expression closeb
  {
    $$ = &SubstrExpr{Name: $3, From: $5, To: $7}
  }
| MATCH openb select_expression_list closeb AGAINST openb value_expression match_option closeb
  {
  $$ = &MatchExpr{Columns: $3, Expr: $7, Option: $8}
  }
| GROUP_CONCAT openb distinct_opt select_expression_list order_by_opt separator_opt closeb
  {
    $$ = &GroupConcatExpr{Distinct: $3, Exprs: $4, OrderBy: $5, Separator: $6}
  }
| CASE expression_opt when_expression_list else_expression_opt END
  {
    $$ = &CaseExpr{Expr: $2, Whens: $3, Else: $4}
  }
| VALUES openb column_name closeb
  {
    $$ = &ValuesFuncExpr{Name: $3}
  }

/*
  Function calls using non reserved keywords but with special syntax forms.
  Dedicated grammar rules are needed because of the special syntax
*/
function_call_nonkeyword:
  CURRENT_TIMESTAMP func_datetime_precision_opt
  {
    $$ = &FuncExpr{Name:NewColIdent("current_timestamp")}
  }
| UTC_TIMESTAMP func_datetime_precision_opt
  {
    $$ = &FuncExpr{Name:NewColIdent("utc_timestamp")}
  }
| UTC_TIME func_datetime_precision_opt
  {
    $$ = &FuncExpr{Name:NewColIdent("utc_time")}
  }
| UTC_DATE func_datetime_precision_opt
  {
    $$ = &FuncExpr{Name:NewColIdent("utc_date")}
  }
  // now
| LOCALTIME func_datetime_precision_opt
  {
    $$ = &FuncExpr{Name:NewColIdent("localtime")}
  }
  // now
| LOCALTIMESTAMP func_datetime_precision_opt
  {
    $$ = &FuncExpr{Name:NewColIdent("localtimestamp")}
  }
  // curdate
| CURRENT_DATE func_datetime_precision_opt
  {
    $$ = &FuncExpr{Name:NewColIdent("current_date")}
  }
  // curtime
| CURRENT_TIME func_datetime_precision_opt
  {
    $$ = &FuncExpr{Name:NewColIdent("current_time")}
  }
| TYPECAST simple_convert_type
  {
    $$ = &ConvertExpr{Type: $2}
  }

func_datetime_precision_opt:
  /* empty */
| openb closeb

/*
  Function calls using non reserved keywords with *normal* syntax forms. Because
  the names are non-reserved, they need a dedicated rule so as not to conflict
*/
function_call_conflict:
  IF openb select_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent("if"), Exprs: $3}
  }
| DATABASE openb select_expression_list_opt closeb
  {
    $$ = &FuncExpr{Name: NewColIdent("database"), Exprs: $3}
  }
| MOD openb select_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent("mod"), Exprs: $3}
  }
| REPLACE openb select_expression_list closeb
  {
    $$ = &FuncExpr{Name: NewColIdent("replace"), Exprs: $3}
  }

match_option:
/*empty*/
  {
    $$ = ""
  }
| IN BOOLEAN MODE
  {
    $$ = BooleanModeStr
  }
| IN NATURAL LANGUAGE MODE
 {
    $$ = NaturalLanguageModeStr
 }
| IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION
 {
    $$ = NaturalLanguageModeWithQueryExpansionStr
 }
| WITH QUERY EXPANSION
 {
    $$ = QueryExpansionStr
 }

charset:
  ID
{
    $$ = string($1)
}
| STRING
{
    $$ = string($1)
}

convert_type:
  BINARY length_opt
  {
    $$ = &ConvertType{Type: string($1), Length: $2}
  }
| CHAR length_opt charset_opt
  {
    $$ = &ConvertType{Type: string($1), Length: $2, Charset: $3, Operator: CharacterSetStr}
  }
| CHAR length_opt ID
  {
    $$ = &ConvertType{Type: string($1), Length: $2, Charset: string($3)}
  }
| DATE
  {
    $$ = &ConvertType{Type: string($1)}
  }
| DATETIME length_opt
  {
    $$ = &ConvertType{Type: string($1), Length: $2}
  }
| DECIMAL decimal_length_opt
  {
    $$ = &ConvertType{Type: string($1)}
    $$.Length = $2.Length
    $$.Scale = $2.Scale
  }
| JSON
  {
    $$ = &ConvertType{Type: string($1)}
  }
| JSONB
  {
    $$ = &ConvertType{Type: string($1)}
  }
| NCHAR length_opt
  {
    $$ = &ConvertType{Type: string($1), Length: $2}
  }
| SIGNED
  {
    $$ = &ConvertType{Type: string($1)}
  }
| SIGNED INTEGER
  {
    $$ = &ConvertType{Type: string($1)}
  }
| TIME length_opt
  {
    $$ = &ConvertType{Type: string($1), Length: $2}
  }
| UNSIGNED
  {
    $$ = &ConvertType{Type: string($1)}
  }
| UNSIGNED INTEGER
  {
    $$ = &ConvertType{Type: string($1)}
  }

simple_convert_type:
  BINARY
  {
    $$ = &ConvertType{Type: string($1)}
  }
| CHARACTER VARYING
  {
    $$ = &ConvertType{Type: string($1)+" "+string($2)}
  }
| DATE
  {
    $$ = &ConvertType{Type: string($1)}
  }
| DATETIME
  {
    $$ = &ConvertType{Type: string($1)}
  }
| int_type
  {
    $$ = &ConvertType{Type: $1.Type}
  }
| bool_type
  {
    $$ = &ConvertType{Type: $1.Type}
  }
| TEXT
  {
    $$ = &ConvertType{Type: string($1)}
  }

expression_opt:
  {
    $$ = nil
  }
| expression
  {
    $$ = $1
  }

separator_opt:
  {
    $$ = string("")
  }
| SEPARATOR STRING
  {
    $$ = " separator '"+string($2)+"'"
  }

when_expression_list:
  when_expression
  {
    $$ = []*When{$1}
  }
| when_expression_list when_expression
  {
    $$ = append($1, $2)
  }

when_expression:
  WHEN expression THEN expression
  {
    $$ = &When{Cond: $2, Val: $4}
  }

else_expression_opt:
  {
    $$ = nil
  }
| ELSE expression
  {
    $$ = $2
  }

column_name:
  sql_id
  {
    $$ = &ColName{Name: $1}
  }
| table_id '.' reserved_sql_id
  {
    $$ = &ColName{Qualifier: TableName{Name: $1}, Name: $3}
  }
| table_id '.' reserved_table_id '.' reserved_sql_id
  {
    $$ = &ColName{Qualifier: TableName{Qualifier: $1, Name: $3}, Name: $5}
  }

new_qualifier_column_name:
  NEW '.' reserved_sql_id
  {
    $$ = &NewQualifierColName{Name: $3}
  }

value:
  STRING
  {
    $$ = NewStrVal($1)
  }
| HEX
  {
    $$ = NewHexVal($1)
  }
| BIT_LITERAL
  {
    $$ = NewBitVal($1)
  }
| INTEGRAL
  {
    $$ = NewIntVal($1)
  }
| FLOAT
  {
    $$ = NewFloatVal($1)
  }
| HEXNUM
  {
    $$ = NewHexNum($1)
  }
| VALUE_ARG
  {
    $$ = NewValArg($1)
  }
| NULL
  {
    $$ = &NullVal{}
  }

num_val:
  sql_id
  {
    // TODO(sougou): Deprecate this construct.
    if $1.Lowered() != "value" {
      yylex.Error("expecting value after next")
      return 1
    }
    $$ = NewIntVal([]byte("1"))
  }
| INTEGRAL VALUES
  {
    $$ = NewIntVal($1)
  }
| VALUE_ARG VALUES
  {
    $$ = NewValArg($1)
  }

group_by_opt:
  {
    $$ = nil
  }
| GROUP BY expression_list
  {
    $$ = $3
  }

having_opt:
  {
    $$ = nil
  }
| HAVING expression
  {
    $$ = $2
  }

order_by_opt:
  {
    $$ = nil
  }
| ORDER BY order_list
  {
    $$ = $3
  }

order_list:
  order
  {
    $$ = OrderBy{$1}
  }
| order_list ',' order
  {
    $$ = append($1, $3)
  }

order:
  expression asc_desc_opt
  {
    $$ = &Order{Expr: $1, Direction: $2}
  }

asc_desc_opt:
  {
    $$ = AscScr
  }
| ASC
  {
    $$ = AscScr
  }
| DESC
  {
    $$ = DescScr
  }

limit_opt:
  {
    $$ = nil
  }
| LIMIT expression
  {
    $$ = &Limit{Rowcount: $2}
  }
| LIMIT expression ',' expression
  {
    $$ = &Limit{Offset: $2, Rowcount: $4}
  }
| LIMIT expression OFFSET expression
  {
    $$ = &Limit{Offset: $4, Rowcount: $2}
  }

lock_opt:
  {
    $$ = ""
  }
| FOR UPDATE
  {
    $$ = ForUpdateStr
  }
| LOCK IN SHARE MODE
  {
    $$ = ShareModeStr
  }

// insert_data expands all combinations into a single rule.
// This avoids a shift/reduce conflict while encountering the
// following two possible constructs:
// insert into t1(a, b) (select * from t2)
// insert into t1(select * from t2)
// Because the rules are together, the parser can keep shifting
// the tokens until it disambiguates a as sql_id and select as keyword.
insert_data:
  VALUES tuple_list
  {
    $$ = &Insert{Rows: $2}
  }
| select_statement
  {
    $$ = &Insert{Rows: $1}
  }
| openb select_statement closeb
  {
    // Drop the redundant parenthesis.
    $$ = &Insert{Rows: $2}
  }
| openb ins_column_list closeb VALUES tuple_list
  {
    $$ = &Insert{Columns: $2, Rows: $5}
  }
| openb ins_column_list closeb select_statement
  {
    $$ = &Insert{Columns: $2, Rows: $4}
  }
| openb ins_column_list closeb openb select_statement closeb
  {
    // Drop the redundant parenthesis.
    $$ = &Insert{Columns: $2, Rows: $5}
  }

ins_column_list:
  sql_id
  {
    $$ = Columns{$1}
  }
| sql_id '.' sql_id
  {
    $$ = Columns{$3}
  }
| ins_column_list ',' sql_id
  {
    $$ = append($$, $3)
  }
| ins_column_list ',' sql_id '.' sql_id
  {
    $$ = append($$, $5)
  }

on_dup_opt:
  {
    $$ = nil
  }
| ON DUPLICATE KEY UPDATE update_list
  {
    $$ = $5
  }

tuple_list:
  tuple_or_empty
  {
    $$ = Values{$1}
  }
| tuple_list ',' tuple_or_empty
  {
    $$ = append($1, $3)
  }

tuple_or_empty:
  row_tuple
  {
    $$ = $1
  }
| openb closeb
  {
    $$ = ValTuple{}
  }

row_tuple:
  openb expression_list closeb
  {
    $$ = ValTuple($2)
  }

tuple_expression:
  row_tuple
  {
    if len($1) == 1 {
      $$ = &ParenExpr{$1[0]}
    } else {
      $$ = $1
    }
  }

update_list:
  update_expression
  {
    $$ = UpdateExprs{$1}
  }
| update_list ',' update_expression
  {
    $$ = append($1, $3)
  }

update_expression:
  column_name '=' expression
  {
    $$ = &UpdateExpr{Name: $1, Expr: $3}
  }

set_list:
  set_expression
  {
    $$ = SetExprs{$1}
  }
| set_list ',' set_expression
  {
    $$ = append($1, $3)
  }

set_expression:
  reserved_sql_id '=' ON
  {
    $$ = &SetExpr{Name: $1, Expr: NewStrVal([]byte("on"))}
  }
| reserved_sql_id '=' OFF
  {
    $$ = &SetExpr{Name: $1, Expr: NewStrVal([]byte("off"))}
  }
| reserved_sql_id '=' expression
  {
    $$ = &SetExpr{Name: $1, Expr: $3}
  }
// MySQL extension of triggers
| NEW '.' reserved_sql_id '=' expression
  {
    $$ = &SetExpr{Name: NewColIdent("NEW." + $3.val), Expr: $5}
  }
| charset_or_character_set charset_value collate_opt
  {
    $$ = &SetExpr{Name: NewColIdent(string($1)), Expr: $2}
  }

charset_or_character_set:
  CHARSET
| CHARACTER SET
  {
    $$ = []byte("charset")
  }
| NAMES

charset_value:
  sql_id
  {
    $$ = NewStrVal([]byte($1.String()))
  }
| STRING
  {
    $$ = NewStrVal($1)
  }
| DEFAULT
  {
    $$ = &Default{}
  }

for_from:
  FOR
| FROM

exists_opt:
  { $$ = 0 }
| IF EXISTS
  { $$ = 1 }

not_exists_opt:
  { $$ = struct{}{} }
| IF NOT EXISTS
  { $$ = struct{}{} }

ignore_opt:
  { $$ = "" }
| IGNORE
  { $$ = IgnoreStr }

non_add_drop_or_rename_operation:
  ALTER
  { $$ = struct{}{} }
| AUTO_INCREMENT
  { $$ = struct{}{} }
| CHARACTER
  { $$ = struct{}{} }
| COMMENT_KEYWORD
  { $$ = struct{}{} }
| DEFAULT
  { $$ = struct{}{} }
| ORDER
  { $$ = struct{}{} }
| CONVERT
  { $$ = struct{}{} }
| PARTITION
  { $$ = struct{}{} }
| UNUSED
  { $$ = struct{}{} }
| ID
  { $$ = struct{}{} }

to_opt:
  { $$ = struct{}{} }
| TO
  { $$ = struct{}{} }
| AS
  { $$ = struct{}{} }

index_opt:
  INDEX
  { $$ = struct{}{} }
| KEY
  { $$ = struct{}{} }

sql_id:
  ID
  {
    $$ = NewColIdent(string($1))
  }
| non_reserved_keyword
  {
    $$ = NewColIdent(string($1))
  }

reserved_sql_id:
  sql_id
| reserved_keyword
  {
    $$ = NewColIdent(string($1))
  }

table_id:
  ID
  {
    $$ = NewTableIdent(string($1))
  }
| non_reserved_keyword
  {
    $$ = NewTableIdent(string($1))
  }

reserved_table_id:
  table_id
| reserved_keyword
  {
    $$ = NewTableIdent(string($1))
  }

deferrable_opt:
  /* empty */
  {
    $$ = BoolVal(false)
  }
| DEFERRABLE
  {
    $$ = BoolVal(true)
  }
| NOT DEFERRABLE
  {
    $$ = BoolVal(false)
  }

initially_deferred_opt:
  /* empty */
  {
    $$ = BoolVal(false)
  }
| INITIALLY DEFERRED
  {
    $$ = BoolVal(true)
  }
| INITIALLY IMMEDIATE
  {
    $$ = BoolVal(false)
  }

variadic_opt:
  /* empty */
  {
    $$ = BoolVal(false)
  }
| VARIADIC
  {
    $$ =BoolVal(true)
  }

/* For PostgreSQL. https://www.postgresql.org/docs/14/sql-expressions.html#SQL-SYNTAX-ARRAY-CONSTRUCTORS */
array_constructor:
  ARRAY '[' array_element_list ']'
  {
    $$ = &ArrayConstructor{Elements: $3}
  }

/* For PostgreSQL */
array_element_list:
  array_element
  {
    $$ = ArrayElements{$1}
  }
| array_element_list ',' array_element
  {
    $$ = append($$, $3)
  }

/* For PostgreSQL */
array_element:
  STRING character_cast_opt
  {
    $$ = NewStrVal($1)
  }

/*
  These are not all necessarily reserved in MySQL, but some are.

  These are more importantly reserved because they may conflict with our grammar.
  If you want to move one that is not reserved in MySQL (i.e. ESCAPE) to the
  non_reserved_keywords, you'll need to deal with any conflicts.

  Sorted alphabetically
*/
reserved_keyword:
  ADD
| AFTER
| ALWAYS
| AND
| AS
| ASC
| AUTO_INCREMENT
| AUTOINCREMENT
| BEFORE
| BETWEEN
| BINARY
| BY
| CASE
| CLOSE
| CLUSTERED
| NONCLUSTERED
| COLLATE
| CONVERT
| CREATE
| CROSS
| CURRENT_DATE
| CURRENT_TIME
| CURRENT_TIMESTAMP
| CURSOR
| SUBSTR
| SUBSTRING
| DATABASE
| DATABASES
| DEALLOCATE
| DECLARE
| DEFAULT
| DELETE
| DESC
| DESCRIBE
| DISTINCT
| DIV
| DROP
| EACH
| ELSE
| END
| ESCAPE
| EXISTS
| EXPLAIN
| FALSE
| FETCH
| FIRST
| FOR
| FORCE
| FOREIGN
| FROM
| GENERATED
| GROUP
| HAVING
| HOLDLOCK
| IDENTITY
| IF
| IGNORE
| IN
| INCLUDE
| INDEX
| INNER
| INSERT
| INTERVAL
| INTO
| IS
| JOIN
| KEY
| LAST
| LEFT
| LIKE
| LIMIT
| LOCALTIME
| LOCALTIMESTAMP
| LOCK
| MATCH
| MAXVALUE
| MOD
| NATURAL
| NEXT // next should be doable as non-reserved, but is not due to the special `select next num_val` query that vitess supports
| NOLOCK
| NOT
| NOWAIT
| NULL
| ON
| ONLY
| OPEN
| OR
| ORDER
| OUTER
| PAGLOCK
| POLICY
| PRIOR
| REGEXP
| RENAME
| REPLACE
| RIGHT
| ROW
| ROWLOCK
| SCHEMA
| SCROLL
| SELECT
| SEPARATOR
| SET
| SHOW
| STRAIGHT_JOIN
| TABLE
| TABLES
| THEN
| TO
| TRUE
| UNION
| UNIQUE
| UPDATE
| USE
| USING
| UTC_DATE
| UTC_TIME
| UTC_TIMESTAMP
| VALUES
| WHEN
| WHERE
| WHILE
| WITH
| OFF

/*
  These are non-reserved Vitess, because they don't cause conflicts in the grammar.
  Some of them may be reserved in MySQL. The good news is we backtick quote them
  when we rewrite the query, so no issue should arise.

  Sorted alphabetically
*/
non_reserved_keyword:
  ACTION
| AGAINST
| ALL
| BEGIN
| BIGINT
| BIGSERIAL
| BIT
| BLOB
| BOOL
| BOOLEAN
| CASCADE
| CHAR
| CHARACTER
| CHARSET
| CHECK
| COMMENT_KEYWORD
| COMMIT
| COMMITTED
| CONSTRAINT
| CURRENT_USER
| DATE
| DATETIME
| DATETIME2
| DATETIMEOFFSET
| DECIMAL
| DOUBLE
| DUPLICATE
| ENUM
| EXPANSION
| FLOAT_TYPE
| FULLTEXT
| GEOMETRY
| GEOMETRYCOLLECTION
| GETDATE
| GLOBAL
| INHERIT
| INT
| INTEGER
| ISOLATION
| JSON
| KEYS
| KEY_BLOCK_SIZE
| LANGUAGE
| LAST_INSERT_ID
| LESS
| LEVEL
| LINESTRING
| LONGBLOB
| LONGTEXT
| MEDIUMBLOB
| MEDIUMINT
| MEDIUMTEXT
| MODE
| MONEY
| MULTILINESTRING
| MULTIPOINT
| MULTIPOLYGON
| NAMES
| NCHAR
| NO
| NOW
| NTEXT
| NUMERIC
| NVARCHAR
| OFFSET
| OPTIMIZE
| PARTITION
| POINT
| POLYGON
| PRECISION
| PERMISSIVE
| PRIMARY
| PROCEDURE
| QUERY
| READ
| REAL
| REORGANIZE
| RESTRICTIVE
| REPAIR
| REPEATABLE
| REPLICATION
| RESTRICT
| ROLLBACK
| SESSION
| SERIAL
| SERIALIZABLE
| SHARE
| SIGNED
| SMALLDATETIME
| SMALLINT
| SMALLMONEY
| SMALLSERIAL
| SPATIAL
| START
| STATUS
| TEXT
| THAN
| TIME
| TIMESTAMP
| TINYBLOB
| TINYINT
| TINYTEXT
| TRANSACTION
| TRIGGER
| TRUNCATE
| UNCOMMITTED
| UNSIGNED
| UNUSED
| UUID
| VARBINARY
| VARCHAR
| VARYING
| VARIABLES
| VIEW
| VINDEX
| VINDEXES
| VITESS_KEYSPACES
| VITESS_SHARDS
| VITESS_TABLETS
| VSCHEMA_TABLES
| WITHOUT
| WRITE
| YEAR
| ZEROFILL
| ZONE
| PAD_INDEX
| FILLFACTOR
| IGNORE_DUP_KEY
| STATISTICS_NORECOMPUTE
| STATISTICS_INCREMENTAL
| ALLOW_ROW_LOCKS
| ALLOW_PAGE_LOCKS

openb:
  '('
  {
    if incNesting(yylex) {
      yylex.Error("max nesting level reached")
      return 1
    }
  }

closeb:
  ')'
  {
    decNesting(yylex)
  }

force_eof:
{
  forceEOF(yylex)
}

ddl_force_eof:
  {
    forceEOF(yylex)
  }
| openb
  {
    forceEOF(yylex)
  }
| reserved_sql_id
  {
    forceEOF(yylex)
  }
