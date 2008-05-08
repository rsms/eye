#import "EyeMonitoredConfiguration.h"

@interface EyeMonitor : NSObject {
  EyeMonitoredConfiguration *configuration;
}

+ (EyeMonitor *)defaultMonitor;

- (void)run;

@end
