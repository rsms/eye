#import "EYRepository.h"

@implementation EYRepository

@synthesize path;

+ (EYRepository *)repositoryWithContentsOfFile:(NSString *)path {
  return [[EYRepository alloc] initWithContentsOfFile:path]; 
}


- (EYRepository *)initWithContentsOfFile:(NSString *)s {
  dict = [NSDictionary dictionaryWithContentsOfFile:s];
  path = s;
  if ([self objectForKey:@"name"] == nil)
    [self setObject:[[path lastPathComponent] stringByDeletingPathExtension] forKey:@"name"];
  return self;
}


- (id)objectForKey:(id)key {
  return [dict objectForKey:key];
}


- (BOOL)boolForKey:(id)key {
  NSNumber *b = [dict objectForKey:key];
  if (b != nil)
    return [b boolValue];
  return FALSE;
}

- (NSInteger)integerForKey:(id)key {
  NSNumber *b = [dict objectForKey:key];
  if (b != nil)
    return [b intValue];
  return 0;
}


- (void)setObject:(id)obj forKey:(id)key {
  [dict setObject:obj forKey:key];
}


- (BOOL)commitModifications {
  if ([dict isEqualToDictionary:[NSDictionary dictionaryWithContentsOfFile:self.path]])
    return YES;
  return [dict writeToFile:self.path atomically:YES];
}


- (BOOL)discardModifications {
  NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:self.path];
  if (!d)
    return NO;
  [dict setDictionary:d];
  return YES;
}

@end
