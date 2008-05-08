#import "EyeException.h"
#import "EyeMonitor.h"

int main (int argc, const char * argv[]) {
  @try {
    [[EyeMonitor defaultMonitor] run];
    return 0;
  }
  @catch(NSException *e) {
    log_error(@"Uncaught %@: %@", [e name], [e description]);
    [EyeException printStackTrace:e];
    return 1;
  }
  return 0;
}
