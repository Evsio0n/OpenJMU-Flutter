#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <UserNotifications/UserNotifications.h>
#import <Flutter/Flutter.h>
static NSString *SendTime;
static NSString *token;
static NSString *isAddToPushSucess;
@implementation AppDelegate
-(NSString*) PushToken{
    return token;
}
-(NSString*) PushTime {
    return SendTime;
}
-(NSString*) PushSucess{
    return isAddToPushSucess;
}
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
    FlutterMethodChannel *iosTokenChannel = [FlutterMethodChannel methodChannelWithName:@"cn.edu.jmu.openjmu/iosPushToken" binaryMessenger:controller];
    [iosTokenChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        
        if ([@"getPushToken" isEqualToString:call.method]) {
            if (token != nil) {
                result([self PushToken]);
                printf("Write success!");
            } else {
                result([FlutterError errorWithCode:@"01" message:[NSString stringWithFormat:@"异常"] details:@"进入tryCatchError"]);}
        } else {
            if ([@"getPushDate" isEqualToString:call.method]) {
                if (SendTime != nil) {
                    result([self PushTime]);
                } else {
                    result([FlutterError errorWithCode:@"02" message:[NSString stringWithFormat:@"异常"] details:@"进入tryCatchError"]);}
            }
            else {
                if ([@"getPushSuccess" isEqualToString:call.method]) {
                    if (isAddToPushSucess != nil) {
                        result([self PushSucess]);
                    } else {
                        result([FlutterError errorWithCode:@"03" message:[NSString stringWithFormat:@"异常"] details:@"进入tryCatchError"]); }
                } else {
                    result(FlutterMethodNotImplemented);
                }
            }
        }
        
        
    }];
    {
        //TODO:暂时还未实现的功能
        if (@available(iOS 10.0, *)) {
            
            [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionBadge|UNAuthorizationOptionSound|UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                NSLog(@"%@", error);
            }];
            UNNotificationCategory* generalCategory = [UNNotificationCategory
                                                       categoryWithIdentifier:@"GENERAL"
                                                       actions:@[]
                                                       intentIdentifiers:@[]
                                                       options:UNNotificationCategoryOptionCustomDismissAction];
            
            // Create the custom actions for expired timer notifications.
            UNNotificationAction* stopAction = [UNNotificationAction
                                                actionWithIdentifier:@"SNOOZE_ACTION"
                                                title:@"取消"
                                                options:UNNotificationActionOptionAuthenticationRequired];
            UNNotificationAction* forAction = [UNNotificationAction
                                               actionWithIdentifier:@"FOR_ACTION"
                                               title:@"进入OpenJMU"
                                               options:UNNotificationActionOptionForeground];
            
            // Create the category with the custom actions.
            UNNotificationCategory* expiredCategory = [UNNotificationCategory
                                                       categoryWithIdentifier:@"TIMER_EXPIRED"
                                                       actions:@[stopAction,forAction]
                                                       intentIdentifiers:@[]
                                                       options:UNNotificationCategoryOptionNone];
            
            // Register the notification categories.
            UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
            [center setDelegate:self];
            [center setNotificationCategories:[NSSet setWithObjects:generalCategory, expiredCategory,
                                               nil]];
            
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        } else {
            
        }
        return YES;
    }
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler
{
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *webpageURL = userActivity.webpageURL;
        NSString *host = webpageURL.host;
        if ([host isEqualToString:@"××××.openjmu.xyz"]) {
            //判断域名是自己的网站，进行我们需要的处理
        }else{
            [[UIApplication sharedApplication]openURL:webpageURL];
        }
    }
    return YES;
}
#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    NSLog(@"%s", __func__);
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
    //在前台的时候显示通知
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler{
    NSLog(@"%s", __func__);
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.badge = @(-1);
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"clearBadge" content:content trigger:0];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
    }];
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)pToken {
    //保存deviceToken并上传token
    //NSLog(@"Register success:%@", pToken);//log当前的token
    NSDate *now = [NSDate date];//获取现在的时间
    NSDateFormatter *forMatter = [[NSDateFormatter alloc] init];
    [forMatter setDateFormat:@"yyyy/MM/dd/HH:mm:ss"];
    SendTime = [forMatter stringFromDate:now];//转换系统现在的时间
    token = [[[[pToken description]
                stringByReplacingOccurrencesOfString:@"<" withString:@""]
               stringByReplacingOccurrencesOfString:@">" withString:@""]
              stringByReplacingOccurrencesOfString:@" " withString:@""];//把空格和<>去掉
    /**NSURL *url = [NSURL URLWithString:@"http://dns.135792468.xyz:8787/push"];//创建请求IP
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *json = @{
                           @"token": token1,
                           @"date": SendTime,
                           };
    isAddToPushSucess = @"Success";
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    request.HTTPBody = data;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    }];**/
}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSData *) error{
    isAddToPushSucess = @"Fail";
}

/// Temporary migration with `quick_actions` package's event not triggered. See https://github.com/flutter/flutter/issues/13634#issuecomment-392303964
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
    FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
    
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/quick_actions" binaryMessenger:controller];
    [channel invokeMethod:@"launch" arguments:shortcutItem.type];
}
-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    NSLog(@"Wait Open Url = %@",url);
    return YES;
}
@end
