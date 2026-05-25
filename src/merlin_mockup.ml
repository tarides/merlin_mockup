exception Closing

type response = Response of string
(* | New_request of Unix.file_descr * Server.request *)

(** [run] = New_merlin.run ou New_commands.run *)
let run =
  let req_count = ref 0 in
  fun config _server_socket ->
    incr req_count;

    let pipeline = Mopipeline.get config in
    match pipeline with
    | None -> failwith "No pipeline found (main)"
    | Some result ->
        Utils.log 0 "Request nb %i - Beginning analysis" !req_count;
        (* Moquery_commands.analysis hermes result config; *)
        let items = result.Mopipeline.result.typedtree in
        Response (Moparser.to_string (ref (List.rev !items)))

(** [main] = Ocaml_merlin_server.main *)
let main () =
  Utils.log 0 "Spawning typer";

  begin try
    let server = Server.build_server () in

    let rec loop client req =
      match req with
      | Server.Close -> raise Closing
      | Server.Config config -> (
          match run config server with
          | Response response ->
              Server.respond client response;
              let new_client, new_req = Server.listen server in
              loop new_client new_req)
      (* | New_request (client, req) -> loop client req) *)
    in
    let client, req = Server.listen server in
    let _ = loop client req in
    Server.close server
  with
  | Closing -> Utils.log 0 "Closing requested received."
  | _ -> Utils.log 0 "Server thread exiting with exception"
  end;
  Utils.log 0 "The end"

let () = main ()
