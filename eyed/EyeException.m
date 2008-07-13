#import "EyeException.h"
#import <ExceptionHandling/ExceptionHandling.h>

@implementation EyeException


+ (void)raise:(NSString *)format, ... {
  EyeException *e;
  NSDictionary *_userInfo;
  va_list args;
  NSString *_reason;
  
  va_start(args, format);
  _reason = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
  va_end(args);
  _userInfo = nil;
  e = [[[self class] alloc] initWithName:NSStringFromClass([self class])
                                  reason:_reason
                                userInfo:_userInfo];
  return [[e autorelease] raise];
}


+ (NSString *)stackTrace:(NSException *)e {
  NSString *stack = [[e userInfo] objectForKey:NSStackTraceKey];
  //static NSString *atos = @"/usr/bin/atos";
  if (stack) {
    return [stack stringByReplacingOccurrencesOfString:@"  " withString:@"\n"];
    /*if ([[NSFileManager defaultManager] fileExistsAtPath:atos]) {
      NSTask *ls = [[NSTask alloc] init];
      NSString *pid = [[NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]] stringValue];
      NSMutableArray *args = [NSMutableArray array];
      [args addObject:@"-p"];
      [args addObject:pid];
      [args addObjectsFromArray:[stack componentsSeparatedByString:@"  "]]; // double spaces, not a single space.
      [ls setLaunchPath:atos];
      [ls setArguments:args];
      [ls setStandardOutput:]
      [ls launch];
      [ls release];
    }*/
  }
  return nil;
}


+ (void)printStackTrace:(NSException *)e {
  NSLog(@"%@", [self stackTrace:e]);
}


@end
