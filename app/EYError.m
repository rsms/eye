#import "EYError.h"

@implementation EYError

@synthesize description;

+ (NSError *)errorWithDescription:(NSString *)msg {
  EYError *e = [[EYError alloc] initWithDomain:@"se.hunch.eye"
                                          code:0
                                      userInfo:nil];
  e.description = msg;
  return e;
}

- (NSString *)localizedDescription {
  return self.description;
}

@end
