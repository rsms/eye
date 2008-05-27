#import "NSError+EyeAdditions.h"

@implementation NSError (EyeAdditions)

+ (id)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)desc {
  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:desc forKey:NSLocalizedDescriptionKey];
  return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

@end
