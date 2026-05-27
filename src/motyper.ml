(* open Effect
open Effect.Deep *)
open Moconfig

type parsedtree = (string * Moparser.expr) list
type typedtree = (string * int) list ref
type result = { config : Moconfig.t; typedtree : typedtree }

(* In mtyper.ml, type_structure, type_implementation and run returns different types*)
type env = (string * int) list

let res : typedtree = ref []

let type_structure (env : env) parsedtree =
  let rec loop env count parsedtree : typedtree =
    (* Utils.log 1 "Typing defs %d / %d" count (List.length parsedtree); *)
    match parsedtree with
    | def :: rparsedtree ->
        begin try
          let v, e = Moparser.eval_item env def in
          res := (v, e) :: !res;
          Utils.stupid_work ();
          loop ((v, e) :: env) (count + 1) rparsedtree
        with exn -> raise exn
        end
    | [] -> res
  in
  loop env 0 parsedtree

let type_implementation config parsedtree =
  match config.completion with
  | All -> type_structure [] parsedtree
  | Part _ -> type_structure [] parsedtree

let run config parsedtree =
  (* Reset "typer" state *)
  res := [];
  let typedtree = type_implementation config parsedtree in
  { config; typedtree }
