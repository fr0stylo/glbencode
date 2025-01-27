import bencode/decode
import glbencode
import gleam/bit_array
import gleam/dict
import gleeunit
import gleeunit/should

import bencode/intermediate.{DictionaryToken, IntToken, ListToken, StringToken}

pub fn main() {
  gleeunit.main()
}

pub fn parse_test() {
  "10:HelloWorldi123e10:HelloWorldld3:heli132e3:heai132e3:heei132eei132ei123eli132ei123ee10:HelloWorldi123e10:HelloWorlde10:HelloWorldi123e10:HelloWorld"
  |> glbencode.parse
  |> should.be_ok
  |> should.equal([
    StringToken(<<"HelloWorld">>),
    IntToken(123),
    StringToken(<<"HelloWorld">>),
    ListToken([
      DictionaryToken(
        dict.new()
        |> dict.insert("hel", IntToken(132))
        |> dict.insert("hea", IntToken(132))
        |> dict.insert("hee", IntToken(132)),
      ),
      IntToken(132),
      IntToken(123),
      ListToken([IntToken(132), IntToken(123)]),
      StringToken(<<"HelloWorld">>),
      IntToken(123),
      StringToken(<<"HelloWorld">>),
    ]),
    StringToken(<<"HelloWorld">>),
    IntToken(123),
    StringToken(<<"HelloWorld">>),
  ])
}

pub fn binary_parse_test() {
  "10:HelloWorldi123e10:HelloWorldld3:heli132e3:heai132e3:heei132eei132ei123eli132ei123ee10:HelloWorldi123e10:HelloWorlde10:HelloWorldi123e10:HelloWorld"
  |> bit_array.from_string
  |> decode.parse
  |> should.be_ok
  |> should.equal([
    StringToken(<<"HelloWorld">>),
    IntToken(123),
    StringToken(<<"HelloWorld">>),
    ListToken([
      DictionaryToken(
        dict.new()
        |> dict.insert("hel", IntToken(132))
        |> dict.insert("hea", IntToken(132))
        |> dict.insert("hee", IntToken(132)),
      ),
      IntToken(132),
      IntToken(123),
      ListToken([IntToken(132), IntToken(123)]),
      StringToken(<<"HelloWorld">>),
      IntToken(123),
      StringToken(<<"HelloWorld">>),
    ]),
    StringToken(<<"HelloWorld">>),
    IntToken(123),
    StringToken(<<"HelloWorld">>),
  ])
}
