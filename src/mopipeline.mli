type t = {
  source : string;
  parsedtree : Motyper.parsedtree;
  result : Motyper.result;
}

type _ Effect.t += Partial : t -> unit Effect.t

val get : Moconfig.t -> t option
(* val get : Moconfig.t -> Motyper.msg Hermes.t -> t option *)
(* val domain_typer : Motyper.msg Hermes.t -> unit *)
