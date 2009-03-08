#import "EyeRepositoryInitOperation.h"
#include <stdlib.h> /* system() */

@implementation EyeRepositoryInitOperation

@synthesize exclude;


- (id)initWithRepository:(EyeMonitoredRepository *)repo {
  self = [super initWithRepository:repo];
  exclude = [NSMutableArray arrayWithObjects:@".DS_Store", @"._*", @"Icon\\r", NULL];
  return self;
}


- (void)main {
  NSString *cmd, *dotgitignorePath, *patterns;
  NSError *ioerror;
  
  // git init
  cmd = [NSString stringWithFormat:@"git --git-dir='%@/.git' --work-tree='%@' init --quiet --shared=group",
         repository.path, repository.path];
  log_debug("system(\"%s\")", [cmd UTF8String]);
  if (system([cmd UTF8String]) != 0) {
    log_error("%s: Failed to initialize path '%s'", [repository.name UTF8String], 
              [repository.path UTF8String]);
    return;
  }
  
  // write .gitignore
  patterns = [NSString string];
  for (id pat in exclude) {
    patterns = [patterns stringByAppendingFormat:@"%@\n", [pat description]];
  }
  dotgitignorePath = [repository.path stringByAppendingPathComponent:@".gitignore"];
  ioerror = NULL;
  [patterns writeToFile:dotgitignorePath atomically:YES encoding:NSUTF8StringEncoding error:&ioerror];
  if (ioerror) {
    log_error("%s: Failed to write .gitignore to '%s': %@", 
             [repository.name UTF8String], [dotgitignorePath UTF8String], 
              [ioerror localizedDescription]);
  }
  else {
    log_info("%s: Wrote default .gitignore file", [repository.name UTF8String]);
  }
}


@end
