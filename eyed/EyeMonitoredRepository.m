#import "EyeMonitoredRepository.h"
#import "EyeRepositorySyncOperation.h"

#undef SRC_MODULE
#define SRC_MODULE "repo"

@implementation EyeMonitoredRepository

@synthesize identifier;
@synthesize operations;


#pragma mark -
#pragma mark Initialization & Finalization

- (id)initWithIdentifier:(NSString *)ident configuration:(NSMutableDictionary *)plist {
  if (!(self = [super initWithConfiguration:plist]))
    return nil;
  
  identifier = ident;
  operations = [[NSOperationQueue alloc] init];
  
  return self;
}

- (void)finalize {
  log_info("%s: finalizing -- flushing operation queue...", [self.name UTF8String]);
  [operations cancelAllOperations];
  // todo: see if we can use int setitimer(3); to add timeout to this one
  [operations waitUntilAllOperationsAreFinished];
  [super finalize];
}


#pragma mark -
#pragma mark Monitoring


- (void)startMonitoring {
  [super startMonitoring];
}


#pragma mark -
#pragma mark Synchronizing

- (void)synchronize {
  [self synchronizePath:self.path recursive:NO];
}

- (void)synchronizePath:(NSString *)path recursive:(BOOL)recursive {
  EyeRepositorySyncOperation *op;
  
  // First line defence
  if ([path hasPrefix:[NSString stringWithFormat:@"%@/.git", self.path]]) {
    // Something happened in the git-dir which we do not track (doh!)
    return;
  }
  
  // Queue and start a sync operation
  op = [[EyeRepositorySyncOperation alloc] initWithRepository:self recursive:recursive];
  log_debug("adding operation sync <EyeRepositorySyncOperation @ %p>", op);
  [self.operations addOperation:op];
}


#pragma mark -
#pragma mark Monitoring

- (void)monitoredDidChange:(NSNotification *)n {
  NSString *path;
  NSDictionary *info;
  BOOL recursive;
  
  if ([n object] != self) {
    log_warn("Unexpected notification received, destined for someone else");
    return;
  }
  
  info = [n userInfo];
  path = [info objectForKey:@"path"];
  recursive = [(NSNumber *)[info objectForKey:@"recursive"] boolValue];
  
  [self synchronizePath:path recursive:recursive];
}

#pragma mark -
#pragma mark Accessing attributes

- (NSString *)name {
  id s = [super name];
  if (s == NULL)
    s = identifier;
  return s;
}

// to string
- (NSString *)description {
  return [NSString stringWithFormat: @"<%@: %@ \"%@\" @%p>",
          NSStringFromClass(isa),
          self.enabled ? @"enabled" : @"disabled",
          identifier,
          self];
}

@end
