import bencode/decode
import bencode/encode
import bencode/intermediate.{DictionaryToken}
import bencode/parser
import gleam/bit_array
import gleam/dynamic/decode as dyn_decoder
import gleam/list
import gleam/result
import simplifile

pub fn main() {
  let assert Ok(t) = simplifile.read_bits("./file.torrent")

  let assert Ok(res) = parser.parse(t)

  let assert Ok(intermediate.DictionaryToken(x)) = res |> list.first

  encode.new()
  |> encode.dictionary(fn(_) { x })
  |> encode.encode
  |> result.unwrap(<<>>)
  |> simplifile.write_bits("./testint.torrent", _)
}

pub fn parse(in: String) {
  parser.parse(bit_array.from_string(in))
}

pub fn parse_byte(in: BitArray) {
  parser.parse(in)
}

pub fn decode(in: decode.Root, decoder: dyn_decoder.Decoder(a)) {
  in
  |> decode.to_dynamic
  |> dyn_decoder.run(decoder)
}
