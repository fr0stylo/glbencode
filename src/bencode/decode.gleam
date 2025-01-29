import bencode/intermediate
import gleam/bit_array
import gleam/bool
import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode as dyn_decode
import gleam/list
import gleam/result

pub type Root =
  intermediate.TokenAST

pub fn to_dynamic(in: Root) -> dynamic.Dynamic {
  case in {
    intermediate.DictionaryToken(x) ->
      dict.map_values(x, fn(_, b) { to_dynamic(b) }) |> dynamic.from
    intermediate.IntToken(x) -> dynamic.from(x)
    intermediate.ListToken(x) -> list.map(x, to_dynamic) |> dynamic.from
    intermediate.StringToken(x) -> {
      use <- bool.guard(bit_array.is_utf8(x), dynamic.from(x))

      bit_array.to_string(x) |> result.unwrap("") |> dynamic.from
    }
  }
}

pub fn decode(
  in: Root,
  deocder: dyn_decode.Decoder(a),
) -> Result(a, List(dyn_decode.DecodeError)) {
  dyn_decode.run(to_dynamic(in), deocder)
}
