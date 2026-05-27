type parsedtree = (string * Moparser.expr) list
type typedtree = (string * int) list ref
type env = (string * int) list
type result = { config : Moconfig.t; typedtree : typedtree }
type partial = { result : result; env : env; rparsedtree : parsedtree }
type res = Complete of result | Partial of partial

val run : Moconfig.t -> ?partial:partial -> parsedtree -> res
