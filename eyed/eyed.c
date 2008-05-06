#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <dirent.h>
#include <assert.h>
#include <fnmatch.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>


#pragma mark -
#pragma mark Macros

#define __FILENAME__ ((strrchr(__FILE__, '/') ?: __FILE__ - 1) + 1)

// Log to stderr
#define log_error(fmt, ...)   fprintf(stderr, "E %s:%-4d in %s: " fmt "\n", __FILENAME__, __LINE__, __FUNCTION__, ##__VA_ARGS__)
#define log_warn(fmt, ...)    fprintf(stderr, "W %s:%-4d in %s: " fmt "\n", __FILENAME__, __LINE__, __FUNCTION__, ##__VA_ARGS__)
#define log_info(fmt, ...)    fprintf(stderr, "I %s:%-4d in %s: " fmt "\n", __FILENAME__, __LINE__, __FUNCTION__, ##__VA_ARGS__)
#if DEBUG
  #define log_debug(fmt, ...) fprintf(stderr, "D %s:%-4d in %s: " fmt "\n", __FILENAME__, __LINE__, __FUNCTION__, ##__VA_ARGS__)
  #define IFDEBUG(x) x
#else
  #define log_debug(fmt, ...) ((void)0)
  #define IFDEBUG(x) 
#endif


#pragma mark -
#pragma mark Prototypes

static FSEventStreamRef my_FSEventStreamCreate(const char **paths, size_t num_paths);



#pragma mark -
#pragma mark Helpers


int should_ignore_path(const char *path) {
  if(strstr(path, "/.hg"))
    return 1;
  //return fnmatch("*/", path, 0) == 0;
  return 0;
}


void absolutize_path(const char *path, char *buf) {
  if (realpath(path, buf) == NULL)
    strlcpy(buf, path, sizeof(buf));
}


#pragma mark -
#pragma mark Callback routines

static void
timer_callback(CFRunLoopRef timer, void *info) {
  FSEventStreamRef streamRef = (FSEventStreamRef)info;
  log_debug("CFAbsoluteTimeGetCurrent() => %.3f", CFAbsoluteTimeGetCurrent());
  log_debug("FSEventStreamFlushAsync(streamRef = %p)...", streamRef);
  FSEventStreamFlushAsync(streamRef);
}

typedef void ( *FSEventStreamCallback)( 
                                       ConstFSEventStreamRef streamRef, 
                                       void *clientCallBackInfo, 
                                       size_t numEvents, 
                                       void *eventPaths, 
                                       const FSEventStreamEventFlags eventFlags[], 
                                       const FSEventStreamEventId eventIds[]);

static void
fsevents_callback(FSEventStreamRef streamRef,
                  void *user_data, 
                  size_t numEvents,
                  /* void* */const char *const event_paths[], 
                  const FSEventStreamEventFlags *eventMasks, 
                  const FSEventStreamEventId event_ids[])
{
  int recursive;
  const char *path = NULL;
  FSEventStreamEventId event_id;
  char cmd_buf[PATH_MAX*2];
  //char *cmd_hgst = "/usr/local/bin/hg --verbose status '%s'";
  static char cmd_hgst[] = "/usr/local/bin/hg -v -y --cwd '%s' ci -A -m eyed:autocommit";
  
  log_debug("streamRef = %p, numEvents = %ld", streamRef, numEvents);
  
  for (size_t i=0; i < numEvents; i++) {
    path = event_paths[i];
    
    // Skip this path?
    if(should_ignore_path(path)) {
      //log_debug("Skipping change to '*/.hg/?': %s", path_buff);
      continue;
    }
    
    event_id = event_ids[i];
    
    log_debug("Processing event %llx (%d of %d) \"%s\"", event_id, i+1, numEvents, path);
	
    if (eventMasks[i] & kFSEventStreamEventFlagMustScanSubDirs) {
      log_debug("MustScanSubDirs flag set -- performing a full rescan");
      recursive = 1;
    }
    else if (eventMasks[i] & kFSEventStreamEventFlagUserDropped) {
      log_warn("We dropped events -- forcing a full rescan");
      recursive = 1;
      //XXX: todo: strlcpy(path, full_path, sizeof(path));
    }
    else if (eventMasks[i] & kFSEventStreamEventFlagKernelDropped) {
      log_warn("Kernel dropped events -- forcing a full rescan");
      recursive = 1;
      //XXX: todo: strlcpy(path, full_path, sizeof(path));
    }
    else {
      log_debug("Performing normal scan");
      recursive = 0;
    }
    
    cmd_buf[0] = 0;
    snprintf(cmd_buf, PATH_MAX*2, cmd_hgst, path);
    log_debug("system(\"%s\")", cmd_buf);
    int pstat = system(cmd_buf);
    log_debug("system() returned %d", pstat);
  }
}


#pragma mark -
#pragma mark Simple wrapper to create an FSEventStream

static FSEventStreamRef my_FSEventStreamCreate(const char **paths, size_t num_paths)
{
  void         *user_data = (void *)(num_paths ? paths[0] : "?");
  FSEventStreamContext  context = {0, user_data, NULL, NULL, NULL};
  FSEventStreamRef    streamRef = NULL;
  CFMutableArrayRef   cfArray;
  
  // Settings
  FSEventStreamEventId sinceWhen = kFSEventStreamEventIdSinceNow;
  int                  flags = 0;
  CFAbsoluteTime       latency = 5.0; // How long it takes from that something 
                                      // happened to an event is dispatched.
  
  // Used as buffer for absolutize_path
  char abspath[PATH_MAX];
  
  // Create paths array
  cfArray = CFArrayCreateMutable(kCFAllocatorDefault, 1, &kCFTypeArrayCallBacks);
  if (NULL == cfArray) {
    log_error("CFArrayCreateMutable() => NULL");
    goto Return;
  }
  
  // Add paths to array
  for(int i=0; i<num_paths; i++) {
    absolutize_path(paths[i], abspath);
    CFStringRef cfStr = CFStringCreateWithCString(kCFAllocatorDefault, abspath, kCFStringEncodingUTF8);
    if (NULL == cfStr) {
      CFRelease(cfArray);
      goto Return;
    }
    CFArraySetValueAtIndex(cfArray, i, cfStr);
    CFRelease(cfStr);
  }
  
  // Create the stream
  streamRef = FSEventStreamCreate(kCFAllocatorDefault,
                  (FSEventStreamCallback)&fsevents_callback,
                  &context,
                  cfArray,
                  /*settings->*/sinceWhen,
                  /*settings->*/latency,
                  /*settings->*/flags);
  
  // Check if FSEventStreamCreate failed
  if (NULL == streamRef) {
    log_error("FSEventStreamCreate() failed");
    goto Return;
  }
  
  // Print the setup
  IFDEBUG(
    FSEventStreamShow(streamRef);
  )
  
Return:
  // Release our array
  CFRelease(cfArray);
  cfArray = NULL;
  
  return streamRef;
}


#pragma mark -
#pragma mark Main

int
main(int argc, const char * argv[])
{
  int result = 0;
  FSEventStreamRef streamRef;
  Boolean startedOK;
  int flush_seconds = 3600; // When to force-flush any queued events
  
  if(argc < 2 || strcasecmp(argv[1], "--help") == 0) {
    fprintf(stderr, "usage: %s path ...\n", argv[0]);
    exit(1);
  }
  
  const char **paths = &argv[1];
  streamRef = my_FSEventStreamCreate(paths, argc-1);
  
  FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  
  startedOK = FSEventStreamStart(streamRef);
  if (!startedOK) {
    log_error("FSEventStreamStart(streamRef) failed");
    goto out;
  }
  
  if (flush_seconds >= 0) {
    log_debug("CFAbsoluteTimeGetCurrent() => %.3f", CFAbsoluteTimeGetCurrent());
    CFAllocatorRef allocator = kCFAllocatorDefault;
    CFAbsoluteTime fireDate = CFAbsoluteTimeGetCurrent() + /*settings->*/flush_seconds;
    CFTimeInterval interval = /*settings->*/flush_seconds;
    CFOptionFlags flags = 0;
    CFIndex order = 0;
    CFRunLoopTimerCallBack callback = (CFRunLoopTimerCallBack)timer_callback;
    CFRunLoopTimerContext context = { 0, streamRef, NULL, NULL, NULL };
    CFRunLoopTimerRef timer = CFRunLoopTimerCreate(allocator, fireDate, interval, flags, order, callback, &context);
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopDefaultMode);
  }
  
  // Run
  CFRunLoopRun();
  
  // Stop / Invalidate / Release
  FSEventStreamStop(streamRef);
out:
  FSEventStreamInvalidate(streamRef);
  FSEventStreamRelease(streamRef);
  
  return result;
}
