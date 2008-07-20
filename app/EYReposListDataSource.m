#import "EYReposListDataSource.h"
#import "EYError.h"
#import "EYRepository.h"

@implementation EYReposListDataSource

@synthesize repositories;

- (id) init {
  self = [super init];
  if (self != nil) {
    [self reload];
  }
  return self;
}


-(void)awakeFromNib {
  [self reload];
}


- (void) reload {
  NSString *config_dir, *path;
  NSDirectoryEnumerator *config_en;
  EYRepository *repo;
  
  repositories = [NSMutableArray array];
  config_dir = [@"~/Library/Application Support/Eyed/repositories" stringByExpandingTildeInPath];
  config_en = [[NSFileManager defaultManager] enumeratorAtPath:config_dir];
  
  for (NSString *filename in config_en) {
    if ([[filename pathExtension] caseInsensitiveCompare:@"plist"] == 0) {
      path = [[config_dir stringByAppendingString:@"/"] stringByAppendingString:filename];
      @try {
        repo = [EYRepository repositoryWithContentsOfFile:path];
        [repositories addObject:repo];
      }
      @catch (NSException * e) {
        NSLog(@"Failed to activate configuration %s. %s: %s",
                [path UTF8String], [[e name] UTF8String], [[e description] UTF8String]);
      }
    }
  }
}


// Number of rows
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [repositories count];
}


// Get value for cell
- (id)tableView:(NSTableView *)tv
objectValueForTableColumn:(NSTableColumn *)col
            row:(NSInteger)row
{
  EYRepository *repo = [repositories objectAtIndex:row];
  
  if ([[col identifier] compare:@"icon"] == 0) {
    if ([repo boolForKey:@"enabled"])
      return [NSImage imageNamed:@"repo_icon_small"];
    else
      return [NSImage imageNamed:@"repo_icon_small_disabled"];
  }
  else {
    return [repo objectForKey:@"name"];
  }
}


// Set value for cell
- (void)tableView:(NSTableView *)tv
   setObjectValue:(id)val
   forTableColumn:(NSTableColumn *)col
              row:(NSInteger)row
{
  EYRepository *repo = [repositories objectAtIndex:row];
  
  // Rename
  if ([[col identifier] compare:@"name"] == 0) {
    if (val == nil) {
      [NSApp presentError:[EYError errorWithDescription:@"Get nil for repository name!"]];
      return;
    }
    val = [val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([val length] == 0) {
      [NSApp presentError:[EYError errorWithDescription:@"Repository name can not be empty"]];
      return;
    }
    [repo setObject:val forKey:@"name"];
    if (![repo commitModifications])
      [NSApp presentError:[EYError errorWithDescription:@"Failed to write changes"]];
  }
}

@end
