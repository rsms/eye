
@interface EyeMonitored : NSObject {
  NSMutableDictionary *configuration;
  BOOL monitored;
}

@property(readonly) BOOL monitored;
@property(assign) NSMutableDictionary *configuration;

// Proxy access to common configuration properties
@property(assign) NSString *path;
@property(assign) CFAbsoluteTime latency;
@property(assign) BOOL enabled;

#pragma mark Helpers
+ (void)validateConfiguration:(NSDictionary *)plist;

#pragma mark Initializing
- (id)initWithConfiguration:(NSMutableDictionary *)plist;

#pragma mark Monitoring
- (void)startMonitoring;
- (void)stopMonitoring;
- (void)restartMonitoring;

@end
