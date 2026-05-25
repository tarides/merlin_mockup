type parsedtree = (string * Moparser.expr) list
type typedtree = (string * int) list ref
type result = { config : Moconfig.t; typedtree : typedtree }

exception Cancel_or_closing
exception Exception_after_partial of exn

type msg =
  | Msg of [ `Cancel | `Close | `Exn of exn ]
  | Config of Moconfig.t
  | Partial of result

val run : Moconfig.t -> parsedtree -> result
