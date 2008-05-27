#import "EyeMonitoredRepository.h"

@implementation EyeMonitoredRepository

@synthesize identifier;


#pragma mark -
#pragma mark Initializing

- (id)initWithIdentifier:(NSString *)ident configuration:(NSMutableDictionary *)plist {
  if (!(self = [super initWithConfiguration:plist]))
    return nil;
  
  identifier = ident;
  
  return self;
}


// xxx: todo: hg commit etc...

#pragma mark -
#pragma mark Monitoring

- (void)pathDidChange:(NSNotification *)n {
  log_debug(@"Yay! n = %@", n);
  assert([n object] == self);
}


#pragma mark -
#pragma mark Accessing attributes

// to string
- (NSString *)description {
  return [NSString stringWithFormat: @"<%@: %@ \"%@\" @%p>",
          NSStringFromClass(isa),
          self.enabled ? @"enabled" : @"disabled",
          self.identifier,
          self];
}

@end
