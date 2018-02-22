/**
 * Utility class to calculate SHA1 hash of some input. This is not thread-safe
 */
class Sha1HashLib extends HashLib;

/**
 * Stores the last result
 */
var private int hash[5];

var private string hashString;

var private array<byte> data;

function string getAlgName()
{
	return "sha1";
}

function string getHash(coerce string inputData)
{
	local int strlen, char, i;
	hashString = "";

	// convert the input string
	data.length = 0;
	strlen = Len(inputData);
	for (i = 0; i < strlen; ++i)
	{
		char = Asc(Mid(inputData, i, 1));
		do {
			data[data.length] = byte(char & 0xFF);
			char = char >>> 8;
		} until (char == 0);
	}

	calcHash();
	data.length = 0;
	return hashString;
}

private final function calcHash()
{
	local int i, chunk, tmp;
  	local int a, b, c, d, e;
  	local int w[80];

  	// initialize the result
	hash[0] = 0x67452301;
	hash[1] = 0xEFCDAB89;
	hash[2] = 0x98BADCFE;
	hash[3] = 0x10325476;
	hash[4] = 0xC3D2E1F0;

	// initialize the data
  	i = data.length;
	if (i % 64 < 56)
	{
		data.length = data.length + 64 - i % 64;
	}
	else {
		data.length = data.length + 128 - i % 64;
	}
	data[i] = 0x80;
	data[data.length - 5] = i >>> 29;
	data[data.length - 4] = i >>> 21;
	data[data.length - 3] = i >>> 13;
	data[data.length - 2] = i >>> 5;
	data[data.length - 1] = i << 3;

	// the transformation stuff
	while (chunk * 64 < data.length) {

		for (i = 0; i < 16; i++) {
			w[i] = (data[chunk * 64 + i * 4] << 24)
					| (data[chunk * 64 + i * 4 + 1] << 16)
					| (data[chunk * 64 + i * 4 + 2] << 8)
					| data[chunk * 64 + i * 4 + 3];
		}

		for (i = 16; i < 80; i++) {
			tmp = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16];
			w[i] = (tmp << 1) | (tmp >>> 31);
		}

		a = hash[0];
    	b = hash[1];
    	c = hash[2];
    	d = hash[3];
    	e = hash[4];

		// Round 1
		e += ((a << 5) | (a >>> -5)) + (d ^ (b & (c ^ d))) + w[ 0] + 0x5A827999;		b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (c ^ (a & (b ^ c))) + w[ 1] + 0x5A827999;		a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (b ^ (e & (a ^ b))) + w[ 2] + 0x5A827999;		e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (a ^ (d & (e ^ a))) + w[ 3] + 0x5A827999;		d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (e ^ (c & (d ^ e))) + w[ 4] + 0x5A827999;		c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + (d ^ (b & (c ^ d))) + w[ 5] + 0x5A827999;		b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (c ^ (a & (b ^ c))) + w[ 6] + 0x5A827999;		a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (b ^ (e & (a ^ b))) + w[ 7] + 0x5A827999;		e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (a ^ (d & (e ^ a))) + w[ 8] + 0x5A827999;		d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (e ^ (c & (d ^ e))) + w[ 9] + 0x5A827999;		c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + (d ^ (b & (c ^ d))) + w[10] + 0x5A827999;		b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (c ^ (a & (b ^ c))) + w[11] + 0x5A827999;		a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (b ^ (e & (a ^ b))) + w[12] + 0x5A827999;		e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (a ^ (d & (e ^ a))) + w[13] + 0x5A827999;		d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (e ^ (c & (d ^ e))) + w[14] + 0x5A827999;		c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + (d ^ (b & (c ^ d))) + w[15] + 0x5A827999;		b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (c ^ (a & (b ^ c))) + w[16] + 0x5A827999;		a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (b ^ (e & (a ^ b))) + w[17] + 0x5A827999;		e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (a ^ (d & (e ^ a))) + w[18] + 0x5A827999;		d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (e ^ (c & (d ^ e))) + w[19] + 0x5A827999;		c = (c << 30) | (c >>> -30);

		// Round 2
		e += ((a << 5) | (a >>> -5)) + (b ^ c ^ d) + w[20] + 0x6ED9EBA1;				b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (a ^ b ^ c) + w[21] + 0x6ED9EBA1;				a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (e ^ a ^ b) + w[22] + 0x6ED9EBA1;				e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (d ^ e ^ a) + w[23] + 0x6ED9EBA1;				d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (c ^ d ^ e) + w[24] + 0x6ED9EBA1;				c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + (b ^ c ^ d) + w[25] + 0x6ED9EBA1;				b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (a ^ b ^ c) + w[26] + 0x6ED9EBA1;				a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (e ^ a ^ b) + w[27] + 0x6ED9EBA1;				e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (d ^ e ^ a) + w[28] + 0x6ED9EBA1;				d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (c ^ d ^ e) + w[29] + 0x6ED9EBA1;				c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + (b ^ c ^ d) + w[30] + 0x6ED9EBA1;				b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (a ^ b ^ c) + w[31] + 0x6ED9EBA1;				a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (e ^ a ^ b) + w[32] + 0x6ED9EBA1;				e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (d ^ e ^ a) + w[33] + 0x6ED9EBA1;				d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (c ^ d ^ e) + w[34] + 0x6ED9EBA1;				c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + (b ^ c ^ d) + w[35] + 0x6ED9EBA1;				b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (a ^ b ^ c) + w[36] + 0x6ED9EBA1;				a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (e ^ a ^ b) + w[37] + 0x6ED9EBA1;				e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (d ^ e ^ a) + w[38] + 0x6ED9EBA1;				d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (c ^ d ^ e) + w[39] + 0x6ED9EBA1;				c = (c << 30) | (c >>> -30);

		// Round 3
		e += ((a << 5) | (a >>> -5)) + ((b & c) | (d & (b | c))) + w[40] + 0x8F1BBCDC;	b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + ((a & b) | (c & (a | b))) + w[41] + 0x8F1BBCDC;	a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + ((e & a) | (b & (e | a))) + w[42] + 0x8F1BBCDC;	e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + ((d & e) | (a & (d | e))) + w[43] + 0x8F1BBCDC;	d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + ((c & d) | (e & (c | d))) + w[44] + 0x8F1BBCDC;	c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + ((b & c) | (d & (b | c))) + w[45] + 0x8F1BBCDC;	b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + ((a & b) | (c & (a | b))) + w[46] + 0x8F1BBCDC;	a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + ((e & a) | (b & (e | a))) + w[47] + 0x8F1BBCDC;	e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + ((d & e) | (a & (d | e))) + w[48] + 0x8F1BBCDC;	d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + ((c & d) | (e & (c | d))) + w[49] + 0x8F1BBCDC;	c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + ((b & c) | (d & (b | c))) + w[50] + 0x8F1BBCDC;	b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + ((a & b) | (c & (a | b))) + w[51] + 0x8F1BBCDC;	a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + ((e & a) | (b & (e | a))) + w[52] + 0x8F1BBCDC;	e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + ((d & e) | (a & (d | e))) + w[53] + 0x8F1BBCDC;	d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + ((c & d) | (e & (c | d))) + w[54] + 0x8F1BBCDC;	c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + ((b & c) | (d & (b | c))) + w[55] + 0x8F1BBCDC;	b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + ((a & b) | (c & (a | b))) + w[56] + 0x8F1BBCDC;	a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + ((e & a) | (b & (e | a))) + w[57] + 0x8F1BBCDC;	e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + ((d & e) | (a & (d | e))) + w[58] + 0x8F1BBCDC;	d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + ((c & d) | (e & (c | d))) + w[59] + 0x8F1BBCDC;	c = (c << 30) | (c >>> -30);

		// Round 4
		e += ((a << 5) | (a >>> -5)) + (b ^ c ^ d) + w[60] + 0xCA62C1D6;				b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (a ^ b ^ c) + w[61] + 0xCA62C1D6;				a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (e ^ a ^ b) + w[62] + 0xCA62C1D6;				e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (d ^ e ^ a) + w[63] + 0xCA62C1D6;				d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (c ^ d ^ e) + w[64] + 0xCA62C1D6;				c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + (b ^ c ^ d) + w[65] + 0xCA62C1D6;				b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (a ^ b ^ c) + w[66] + 0xCA62C1D6;				a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (e ^ a ^ b) + w[67] + 0xCA62C1D6;				e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (d ^ e ^ a) + w[68] + 0xCA62C1D6;				d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (c ^ d ^ e) + w[69] + 0xCA62C1D6;				c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + (b ^ c ^ d) + w[70] + 0xCA62C1D6;				b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (a ^ b ^ c) + w[71] + 0xCA62C1D6;				a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (e ^ a ^ b) + w[72] + 0xCA62C1D6;				e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (d ^ e ^ a) + w[73] + 0xCA62C1D6;				d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (c ^ d ^ e) + w[74] + 0xCA62C1D6;				c = (c << 30) | (c >>> -30);

		e += ((a << 5) | (a >>> -5)) + (b ^ c ^ d) + w[75] + 0xCA62C1D6;				b = (b << 30) | (b >>> -30);
		d += ((e << 5) | (e >>> -5)) + (a ^ b ^ c) + w[76] + 0xCA62C1D6;				a = (a << 30) | (a >>> -30);
		c += ((d << 5) | (d >>> -5)) + (e ^ a ^ b) + w[77] + 0xCA62C1D6;				e = (e << 30) | (e >>> -30);
		b += ((c << 5) | (c >>> -5)) + (d ^ e ^ a) + w[78] + 0xCA62C1D6;				d = (d << 30) | (d >>> -30);
		a += ((b << 5) | (b >>> -5)) + (c ^ d ^ e) + w[79] + 0xCA62C1D6;				c = (c << 30) | (c >>> -30);

		hash[0] += A;
		hash[1] += B;
		hash[2] += C;
		hash[3] += D;
		hash[4] += E;

		chunk++;
	}

	hashString = ToHex(hash[0])$ToHex(hash[1])$ToHex(hash[2])$ToHex(hash[3])$ToHex(hash[4]);
}
