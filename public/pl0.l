/* lexical grammar */
%{
var reserved_words ={ PROCEDURE : 'PROCEDURE', CALL : 'CALL', CONST : 'CONST', VAR : 'VAR', BEGIN : 'BEGIN', END : 'END', WHILE : 'WHILE', DO : 'DO', ODD : 'ODD', IF : 'IF', THEN : 'THEN', ELSE : 'ELSE' }

function idORrw(x) {
  return (x.toUpperCase() in reserved_words)? x.toUpperCase() : 'ID'
}

%}
%%

\s+|\#.*                         /* skip whitespace and comments */
[;]                              return 'PUNTOCOMA'
\.                               return 'PUNTO'
[,]                              return 'COMA'
('=='|'!='|'<='|'<'|'>='|'>')    return 'COMPARISON'
\b\d+("."\d*)?([eE][-+]?\d+)?\b  return 'NUMBER'
\b[A-Za-z_]\w*\b                 return idORrw(yytext)
[-*/+^!%=();]                    return yytext;
<<EOF>>                          return 'EOF'
.                                return 'INVALID'