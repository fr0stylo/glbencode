# GLBEncode

## Overview

GLBEncode is a Gleam-based library for encoding and decoding messages using the Bencode format. This library provides functionality to parse, encode, and decode Bencoded data, which is commonly used in torrent files.

## Prerequisites

Before running the code, ensure you have the following installed:

- [Gleam](https://gleam.run/getting-started/) (version 0.17.0 or later)
- Any necessary libraries or dependencies (listed in `gleam.toml` if applicable)

## How to Run the Code

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/glbencode.git
   cd glbencode
   ```

2. **Build the Project**

   Compile the Gleam project:

   ```bash
   gleam build
   ```

3. **Run the Code**

   To run the main function, use the following command:

   ```bash
   gleam run
   ```

   This will execute the `main` function in `glbencode/src/glbencode.gleam`.

## How to Run the Tests

1. **Navigate to the Project Directory**

   ```bash
   cd glbencode
   ```

2. **Run the Tests**

   You can run the tests using Gleam's built-in test runner:

   ```bash
   gleam test
   ```

## How to Encode and Decode a Message

### Encoding a Message

To encode a message, use the `encode` module provided in the code. For example:

```gleam
import bencode/encode

fn encode_message() {
  let encoder = encode.new()
  let encoder = encode.string(encoder, "Hello, World!")
  let result = encode.encode(encoder)
  case result {
    Ok(encoded_message) -> io.debug(encoded_message)
    Error(error) -> io.debug(error)
  }
}
```

### Decoding a Message

To decode a message, use the `decode` module provided in the code. For example:

```gleam
import bencode/decode
import bencode/parser
import gleam/bit_array
import gleam/dynamic/decode as dyn_decoder

fn decode_message() {
  let encoded_message = bit_array.from_string("12:Hello, World!")
  let parsed = parser.parse(encoded_message)
  case parsed {
    Ok(tokens) -> {
      let first_token = list.head(tokens)
      case first_token {
        Some(token) -> {
          let decoder = dyn_decoder.string()
          let result = decode.decode(token, decoder)
          case result {
            Ok(decoded_message) -> io.debug(decoded_message)
            Error(errors) -> io.debug(errors)
          }
        }
        None -> io.debug("No tokens found")
      }
    }
    Error(error) -> io.debug(error)
  }
}
```

## Example Usage

Here is a complete example of encoding and decoding a message:

```gleam
import gleam/io
import bencode/encode
import bencode/decode
import bencode/parser
import gleam/bit_array
import gleam/dynamic/decode as dyn_decoder

fn main() {
  // Original message
  let message = "Hello, World!"

  // Encode the message
  let encoder = encode.new()
  let encoder = encode.string(encoder, message)
  let encoded_result = encode.encode(encoder)
  case encoded_result {
    Ok(encoded_message) -> {
      io.debug(encoded_message)

      // Decode the message
      let parsed = parser.parse(encoded_message)
      case parsed {
        Ok(tokens) -> {
          let first_token = list.head(tokens)
          case first_token {
            Some(token) -> {
              let decoder = dyn_decoder.string()
              let decoded_result = decode.decode(token, decoder)
              case decoded_result {
                Ok(decoded_message) -> io.debug(decoded_message)
                Error(errors) -> io.debug(errors)
              }
            }
            None -> io.debug("No tokens found")
          }
        }
        Error(error) -> io.debug(error)
      }
    }
    Error(error) -> io.debug(error)
  }
}
```

## Contributing

If you would like to contribute to this project, please fork the repository and submit a pull request. We welcome all contributions!

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

---

Thank you for using GLBEncode!
