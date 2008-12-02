#import "EyeMonitoredRepository.h"
#import "NSTask+EyeAdditions.h"

#undef SRC_MODULE
#define SRC_MODULE "repo"

@interface EyeMonitoredRepository (Private)
- (NSTask *)_hgTask:(NSString *)path args:(NSArray *)args cb:(SEL)cb;
- (NSTask *)_hgTaskCommit:(NSString *)path;
- (NSTask *)_hgTaskInit:(NSString *)path;
@end


@implementation EyeMonitoredRepository

@synthesize identifier;


#pragma mark -
#pragma mark Initializing

- (id)initWithIdentifier:(NSString *)ident configuration:(NSMutableDictionary *)plist {
  if (!(self = [super initWithConfiguration:plist]))
    return nil;
  
  identifier = ident;
  sync_task = nil;
  
  return self;
}


#pragma mark -
#pragma mark Monitoring


- (void)startMonitoring {
  [super startMonitoring];
  [self synchronizePath:self.path recursive:YES];
}


#pragma mark -
#pragma mark Synchronizing

- (void)synchronizePath:(NSString *)path recursive:(BOOL)recursive {
  NSFileManager *fm;
  NSDate *pathMTime, *dothgMTime;
  
  if (sync_task != nil) {
    log_warn("Synchronization of %s requested, "
             "but the repository is currently being processed by [%d]",
             [path UTF8String], [sync_task processIdentifier]);
    return;
  }
  
  // Check content modification time
  fm = [NSFileManager defaultManager];
  
  #define M(_pth) [[fm fileAttributesAtPath:_pth traverseLink:YES] objectForKey:NSFileModificationDate]
  pathMTime = M(path);
  dothgMTime = M([self.path stringByAppendingPathComponent:@".hg"]);
  log_debug("mtime:path=%s, mtime:basedir/.hg=%s", obj2utf8(pathMTime), obj2utf8(dothgMTime));
  #undef M
  
  // Repo directory does not exist 
  if (pathMTime == NULL) {
    log_warn("%s: directory \"%s\" does not exist -- idling", str2utf8(self.name), str2utf8(path));
    return;
  }
  
  // Repo is not initialized
  if (dothgMTime == NULL) {
    log_notice("%s: Not initialized -- starting initialization process", str2utf8(self.name), str2utf8(path));
    sync_task = [self _hgTaskInit:path];
    return;
  }
  
  // Abort if no data was modified
  if ([pathMTime compare:dothgMTime] != NSOrderedDescending) {
    log_info("%s: Path not modified (mtime(path) <= mtime(base_path/.hg)) -- skipping sync", [self.name UTF8String]);
    return;
  }
  
  // Looks like a valid change -- keep going
  log_debug("%s: Synchronizing (path=%s, recursive=%s)",
            [self.name UTF8String],
            [path UTF8String],
            recursive ? "YES" : "NO");
  
  // XXX todo: Replace this so we can handle multiple concurrent syncs, 
  //           but still detect and avoid per-repository sync race conditions.
  
  sync_task = [self _hgTaskCommit:path];
}


- (NSTask *)_hgTask:(NSString *)path args:(NSArray *)args cb:(SEL)cb {
  static NSString *hg_bin = @"/usr/local/bin/hg";
  log_notice("Dispatching process: %s %s", [hg_bin UTF8String], obj2utf8(args));
  NSTask *t = [[NSTask alloc] init];
  [t setLaunchPath:hg_bin];
  [t setArguments:args];
  [t setCurrentDirectoryPath:path];
  [t setStandardOutput:[NSPipe pipe]];
  [t setStandardError:[NSPipe pipe]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:cb
                                               name:NSTaskDidTerminateNotification
                                             object:t];
  [t launch];
  return t;
}


- (NSTask *)_hgTaskInit:(NSString *)path {
  return [self _hgTask:path
                  args:[NSArray arrayWithObjects:/*@"-v",*/ @"-y", @"init", nil]
                    cb:@selector(initializationTaskDidEnd:)];
}


- (NSTask *)_hgTaskCommit:(NSString *)path {
  return [self _hgTask:path
                  args:[NSArray arrayWithObjects:/*@"-v",*/ @"-y", @"ci", @"-A", @"-m", @"eyed:auto", nil]
                    cb:@selector(synchronizationTaskDidEnd:)];
}


- (void)initializationTaskDidEnd:(NSNotification *)n {
  int status = [sync_task terminationStatus];
  
  if (status == 0) {
    [@".DS_Store\nIcon\\r\n" writeToFile:[self.path stringByAppendingPathComponent:@".hgignore"] atomically:YES];
    log_info("%s: Wrote default .hgignore file", [self.name UTF8String]);
    log_notice("Initialized %s (\"%s\") -- just need to sync one first time...", [self.name UTF8String], [self.path UTF8String]);
    sync_task = [self _hgTaskCommit:self.path];
  }
  else {
    log_err("Failed to initialize %s (\"%s\") -- hg exited %d: %s\n%s",
            [self.name UTF8String],
            [self.path UTF8String],
            status,
            [[sync_task stringWithContentsOfStandardError] UTF8String],
            [[sync_task stringWithContentsOfStandardOutput] UTF8String]);
    sync_task = nil;
  }
}


- (void)synchronizationTaskDidEnd:(NSNotification *)n {
  assert([n object] == sync_task);
  
  // We have gotten our notification. As we create a new NSTask each time, and
  // register for notifications to that specific object, we need to remove the
  // observation (and later add a new one for another NSTask instance).
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSTaskDidTerminateNotification
                                                object:sync_task];
  
  int status = [sync_task terminationStatus];
  if (status == 0) {
    log_notice("Synchronized %s", [self.name UTF8String]);
    log_debug("sync message: %s", [[sync_task stringWithContentsOfStandardOutput] UTF8String]);
  }
  else {
    log_err("Failed to synchronize %s (\"%s\") -- hg exited %d: %s\n%s",
            [self.name UTF8String],
            [self.path UTF8String],
            status,
            [[sync_task stringWithContentsOfStandardError] UTF8String],
            [[sync_task stringWithContentsOfStandardOutput] UTF8String]);
  }
  
  sync_task = nil;
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
