#import "EyeMonitored.h"

@interface EyeMonitoredRepository : EyeMonitored {
  NSString *identifier;
}

@property(readonly) NSString *identifier;

#pragma mark Initializing
- (id)initWithIdentifier:(NSString *)identifier configuration:(NSMutableDictionary *)plist;

#pragma mark Synchronizing
- (void)synchronize;

@end
