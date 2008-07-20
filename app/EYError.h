
@interface EYError : NSError {
  NSString *description;
}

+ (NSError *)errorWithDescription:(NSString *)msg;

@property(assign) NSString *description;

@end
