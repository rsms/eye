#import "EyeMonitored.h"

@interface EyeMonitoredRepository : EyeMonitored {
  NSString *identifier;
}

@property(readonly) NSString *identifier;

- (id)initWithIdentifier:(NSString *)identifier configuration:(NSMutableDictionary *)plist;

@end
