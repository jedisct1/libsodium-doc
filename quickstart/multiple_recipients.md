# Multiple recipients

A message encrypted using a shared secret doesn’t authenticate the sender: anyone with a key can pretend to be the author of any message encrypted using that key.

This is usually not an issue when only two parties are involved.

However, it can become a concern for group communications, where a single key is shared by multiple recipients:.

Signatures can prove the identity of a sender. In order to prove the identity of a sender for messages encrypted using shared secrets, signatures can thus be combined with encryption.

The recommended approach is to:

  - Sign the message, as well as the context of the message: the identity of the sender, the identity of the recipient, and a message identifier (ex: uid, timestamp).
  - Encrypt and authenticate the message and its signature.

While, under some circumstances, a single key pair could be used both for signing and encryption, this is neither recommended nor usually necessary. In libsodium, signature and encryption public keys are only 32 bytes long, and these two kind of public keys can be encoded as a compound 64 byte key.

  - `sender_kx.pk`: the sender’s public key used to compute a shared secret
  - `sender_kx.sk`: the sender’s secret key used to compute a shared secret
  - `recipient_kx.pk`: the recipient’s public key for signature verification
  - `recipient_kx.sk`: the recipient’s secret key for signing

<!-- end list -->

``` c
static int crypto_sign_with_id(unsigned char *signed_msg, const unsigned char *msg, size_t msg_len,
                               const unsigned char *sender_info, size_t sender_info_len,
                               const unsigned char *recipient_info, size_t recipient_info_len,
                               const unsigned char *info, size_t info_len,
                               const unsigned char client_sign_sk[crypto_sign_SECRETKEYBYTES])
{
    crypto_sign_state st;

    if (msg != signed_msg && msg_len > 0) {
        memmove(signed_msg, msg, msg_len);
    }
    crypto_sign_init(&st);
    crypto_sign_update(&st, sender_info, sender_info_len);
    crypto_sign_update(&st, recipient_info, recipient_info_len);
    crypto_sign_update(&st, info, info_len);
    crypto_sign_update(&st, msg, msg_len);

    return crypto_sign_final_create(&st, &signed_msg[msg_len], NULL, client_sign_sk);
}

static int
crypto_sign_verify_with_id(const unsigned char *signed_msg, size_t signed_msg_len,
                           const unsigned char *sender_info, size_t sender_info_len,
                           const unsigned char *recipient_info, size_t recipient_info_len,
                           const unsigned char *info, size_t info_len,
                           const unsigned char client_sign_pk[crypto_sign_PUBLICKEYBYTES])
{
    crypto_sign_state st;

    if (signed_msg_len < crypto_sign_BYTES) {
        return -1;
    }
    crypto_sign_init(&st);
    crypto_sign_update(&st, sender_info, sender_info_len);
    crypto_sign_update(&st, recipient_info, recipient_info_len);
    crypto_sign_update(&st, info, info_len);
    crypto_sign_update(&st, signed_msg, signed_msg_len - crypto_sign_BYTES);

    return crypto_sign_final_verify(&st, &signed_msg[signed_msg_len - crypto_sign_BYTES],
                                    client_sign_pk);
}
```

``` c

typedef struct KXKeyPair_ {
    unsigned char pk[crypto_kx_PUBLICKEYBYTES], sk[crypto_kx_SECRETKEYBYTES];
} KXKeyPair;

typedef struct SignKeyPair_ {
    unsigned char pk[crypto_sign_PUBLICKEYBYTES], sk[crypto_sign_SECRETKEYBYTES];
} SignKeyPair;

#define MSG (const unsigned char *) "test"
#define MSG_LEN (sizeof "test" - 1)

static void create_key_pairs(KXKeyPair *sender_kx, KXKeyPair *recipient_kx,
                             SignKeyPair *sender_sign, SignKeyPair *recipient_sign)
{
    crypto_kx_keypair(sender_kx->pk, sender_kx->sk);
    crypto_kx_keypair(recipient_kx->pk, recipient_kx->sk);
    crypto_sign_keypair(sender_sign->pk, sender_sign->sk);
    crypto_sign_keypair(recipient_sign->pk, recipient_sign->sk);
}

int main(void)
{
    KXKeyPair     sender_kx, recipient_kx;
    SignKeyPair   sender_sign, recipient_sign;
    unsigned char sender_encrypt_k[crypto_kx_SESSIONKEYBYTES];
    unsigned char signed_encrypted_msg[MSG_LEN + crypto_sign_BYTES + crypto_box_MACBYTES];
    unsigned char signed_decrypted_msg[MSG_LEN + crypto_sign_BYTES];
    unsigned char nonce[crypto_box_NONCEBYTES];

    if (sodium_init() != 0) {
        return 1;
    }
    create_key_pairs(&sender_kx, &recipient_kx, &sender_sign, &recipient_sign);

    /* sender-side */

    if (crypto_kx_client_session_keys(sender_encrypt_k, NULL, sender_kx.pk, sender_kx.sk,
                                      recipient_kx.pk) != 0) {
        return 1;
    }
    /* sign then encrypt */
    if (crypto_sign_with_id(signed_encrypted_msg, MSG, MSG_LEN, sender_kx.pk, sizeof sender_kx.pk,
                            recipient_kx.pk, sizeof recipient_kx.pk, nonce, sizeof nonce,
                            sender_sign.sk) != 0 ||
        crypto_secretbox_easy(signed_encrypted_msg, signed_encrypted_msg,
                              MSG_LEN + crypto_sign_BYTES, nonce, sender_encrypt_k) != 0) {
        return 1;
    }

    /* recipient-side */

    if (crypto_kx_server_session_keys(NULL, sender_encrypt_k, recipient_kx.pk, recipient_kx.sk,
                                      sender_kx.pk) != 0) {
        return 1;
    }
    /* decrypt then verify the signature */
    if (crypto_secretbox_open_easy(signed_decrypted_msg, signed_encrypted_msg,
                                   MSG_LEN + crypto_sign_BYTES + crypto_box_MACBYTES, nonce,
                                   sender_encrypt_k) != 0 ||
        crypto_sign_verify_with_id(signed_decrypted_msg, MSG_LEN + crypto_sign_BYTES, sender_kx.pk,
                                   sizeof sender_kx.pk, recipient_kx.pk, sizeof recipient_kx.pk,
                                   nonce, sizeof nonce, sender_sign.pk) != 0) {
        return 1;
    }
    return 0;
}
```

But group messaging is complex topic. [RFC9420](https://datatracker.ietf.org/doc/rfc9420/) is a proper approach.
