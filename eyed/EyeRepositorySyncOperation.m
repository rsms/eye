#import "EyeRepositorySyncOperation.h"
#import "EyeRepositoryInitOperation.h"
#import "EyeRepositoryCommitOperation.h"

@implementation EyeRepositorySyncOperation


- (id)initWithRepository:(EyeMonitoredRepository *)repo recursive:(BOOL)r {
  self = [super initWithRepository:repo];
  recursive = r;
  return self;
}


- (void)main {
  NSFileManager *fm;
  NSDate *pathMTime, *dotgitMTime;
  EyeRepositoryInitOperation *initOp;
  EyeRepositoryCommitOperation *commitOp;
  
  // Check content modification time
  fm = [NSFileManager defaultManager];
  pathMTime = [[fm fileAttributesAtPath:repository.path 
                           traverseLink:YES] objectForKey:NSFileModificationDate];
  dotgitMTime = [[fm fileAttributesAtPath:[repository.path stringByAppendingPathComponent:@".git"] 
                             traverseLink:YES] objectForKey:NSFileModificationDate];
  log_debug("mtime(repository path) => %s, mtime(repository path/.git) => %s", 
            obj2utf8(pathMTime), obj2utf8(dotgitMTime));
  
  // Repo directory does not exist
  if (pathMTime == NULL) {
    log_warn("%s: directory \"%s\" does not exist", 
             str2utf8(repository.name), str2utf8(repository.path));
    return;
  }
  
  // Repo is not initialized
  initOp = NULL;
  if (dotgitMTime == NULL) {
    log_notice("%s: Not initialized -- starting initialization process", 
               str2utf8(repository.name), str2utf8(repository.path));
    initOp = [[EyeRepositoryInitOperation alloc] initWithRepository:repository];
  }
  // Abort if no data was modified
  /*else if ([pathMTime compare:dotgitMTime] != NSOrderedDescending) {
    log_info("%s: Path not modified (mtime(repository path) <= mtime(repository path/.git)) -- skipping sync",
             [repository.name UTF8String]);
    return;
  }*/
  
  // Queue operations
  commitOp = [[EyeRepositoryCommitOperation alloc] initWithRepository:repository];
  if (initOp) {
    [commitOp addDependency:initOp];
    [repository.operations addOperation:initOp];
  }
  [repository.operations addOperation:commitOp];
  //[self addDependency:commitOp]; // does this have any effect? we want this task to 
                                 // "wait" for commitOp before it's isFinished method 
                                 // returns YES instead of NO.
}


@end
