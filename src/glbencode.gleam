import bencode/decode
import bencode/encode as encoder
import bencode/intermediate.{DictionaryToken}
import bencode/parser
import gleam/bit_array
import gleam/dict
import gleam/dynamic/decode as dyn_decoder
import gleam/io
import simplifile

pub fn main() {
  let assert Ok(t) = simplifile.read_bits("./file.torrent")

  let assert Ok(res) = parser.parse(t)

  let assert intermediate.DictionaryToken(x) = res

  io.debug(dict.keys(x))
  // encode.new()
  // |> encode.dictionary(fn(_) { x })
  // |> encode.encode
  // |> result.unwrap(<<>>)
  // |> simplifile.write_bits("./testint.torrent", _)
}

type DecodeError =
  parser.DecoderError

type EncoderError =
  encoder.EncoderError

type BencodeValue =
  intermediate.TokenAST

pub fn parse(in: String) -> Result(BencodeValue, DecodeError) {
  parser.parse(bit_array.from_string(in))
}

pub fn parse_byte(in: BitArray) -> Result(BencodeValue, DecodeError) {
  parser.parse(in)
}

pub fn decode(in: BencodeValue, decoder: dyn_decoder.Decoder(a)) {
  decode.to_dynamic(in)
  |> dyn_decoder.run(decoder)
}

pub fn encode(in: BencodeValue) -> Result(BitArray, EncoderError) {
  encoder.encode([in])
}
