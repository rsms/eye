@interface EYReposListDataSource : NSObject {
  NSMutableArray *repositories;
}

@property(assign) NSMutableArray *repositories;

- (void) reload;

@end
