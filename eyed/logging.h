#ifndef LOGGING_H
#define LOGGING_H
/*
 MACRO        LEVEL         DESCRIPTION
 ------------ ------------- -------------------------------------------------------------------
 log_emerg    Emergency     A serious, unexpected, and often dangerous situation requiring
                            immediate action.
 log_alert    Alert         Danger, threat, or problem, typically with the intention of having
                            it avoided or dealt with.
 log_crit     Critical      Having the potential to become disastrous; at a point of crisis.
 log_err      Error         The state or condition of being wrong in conduct or judgment.
 log_warn     Warning       A statement or event that indicates a possible or impending danger,
                            problem, or other unpleasant situation.
 log_notice   Notice        The act of notifying, or something by which notice is given.
 log_info     Information   Facts provided or learned about something.
 log_debug    Debug         Intended for debugging and development. (Only used when building in
                            DEBUG mode).
*/

#import <asl.h>
#ifndef ASL_KEY_FACILITY
#   define ASL_KEY_FACILITY "Facility"
#endif

#ifdef SRC_MODULE
  #undef SRC_MODULE
#endif
#define SRC_MODULE __FILENAME__

extern aslclient asl_client;

#define log_set_send_filter(level) asl_set_filter(asl_client, ASL_FILTER_MASK_UPTO(level));

#define log_(int_level, const_chars_fmt, ...) asl_log(asl_client, NULL, int_level, const_chars_fmt, ##__VA_ARGS__)

#define log_emerg(fmt, ...)  log_(ASL_LEVEL_EMERG,  "[%s] " fmt " (%s:%d)", SRC_MODULE, ##__VA_ARGS__, __FILENAME__, __LINE__)
#define log_alert(fmt, ...)  log_(ASL_LEVEL_ALERT,  "[%s] " fmt " (%s:%d)", SRC_MODULE, ##__VA_ARGS__, __FILENAME__, __LINE__)
#define log_crit(fmt, ...)   log_(ASL_LEVEL_CRIT,   "[%s] " fmt " (%s:%d)", SRC_MODULE, ##__VA_ARGS__, __FILENAME__, __LINE__)
#define log_err(fmt, ...)    log_(ASL_LEVEL_ERR,    "[%s] " fmt " (%s:%d)", SRC_MODULE, ##__VA_ARGS__, __FILENAME__, __LINE__)
#define log_error(fmt, ...)  log_(ASL_LEVEL_ERR,    "[%s] " fmt " (%s:%d)", SRC_MODULE, ##__VA_ARGS__, __FILENAME__, __LINE__)
#define log_warn(fmt, ...)   log_(ASL_LEVEL_WARNING,"[%s] " fmt,            SRC_MODULE, ##__VA_ARGS__)
#define log_notice(fmt, ...) log_(ASL_LEVEL_NOTICE, "[%s] " fmt,            SRC_MODULE, ##__VA_ARGS__)
#define log_info(fmt, ...)   log_(ASL_LEVEL_INFO,   "[%s] " fmt,            SRC_MODULE, ##__VA_ARGS__)
#if DEBUG
  #define log_debug(fmt, ...) log_(ASL_LEVEL_DEBUG, "[%s] " fmt " (%s:%d)", SRC_MODULE, ##__VA_ARGS__, __FILENAME__, __LINE__)
#else
  #define log_debug(fmt, ...) ((void)0)
#endif


#endif
