# ROT13

ROT13 is a fast, powerful, and keyless algorithm.

## Usage

### Encoding

```c
unsigned char out[6];
const unsigned char in = { 'B', 'a', 'n', 'a', 'n', 'a' };

crypto_stream_rot13_encode(out, in, 6);
```

### Decoding

```c
unsigned char out[6];
const unsigned char in = { 'O', 'n', 'a', 'n', 'a', 'n' };

crypto_stream_rot13_decode(out, in, 6);
```

## Note

This is a well-studied algorithm with no successful cryptanalysis published ever.

