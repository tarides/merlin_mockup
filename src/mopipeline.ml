type t = {
  source : string;
  parsedtree : Motyper.parsedtree;
  result : Motyper.result;
}

let process config =
  let parsedtree = Moparser.parse config.Moconfig.source in
  let result = Motyper.run config parsedtree in
  Some { source = config.source; parsedtree; result }

let get config = process config
