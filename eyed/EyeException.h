@interface EyeException : NSException {
}

+ (void)raise:(NSString *)format, ... ;
+ (void)printStackTrace:(NSException *)e;

@end
