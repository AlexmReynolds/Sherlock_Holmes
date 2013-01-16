//
//  Sherlock.h
//
//
//  Created by Alex Reynolds on 1/11/13.
//  Copyright (c) 2013 OutCoursing. All rights reserved.
//

#import <Foundation/Foundation.h>

// Set default values that can be overwritten by values defined in the app
//

#ifndef SHERLOCK_ENABLED
#   define SHERLOCK_ENABLED 1
#endif

#ifndef SHERLOCK_MEMORY
#   define SHERLOCK_MEMORY 1
#endif

#ifndef SHERLOCK_DATE
#   define SHERLOCK_DATE 1
#endif

// Begin defining key names for log data

#define Watson_Event @"event"
#define Watson_Controller @"navigationPath"
#define Watson_Date @"Date"
#define Watson_Memory @"Memory"
#define Watson_DeviceInfo @"DeviceInfo"


@interface Sherlock : NSObject{
    NSMutableDictionary *_logger;
    NSString *_logPath;
}
-(void) logUncaughtException:(NSDictionary *)exception;
-(void) updateAppStatus:(NSString *)event controller:(NSString *)controller data:(id)data;
-(BOOL) sendDebugLog;
+(BOOL) checkForCrash;
+(void) deleteDebugLog;
@end


#if defined(SHERLOCK_ENABLED) && SHERLOCK_ENABLED
    #define Sherlock_Sleuth( event, logData ) \
    {\
        NSString *eventName = @""; \
        Sherlock *logger = [[Sherlock alloc] init]; \
        if (event){\
            eventName = event;\
        }else {\
            eventName = NSStringFromSelector(_cmd); \
        }\
        [logger updateAppStatus:eventName controller:NSStringFromClass([self class]) data:logData]; \
    }
    #define Sherlock_Solve() \
    {\
        Sherlock *logger = [[Sherlock alloc] init]; \
        [logger sendDebugLog]; \
    }
    #define Sherlock_Investigate()[Sherlock checkForCrash]
#else
    #define Sherlock_Sleuth(...)
    #define Sherlock_Investigate(...)
    #define Sherlock_Solve(...)
#endif