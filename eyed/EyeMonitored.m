#import "EyeMonitored.h"
#import "EyeException.h"

@implementation EyeMonitored

#pragma mark -
#pragma mark Helpers

+ (void)validateConfiguration:(NSDictionary *)plist {
  if([plist objectForKey:@"path"] == nil)
    [EyeException raise:@"Missing path key in configuration"];
}


#pragma mark -
#pragma mark Initializing

- (id)initWithConfiguration:(NSMutableDictionary *)plist {
  if (!(self = [super init]))
    return nil;
  self.configuration = plist;
  return self;
}


- (id)init {
  if (!(self = [super init]))
    return nil;
  self.configuration = [NSMutableDictionary dictionary];
  return self;
}


#pragma mark -
#pragma mark Monitoring


- (void)startMonitoring {
  if (!self.enabled)
    return;
  if (monitored)
    [EyeException raise:@"%@ is already being monitored", self];
  
  // Normalize path
  self.path = [self.path stringByStandardizingPath];
  
  // do...
}


- (void)stopMonitoring {
  if (!monitored)
    return;
  
  // do...
}


- (void)restartMonitoring {
  if (!self.enabled || !monitored)
    return;
  
  [self stopMonitoring];
  [self startMonitoring]; // start stream, based on current configuration.
}


#pragma mark -
#pragma mark Properties


@synthesize monitored;


- (NSMutableDictionary *)configuration {
  return configuration;
}

- (void)setConfiguration:(NSMutableDictionary *)plist {
  configuration = plist;
  [self restartMonitoring];
}


- (NSString *)path {
  return [configuration objectForKey:@"path"];
}

- (void)setPath:(NSString *)path {
  return [configuration setObject:path forKey:@"path"];
}


- (BOOL)enabled {
  NSNumber *n = (NSNumber *)[configuration objectForKey:@"enabled"];
  return n ? [n boolValue] : YES;
}

- (void)setEnabled:(BOOL)enabled {
  return [configuration setObject:[NSNumber numberWithBool:enabled] forKey:@"enabled"];
}


- (CFAbsoluteTime)latency {
  NSNumber *n = (NSNumber *)[configuration objectForKey:@"latency"];
  return n ? (CFAbsoluteTime)[n doubleValue] : YES;
}

- (void)setLatency:(CFAbsoluteTime)latency {
  return [configuration setObject:[NSNumber numberWithDouble:(double)latency] forKey:@"latency"];
}


@end
