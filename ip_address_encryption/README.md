# IP address encryption

The `crypto_ipcrypt` API provides efficient, secure encryption of IP addresses (IPv4 and IPv6) for privacy-preserving storage, logging, and analytics.

Unlike truncation (which irreversibly destroys data) or hashing (which prevents decryption), ipcrypt provides reversible encryption with well-defined security properties while maintaining operational utility.

## Use cases

  - Privacy-preserving logs: Encrypt IP addresses in access logs while retaining the ability to decrypt when needed for abuse investigation.
  - Analytics without exposure: Count unique clients, detect patterns, and perform rate limiting without exposing original addresses to third parties.
  - Data sharing: Share network data (e.g., attack traffic) with external parties using encrypted addresses.
  - Compliance: Store IP addresses in encrypted form to meet privacy regulations (GDPR, etc.) while maintaining the ability to respond to lawful requests.

## Variants

ipcrypt provides four variants with different security and format trade-offs:

| Variant                          | Key      | Output   | Properties                                                |
| :------------------------------- | :------- | :------- | :-------------------------------------------------------- |
| Deterministic                    | 16 bytes | 16 bytes | Same input always produces same output; format-preserving |
| ND (non-deterministic)           | 16 bytes | 24 bytes | Different output each time; 8-byte random tweak           |
| NDX (extended non-deterministic) | 32 bytes | 32 bytes | Different output each time; 16-byte random tweak          |
| PFX (prefix-preserving)          | 32 bytes | 16 bytes | Preserves network prefix relationships                    |

## IP address representation

All variants operate on 16-byte values. IPv4 addresses are represented as IPv4-mapped IPv6 addresses:

  - IPv6: Used directly (16 bytes in network byte order)
  - IPv4: Encoded as `::ffff:a.b.c.d` (10 zero bytes, `0xff 0xff`, then 4 IPv4 bytes)

For example, `192.0.2.1` is represented as:

    00 00 00 00 00 00 00 00 00 00 ff ff c0 00 02 01

## Converting IP addresses

The `sodium_ip2bin()` and `sodium_bin2ip()` functions convert between string and binary representations.

``` c
int sodium_ip2bin(unsigned char *out, const char *src);
```

The `sodium_ip2bin()` function parses the IP address string `src` and writes the 16-byte binary representation to `out`.

It accepts both IPv4 (e.g., `"192.0.2.1"`) and IPv6 (e.g., `"2001:db8::1"`) addresses. IPv4 addresses are automatically converted to IPv4-mapped format.

Returns `0` on success, `-1` on error.

``` c
char *sodium_bin2ip(char *dst, size_t dst_len, const unsigned char *in);
```

The `sodium_bin2ip()` function converts the 16-byte binary address `in` to a string and writes it to `dst`. 

The buffer `dst` must be at least 16 bytes for IPv4 addresses or 46 bytes for IPv6 addresses. IPv4-mapped addresses are automatically converted to dotted-decimal notation.

Returns a pointer to `dst` on success, `NULL` on error.

## Deterministic encryption

The simplest variant encrypts an IP address to a 16-byte ciphertext. The same address with the same key always produces the same ciphertext.

``` c
void crypto_ipcrypt_encrypt(unsigned char *out,
                            const unsigned char *in,
                            const unsigned char *k);
```

``` c
void crypto_ipcrypt_decrypt(unsigned char *out,
                            const unsigned char *in,
                            const unsigned char *k);
```

The `crypto_ipcrypt_encrypt()` function encrypts a 16-byte address `in` using the key `k` and writes the result to `out`.

The `crypto_ipcrypt_decrypt()` function reverses the encryption.

``` c
void crypto_ipcrypt_keygen(unsigned char *k);
```

The `crypto_ipcrypt_keygen()` function generates a random 16-byte key.

### Example (deterministic)

``` c
#include <sodium.h>
#include <stdio.h>

int main(void)
{
    unsigned char key[crypto_ipcrypt_KEYBYTES];
    unsigned char addr[crypto_ipcrypt_BYTES];
    unsigned char encrypted[crypto_ipcrypt_BYTES];
    unsigned char decrypted[crypto_ipcrypt_BYTES];
    char ip_str[46];

    if (sodium_init() < 0) {
        return 1;
    }

    /* Generate a random key */
    crypto_ipcrypt_keygen(key);

    /* Parse an IP address */
    if (sodium_ip2bin(addr, "192.0.2.1") != 0) {
        return 1;
    }

    /* Encrypt */
    crypto_ipcrypt_encrypt(encrypted, addr, key);

    /* The encrypted address can be displayed as an IP */
    sodium_bin2ip(ip_str, sizeof ip_str, encrypted);
    printf("Encrypted: %s\n", ip_str);

    /* Decrypt */
    crypto_ipcrypt_decrypt(decrypted, encrypted, key);

    /* Convert back to string */
    sodium_bin2ip(ip_str, sizeof ip_str, decrypted);
    printf("Decrypted: %s\n", ip_str);  /* "192.0.2.1" */

    return 0;
}
```

### When to use deterministic mode

Use deterministic encryption when:

  - You need to identify duplicate addresses (rate limiting, deduplication)
  - Format preservation matters (output is also a valid IP representation)
  - Storage space is constrained

The trade-off is that identical addresses produce identical ciphertexts, allowing correlation analysis. An attacker who knows a specific address was encrypted can verify this by encrypting it with a guessed key.

## Non-deterministic encryption (ND)

The ND variant uses a random 8-byte tweak, ensuring the same address produces different ciphertexts each time.

``` c
void crypto_ipcrypt_nd_encrypt(unsigned char *out,
                               const unsigned char *in,
                               const unsigned char *t,
                               const unsigned char *k);
```

``` c
void crypto_ipcrypt_nd_decrypt(unsigned char *out,
                               const unsigned char *in,
                               const unsigned char *k);
```

The `crypto_ipcrypt_nd_encrypt()` function encrypts a 16-byte address `in` using the key `k` and tweak `t`, writing the 24-byte result (tweak prepended to ciphertext) to `out`.

The `crypto_ipcrypt_nd_decrypt()` function decrypts a 24-byte ciphertext `in` (which includes the tweak) and writes the 16-byte address to `out`. No separate tweak parameter is needed because the tweak is extracted from the ciphertext.

### Example (ND)

``` c
unsigned char key[crypto_ipcrypt_ND_KEYBYTES];
unsigned char tweak[crypto_ipcrypt_ND_TWEAKBYTES];
unsigned char addr[crypto_ipcrypt_ND_INPUTBYTES];
unsigned char encrypted[crypto_ipcrypt_ND_OUTPUTBYTES];
unsigned char decrypted[crypto_ipcrypt_ND_INPUTBYTES];
char ip_str[46];

crypto_ipcrypt_keygen(key);
randombytes_buf(tweak, sizeof tweak);

if (sodium_ip2bin(addr, "192.0.2.1") != 0) {
    /* handle error */
}

crypto_ipcrypt_nd_encrypt(encrypted, addr, tweak, key);
crypto_ipcrypt_nd_decrypt(decrypted, encrypted, key);

sodium_bin2ip(ip_str, sizeof ip_str, decrypted);  /* "192.0.2.1" */
```

### When to use ND mode

Use ND encryption when:

  - Preventing correlation analysis is important
  - 24-byte output is acceptable
  - You’ll perform fewer than \~4 billion encryptions with the same key (birthday bound on 64-bit tweaks)

## Extended non-deterministic encryption (NDX)

The NDX variant provides larger tweaks and a larger key for higher security margins.

``` c
void crypto_ipcrypt_ndx_encrypt(unsigned char *out,
                                const unsigned char *in,
                                const unsigned char *t,
                                const unsigned char *k);
```

``` c
void crypto_ipcrypt_ndx_decrypt(unsigned char *out,
                                const unsigned char *in,
                                const unsigned char *k);
```

The `crypto_ipcrypt_ndx_encrypt()` function encrypts a 16-byte address `in` using the 32-byte key `k` and 16-byte tweak `t`, writing the 32-byte result to `out`.

The `crypto_ipcrypt_ndx_decrypt()` function decrypts a 32-byte ciphertext.

``` c
void crypto_ipcrypt_ndx_keygen(unsigned char *k);
```

The `crypto_ipcrypt_ndx_keygen()` function generates a random 32-byte key.

### Example (NDX)

``` c
unsigned char key[crypto_ipcrypt_NDX_KEYBYTES];
unsigned char tweak[crypto_ipcrypt_NDX_TWEAKBYTES];
unsigned char addr[crypto_ipcrypt_NDX_INPUTBYTES];
unsigned char encrypted[crypto_ipcrypt_NDX_OUTPUTBYTES];
unsigned char decrypted[crypto_ipcrypt_NDX_INPUTBYTES];
char ip_str[46];

crypto_ipcrypt_ndx_keygen(key);
randombytes_buf(tweak, sizeof tweak);

if (sodium_ip2bin(addr, "2001:db8::1") != 0) {
    /* handle error */
}

crypto_ipcrypt_ndx_encrypt(encrypted, addr, tweak, key);
crypto_ipcrypt_ndx_decrypt(decrypted, encrypted, key);

sodium_bin2ip(ip_str, sizeof ip_str, decrypted);  /* "2001:db8::1" */
```

### When to use NDX mode

Use NDX encryption when:

  - Maximum security is required
  - 32-byte output is acceptable
  - You want practically unlimited encryptions per key (\~2^64 birthday bound)

## Prefix-preserving encryption (PFX)

The PFX variant preserves network prefix relationships: addresses sharing a common prefix will have ciphertexts sharing a corresponding (different) prefix.

``` c
void crypto_ipcrypt_pfx_encrypt(unsigned char *out,
                                const unsigned char *in,
                                const unsigned char *k);
```

``` c
void crypto_ipcrypt_pfx_decrypt(unsigned char *out,
                                const unsigned char *in,
                                const unsigned char *k);
```

The `crypto_ipcrypt_pfx_encrypt()` function encrypts a 16-byte address `in` using the 32-byte key `k` and writes the 16-byte result to `out`.

The address family is preserved: IPv4 addresses encrypt to IPv4 addresses.

``` c
void crypto_ipcrypt_pfx_keygen(unsigned char *k);
```

The `crypto_ipcrypt_pfx_keygen()` function generates a random 32-byte key.

### Example (PFX)

``` c
unsigned char key[crypto_ipcrypt_PFX_KEYBYTES];
unsigned char addr1[crypto_ipcrypt_PFX_BYTES];
unsigned char addr2[crypto_ipcrypt_PFX_BYTES];
unsigned char enc1[crypto_ipcrypt_PFX_BYTES];
unsigned char enc2[crypto_ipcrypt_PFX_BYTES];
char ip_str[46];

crypto_ipcrypt_pfx_keygen(key);

/* Encrypt two addresses in the same /24 */
if (sodium_ip2bin(addr1, "10.0.0.1") != 0) {
    /* handle error */
}
if (sodium_ip2bin(addr2, "10.0.0.100") != 0) {
    /* handle error */
}

crypto_ipcrypt_pfx_encrypt(enc1, addr1, key);
crypto_ipcrypt_pfx_encrypt(enc2, addr2, key);

sodium_bin2ip(ip_str, sizeof ip_str, enc1);
printf("10.0.0.1   -> %s\n", ip_str);  /* e.g., "79.55.98.17" */

sodium_bin2ip(ip_str, sizeof ip_str, enc2);
printf("10.0.0.100 -> %s\n", ip_str);  /* e.g., "79.55.98.127" - same /24 */
```

### When to use PFX mode

Use PFX encryption when:

  - Network-level analytics are needed (subnet analysis, routing studies)
  - You want to analyze traffic patterns while protecting individual addresses
  - Format preservation is required

The trade-off is that network topology is revealed. Addresses in the same subnet will have ciphertexts in a corresponding (encrypted) subnet.

## Algorithm details

  - Deterministic: Single-block AES-128
  - ND: KIASU-BC (tweakable AES-128 with 64-bit tweak)
  - NDX: AES-XTS (IEEE 1619-2007) with 128-bit tweak
  - PFX: Bit-by-bit format-preserving encryption using XOR of two AES-128 permutations

All implementations use hardware acceleration when available (AES-NI on x86-64, ARM Crypto extensions on ARM).

## Security considerations

What ipcrypt protects against:

  - Unauthorized parties learning original addresses without the key
  - Statistical analysis revealing traffic patterns (non-deterministic modes)
  - Brute-force attacks on the address space (128-bit AES security)

What ipcrypt does not protect against:

  - Active attackers modifying, reordering, or removing encrypted addresses
  - Correlation of identical addresses (deterministic mode)
  - Traffic analysis based on volume and timing metadata

Key management:

  - Generate keys using `crypto_ipcrypt_keygen()`, `crypto_ipcrypt_ndx_keygen()`, or `crypto_ipcrypt_pfx_keygen()`
  - Never reuse keys across different variants; use HKDF to derive separate keys if needed
  - Rotate keys based on usage volume and security requirements

Tweak generation (ND/NDX modes):

  - Tweaks must be generated using a cryptographically secure random source
  - Use `randombytes_buf()` to generate tweaks

## Constants

  - `crypto_ipcrypt_BYTES`
  - `crypto_ipcrypt_KEYBYTES`
  - `crypto_ipcrypt_ND_KEYBYTES`
  - `crypto_ipcrypt_ND_TWEAKBYTES`
  - `crypto_ipcrypt_ND_INPUTBYTES`
  - `crypto_ipcrypt_ND_OUTPUTBYTES`
  - `crypto_ipcrypt_NDX_KEYBYTES`
  - `crypto_ipcrypt_NDX_TWEAKBYTES`
  - `crypto_ipcrypt_NDX_INPUTBYTES`
  - `crypto_ipcrypt_NDX_OUTPUTBYTES`
  - `crypto_ipcrypt_PFX_KEYBYTES`
  - `crypto_ipcrypt_PFX_BYTES`

## See also

  - [ipcrypt specification](https://ipcrypt-std.github.io/)
  - [IETF draft](https://datatracker.ietf.org/doc/draft-denis-ipcrypt/)
