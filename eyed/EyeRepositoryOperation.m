#import "EyeRepositoryOperation.h"
#import "EyeMonitoredRepository.h"

@implementation EyeRepositoryOperation

@synthesize repository;

- (id)initWithRepository:(EyeMonitoredRepository *)repo {
  self = [super init];
  self.repository = repo;
  return self;
}

@end
