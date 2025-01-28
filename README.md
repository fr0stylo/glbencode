
# GLBEncode

GLBEncode is a Gleam library for encoding and decoding Bencode data. Bencode is a simple encoding format used by the BitTorrent protocol for storing and transmitting loosely structured data.

## Features

- **Parsing**: Convert Bencode data into an intermediate representation.
- **Encoding**: Convert the intermediate representation back into Bencode format.
- **Decoding**: Convert the intermediate representation into dynamic Gleam types for further processing.

## Installation

To use GLBEncode in your Gleam project, add it to your `gleam.toml` dependencies:

```toml
[dependencies]
glbencode = { path = "./path/to/glbencode" }
```

## Usage

### Parsing Bencode Data

You can parse Bencode data from a string or a byte array:

```gleam
import glbencode
import gleam/result.{Ok, Error}

let bencode_string = "d3:cow3:moo4:spam4:eggse"
let parsed = glbencode.parse(bencode_string)

case parsed {
  Ok(value) -> // Handle the parsed value
  Error(error) -> // Handle the error
}
```

### Encoding Bencode Data

You can encode data into Bencode format:

```gleam
import glbencode/encode

let encoder = encode.new()
let encoder = encode.dictionary(encoder, fn(_) {
  dict.from_list([#("cow", encode.string_value("moo")), #("spam", encode.string_value("eggs"))])
})
let encoded = encode.encode(encoder)

case encoded {
  Ok(bytes) -> // Handle the encoded bytes
  Error(error) -> // Handle the error
}
```

### Decoding Bencode Data

You can decode Bencode data into dynamic Gleam types:

```gleam
import glbencode
import gleam/dynamic/decode as dyn_decoder

let bencode_string = "d3:cow3:moo4:spam4:eggse"
let parsed = glbencode.parse(bencode_string)

case parsed {
  Ok(value) -> {
    let decoder = dyn_decoder.string()
    let decoded = glbencode.decode(value, decoder)
    // Handle the decoded value
  }
  Error(error) -> // Handle the error
}
```

## Running the Example

An example is provided in `glbencode/src/glbencode.gleam`. To run it, make sure you have a file named `file.torrent` in the same directory and execute the following command:

```sh
gleam run
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## License

This project is licensed under the MIT License.
