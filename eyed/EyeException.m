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


+ (void)printStackTrace:(NSException *)e {
  NSString *stack = [[e userInfo] objectForKey:NSStackTraceKey];
  if (stack) {
    NSTask *ls = [[NSTask alloc] init];
    NSString *pid = [[NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]] stringValue];
    NSMutableArray *args = [NSMutableArray arrayWithCapacity:20];
    
    [args addObject:@"-p"];
    [args addObject:pid];
    [args addObjectsFromArray:[stack componentsSeparatedByString:@"  "]];
    // Note: function addresses are separated by double spaces, not a single space.
    
    [ls setLaunchPath:@"/usr/bin/atos"];
    [ls setArguments:args];
    [ls launch];
    [ls release];
  }
  //else { NSLog(@"(No stack trace available)"); }
}


@end
