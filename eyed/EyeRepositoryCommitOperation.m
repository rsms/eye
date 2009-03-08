#import "EyeRepositoryCommitOperation.h"
#include <stdlib.h> /* system() */
#include <stdio.h> /* popen(), pclose() */

@implementation EyeRepositoryCommitOperation


- (id)initWithRepository:(EyeMonitoredRepository *)repo {
  self = [super initWithRepository:repo];
  includeUntracked = YES;
  return self;
}


- (void)main {
  NSString *cmd;
  
  if (includeUntracked) {
    cmd = [NSString stringWithFormat:@"git --git-dir='%@/.git' --work-tree='%@' add --all --verbose --ignore-errors",
           repository.path, repository.path];
    
    log_debug("popen(\"%s\", \"r\")", [cmd UTF8String]);
    
    FILE *fp = popen([cmd UTF8String], "r");
    if (fp == NULL) {
      log_error("%s: Failed to start git-add", [repository.name UTF8String]);
      return;
    }
    NSMutableArray *files = [NSMutableArray array];
    char line[290];
    while (fgets(line, sizeof line, fp)) {
      if (strlen(line) > 1) {
        // how the lines look like:
        // "add 'a'\n"
        // "remove 'a'\n"
        [files addObject:[NSString stringWithCString:line encoding:NSUTF8StringEncoding]];
      }
    }
    pclose(fp);
    log_debug("%s: add: files length = %d, files = %s",
              [repository.name UTF8String], [files count], obj2utf8(files));
    
    if ([files count] == 0) {
      log_debug("%s: nothing changed", [repository.name UTF8String]);
      return;
    }
    
    if (system([cmd UTF8String]) != 0) {
      log_error("%s: Failed to add untracked files", [repository.name UTF8String]);
      return;
    }
  }
  
  if (self.isCancelled) {
    /* cancel might have been called on this op during the above system() call */
    return;
  }
  
  cmd = [NSString stringWithFormat:@"git --git-dir='%@/.git' --work-tree='%@' commit --quiet --all -m eyed:auto",
         repository.path, repository.path];
  log_debug("system(\"%s\")", [cmd UTF8String]);
  if (system([cmd UTF8String]) != 0) {
    log_error("%s: Failed to commit", [repository.name UTF8String]);
  }
  else {
    log_notice("%s: Synchronized", [repository.name UTF8String]);
  }
}


@end
