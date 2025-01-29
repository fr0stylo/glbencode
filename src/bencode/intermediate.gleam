import gleam/dict.{type Dict}

pub type TokenAST {
  IntToken(Int)
  StringToken(BitArray)
  DictionaryToken(Dict(String, TokenAST))
  ListToken(List(TokenAST))
}
