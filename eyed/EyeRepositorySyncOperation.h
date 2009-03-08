#import "EyeRepositoryOperation.h"

/*
 
 This operation should be dispatched as soon as a monitored repository
 _might have_ been modified and needs synchronization.
 
 If synchronization is needed, this operation will in turn dispatch a
 EyeRepositoryCommitOperation, handling the actual add and commit.
 
 If the repository is new and has not yet been initialized, this
 operation will also dispatch a EyeRepositoryInitOperation which will
 become a dependency for the aforementioned EyeRepositoryCommitOperation.
 
 */

@interface EyeRepositorySyncOperation : EyeRepositoryOperation {
  BOOL recursive;
}

- (id)initWithRepository:(EyeMonitoredRepository *)repo recursive:(BOOL)r;

@end
