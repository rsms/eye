#import "EyeMonitoredRepository.h"

@interface EyeRepositoryOperation : NSOperation {
  EyeMonitoredRepository *repository;
}

@property(assign) EyeMonitoredRepository *repository;

- (id)initWithRepository:(EyeMonitoredRepository *)repo;

@end
