import bencode/decode
import bencode/encode as encoder
import bencode/intermediate
import bencode/parser
import gleam/bit_array
import gleam/dynamic/decode as dyn_decoder

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
