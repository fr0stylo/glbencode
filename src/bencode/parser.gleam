import gleam/bit_array
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/string

import bencode/intermediate.{
  type TokenAST, DictionaryToken, IntToken, ListToken, NilToken, StringToken,
}

type BinaryData {
  Utf8Data(String, BitArray)
  BinaryData(BitArray, BitArray)
}

pub type DecoderError {
  EOF
  ParseError(String)
  UnexpectedError
  IllegalCharacter
  UnknownToken(String)
}

fn head_tails(in: BitArray) -> Result(BinaryData, DecoderError) {
  use <- bool.guard(bit_array.byte_size(in) == 0, Error(EOF))
  case in {
    <<head:utf8_codepoint, rest:bytes>> ->
      Ok(Utf8Data(string.from_utf_codepoints([head]), rest))
    <<head:size(8), rest:bytes>> -> Ok(BinaryData(<<head>>, rest))
    _ -> Error(UnexpectedError)
  }
}

pub fn take(
  in: BitArray,
  amount: Int,
) -> Result(#(BitArray, BitArray), DecoderError) {
  take_loop(in, amount, <<>>)
}

fn take_loop(
  in: BitArray,
  amount: Int,
  carry: BitArray,
) -> Result(#(BitArray, BitArray), DecoderError) {
  use <- bool.guard(amount == bit_array.byte_size(carry), Ok(#(carry, in)))
  case head_tails(in) {
    Ok(Utf8Data(head, rest)) ->
      take_loop(rest, amount, bit_array.append(carry, <<head:utf8>>))
    Ok(BinaryData(head, rest)) ->
      take_loop(rest, amount, bit_array.append(carry, head))
    Error(x) -> Error(x)
  }
}

pub fn take_while(in: BitArray, predicate: fn(String) -> Bool) {
  take_while_loop(in, <<>>, predicate)
}

fn take_while_loop(in: BitArray, carry: BitArray, predicate: fn(String) -> Bool) {
  let assert Ok(Utf8Data(head, rest)) = head_tails(in)
  use <- bool.guard(predicate(head), #(rest, carry))
  use <- bool.guard(bit_array.byte_size(in) == 0, #(in, carry))

  take_while_loop(
    rest,
    bit_array.append(carry, bit_array.from_string(head)),
    predicate,
  )
}

pub fn lookahead(
  in: BitArray,
  lambda: fn(String, BitArray) -> Result(a, DecoderError),
) -> Result(a, DecoderError) {
  use <- bool.guard(bit_array.byte_size(in) == 0, Error(EOF))
  head_tails(in)
  |> result.try(fn(res) {
    case res {
      BinaryData(_, _) -> Error(ParseError("Unexpected binary data"))
      Utf8Data(head, _) -> lambda(head, in)
    }
  })
}

// i<int>e
pub fn int(in: BitArray) -> Result(#(BitArray, TokenAST), DecoderError) {
  let assert Ok(Utf8Data(_, rest)) = head_tails(in)
  let #(rest, state) = take_while(rest, fn(x: String) { x == "e" || x == "E" })
  let number =
    int.base_parse(bit_array.to_string(state) |> result.unwrap("x"), 10)
  use <- bool.guard(result.is_error(number), Error(IllegalCharacter))

  Ok(#(rest, IntToken(number |> result.unwrap(0))))
}

// <length>:<string>
pub fn binary_string(
  in: BitArray,
) -> Result(#(BitArray, TokenAST), DecoderError) {
  let #(rest, state) = take_while(in, fn(x: String) { x == ":" })
  let size =
    bit_array.to_string(state) |> result.unwrap("x") |> int.base_parse(10)
  use <- bool.guard(result.is_error(size), Error(IllegalCharacter))

  let result = size |> result.unwrap(0) |> take(rest, _)

  case result {
    Error(x) -> Error(x)
    Ok(#(head, rest)) -> {
      Ok(#(rest, StringToken(head)))
    }
  }
}

// l<elements>e
pub fn list(in: BitArray) -> Result(#(BitArray, TokenAST), DecoderError) {
  head_tails(in)
  |> result.then(fn(x) {
    case x {
      Utf8Data(_, rest) -> Ok(rest)
      BinaryData(_, _) -> Error(UnexpectedError)
    }
  })
  |> result.try(fn(x) { list_loop(x, []) })
  |> result.then(fn(x) {
    let #(res, tokens) = x
    Ok(#(res, ListToken(tokens)))
  })
}

fn list_loop(
  in: BitArray,
  carry: List(TokenAST),
) -> Result(#(BitArray, List(TokenAST)), DecoderError) {
  use head, rest <- lookahead(in)
  case head {
    "e" | "E" -> {
      head_tails(in)
      |> result.then(fn(x) {
        case x {
          Utf8Data(_, rest) -> Ok(#(rest, carry))
          BinaryData(_, _) -> Error(UnexpectedError)
        }
      })
    }
    _ ->
      type_parser(head, rest)
      |> result.then(fn(x) {
        let #(r, x) = x
        list_loop(r, list.append(carry, [x]))
      })
  }
}

fn type_parser(
  ahead: String,
  in: BitArray,
) -> Result(#(BitArray, TokenAST), DecoderError) {
  case ahead {
    "i" | "I" -> int(in)
    "l" | "L" -> list(in)
    "d" | "D" -> dicrionary(in)
    "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> binary_string(in)
    _ -> Error(UnknownToken(ahead))
  }
}

// // d<pairs>e
pub fn dicrionary(in: BitArray) -> Result(#(BitArray, TokenAST), DecoderError) {
  head_tails(in)
  |> result.then(fn(x) {
    case x {
      Utf8Data(_, rest) -> Ok(rest)
      BinaryData(_, _) -> Error(UnexpectedError)
    }
  })
  |> result.try(fn(x) { dictionary_loop(x, dict.new()) })
  |> result.then(fn(x) {
    let #(res, tokens) = x
    Ok(#(res, DictionaryToken(tokens)))
  })
}

fn dictionary_loop(
  in: BitArray,
  carry: dict.Dict(String, TokenAST),
) -> Result(#(BitArray, dict.Dict(String, TokenAST)), DecoderError) {
  use head, rest <- lookahead(in)
  case head {
    "e" | "E" -> {
      let assert Ok(Utf8Data(_, rest)) = head_tails(in)

      Ok(#(rest, carry))
    }
    _ -> {
      binary_string(rest)
      |> result.try(fn(x) {
        case x {
          #(rest, StringToken(name)) -> {
            let assert Ok(Utf8Data(head, _)) = head_tails(rest)
            type_parser(head, rest)
            |> result.then(fn(x) {
              let #(rest, value) = x
              dict.insert(
                carry,
                bit_array.to_string(name) |> result.unwrap(""),
                value,
              )
              |> dictionary_loop(rest, _)
            })
          }
          _ -> Error(UnexpectedError)
        }
      })
    }
  }
}

pub fn parse(in: BitArray) -> Result(TokenAST, DecoderError) {
  parse_loop(in, [])
  |> result.try(fn(x) { list.first(x) |> result.replace_error(UnexpectedError) })
  |> result.replace_error(UnexpectedError)
}

fn parse_loop(in: BitArray, carry: List(TokenAST)) {
  use <- bool.guard(bit_array.byte_size(in) == 0, Ok(carry))
  let res = lookahead(in, type_parser)
  use <- bool.guard(
    result.is_error(res),
    Error(res |> result.unwrap_error(ParseError("Unknown error"))),
  )

  let #(rest, token) = res |> result.unwrap(#(<<>>, NilToken))
  parse_loop(rest, list.append(carry, [token]))
}
