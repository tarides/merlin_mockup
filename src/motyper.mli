type parsedtree = (string * Moparser.expr) list
type typedtree = (string * int) list ref
type env = (string * int) list

type result =
  | Complete of { config : Moconfig.t; typedtree : typedtree }
  | Partial of {
      config : Moconfig.t;
      typedtree : typedtree;
      env : env;
      rparsedtree : parsedtree;
    }

val run : Moconfig.t -> ?partial:'a -> parsedtree -> result
