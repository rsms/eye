#import "EyeMonitored.h"

@interface EyeMonitoredRepository : EyeMonitored {
  NSString *identifier;
  NSTask *sync_task;
}

@property(readonly) NSString *identifier;

#pragma mark Initializing
- (id)initWithIdentifier:(NSString *)identifier configuration:(NSMutableDictionary *)plist;

#pragma mark Synchronizing
- (void)synchronizePath:(NSString *)path recursive:(BOOL)recursive;
- (void)synchronizationTaskDidEnd:(NSNotification *)n;

@end
