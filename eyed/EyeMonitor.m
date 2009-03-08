#import "EyeMonitor.h"
#import "EyeMonitoredRepository.h"
#import "EyeException.h"

#undef SRC_MODULE
#define SRC_MODULE "monitor"

@implementation EyeMonitor

static EyeMonitor *_default = nil;


@synthesize operations;


+ (EyeMonitor *)defaultMonitor {
  if (_default == nil)
    _default = [[EyeMonitor alloc] init];
  return _default;
}


- (id)init {
  if (!(self = [super init]))
    return nil;
  
  configuration = [EyeMonitoredConfiguration defaultConfiguration];
  operations = [[NSOperationQueue alloc] init];
  
  return self;
}


- (void)run {
  log_info("Loading configuration");
  [configuration reload];
  
  // Activate auto-reloading of configurations
  [configuration startMonitoring];
  
  log_info("Registering repositories");
  NSEnumerator *en = [configuration.repositories objectEnumerator];
  for (EyeMonitoredRepository *repo in en) {
    [repo startMonitoring];
    [repo synchronize];
  }
  
  log_info("Entering runloop");
  [[NSRunLoop mainRunLoop] run];
  
  log_info("Shutting down -- flushing operation queue...");
  [operations cancelAllOperations];
  // todo: see if we can use int setitimer(3); to add timeout to this one
  [operations waitUntilAllOperationsAreFinished];
}


@end
