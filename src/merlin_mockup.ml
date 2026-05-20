exception Closing

type response = Response of string
(* | New_request of Unix.file_descr * Server.request *)

(** [run] = New_merlin.run ou New_commands.run *)
let run =
  let req_count = ref 0 in
  fun config hermes ->
    Hermes.send_and_wait hermes (Motyper.Msg `Cancel);
    incr req_count;
    let result = Mopipeline.get config hermes in
    Utils.log 0 "Request nb %i - Beginning analysis" !req_count;
    Option.iter (fun r -> Moquery_commands.analysis hermes r config) result;
    match result with
    | None -> failwith "No pipeline found (main)"
    | Some result ->
        let items = result.Mopipeline.result.typedtree in
        Response (Moparser.to_string (ref (List.rev !items)))

(** [main] = Ocaml_merlin_server.main *)
let main () =
  let hermes = Hermes.create () in
  Utils.log 0 "Spawning typer";
  let domain_typer = Domain.spawn (fun () -> Mopipeline.domain_typer hermes) in
  begin try
    let socket = Server.build_server () in

    let rec loop client req =
      match req with
      | Server.Close -> raise Closing
      | Server.Config config -> (
          match run config hermes with
          | Response response ->
              Server.respond client response;
              let new_client, new_req = Server.listen socket in
              loop new_client new_req)
      (* | New_request (client, req) -> loop client req) *)
    in
    let client, req = Server.listen socket in
    let _ = loop client req in
    Unix.close socket;
    Domain.join domain_typer
  with
  | Closing ->
      Utils.log 0 "Closing requested received.";
      Hermes.send_and_wait hermes (Motyper.Msg `Close)
  | _ ->
      Utils.log 0 "Server thread exiting with exception";
      Hermes.send_and_wait hermes (Motyper.Msg `Close)
  end;
  Utils.log 0 "The end"

let () = main ()
