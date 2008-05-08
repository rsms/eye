#import "EyeMonitoredConfiguration.h"
#import "EyeMonitoredRepository.h"


@interface EyeMonitoredConfiguration (Private)
- (void)_postInit;
@end


@implementation EyeMonitoredConfiguration

static EyeMonitoredConfiguration *_default = nil;


+ (EyeMonitoredConfiguration *)defaultConfiguration {
  if (_default == nil) {
    NSString *path = [@"~/Library/Application Support/Eyed/repositories" stringByExpandingTildeInPath];
    _default = [[EyeMonitoredConfiguration alloc] initWithPathToRepositoryConfigurations:path];
  }
  return _default;
}


- (id)initWithPathToRepositoryConfigurations:(NSString *)path {
  NSMutableDictionary *conf = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               path,                          @"path",
                               [NSNumber numberWithDouble:5], @"latency",
                               nil];
  self = [super initWithConfiguration:conf];
  if (!self)
    return nil;
  [self _postInit];
  return self;
}


- (id)init {
  if (!(self = [super init]))
    return nil;
  [self _postInit];
  return self;
}


- (void)_postInit {
  repositories = [NSMutableDictionary dictionary];
}


@synthesize repositories;


- (void)reload {
  [self reloadRepositories];
}


- (void)reloadRepositories {
  NSDirectoryEnumerator *configEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.path];
  
  for (NSString *filename in configEnumerator) {
    NSString *path = [[self.path stringByAppendingString:@"/"] stringByAppendingString:filename];
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    [self reloadRepositoryUsingConfiguration:plist];
  }
}


- (void)reloadRepositoryUsingConfiguration:(NSMutableDictionary *)plist {
  EyeMonitoredRepository *repo;
  log_debug("plist=%@", plist);
  
  [EyeMonitored validateConfiguration:plist];
  
  if (!(repo = [repositories objectForKey:[plist objectForKey:@"path"]])) {
    log_debug(@"Creating new repository");
    repo = [[EyeMonitoredRepository alloc] initWithConfiguration:plist];
    [repositories setObject:repo forKey:repo.path];
  }
  else {
    log_debug(@"Reloading existing repository %@", repo);
    repo.configuration = plist;
  }
}


// xxx: todo: reload configuration on change

@end
