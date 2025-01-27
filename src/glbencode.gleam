import bencode/decode
import bencode/encode
import bencode/intermediate
import gleam/bit_array
import gleam/list
import gleam/result
import simplifile

pub fn main() {
  let assert Ok(t) = simplifile.read_bits("./file.torrent")

  let assert Ok(res) = decode.parse(t)

  let assert Ok(intermediate.DictionaryToken(x)) = res |> list.first

  encode.new()
  |> encode.dictionary(fn(_) { x })
  |> encode.encode
  |> result.unwrap(<<>>)
  |> simplifile.write_bits("./testint.torrent", _)
}

pub fn parse(in: String) {
  decode.parse(bit_array.from_string(in))
}
