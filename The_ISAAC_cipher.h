// https://rosettacode.org/wiki/The_ISAAC_cipher
#ifndef THE_ISAAC_CIPHER_H
#define THE_ISAAC_CIPHER_H

// maximum length of message
#define MAXMSG 4096
#define MOD 95
#define START 32
// cipher modes for Caesar
enum ciphermode {
	mEncipher, mDecipher, mNone 
};

void iSeed(const char *seed, int flag);
const char* Vernam(const char *msg);
const char* CaesarStr(enum ciphermode m, const char *msg, char modulo, char start);

#endif // THE_ISAAC_CIPHER_H
