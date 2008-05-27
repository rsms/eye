@interface NSError (EyeAdditions)

+ (id)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)desc;

@end