# Public-key cryptography

_Public-key cryptography_ refers to cryptographic systems that require two
different keys, linked together by some one-way mathematical relationship (which
depends on the algorithm used, but in any case the private key may never be
recovered from the public key).

Typically, the _private_ key is used to decrypt (and/or sign) a message, and the
_public_ key is used to encrypt a message (and/or authenticate it – that is,
check its signature). Before beginning communications, there must be a _key
exchange_ (every involved person send to other people their **public key**).

The private keys **_must remain private_**, otherwise everyone can impersonate
the owner of the _leaked_ private key, and everyone can decrypt private messages
supposedly sent only to him.

As long as no private key is leaked, the security of the system is ensured:
while everyone can check that a message really comes from a specific person
(_authenticity_), no one can fake it. In the same way, while everyone can
encrypt a message to some specific person, no one might decrypt it but this
person.

Before Alice and Bob can communicate privately and ensure trust, they have to
exchange their keys: Alice sends her **public** key to Bob, and Bob sends his
**public** key to Alice.

Now, Alice wants to send a message to Bob.

She encrypts it using Bob's public key, and adds an authentication tag using her
own private key. When Bob receives it, he will check the message's integrity and 
that it was signed by her key, then he will decrypt it using his own private key.

An adversary has to get hold of Alice or Bob's private keys in order to decrypt
this message, or construct a different, valid message.
