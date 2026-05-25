(* open Effect
open Effect.Deep *)
open Moconfig

type parsedtree = (string * Moparser.expr) list
type typedtree = (string * int) list ref
type result = { config : Moconfig.t; typedtree : typedtree }

exception Cancel_or_closing
exception Exception_after_partial of exn

type msg =
  | Msg of [ `Close | `Cancel | `Exn of exn ]
  | Config of Moconfig.t
  | Partial of result

(* In mtyper.ml, type_structure, type_implementation and run returns different types*)
type env = (string * int) list

let res : typedtree = ref []

let type_structure env parsedtree =
  let rec loop : env -> parsedtree -> typedtree =
   fun env ldefs ->
    (* Utils.log 1 "Typing defs %d / %d" count (List.length parsedtree); *)
    let typer_state =
      match ldefs with
      | def :: rest ->
          begin try
            let v, e = Moparser.eval_item env def in
            res := (v, e) :: !res;
            `Rest (rest, (v, e))
          with exn -> `Exn exn
          end
      | [] -> `Finish
    in
    match typer_state with
    | `Exn exn -> raise exn
    | `Finish -> res
    | `Rest (rest, (v, e)) ->
        Utils.stupid_work ();
        loop ((v, e) :: env) rest
  in
  loop env parsedtree

let type_implementation config parsedtree =
  match config.completion with
  | All -> type_structure [] parsedtree
  | Part _ -> type_structure [] parsedtree

let run config parsedtree =
  (* Reset "typer" state *)
  res := [];
  let typedtree = type_implementation config parsedtree in
  { config; typedtree }
