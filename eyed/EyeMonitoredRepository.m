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

- (void)synchronizePath:(NSString *)path recursive:(BOOL)recursive {
  char cmd_buf[PATH_MAX*2];
  static char cmd_hgst[] = "/usr/local/bin/hg -v -y --cwd '%s' ci -A -m eyed:auto";
  
  log_debug(@"Synchronizing %@ based on:\n  path      = %@\n  recursive = %@",
            self,
            path,
            recursive ? @"YES" : @"NO");
  
  // xxx: redo this using NSTask
  // xxx: cache <key path> => <value mtime> and only run this if path has changed.
  
  cmd_buf[0] = 0;
  snprintf(cmd_buf, PATH_MAX*2, cmd_hgst, [path UTF8String]);
  log_debug(@"%@ system(\"%s\")", self, cmd_buf);
  int pstat = system(cmd_buf);
  log_debug(@"%@ system() returned %d", self, pstat);
}


#pragma mark -
#pragma mark Monitoring

- (void)monitoredDidChange:(NSNotification *)n {
  NSString *path;
  NSDictionary *info;
  BOOL recursive;
  
  if ([n object] != self) {
    log_warn(@"Unexpected notification received destined for someone else. (object = %@)", [n object]);
    return;
  }
  
  info = [n userInfo];
  path = [info objectForKey:@"path"];
  recursive = [(NSNumber *)[info objectForKey:@"recursive"] boolValue];
  
  [self synchronizePath:path recursive:recursive];
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
