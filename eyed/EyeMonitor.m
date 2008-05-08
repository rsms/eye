#import "EyeMonitor.h"
#import "EyeMonitoredRepository.h"

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
  [configuration reload];
  
  return self;
}


- (void)run {
  NSEnumerator *en = [configuration.repositories objectEnumerator];
  for (EyeMonitoredRepository *repo in en)
    [repo startMonitoring];
  log_info(@"Entering runloop");
  [[NSRunLoop mainRunLoop] run];
}


@end
