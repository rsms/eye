#import "EyeMonitoredConfiguration.h"

@interface EyeMonitor : NSObject {
  EyeMonitoredConfiguration *configuration;
  NSOperationQueue *operations;
}

@property(readonly) NSOperationQueue *operations;

+ (EyeMonitor *)defaultMonitor;

- (void)run;

@end
