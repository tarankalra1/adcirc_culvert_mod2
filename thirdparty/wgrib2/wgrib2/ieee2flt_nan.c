#include <stdio.h>
#include <math.h>
#include "wgrib2.h"

/* wesley ebisuzaki v0.2
 *
 * takes 4 byte character string (single precision ieee big-endian)
 * and returns a float
 *
 * NaN, infinity are mapped into UNDEFINED.
 *
 * ansi C
 */

float ieee2flt_nan(unsigned char *ieee) {
	double fmant;
	int exp;

        if ((ieee[0] & 127) == 0 && ieee[1] == 0 && ieee[2] == 0 && ieee[3] == 0)
	   return (float) 0.0;

	exp = ((ieee[0] & 127) << 1) + (ieee[1] >> 7);

	if (exp == 255) return (float) UNDEFINED;

	fmant = (double) ((int) ieee[3] + (int) (ieee[2] << 8) + 
              (int) ((ieee[1] | 128) << 16));
	if (ieee[0] & 128) fmant = -fmant;


	return (float) (ldexp(fmant, (int) (exp - 128 - 22)));
}
