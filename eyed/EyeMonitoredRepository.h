#import "EyeMonitored.h"

@interface EyeMonitoredRepository : EyeMonitored {
  NSString *identifier;
  NSOperationQueue *operations;
}

@property(readonly) NSString *identifier;
@property(readonly) NSOperationQueue *operations;

#pragma mark Initializing
- (id)initWithIdentifier:(NSString *)identifier configuration:(NSMutableDictionary *)plist;

#pragma mark Synchronizing
- (void)synchronizePath:(NSString *)path recursive:(BOOL)recursive;
- (void)synchronize;

@end
