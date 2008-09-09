#import "EyeMonitored.h"
#import "EyeException.h"
#import "NSError+EyeAdditions.h"


// All fsevents are handled through this function which dispatches objc messages
static void _fsevents_callback(FSEventStreamRef streamRef,
                               void *obj,
                               size_t num_events,
                               const char *const event_paths[],
                               const FSEventStreamEventFlags *event_masks,
                               const FSEventStreamEventId event_ids[])
{
  FSEventStreamEventId event_id;
  EyeMonitored *monitored = nil;
  NSString *path = nil;
  int recursive = 0;
  
  if (!obj) {
    log_crit("_fsevents_callback() called with NULL obj");
    return;
  }
  
  monitored = (EyeMonitored *)obj;
  
  log_debug("streamRef = %p, num_events = %ld", streamRef, num_events);
  
  // For each event, dispatch a notification
  for (size_t i=0; i < num_events; i++) {
    path = [NSString stringWithUTF8String:event_paths[i]];
    
    // Skip .hg dirs
    if (strstr(event_paths[i], "/.hg")) {
      log_info("Skipped change to .hg directory");
      continue;
    }
    
    event_id = event_ids[i];
    
    log_info("Dispatching event %llx (%d of %d) \"%s\"", event_id, i+1, num_events, [path UTF8String]);
    
    if (event_masks[i] & kFSEventStreamEventFlagMustScanSubDirs) {
      log_debug("MustScanSubDirs flag set -- performing a full rescan");
      recursive = 1;
    }
    else if (event_masks[i] & kFSEventStreamEventFlagUserDropped) {
      log_warn("We dropped events -- forcing a full rescan");
      recursive = 1;
    }
    else if (event_masks[i] & kFSEventStreamEventFlagKernelDropped) {
      log_warn("Kernel dropped events -- forcing a full rescan");
      recursive = 1;
    }
    
    // Set to base path if recursive
    if (recursive)
      path = monitored.path;
    
    // Construct event info
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          path,                                     @"path",
                          [NSNumber numberWithLongLong:event_id],   @"id",
                          [NSNumber numberWithLong:event_masks[i]], @"mask",
                          [NSNumber numberWithBool:recursive],      @"recursive",
                          nil];
    
    // Dispatch
    [[NSNotificationCenter defaultCenter] postNotificationName:EyeMonitoredDidChangeNotification
                                                        object:monitored
                                                      userInfo:info];
  }
}



@interface EyeMonitored (Private)
- (id)_init;
@end


@implementation EyeMonitored

#pragma mark -
#pragma mark Helpers

+ (void)validateConfiguration:(NSDictionary *)plist {
  if([plist objectForKey:@"path"] == nil)
    [EyeException raise:@"Monitored configuration validation failed: Missing path key in configuration"];
}


#pragma mark -
#pragma mark Initializing

- (id)_init {
  if (!(self = [super init]))
    return nil;
  
  // Initialize members
  streamRef = nil;
  configuration = nil;
  
  // Register for notifications
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc addObserver:self
         selector:@selector(monitoredDidChange:)
             name:EyeMonitoredDidChangeNotification
           object:self];
  
  return self;
}


- (id)initWithConfiguration:(NSMutableDictionary *)plist {
  if (![self _init])
    return nil;
  configuration = plist;
  return self;
}


- (id)init {
  if (![self _init])
    return nil;
  configuration = [NSMutableDictionary dictionary];
  return self;
}


#pragma mark -
#pragma mark Managing FSEventStreams


- (void)createFSEventStreamForPaths:(NSArray *)paths {
  FSEventStreamEventId since_when = kFSEventStreamEventIdSinceNow;
  FSEventStreamContext context = {0, (void *)self, NULL, NULL, NULL};
  FSEventStreamEventFlags flags = 0;
  
  streamRef = FSEventStreamCreate(kCFAllocatorDefault,
                                  (FSEventStreamCallback)&_fsevents_callback,
                                  &context,
                                  (CFArrayRef)paths,
                                  since_when,
                                  self.latency,
                                  flags);
  
  if (NULL == streamRef)
    [EyeException raise:@"FSEventStreamCreate(7) failed"];
  
  // Print the setup
  log_info("Created stream %p", streamRef);
  IFDEBUG(FSEventStreamShow(streamRef));
}


- (void)destroyFSEventStream {
  assert(streamRef != NULL);
  FSEventStreamInvalidate(streamRef);
  FSEventStreamRelease(streamRef);
  streamRef = NULL;
}


#pragma mark -
#pragma mark Monitoring


- (void)startMonitoring {
  if (!self.enabled) {
    //log_debug(@"%@ is not enabled. Will not start.", self);
    return;
  }
  
  if (monitored) {
    //log_debug(@"%@ is already being monitored. Will not start.", self);
    return;
  }
  
  // Normalize path
  self.path = [self.path stringByStandardizingPath];
  
  log_notice("Starting %s", [[self description] UTF8String]);
  
  // Create FSEventStream
  [self createFSEventStreamForPaths:[NSArray arrayWithObject:self.path]];
  
  // Schedule it on a runloop
  FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  
  // Start it
  if (!FSEventStreamStart(streamRef))
    [EyeException raise:@"FSEventStreamStart(streamRef) failed"];
  
  monitored = YES;
}


- (void)monitoredDidChange:(NSNotification *)n {
  // Override in subclasses
}


- (void)stopMonitoring {
  if (!monitored) {
    log_info("%s was asked to stop, but is not monitored. Not taking any action.",
             [[self description] UTF8String]);
    return;
  }
  
  assert(streamRef != NULL);
  
  log_notice("Stopping %s", [[self description] UTF8String]);
  FSEventStreamStop(streamRef);
  [self destroyFSEventStream];
  
  monitored = NO;
}


- (void)restartMonitoring {
  if (self.monitored)
    [self stopMonitoring];
  
  if (self.enabled)
    [self startMonitoring];
}


#pragma mark -
#pragma mark Accessing attributes


@synthesize monitored;


- (NSMutableDictionary *)configuration {
  return configuration;
}

- (void)setConfiguration:(NSMutableDictionary *)plist {
  if (![plist isEqualToDictionary:configuration]) {
    log_notice("Configuration changed for %s", [[self description] UTF8String]);
#ifdef DEBUG
    log_debug("Configuration diff for %s\n"
              "previous = %s\n"
              "new = %s",
              [[self description] UTF8String],
              [[configuration description] UTF8String],
              [[plist description] UTF8String]);
#endif
    configuration = plist;
    [self restartMonitoring];
  }
  else {
    // We need to set it either way, as the dict itself might be another object.
    configuration = plist;
  }
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

// to string
- (NSString *)description {
  return [NSString stringWithFormat: @"<%@: %@ \"%@\" @%p>",
          NSStringFromClass(isa),
          self.enabled ? @"enabled" : @"disabled",
          self.path,
          self];
}


@end
