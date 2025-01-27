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

fn head_tails(in: BitArray) {
  use <- bool.guard(bit_array.byte_size(in) == 0, Error("EOF"))
  case in {
    <<head:utf8_codepoint, rest:bytes>> ->
      Ok(Utf8Data(string.from_utf_codepoints([head]), rest))
    <<head:size(8), rest:bytes>> -> Ok(BinaryData(<<head>>, rest))
    _ -> Error("Unexpected head_tails error")
  }
}

pub fn take(in: BitArray, amount: Int) {
  take_loop(in, amount, <<>>)
}

fn take_loop(
  in: BitArray,
  amount: Int,
  carry: BitArray,
) -> Result(#(BitArray, BitArray), String) {
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
  lambda: fn(String, BitArray) -> Result(a, String),
) -> Result(a, String) {
  use <- bool.guard(bit_array.byte_size(in) == 0, Error("EOF"))
  let assert Ok(res) = head_tails(in)
  case res {
    BinaryData(_, _) -> Error("Binary lookahead not supported")
    Utf8Data(head, _) -> lambda(head, in)
  }
}

// i<int>e
pub fn int(in: BitArray) -> Result(#(BitArray, TokenAST), String) {
  let assert Ok(Utf8Data(_, rest)) = head_tails(in)
  let #(rest, state) = take_while(rest, fn(x: String) { x == "e" || x == "E" })
  let number =
    int.base_parse(bit_array.to_string(state) |> result.unwrap("x"), 10)
  use <- bool.guard(
    result.is_error(number),
    Error("integer contains illegal characters"),
  )

  Ok(#(rest, IntToken(number |> result.unwrap(0))))
}

// <length>:<string>
pub fn binary_string(in: BitArray) -> Result(#(BitArray, TokenAST), String) {
  let #(rest, state) = take_while(in, fn(x: String) { x == ":" })
  let size =
    bit_array.to_string(state) |> result.unwrap("x") |> int.base_parse(10)
  use <- bool.guard(
    result.is_error(size),
    Error(string.append(
      "string length contains illegal characters: ",
      bit_array.to_string(state) |> result.unwrap("non utf8 characters"),
    )),
  )

  let result = size |> result.unwrap(0) |> take(rest, _)

  case result {
    Error(x) -> Error(x)
    Ok(#(head, rest)) -> {
      Ok(#(rest, StringToken(head)))
    }
  }
}

// l<elements>e
pub fn list(in: BitArray) -> Result(#(BitArray, TokenAST), String) {
  let assert Ok(Utf8Data(_, rest)) = head_tails(in)

  case list_loop(rest, []) {
    Ok(#(res, tokens)) -> {
      Ok(#(res, ListToken(tokens)))
    }
    Error(x) -> Error(x)
  }
}

fn list_loop(
  in: BitArray,
  carry: List(TokenAST),
) -> Result(#(BitArray, List(TokenAST)), String) {
  let res =
    lookahead(in, fn(head, rest) {
      case head {
        "e" | "E" -> {
          let assert Ok(Utf8Data(_, rest)) = head_tails(in)

          Ok(#(rest, carry, True))
        }
        _ ->
          case type_parser(head, rest) {
            Ok(#(r, x)) -> Ok(#(r, [x], False))
            Error(x) -> Error(x)
          }
      }
    })
  case res {
    Ok(#(rest, token, False)) -> list_loop(rest, list.append(carry, token))
    Ok(#(rest, token, True)) -> Ok(#(rest, token))
    Error("EOF") -> Ok(#(<<>>, carry))
    Error(x) -> Error(x)
  }
}

fn type_parser(
  ahead: String,
  in: BitArray,
) -> Result(#(BitArray, TokenAST), String) {
  case ahead {
    "i" | "I" -> int(in)
    "l" | "L" -> list(in)
    "d" | "D" -> dicrionary(in)
    "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> binary_string(in)
    _ -> Error(string.append("unknown token: ", ahead))
  }
}

// // d<pairs>e
pub fn dicrionary(in: BitArray) -> Result(#(BitArray, TokenAST), String) {
  let assert Ok(Utf8Data(_, rest)) = head_tails(in)

  case dictionary_loop(rest, dict.new()) {
    Ok(#(rest, tokens)) -> Ok(#(rest, DictionaryToken(tokens)))
    Error(x) -> Error(x)
  }
}

fn dictionary_loop(
  in: BitArray,
  carry: dict.Dict(String, TokenAST),
) -> Result(#(BitArray, dict.Dict(String, TokenAST)), String) {
  let res =
    lookahead(in, fn(head, rest) {
      case head {
        "e" | "E" -> {
          let assert Ok(Utf8Data(_, rest)) = head_tails(in)

          Ok(#(rest, carry, True))
        }
        _ -> {
          case binary_string(rest) {
            Ok(#(rest, StringToken(name))) -> {
              let assert Ok(Utf8Data(head, _)) = head_tails(rest)
              case type_parser(head, rest) {
                Ok(#(rest, value)) -> {
                  let new =
                    dict.insert(
                      carry,
                      bit_array.to_string(name) |> result.unwrap(""),
                      value,
                    )
                  Ok(#(rest, new, False))
                }
                Error(x) -> Error(x)
              }
            }
            Ok(_) -> Error("Somthing went wrong")
            Error(x) -> Error(x)
          }
        }
      }
    })

  case res {
    Ok(#(rest, token, False)) -> dictionary_loop(rest, token)
    Ok(#(rest, token, True)) -> Ok(#(rest, token))
    Error("EOF") -> Ok(#(<<>>, carry))
    Error(x) -> Error(x)
  }
}

pub fn parse(in: BitArray) -> Result(List(TokenAST), String) {
  parse_loop(in, [])
}

fn parse_loop(in: BitArray, carry: List(TokenAST)) {
  use <- bool.guard(bit_array.byte_size(in) == 0, Ok(carry))
  let res = lookahead(in, type_parser)
  use <- bool.guard(
    result.is_error(res),
    Error(res |> result.unwrap_error("Parse error")),
  )

  let #(rest, token) = res |> result.unwrap(#(<<>>, NilToken))
  parse_loop(rest, list.append(carry, [token]))
}
