module Unix = UnixLabels

type req = Config of Moconfig.t | Close
type request = Request of req | Bad_request
type t = Unix.file_descr
type client = Unix.file_descr

let log fmt = Utils.log 0 ("Server : " ^^ fmt)

let parse_request req =
  match String.split_on_char '\n' req with
  | [ source; "all" ] -> Request (Config { Moconfig.source; completion = All })
  | [ _; "close" ] -> Request Close
  | [ source; compl ] ->
      begin match Scanf.sscanf_opt compl "part %i" Fun.id with
      | None -> Bad_request
      | Some n -> Request (Config { Moconfig.source; completion = Part n })
      end
  | _ -> Bad_request

let read_request socket =
  let buf = Bytes.create 1000 in
  let read = Unix.recv socket ~buf ~pos:0 ~len:(Bytes.length buf) ~mode:[] in
  let req = Bytes.sub buf 0 read |> String.of_bytes in
  log "IO read request %S" req;
  req

let respond (socket : client) resp =
  Unix.send socket ~buf:(Bytes.of_string resp) ~pos:0 ~len:(String.length resp)
    ~mode:[]
  |> ignore;
  log "IO: write response %S" resp;
  Unix.close socket

let build_server () : t =
  let socket =
    Unix.socket ~cloexec:true ~domain:PF_INET ~kind:SOCK_STREAM ~protocol:0
  in
  Unix.setsockopt socket SO_REUSEADDR true;
  Unix.setsockopt socket SO_REUSEPORT true;
  let addr = Unix.(ADDR_INET (inet_addr_loopback, 8453)) in
  Unix.bind socket ~addr;
  Unix.listen socket ~max:20;
  log "server socket is setup";
  socket

let rec listen (socket : t) : client * req =
  let client, _client_addr = Unix.accept socket in
  match read_request client |> parse_request with
  | Bad_request ->
      log "malformed response";
      listen socket
  | Request req -> (client, req)

(* Non-blocking variant of [listen]: returns [None] at once if no connection is
   pending, otherwise [Some (client, req)]. A zero timeout makes [select] poll
   rather than wait. *)
let rec try_listen (socket : t) : (client * req) option =
  let readable, _, _ =
    Unix.select ~read:[ socket ] ~write:[] ~except:[] ~timeout:0.
  in
  if readable = [] then None
  else begin
    let client, _client_addr = Unix.accept socket in
    match read_request client |> parse_request with
    | Bad_request ->
        log "malformed request";
        try_listen socket
    | Request req -> Some (client, req)
  end

let close (socket : t) = Unix.close socket
