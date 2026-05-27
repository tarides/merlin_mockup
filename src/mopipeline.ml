open! Effect
open! Effect.Deep

type t = {
  source : string;
  parsedtree : Motyper.parsedtree;
  result : Motyper.result;
}

type _ Effect.t += Partial : t -> unit Effect.t

(* let process config =
  let parsedtree = Moparser.parse config.Moconfig.source in
  let rec loop ?partial () =
    match Motyper.run config ?partial parsedtree with
    | Motyper.Complete result ->
        Some { source = config.source; parsedtree; result }
    | Motyper.Partial { config; typedtree; env; rparsedtree } ->
        perform
          (Partial
             {
               source = config.source;
               parsedtree = rparsedtree;
               result = { config; typedtree };
             });
        loop ~partial:{ config; typedtree; env; rparsedtree } ()
  in
  loop () *)

let process config =
  let parsedtree = Moparser.parse config.Moconfig.source in
  match Motyper.run config parsedtree with
  | Motyper.Complete result ->
      Some { source = config.source; parsedtree; result }
  | Motyper.Partial ({ result; rparsedtree; _ } as partial) -> (
      perform (Partial { source = config.source; parsedtree; result });
      match
        Motyper.run
          { source = config.source; completion = All }
          ?partial:(Some partial) rparsedtree
      with
      | Motyper.Complete result ->
          Some { source = config.source; parsedtree; result }
      | Motyper.Partial _ -> None)

let get config = process config
