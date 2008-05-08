#import "EyeMonitored.h"

@interface EyeMonitoredConfiguration : EyeMonitored {
  NSMutableDictionary *repositories; /// EyeMonitoredRepository keyed by it's path
}

@property(assign) NSMutableDictionary *repositories;

#pragma mark Helpers
+ (EyeMonitoredConfiguration *)defaultConfiguration;

#pragma mark Initialization
- (id)initWithPathToRepositoryConfigurations:(NSString *)path;

#pragma mark Loading configuration
- (void)reload;
- (void)reloadRepositories;
- (void)reloadRepositoryUsingConfiguration:(NSMutableDictionary *)plist;  

@end
