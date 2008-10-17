/* $Id: string.c,v 1.1 2008/10/05 00:48:48 ryuji Exp $ */

#include <stddef.h>

size_t
strlen(const char * s)
{
	const char *t;
	for (t = s; *t; t++);
	return t - s;
}


void *
memset(void *s, int c, size_t count)
{
	char *t = (char *)s;
	while (count-- > 0)
		*t++ = c;
	return s;
}


void *
memcpy(void *dest, const void *src, size_t count)
{
	char *t = (char *)dest, *s = (char *)src;
	while (count-- > 0)
		*t++ = *s++;
	return dest;
}
