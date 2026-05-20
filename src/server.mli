type req = Config of Moconfig.t | Close
type request = Request of req | Bad_request
type t
type client

val build_server : unit -> t
val listen : t -> client * req

val try_listen : t -> (client * req) option
(** Non-blocking poll: [Some (client, req)] if a request is already pending,
    [None] otherwise. Returns immediately in both cases. *)

val respond : client -> string -> unit
val close : t -> unit
