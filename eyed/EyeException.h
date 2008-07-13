@interface EyeException : NSException {
}

+ (void)raise:(NSString *)format, ... ;
+ (NSString *)stackTrace:(NSException *)e;
+ (void)printStackTrace:(NSException *)e;

@end
