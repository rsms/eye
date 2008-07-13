#import "EyeMonitor.h"
#import "EyeMonitoredRepository.h"
#import "EyeException.h"

@implementation EyeMonitor

static EyeMonitor *_default = nil;


+ (EyeMonitor *)defaultMonitor {
  if (_default == nil)
    _default = [[EyeMonitor alloc] init];
  return _default;
}


- (id)init {
  if (!(self = [super init]))
    return nil;
  
  configuration = [EyeMonitoredConfiguration defaultConfiguration];
  
  return self;
}


- (void)run {
  log_info("Loading configuration");
  [configuration reload];
  
  // Activate auto-reloading of configurations
  [configuration startMonitoring];
  
  log_info("Registering repositories");
  NSEnumerator *en = [configuration.repositories objectEnumerator];
  for (EyeMonitoredRepository *repo in en)
    [repo startMonitoring];
  
  log_info("Entering runloop");
  [[NSRunLoop mainRunLoop] run];
}


@end
