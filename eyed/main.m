#import "EyeException.h"
#import "EyeMonitor.h"
#import <getopt.h>

#undef SRC_MODULE
#define SRC_MODULE "main"

static void _main_cleanup(void) {
  asl_close(asl_client);
}


static void _sighandler(int signal) {
  _main_cleanup();
  _exit(0);
}


static void usage(const char* prog) {
  fprintf(stderr,
          "usage: %s [options]\n"
          "Options:\n"
          "  -d/--log-debug   Enable sending INFO and DEBUG messages to syslogd.\n"
          "                   If not run as root, remote filters will probably cause\n"
          "                   info and debug messages not to be logged anyway.\n"
          "  -h/--help        Print this help message and exit.\n"
          "  -l/--log-local   Like --log-stderr but also disables logging to syslogd.\n"
          "  -s/--log-stderr  Print log messages to stderr.\n"
          ,
          prog);
}


int main (int argc, char * const *argv) {
  uint32_t asl_client_opts = 0,
           asl_send_level = ASL_LEVEL_NOTICE;
  
  // Parse options
  int ch;
  static struct option longopts[] = {
    { "log-debug", no_argument, NULL, 'd' },
    { "help", no_argument, NULL, 'h' },
    { "log-local", no_argument, NULL, 'l' },
    { "log-stderr", no_argument, NULL, 's' },
    { NULL, 0, NULL, 0 }
  };
  while ((ch = getopt_long(argc, argv, "dhls", longopts, NULL)) != -1) switch (ch) {
    case 'd':
      asl_send_level = ASL_LEVEL_DEBUG;
      asl_client_opts |= ASL_OPT_NO_REMOTE; // only works if euid==root
      break;
    case 'l':
      asl_send_level = -1;
      asl_client_opts |= ASL_OPT_STDERR;
      break;
    case 's':
      asl_client_opts |= ASL_OPT_STDERR;
      break;
    case 'h':
      fprintf(stderr,
              "Eye monitor -- handles repository synchronization.\n");
      usage(argv[0]);
      fprintf(stderr,
              "\n"
              "Copyright (c) %s Rasmus Andersson.\n"
              "See http://trac.hunch.se/eye for more information.\n",
              (__DATE__+7) );
      exit(1);
      break;
    default:
      usage(argv[0]);
      exit(1);
  }
  argc -= optind;
  argv += optind;
  
  // Connect to server in asl_open rather than on first call to asl_log.
  asl_client_opts |= ASL_OPT_NO_DELAY;
  
  // Open connection to ASL (asl_client defined in logging.h)
  asl_client = asl_open(NULL, "se.hunch.eye", asl_client_opts);
  log_set_send_filter(asl_send_level);
  
  // Register cleanup function
  if (atexit(_main_cleanup) != 0) {
    log_alert("atexit registration failed, probably due to exhausted memory. %m -- exiting");
    return 1;
  }
  
  // Register signal handler
  signal(SIGINT, _sighandler);
  
  // Start eyed
  @try {
    [[EyeMonitor defaultMonitor] run];
  }
  @catch(NSException *e) {
    NSString *st = [EyeException stackTrace:e];
    log_emerg("Uncaught %s: %s%s%s", [[e name] UTF8String], [[e description] UTF8String],
              st ? "\n" : " (no stacktrace)",
              st ? [st UTF8String] : "");
    return 1;
  }
  
  return 0;
}
