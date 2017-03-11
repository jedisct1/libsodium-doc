# Diffie-Hellman function

Sodium provides X25519, a state-of-the-art Diffie-Hellman function suitable for a wide variety of applications.

## Usage

```c
int crypto_scalarmult_base(unsigned char *q, const unsigned char *n);
```

Given a user's secret key `n` \(`crypto_scalarmult_SCALARBYTES` bytes\), the `crypto_scalarmult_base()` function computes the user's public key and puts it into `q` \(`crypto_scalarmult_BYTES` bytes\).

`crypto_scalarmult_BYTES` and `crypto_scalarmult_SCALARBYTES` are provided for consistency, but it is safe to assume that `crypto_scalarmult_BYTES == crypto_scalarmult_SCALARBYTES`.

```c
int crypto_scalarmult(unsigned char *q, const unsigned char *n,
                      const unsigned char *p);
```

This function can be used to compute a shared secret `q` given a user's secret key and another user's public key.

`n` is `crypto_scalarmult_SCALARBYTES` bytes long, `p` and the output are `crypto_scalarmult_BYTES` bytes long.

`q` represents the X coordinate of a point on the curve. As a result, the number of possible keys is limited to the group size \(≈2^252\), and the key distribution is not uniform.   
For this reason, instead of directly using the output of the multiplication `q` as a shared key, it is recommended to use `h(q ‖ pk1 ‖ pk2)`, with `pk1` and `pk2` being the public keys.

  
This can be achieved with the following code snippet:

```c
unsigned char client_publickey[crypto_box_PUBLICKEYBYTES];
unsigned char client_secretkey[crypto_box_SECRETKEYBYTES];
unsigned char server_publickey[crypto_box_PUBLICKEYBYTES];
unsigned char server_secretkey[crypto_box_SECRETKEYBYTES];
unsigned char scalarmult_q_by_client[crypto_scalarmult_BYTES];
unsigned char scalarmult_q_by_server[crypto_scalarmult_BYTES];
unsigned char sharedkey_by_client[crypto_generichash_BYTES];
unsigned char sharedkey_by_server[crypto_generichash_BYTES];
crypto_generichash_state h;

/* Create client's secret and public keys */
randombytes_buf(client_secretkey, sizeof client_secretkey);
crypto_scalarmult_base(client_publickey, client_secretkey);

/* Create server's secret and public keys */
randombytes_buf(server_secretkey, sizeof server_secretkey);
crypto_scalarmult_base(server_publickey, server_secretkey);

/* The client derives a shared key from its secret key and the server's public key */
/* shared key = h(q ‖ client_publickey ‖ server_publickey) */
if (crypto_scalarmult(scalarmult_q_by_client, client_secretkey, server_publickey) != 0) {
    /* Error */
}
crypto_generichash_init(&h, NULL, 0U, crypto_generichash_BYTES);
crypto_generichash_update(&h, scalarmult_q_by_client, sizeof scalarmult_q_by_client);
crypto_generichash_update(&h, client_publickey, sizeof client_publickey);
crypto_generichash_update(&h, server_publickey, sizeof server_publickey);
crypto_generichash_final(&h, sharedkey_by_client, sizeof sharedkey_by_client);

/* The server derives a shared key from its secret key and the client's public key */
/* shared key = h(q ‖ client_publickey ‖ server_publickey) */
if (crypto_scalarmult(scalarmult_q_by_server, server_secretkey, client_publickey) != 0) {
    /* Error */
}
crypto_generichash_init(&h, NULL, 0U, crypto_generichash_BYTES);
crypto_generichash_update(&h, scalarmult_q_by_server, sizeof scalarmult_q_by_server);
crypto_generichash_update(&h, client_publickey, sizeof client_publickey);
crypto_generichash_update(&h, server_publickey, sizeof server_publickey);
crypto_generichash_final(&h, sharedkey_by_server, sizeof sharedkey_by_server);

/* sharedkey_by_client and sharedkey_by_server are identical */
```

## Constants

* `crypto_scalarmult_BYTES`
* `crypto_scalarmult_SCALARBYTES`

## Algorithm details

* X25519 \(ECDH over Curve25519\) - [RFC 7748](https://www.rfc-editor.org/rfc/rfc7748.txt)



