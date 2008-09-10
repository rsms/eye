#ifndef MACROS_H
#define MACROS_H

#define __FILENAME__ ((strrchr(__FILE__, '/') ?: __FILE__ - 1) + 1)

#if DEBUG
  #define IFDEBUG(x) x
#else
  #define IFDEBUG(x)
#endif

#define str2utf8(obj) [obj UTF8String]
#define obj2utf8(obj) [[obj description] UTF8String]

#endif
