
@interface EYRepository : NSObject {
  NSMutableDictionary *dict;
  NSString *path;
}

@property(readonly) NSString *path;

+ (EYRepository *)repositoryWithContentsOfFile:(NSString *)path;
- (EYRepository *)initWithContentsOfFile:(NSString *)path;

- (id)objectForKey:(id)key;
- (BOOL)boolForKey:(id)key;
- (NSInteger)integerForKey:(id)key;

- (void)setObject:(id)obj forKey:(id)key;

- (BOOL)commitModifications;
- (BOOL)discardModifications;

@end
