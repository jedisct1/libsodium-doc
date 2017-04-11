# Public-key cryptography

*Public-key cryptography* refers to cryptographic systems that require two different keys, linked together by some one-way mathematical relationship (which depends on the algorithm used, but in any case the private key may never be recovered from the public key).

Typically, the *private* key is used to decrypt (and/or sign) a message, and the *public* key is used to encrypt a message (and/or authenticate it – that is, check its signature). Before beginning communications, there must be a *key exchange* (every involved person send to other people their **public key**).

The private keys ***must remain private***, otherwise everyone can impersonate the owner of the *leaked* private key, and everyone can decrypt private messages supposedly sent only to him.

As long as no private key is leaked, the security of the system is ensured: while everyone can check that a message really comes from a specific person (*authenticity*), no one can fake it. In the same way, while everyone can encrypt a message to some specific person, no one might decrypt it but this person.

To make things clearer, let's take Alice & Bob (as usual), who are lovers. Before they can communicate privately and ensure trust, they have to exchange their keys: Alice sends her **public** key to Bob, and Bob sends his **public** key to Alice. Now, Alice wants to send a message to Bob. 

She encrypts it using Bob's public key, and then signs it using her own private key. When Bob receives it, he will first check the message's *integrity*<sup>[1](#footnote1)</sup>, then its *authenticity*<sup>[2](#footnote2)</sup>, then he will decrypt it using his own private key. Now let's say Eve, Bob's jealous wife, wants to spy on the lovers.

She has to get hold of both Alice and Bob's private keys in order to do so. Otherwise, the security of the system is ensured, and she may not send a fake message nor read any of them.

<a name="footnote1"><sup>1</sup></a> i.e. that the message has not been altered, accidentally or not, during transfer. Remember when we talked about ensuring trust? That's the first part.

<a name="footnote2"><sup>2</sup></a> i.e. that the message really comes from Alice. That's the second part of "trust.”
