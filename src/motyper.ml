(* open Effect
open Effect.Deep *)
open Moconfig

type parsedtree = (string * Moparser.expr) list
type typedtree = (string * int) list ref

(* In mtyper.ml, type_structure, type_implementation and run returns different types*)
type env = (string * int) list

let res : typedtree = ref []

type result =
  | Complete of { config : Moconfig.t; typedtree : typedtree }
  | Partial of {
      config : Moconfig.t;
      typedtree : typedtree;
      env : env;
      rparsedtree : parsedtree;
    }

let type_structure ~until (env : env) parsedtree =
  let rec loop env count parsedtree =
    (* Utils.log 1 "Typing defs %d / %d" count (List.length parsedtree); *)
    match parsedtree with
    | def :: rparsedtree ->
        begin try
          let v, e = Moparser.eval_item env def in
          res := (v, e) :: !res;
          Utils.stupid_work ();
          if count = until then (res, env, rparsedtree)
          else loop ((v, e) :: env) (count + 1) rparsedtree
        with exn -> raise exn
        end
    | [] -> (res, env, [])
  in
  loop env 0 parsedtree

let type_implementation config parsedtree =
  match config.completion with
  | All -> type_structure ~until:max_int [] parsedtree
  | Part n -> type_structure ~until:n [] parsedtree

let run config ?partial parsedtree =
  (* Reset "typer" state *)
  let typedtree, env, rparsedtree =
    match partial with
    | None ->
        res := [];
        type_implementation config parsedtree
    | Some _ -> failwith "todo"
  in
  match (config.completion, rparsedtree) with
  | _, [] -> Complete { config; typedtree }
  | Part _, _ -> Partial { config; typedtree; env; rparsedtree }
  | All, _ -> failwith "Unexpected remaining parsedtree with completion = All"
