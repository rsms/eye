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


#pragma mark -
#pragma mark Synchronizing

- (void)synchronize {
  char cmd_buf[PATH_MAX*2];
  static char cmd_hgst[] = "/usr/local/bin/hg -v -y --cwd '%s' ci -A -m eyed:auto";
  
  cmd_buf[0] = 0;
  snprintf(cmd_buf, PATH_MAX*2, cmd_hgst, [self.path UTF8String]);
  log_debug(@"%@ system(\"%s\")", self, cmd_buf);
  int pstat = system(cmd_buf);
  log_debug(@"%@ system() returned %d", self, pstat);
}


#pragma mark -
#pragma mark Monitoring

- (void)monitoredDidChange:(NSNotification *)n {
  if ([n object] != self) {
    log_warn(@"Unexpected notification received destined for someone else. (object = %@)", [n object]);
    return;
  }
  
  NSDictionary *info = [n userInfo];
  
  log_debug(@"Synchronizing %@ based on:\n  path      = %@\n  recursive = %@",
            self,
            [info objectForKey:@"path"],
            [(NSNumber *)[info objectForKey:@"recursive"] boolValue] ? @"YES" : @"NO");
  
  [self synchronize];
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
