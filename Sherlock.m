//
//  Sherlock.m
//
//
//  Created by Alex Reynolds on 1/11/13.
//  Copyright (c) 2013 OutCoursing. All rights reserved.
//

#import "Sherlock.h"
#import <mach/mach.h>
#import <mach/mach_host.h>

static NSString *const kDebugLogName = @"debugLog.plist";
static NSString *const kDeviceModel = @"Device Model";
static NSString *const kDeviceiOSVersion = @"Device iOS Version";
static NSString *const kDeviceAppVersion = @"Device App version";

@implementation Sherlock

-(id) init{
    
    NSArray *pListpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *pListdocumentsDirectory = [pListpaths objectAtIndex:0];
    _logPath = [pListdocumentsDirectory stringByAppendingPathComponent:kDebugLogName];
    _logger = [self loadDebugLog];
    
    if(![_logger objectForKey:Watson_DeviceInfo]){
        [self getDeviceInfo];
    }

    return self;
}

/** logUncaughtException is called from main.m when an uncaught exception occurs and is passed an NSException Object
 *  According to Apple all exceptions are non-recoverable so @try @catch should not be applied
 *  We catch all exceptions here and log the stack trace to the debug log for later send
 */
-(void) logUncaughtException:(NSDictionary *)exception
{
    NSLog(@"exception");
    // Get our log file

    NSMutableDictionary *lastState;
    int navCounter = [[_logger objectForKey:Watson_Controller] count];

    if(navCounter){
        lastState = [[_logger objectForKey:Watson_Controller] lastObject];
    }
    
    
    [_logger setObject:exception forKey:@"uncaughtException"];
    [_logger setObject:[lastState valueForKey:@"controllerName"] forKey:@"crashedOnController"];
    [_logger setObject:[NSNumber numberWithBool:YES] forKey:@"crashed"];
    [self saveDebugLog];
}


-(BOOL) sendDebugLog
{

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_logger
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *jsonString =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
    [Sherlock deleteDebugLog];
    
    return YES;
}

-(void) updateAppStatus:(NSString *)event controller:(NSString *)controller data:(id)data{
    
    NSString *currentEventName = event;
    
    NSMutableArray *currentAction = [[NSMutableArray alloc] init];
    if(data){
        [currentAction addObject:data];
    }
    [currentAction addObject:currentEventName];
    
    

    
    NSString *currentControllerName = controller;
    NSMutableDictionary *lastState;
    
    
    int navCounter = [[_logger objectForKey:Watson_Controller] count];
    if(navCounter){
        lastState = [[_logger objectForKey:Watson_Controller] lastObject];
    }
    
    // Controller already exists in the log so append to controller data
    if(navCounter &&
       [[lastState valueForKey:@"controllerName"] isEqualToString:currentControllerName]){
        
        [[[[_logger objectForKey:Watson_Controller] lastObject] objectForKey:Watson_Event] addObject:currentEventName];
        if(data){
            [[[[_logger objectForKey:Watson_Controller] lastObject] objectForKey:Watson_Event] addObject:data];
        }
        
        // Controller doesn't exist so make a new entry
    } else {
        NSMutableDictionary *newState = [[NSMutableDictionary alloc] init];
        [newState setObject:currentControllerName forKey:@"controllerName"];
        [newState setObject:currentAction forKey:Watson_Event];
        
        [[_logger objectForKey:Watson_Controller] addObject:newState];
    }
    
    // If storing of system memory is enable, then go get current stats
    if(SHERLOCK_MEMORY){
        [self updateSherlockMemory];
    }    

    [self saveDebugLog];
}


-(void) updateSherlockMemory
{
    // Go get our memory stats
    NSDictionary *memory = [Sherlock report_memory];
    
    // Grab a reference to the memory array to check to see if it exists
    NSMutableArray *memoryArray = [[[_logger objectForKey:Watson_Controller] lastObject] objectForKey:Watson_Memory];
    
    // If we haven't added the array yet, IE New log for controller, then add array.
    if (!memoryArray) {
        [[[_logger objectForKey:Watson_Controller] lastObject] setObject:[[NSMutableArray alloc] init] forKey:Watson_Memory];
    }
    
    // Update array with memory info
    [[[[_logger objectForKey:Watson_Controller] lastObject] objectForKey:Watson_Memory] addObject:memory];

    
}

+(BOOL) checkForCrash{
    NSArray *pListpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *pListdocumentsDirectory = [pListpaths objectAtIndex:0];
    NSString *loggerPath = [pListdocumentsDirectory stringByAppendingPathComponent:kDebugLogName];
    NSFileManager*fileManager = [NSFileManager defaultManager];
    
    //Create a plist if it doesn't alread exist
    if ([fileManager fileExistsAtPath: loggerPath])
    {
        NSDictionary *log = [[NSDictionary alloc] initWithContentsOfFile:loggerPath];
        if([[log valueForKey:@"crashed"]boolValue]){
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

+(NSDictionary *) report_memory {
    NSString *memory_used = @"";
    NSString *memory_free = @"";
    
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"Memory in use (in bytes): %u  Free: %u", info.resident_size, info.virtual_size);
        
        memory_used = [NSString stringWithFormat:@"%u", info.resident_size ];
        memory_free = [NSString stringWithFormat:@"%u", (info.virtual_size -  info.resident_size) ];
        
        return [NSDictionary dictionaryWithObjectsAndKeys:memory_used, @"Used", memory_free, @"Free", nil];
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
        return nil;
    }
}

-(void) getDeviceInfo
{
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *model = [currentDevice model];
    NSString *systemVersion = [currentDevice systemVersion];
    NSString *appVersion = [[NSBundle mainBundle]
                            objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    
    NSDictionary *deviceInfo = [NSDictionary dictionaryWithObjectsAndKeys:model, kDeviceModel, systemVersion, kDeviceiOSVersion, appVersion, kDeviceAppVersion, nil];
    

    [_logger setObject:deviceInfo forKey:Watson_DeviceInfo];
    
    
}
#pragma mark  - File Access Methods
-(NSMutableDictionary *) loadDebugLog
{
    NSMutableDictionary *log;
    NSFileManager*fileManager = [NSFileManager defaultManager];
    
    //Create a plist if it doesn't alread exist
    if ([fileManager fileExistsAtPath: _logPath])
    {
        log = [[NSMutableDictionary alloc] initWithContentsOfFile:_logPath];
    } else {
        log = [[NSMutableDictionary alloc] init];
        [log setObject:[[NSMutableArray alloc] init] forKey:Watson_Controller];
        
    }
    return log;
}

-(void) saveDebugLog
{
    [_logger writeToFile: _logPath atomically: YES];
}

+(void) deleteDebugLog
{
    NSArray *pListpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *pListdocumentsDirectory = [pListpaths objectAtIndex:0];
    NSString *loggerPath = [pListdocumentsDirectory stringByAppendingPathComponent:kDebugLogName];
    NSFileManager*fileManager = [NSFileManager defaultManager];
    
    //Create a plist if it doesn't alread exist
    if ([fileManager fileExistsAtPath: loggerPath])
    {
        [fileManager removeItemAtPath:loggerPath error:nil];
    } 
}

@end
