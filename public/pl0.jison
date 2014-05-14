/* description: Parses end executes mathematical expressions. */

%{
  
  var symbolTables = [{name: "RAIZ", father: null, vars: {}}]; 
  var scope = 0;
  var symbolTable = symbolTables[scope];

  function getScope() {
    return scope;
  }

  function getFormerScope() {
    scope--;
    symbolTable = symbolTables[scope];
  }

  function makeNewScope(id) {
    scope++;
    symbolTable.vars[id].symbolTable = symbolTables[scope] =  { name: id, father: symbolTable, vars: {} };
    symbolTable = symbolTables[scope];
    return symbolTable;
  }

  function findSymbol(x) {
    var f;
    var s = scope;
    do {
      f = symbolTables[s].vars[x];
      s--;
    } while (s >= 0 && !f);
    s++;
    return [f, s];
  }

%}

%token NUMBER ID EOF PROCEDURE CALL CONST VAR BEGIN END WHILE DO ODD IF THEN ELSE
/* operator associations and precedence */

%right THEN ELSE
%right '='
%left '+' '-'
%left '*' '/'
%left UMINUS

%start PROGRAMA

%% /* language grammar */
PROGRAMA
    : LIMPIAR BLOQUE PUNTO EOF
    {
      return $2;
    }
    ;

LIMPIAR
    : 
    {
      symbolTables = [{name: "RAIZ", father: null, vars: {}}]; 
      scope = 0;
      symbolTable = symbolTables[scope]; 
    }
    ;
    
BLOQUE
    : CONSTANTES VARIABLES FUNCIONES STATEMENT
    {
        $$ = [];
        
        if($1) $$ = $$.concat($1);
        if($2) $$ = $$.concat($2);
        if($3) $$ = $$.concat($3);
        
        if($$.length > 0) $$ = [$$];
        
        if($4) $$ = $$.concat($4);
    }
  ;

  CONSTANTES
      : CONST ID '=' NUMBER OTRA_CONSTANTE PUNTOCOMA
      {
          if (symbolTable.vars[$ID])
            throw new Error ("Constant "+$ID+" defined twice")

          symbolTable.vars[$ID] = { type: $1, value: $4 }

          $$ = [{ type: $1, id: $2, value: $4 }];
          if($5) $$ = $$.concat($5);
        }
      | {  
          $$ = [];
        }
      ;

  OTRA_CONSTANTE
      : COMA ID '=' NUMBER OTRA_CONSTANTE
      {
          if (symbolTable.vars[$ID])
            throw new Error ("Constant "+$ID+" defined twice")

          symbolTable.vars[$ID] = { type: $1, value: $4 }

          $$ = [{ type: "CONST", id: $2, value: $4 }];
          if($5) $$ = $$.concat($5);
        }
      | {  
          $$ = [];
        }
      ;

  VARIABLES
      : VAR ID OTRA_VARIABLE PUNTOCOMA
      {
        if (symbolTable.vars[$ID]) 
          throw new Error("Var "+$ID+" defined twice");
        
        symbolTable.vars[$ID] = { type: $1, value: "" /* VACIO */ }

        $$ = [{ type: $1, value: $2 , declared_in: "RAIZ"}];
        if($3) $$ = $$.concat($3);
      }
    | {  
          $$ = [];
        }
    ;

  OTRA_VARIABLE
      : COMA ID OTRA_VARIABLE
        {
          if (symbolTable.vars[$ID]) 
            throw new Error("Var "+$ID+" defined twice");
        
          symbolTable.vars[$ID] = { type: $1, value: "" /* VACIO */ }

          $$ = [{ type: "VAR", value: $2, declared_in: "RAIZ" }];
          if($3) $$ = $$.concat($3);
        }
      | {  
          $$ = [];
        }
      ;


  FUNCIONES
      : PROCEDURE NOMBRE_FUNCION PUNTOCOMA BLOQUE PUNTOCOMA FUNCIONES
        {
          $$ = [{type: $1, id: $2.nombreFuncion, parameters: $2.parametros, block: $4 }];
          getFormerScope();

          if($6) $$ = $$.concat($6);
        }
    | {  
          $$ = [];
        }
    ;

  NOMBRE_FUNCION
    : ID PARAMETROS
      {
        if (symbolTable.vars[$ID]) 
          throw new Error("Function "+$ID+" defined twice");
        symbolTable.vars[$ID] = { type: "PROCEDURE", name: $ID, value: $2.length}; 

        makeNewScope($ID);
        
        $2.forEach(function(p) {
          if (symbolTable.vars[p.value]) 
            throw new Error("This ID: " + p.value + " is already defined");
            
          symbolTable.vars[p.value] = { type: "PARAM", value: "" };
        });


        $$ = {nombreFuncion: $1, parametros: $2};
      }
    ;

  PARAMETROS
      : '(' VAR ID OTROS_PARAMETROS ')'
        {
          if (symbolTable.vars[$ID]) 
            throw new Error("Parameter " +$ID+ " is already defined");
            
          symbolTable.vars[$ID] = { type: "PARAM", value: "" };

          $$ = [{type: 'ID', value: $3}].concat($4);
        }
      | '(' ')'
        {
          $$ = [];
        }
      | {  
          $$ = [];
        }
      ;

  OTROS_PARAMETROS
      : COMA VAR ID OTROS_PARAMETROS
        {
          if (symbolTable.vars[$ID]) 
            throw new Error("Parameter " +$ID+ " is already defined");
            
          symbolTable.vars[$ID] = { type: "PARAM", value: "" };
          $$ = [{type: 'ID', value: $3}].concat($4);
        }
      | {  
          $$ = [];
        }
      ;

STATEMENT
    : ID '=' EXPRESSION
      {
        var symbol = findSymbol($ID);
        var f = symbol[0];
        var s = symbol[1];

        if (f && f.type === "VAR") { 
          $$ = {type: $2, left: {id: $1, declared_in: symbolTables[s].name }, right: $3};
        }
        else if (f && f.type === "PARAM") { //Parametro 
          $$ = {type: $2, left: {id: $1, declared_in: symbolTables[s].name }, right: $3, declared_in: symbolTables[s].name};
        }
        else { 
           throw new Error("Symbol "+$ID+" not declared, or cannot be modified");
        }
      }

  | CALL ID PARAMETROS_CALL
    {
      var symbol = findSymbol($ID);
      var f = symbol[0];
      var s = symbol[1];

      if (f && f.type === "PROCEDURE" && f.value == $3.length) { 
         $$ = {type: $1, id: $2, arguments: $3};
      }
      else if(f && f.type == "PROCEDURE"){
        throw new Error("Number of arguments incorrect");
      }
      else { 
         throw new Error("Symbol "+$ID+" not declared as a Procedure");
      }

    }
  | BEGIN STATEMENT OTRO_STATEMENT END
    {
      $$ = {type: $1, value: [$2].concat($3)};
    }
  | IF CONDITION THEN STATEMENT
    {
      $$ = {type: $1, condition: $2, statement: $4};
    }
  | IF CONDITION THEN STATEMENT ELSE STATEMENT
    {
      $$ = {type: "IFELSE", condition: $2, statement_true: $4, statement_false: $6};
    }
  | WHILE CONDITION DO STATEMENT
    {
      $$ = {type: $1, condition: $2, statement: $4};
    }
  | {  
      $$ = [];
    }
  ;

  PARAMETROS_CALL
      : '(' ID OTROS_PARAMETROS_CALL ')'
        {
          var symbol = findSymbol($ID);
          var f = symbol[0];
          var s = symbol[1];

          if(f) {
            $$ = [{type: 'ID', value: $2}].concat($3);
          }
          else { 
             throw new Error($ID+" has not been declared yet");
          }
        }
      | '(' NUMBER OTROS_PARAMETROS_CALL ')'
        {
          $$ = [{type: 'NUMBER', value: $2}].concat($3);
        }
      | '(' ')'
        {
          $$ = [];
        }
      | {  
          $$ = [];
        }
      ;

  OTROS_PARAMETROS_CALL
      : COMA ID OTROS_PARAMETROS_CALL
        {
          var symbol = findSymbol($ID);
          var f = symbol[0];
          var s = symbol[1];

          if(f) {
            $$ = [{type: 'ID', value: $2}].concat($3);
          }
          else { 
             throw new Error($ID+" has not been declared yet");
          }
        }
      | COMA NUMBER OTROS_PARAMETROS_CALL
        {
          $$ = [{type: 'NUMBER', value: $2}].concat($3);
        }
      | {  
          $$ = [];
        }
      ;

  OTRO_STATEMENT
      : PUNTOCOMA STATEMENT OTRO_STATEMENT
      {
        $$ = [];

        if($2) $$ = $$.concat($2)
            
        if($3) $$ = $$.concat($3)
    }
    | {  
          $$ = [];
        }
    ;

CONDITION
    : ODD EXPRESSION
    {
      $$ = {type: $1, value: $2};
    }
  | EXPRESSION COMPARISON EXPRESSION
    {
      $$ = {type: $2, left: $1, right: $3};
    }
  ;

EXPRESSION
    : EXPRESSION '+' EXPRESSION
    {
      $$ = $1+$3;
    }
  | EXPRESSION '-' EXPRESSION
    {
      $$ = $1-$3;
    }
  | EXPRESSION '*' EXPRESSION
    {
      $$ = $1*$3;
    }
  | EXPRESSION '/' EXPRESSION
    {
      if($3 == 0){throw new Error ("Cannot divide by zero")}
      $$ = $1/$3;
    }
  | '-' EXPRESSION %prec UMINUS
    {
      $$ = -$2;
    }
  | '(' EXPRESSION ')'
    {
      $$ = $2;
    }
  | ID
    {
        var symbol = findSymbol($ID);
        var f = symbol[0];
        var s = symbol[1];

        if (f)
          $$ = { id: $1, declared_in: symbolTables[s].name };
        else
          throw new Error($ID+" has not been declared yet");
    }
  | NUMBER
    {
      $$ = Number(yytext);
    }
  ;