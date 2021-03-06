module Json =

(* A generic lens for Json files                                           *)
(* Based on the following grammar from http://www.json.org/                *)
(* Object ::= '{'Members ? '}'                                             *)
(* Members ::= Pair+                                                       *)
(* Pair ::= String ':' Value                                               *)
(* Array ::= '[' Elements ']'                                              *)
(* Elements ::= Value ( "," Value )*                                       *)
(* Value ::= String | Number | Object | Array | "true" | "false" | "null"  *)
(* String ::= "\"" Char* "\""                                              *)
(* Number ::= /-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?/                      *)


let ws = del /[ \t\n]*/ ""
let comment = Util.empty_c_style | Util.comment_c_style | Util.comment_multiline
let comments = comment* . Sep.opt_space

let comma = Util.del_str "," . comments
let colon = Util.del_str ":" . comments
let lbrace = Util.del_str "{" . comments
let rbrace = Util.del_str "}"
let lbrack = Util.del_str "[" . comments
let rbrack = Util.del_str "]"

let str_store = Quote.dquote . store /[^"]*/ . Quote.dquote  (* " Emacs, relax *)

let number = [ label "number" . store /-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?/
             . comments ]
let str = [ label "string" . str_store . comments ]

let const (r:regexp) = [ label "const" . store r . comments ]

let fix_value (value:lens) =
     let array = [ label "array" . lbrack
               . ( ( Build.opt_list value comma . rbrack . comments )
                   | (rbrack . ws) ) ]
  in let pair = [ label "entry" . str_store . ws . colon . value ]
  in let obj = [ label "dict" . lbrace
             . ( ( Build.opt_list pair comma. rbrace . comments )
                 | (rbrace . ws ) ) ]
  in (str | number | obj | array | const /true|false|null/)

(* Process arbitrarily deeply nested JSON objects *)
let rec rlns = fix_value rlns

let lns = comments . rlns
