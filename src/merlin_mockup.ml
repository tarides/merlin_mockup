exception Closing

(** [run] = New_merlin.run ou New_commands.run *)
let run =
  let req_count = ref 0 in
  fun config _server_socket client_socket ->
    incr req_count;

    (* Respond to the client exactly once: either with the first partial result,
       or with the complete result when no partial is produced. [respond] closes
       the socket, so a second send would raise EBADF. *)
    let answered = ref false in
    let answer (items : Motyper.typedtree) =
      if not !answered then begin
        answered := true;
        Server.respond client_socket
          (Moparser.to_string (ref (List.rev !items)))
      end
    in

    match Mopipeline.get config with
    | None -> failwith "No pipeline found (main)"
    | Some result ->
        Utils.log 0 "Request nb %i - Beginning analysis" !req_count;
        (* Moquery_commands.analysis hermes result config; *)
        answer result.Mopipeline.result.typedtree
    | effect Mopipeline.Partial partial, k ->
        Utils.log 0 "Request nb %i - Partial result, waiting for completion"
          !req_count;
        answer partial.Mopipeline.result.typedtree;
        (* Finish typing the rest (e.g. to warm a cache); the completed result
           must not trigger a second response. *)
        Effect.Deep.continue k ()

(** [main] = Ocaml_merlin_server.main *)
let main () =
  Utils.log 0 "Spawning typer";

  begin try
    let server = Server.build_server () in

    let rec loop client req =
      match req with
      | Server.Close -> raise Closing
      | Server.Config config ->
          run config server client;
          let new_client, new_req = Server.listen server in
          loop new_client new_req
      (* | New_request (client, req) -> loop client req) *)
    in
    let client, req = Server.listen server in
    let _ = loop client req in
    Server.close server
  with
  | Closing -> Utils.log 0 "Closing requested received."
  | exn ->
      Utils.log 0 "Server thread exiting with exception: %s\n%s"
        (Printexc.to_string exn)
        (Printexc.get_backtrace ())
  end;
  Utils.log 0 "The end"

let () = main ()
