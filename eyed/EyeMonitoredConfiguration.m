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
    
    path = [@"~/Library/Application Support/Eyed/repositories" stringByExpandingTildeInPath];
    
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
  log_info(@"Reloading configuration");
  [self reloadRepositories];
}


- (void)reloadRepositories {
  NSDirectoryEnumerator *configEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.path];
  NSString *path;
  
  for (NSString *filename in configEnumerator) {
    if ([[filename pathExtension] caseInsensitiveCompare:@"plist"] == 0) {
      path = filename;
      @try {
        path = [[self.path stringByAppendingString:@"/"] stringByAppendingString:filename];
        NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        [self reloadRepository:path usingConfiguration:plist];
      }
      @catch (NSException * e) {
        log_error(@"Failed to activate configuration %@. %@: %@", path, [e name], [e description]);
        [EyeException printStackTrace:e];
      }
    }
  }
}


- (void)reloadRepository:(NSString *)identifier usingConfiguration:(NSMutableDictionary *)plist
{
  EyeMonitoredRepository *repo;
  log_debug("identifier=%@ plist=%@", identifier, plist);
  
  [EyeMonitored validateConfiguration:plist];
  
  if (!(repo = [repositories objectForKey:identifier])) {
    log_debug(@"Creating new repository %@", identifier);
    repo = [[EyeMonitoredRepository alloc] initWithIdentifier:identifier configuration:plist];
    [repositories setObject:repo forKey:identifier];
    [repo startMonitoring];
  }
  else {
    log_debug(@"Reloading existing repository %@", identifier);
    repo.configuration = plist;
  }
}


#pragma mark -
#pragma mark Monitoring


// xxx: todo: reload configuration on change
- (void)monitoredDidChange:(NSNotification *)n {
  if ([n object] != self) {
    log_warn(@"Unexpected notification received destined for someone else. object = %@", [n object]);
    return;
  }
  
  [self reload];
}

@end
