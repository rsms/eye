#import "EyeMonitoredConfiguration.h"
#import "EyeMonitoredRepository.h"
#import "EyeException.h"

@interface EyeMonitoredConfiguration (Private)
- (void)_postInit;
@end


@implementation EyeMonitoredConfiguration

static EyeMonitoredConfiguration *_default = nil;


+ (EyeMonitoredConfiguration *)defaultConfiguration {
  if (_default == nil) {
    NSString *path;
    NSError *error = nil;
    
#ifdef DEBUG
    path = [@"~/Library/Application Support/Eye-debug/repositories" stringByExpandingTildeInPath];
#else
    path = [@"~/Library/Application Support/Eye/repositories" stringByExpandingTildeInPath];
#endif
    
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error) {
      [EyeException raise:@"Failed to create path %@. Error: %@ Reason: %@",
        path, [error localizedDescription], [error localizedFailureReason]];
    }
    
    _default = [[EyeMonitoredConfiguration alloc] initWithPathToRepositoryConfigurations:path];
  }
  return _default;
}


- (id)initWithPathToRepositoryConfigurations:(NSString *)path
{
  NSMutableDictionary *conf;
  
  conf = [NSMutableDictionary dictionaryWithObjectsAndKeys:
          path,                          @"path",
          [NSNumber numberWithDouble:5], @"latency",
          nil];
  
  if (!(self = [super initWithConfiguration:conf]))
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


#pragma mark -
#pragma mark Reloading configurations

- (void)reload {
  log_info("Reloading configuration");
  [self reloadRepositories];
}


- (NSString *)repositoryIdentifierForConfigurationAtPath:(NSString *)path {
  return [[path stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension];
}


- (void)reloadRepositories {
  NSDirectoryEnumerator *configEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.path];
  NSString *path, *identifier;
  NSMutableDictionary *plist;
  
  for (NSString *filename in configEnumerator) {
    if ([[filename pathExtension] caseInsensitiveCompare:@"plist"] == 0) {
      path = [[self.path stringByAppendingString:@"/"] stringByAppendingString:filename];
      @try {
        identifier = [self repositoryIdentifierForConfigurationAtPath:path];
        plist = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        [self reloadRepository:identifier usingConfiguration:plist];
      }
      @catch (NSException * e) {
        log_err("Failed to activate configuration %s. %s: %s",
                [path UTF8String], [[e name] UTF8String], [[e description] UTF8String]);
        [EyeException printStackTrace:e];
      }
    }
  }
}


- (void)reloadRepository:(NSString *)identifier usingConfiguration:(NSMutableDictionary *)plist {
  EyeMonitoredRepository *repo;
  
  log_debug("identifier=%s plist=%s",
            [identifier UTF8String], [[plist description] UTF8String]);
  
  [EyeMonitored validateConfiguration:plist];
  
  if (!(repo = [repositories objectForKey:identifier])) {
    log_info("Setting up repository %s", [identifier UTF8String]);
    repo = [[EyeMonitoredRepository alloc] initWithIdentifier:identifier configuration:plist];
    [repositories setObject:repo forKey:identifier];
    [repo startMonitoring];
  }
  else {
    log_debug("Reloading repository %s", [identifier UTF8String]);
    repo.configuration = plist;
  }
}


#pragma mark -
#pragma mark Monitoring


- (void)monitoredDidChange:(NSNotification *)n {
  assert([n object] == self);
  [[n object] reload];
}

@end
