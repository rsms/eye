#import "NSTask+EyeAdditions.h"

#define DRYFTW(sel) \
  NSData *data = [[[self sel] fileHandleForReading] availableData];\
  if (data != nil)\
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];\
  else\
    return @"";

@implementation NSTask (EyeAdditions)

-(NSString *)stringWithContentsOfStandardOutput {
  DRYFTW(standardOutput);
}

-(NSString *)stringWithContentsOfStandardError {
  DRYFTW(standardError);
}

@end
