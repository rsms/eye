
@interface EyeMonitored : NSObject {
  NSMutableDictionary *configuration;
  BOOL monitored;
  FSEventStreamRef streamRef;
}

@property(readonly) BOOL monitored;
@property(assign) NSMutableDictionary *configuration;

// Proxy access to common configuration properties
@property(assign) NSString *path;
@property(assign) CFAbsoluteTime latency;
@property(assign) BOOL enabled;
@property(assign) NSString *name;


#pragma mark Helpers
+ (void)validateConfiguration:(NSDictionary *)plist;

#pragma mark Initializing
- (id)initWithConfiguration:(NSMutableDictionary *)plist;

#pragma mark Managing FSEventStreams
- (void)createFSEventStreamForPaths:(NSArray *)paths;
- (void)destroyFSEventStream;

#pragma mark Monitoring
- (void)startMonitoring;
- (void)stopMonitoring;
- (void)restartMonitoring;
- (void)monitoredDidChange:(NSNotification *)n; // Called whenever something has changed

@end
