#import "EyeRepositoryOperation.h"

@interface EyeRepositoryInitOperation : EyeRepositoryOperation {
  NSMutableArray *exclude;
}

@property(assign) NSMutableArray *exclude;

@end
