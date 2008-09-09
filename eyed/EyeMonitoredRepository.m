#import "EyeMonitoredRepository.h"
#import "NSTask+EyeAdditions.h"

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
  #define MTIME(_pth) [[fm fileAttributesAtPath:_pth traverseLink:YES] objectForKey:NSFileModificationDate]
  pathMTime = MTIME(path);
  dothgMTime = MTIME([self.path stringByAppendingPathComponent:@".hg"]);
  //log_debug(@"mtime:path=%@, mtime:basedir/.hg=%@",pathMTime,dothgMTime);
  
  // Abort if no data was modified
  if ([pathMTime compare:dothgMTime] != NSOrderedDescending) {
    //log_debug(@"Path not modified (mtime(path) <= mtime(basedir/.hg))");
    return;
  }
  
  // Check content mtime
  // Removed: when copying a file and preserving it's modification date, this will fail.
  /*contentMTime = [NSDate distantPast];
  for (NSString *fn in [fm enumeratorAtPath:path]) {
    if ( ! [fn isEqualToString:@".DS_Store"]) {
      contentMTime = [contentMTime laterDate:MTIME([path stringByAppendingPathComponent:fn])];
    }
  }
  log_debug(@"contentMTime=%@", contentMTime);
  
  // Abort if the change was due to a file or directory we do not care about
  if ([contentMTime compare:dothgMTime] != NSOrderedDescending) {
    log_debug(@"Contents not modified (mtime(contents) <= mtime(basedir/.hg))");
    return;
  }*/
  
  #undef MTIME
  
  // Looks like a valid change -- keep going
  log_debug("Synchronizing %s (path=%s, recursive=%s)",
            [[self description] UTF8String],
            [path UTF8String],
            recursive ? "YES" : "NO");
  
  // Dispatch hg update process
  sync_task = [[NSTask alloc] init];
  [sync_task setLaunchPath:@"/usr/local/bin/hg"];
  [sync_task setArguments:[NSArray arrayWithObjects:@"-v", @"-y", @"ci", @"-A", @"-m", @"eyed:auto", nil]];
  [sync_task setCurrentDirectoryPath:path];
  [sync_task setStandardOutput:[NSPipe pipe]];
  [sync_task setStandardError:[NSPipe pipe]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(synchronizationTaskDidEnd:)
                                               name:NSTaskDidTerminateNotification
                                             object:sync_task];
  [sync_task launch];
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
    log_notice("Synchronized %s", [self.path UTF8String]);
    log_debug("sync message: %s", [[sync_task stringWithContentsOfStandardOutput] UTF8String]);
  }
  else {
    log_err("Failed to synchronize %s -- %s\n%s", [self.path UTF8String],
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

// to string
- (NSString *)description {
  return [NSString stringWithFormat: @"<%@: %@ \"%@\" @%p>",
          NSStringFromClass(isa),
          self.enabled ? @"enabled" : @"disabled",
          self.identifier,
          self];
}

@end
