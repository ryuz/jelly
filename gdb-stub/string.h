#ifndef __STRING_H
#define __STRING_H

extern void *memcpy (void *__dest, const void *__src, unsigned int __n);
extern char *strcpy (char *dest, __const char *__src);
extern int strlen (__const char *__s);
extern void * memset(void *__s, int __c, unsigned int __n);

#endif /* __STRING_H */
