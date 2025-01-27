import bencode/intermediate.{DictionaryToken, IntToken, ListToken, StringToken}
import gleam/bit_array
import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result

type Encoder =
  List(intermediate.TokenAST)

type Value =
  intermediate.TokenAST

pub fn new() -> Encoder {
  []
}

pub fn list(in: Encoder, contents: Encoder) -> Encoder {
  list.append(in, [list_value(contents)])
}

pub fn dictionary(
  in: Encoder,
  content: fn(dict.Dict(String, Value)) -> dict.Dict(String, Value),
) -> Encoder {
  list.append(in, [dict_value(content)])
}

pub fn int(in: Encoder, contents: Int) -> Encoder {
  list.append(in, [int_value(contents)])
}

pub fn string(in: Encoder, contents: String) -> Encoder {
  list.append(in, [intermediate.StringToken(<<contents:utf8>>)])
}

pub fn bytes(in: Encoder, contents: BitArray) -> Encoder {
  list.append(in, [intermediate.StringToken(contents)])
}

pub fn list_value(contents: Encoder) -> Value {
  intermediate.ListToken(contents)
}

pub fn dict_value(
  contents: fn(dict.Dict(String, Value)) -> dict.Dict(String, Value),
) -> Value {
  intermediate.DictionaryToken(contents(dict.new()))
}

pub fn int_value(contents: Int) -> Value {
  intermediate.IntToken(contents)
}

pub fn string_value(contents: String) -> Value {
  bytes_value(<<contents:utf8>>)
}

pub fn bytes_value(contents: BitArray) -> Value {
  intermediate.StringToken(contents)
}

fn encode_string(x: BitArray) -> BitArray {
  let size = bit_array.byte_size(x)
  use <- bool.guard(
    !bit_array.is_utf8(x),
    <<int.to_string(size):utf8, ":">>
      |> bit_array.append(x),
  )
  let str = bit_array.to_string(x) |> result.unwrap("")
  <<int.to_string(size):utf8, ":", str:utf8>>
}

fn encode_type(carry: BitArray, in: intermediate.TokenAST) -> BitArray {
  case in {
    IntToken(x) -> bit_array.append(carry, <<"i", int.to_string(x):utf8, "e">>)
    DictionaryToken(tokens_dict) -> {
      bit_array.append(carry, <<"d">>)
      |> dict.fold(tokens_dict, _, fn(accumulator, key, value) {
        bit_array.append(accumulator, encode_string(<<key:utf8>>))
        |> bit_array.append(encode_type(<<>>, value))
      })
      |> bit_array.append(<<"e">>)
    }
    ListToken(tokens) -> {
      list.map(tokens, fn(t) { encode_type(<<>>, t) })
      |> bit_array.concat
      |> bit_array.append(<<"l">>, _)
      |> bit_array.append(<<"e">>)
      |> bit_array.append(carry, _)
    }
    StringToken(x) -> encode_string(x)
    _ -> {
      io.debug("Unreachable")
      <<>>
    }
  }
}

pub fn encode(in: Encoder) -> Result(BitArray, String) {
  use <- bool.guard(
    list.length(in) > 1,
    Error("Bencode must have only one root element"),
  )

  Ok(list.map(in, fn(x) { encode_type(<<>>, x) }) |> bit_array.concat)
}
