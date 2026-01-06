# Keccak-f\[1600\] permutation

The `crypto_core_keccak1600` functions provide direct access to the Keccak-f\[1600\] permutation, the core building block of SHA-3, SHAKE, and TurboSHAKE.

This is a low-level API. For most applications, use the high-level [XOF API](../hashing/xof.md) (SHAKE128, SHAKE256, TurboSHAKE128, TurboSHAKE256) instead.

## Usage

The API follows the sponge construction pattern:

1.  Initialize the state
2.  Absorb data by XORing it into the state, applying the permutation between blocks
3.  Squeeze output by extracting bytes from the state, applying the permutation between blocks

<!-- end list -->

``` c
crypto_core_keccak1600_state state;

/* Initialize */
crypto_core_keccak1600_init(&state);

/* Absorb: XOR data into state and permute */
crypto_core_keccak1600_xor_bytes(&state, input, 0, input_len);
crypto_core_keccak1600_permute_24(&state);

/* Squeeze: extract output from state */
crypto_core_keccak1600_extract_bytes(&state, output, 0, output_len);
```

## State

``` c
typedef struct crypto_core_keccak1600_state {
    unsigned char opaque[224];
} crypto_core_keccak1600_state;
```

The state is an opaque 224-byte structure with 16-byte alignment. The internal Keccak state is 200 bytes (1600 bits), with additional bytes reserved for metadata and alignment.

The state size can be queried at runtime:

``` c
size_t crypto_core_keccak1600_statebytes(void);
```

Returns `224`.

## Initialization

``` c
void crypto_core_keccak1600_init(crypto_core_keccak1600_state *state);
```

Initializes the state to all zeros. Must be called before any other operation on a fresh state.

## Absorbing data

``` c
void crypto_core_keccak1600_xor_bytes(crypto_core_keccak1600_state *state,
                                      const unsigned char *bytes,
                                      size_t offset, size_t length);
```

XORs `length` bytes from `bytes` into the state starting at byte position `offset`.

Parameters:

  - `state`: pointer to the state
  - `bytes`: input data to absorb
  - `offset`: byte offset within the state (0-199)
  - `length`: number of bytes to XOR

The offset and length must satisfy `offset + length <= 200`. This function does not apply the permutation; call `permute_24()` or `permute_12()` after absorbing a block.

## Extracting output

``` c
void crypto_core_keccak1600_extract_bytes(const crypto_core_keccak1600_state *state,
                                          unsigned char *bytes,
                                          size_t offset, size_t length);
```

Extracts `length` bytes from the state starting at byte position `offset` into `bytes`.

Parameters:

  - `state`: pointer to the state (not modified)
  - `bytes`: output buffer
  - `offset`: byte offset within the state (0-199)
  - `length`: number of bytes to extract

The offset and length must satisfy `offset + length <= 200`. This function does not apply the permutation; call `permute_24()` or `permute_12()` to generate additional output.

## Permutations

``` c
void crypto_core_keccak1600_permute_24(crypto_core_keccak1600_state *state);
```

Applies the Keccak-f\[1600\] permutation with 24 rounds. This is the full-strength permutation used by SHAKE128 and SHAKE256.

``` c
void crypto_core_keccak1600_permute_12(crypto_core_keccak1600_state *state);
```

Applies the Keccak-p\[1600,12\] permutation with 12 rounds. This reduced-round variant is used by TurboSHAKE128 and TurboSHAKE256 for approximately 2x better performance while maintaining the same security claims.

## Building a sponge

To implement a sponge-based construction:

``` c
#define RATE 136  /* For a 256-bit capacity (like SHAKE256/TurboSHAKE256) */

void absorb_block(crypto_core_keccak1600_state *state,
                  const unsigned char *block) {
    crypto_core_keccak1600_xor_bytes(state, block, 0, RATE);
    crypto_core_keccak1600_permute_24(state);  /* or permute_12 for TurboSHAKE */
}

void squeeze_block(crypto_core_keccak1600_state *state,
                   unsigned char *block) {
    crypto_core_keccak1600_extract_bytes(state, block, 0, RATE);
    crypto_core_keccak1600_permute_24(state);  /* or permute_12 for TurboSHAKE */
}
```

The rate depends on the desired security level:

  - 168 bytes for 128-bit security (SHAKE128, TurboSHAKE128)
  - 136 bytes for 256-bit security (SHAKE256, TurboSHAKE256)

## Notes

This is a low-level primitive with no built-in padding or domain separation. Applications must implement proper padding (typically pad10\*1) and domain separation to build secure constructions.

For standard XOF functionality with proper padding and domain separation, use the high-level API:

  - `crypto_xof_shake128()` / `crypto_xof_shake256()`
  - `crypto_xof_turboshake128()` / `crypto_xof_turboshake256()`

The state type uses an opaque structure to provide type safety. The state must be declared as `crypto_core_keccak1600_state`, not allocated manually using the size from `crypto_core_keccak1600_statebytes()`.

These functions are constant-time and safe for use with secret data.
