
#import "SBChoosyAppInfo.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "SBChoosyAppAction.h"
#import "SBChoosyNetworkStore.h"
#import "SBChoosyLocalStore.h"
#import "NSThread+Helpers.h"

NSString * const SBChoosyDidUpdateAppIconNotification = @"SBChoosyDidUpdateAppIconNotification";

@implementation SBChoosyAppInfo

static NSString *_appIconFileExtension = @"png";

- (SBChoosyAppAction *)findActionWithKey:(NSString *)actionKey
{
    for (SBChoosyAppAction *action in self.appActions) {
        if ([[action.actionKey lowercaseString] isEqualToString:[actionKey lowercaseString]]) {
            return action;
        }
    }
    
    return nil;
}

- (void)downloadAppIcon
{
    [SBChoosyNetworkStore downloadAppIconForAppKey:self.appKey success:^(UIImage *appIcon)
     {
         [SBChoosyLocalStore cacheAppIcon:appIcon forAppKey:self.appKey];
         
         // tell everyone icon got updated! woooo
         [NSThread executeOnMainThread:^{
             [[NSNotificationCenter defaultCenter] postNotificationName:SBChoosyDidUpdateAppIconNotification object:self userInfo:@{@"appIcon" : appIcon}];
         }];
     } failure:^(NSError *error) {
         NSLog(@"Couldn't download icon for app key %@", self.appKey);
     }];
}

#pragma mark MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"appName" : @"name",
             @"appKey" : @"key",
             @"appURLScheme" : @"app_url_scheme",
             @"appActions" : @"actions",
             @"isInstalled" : NSNull.null,
             @"isNew" : NSNull.null,
             @"isDefault" : NSNull.null,
             @"isAppIconDownloading" : NSNull.null
             };
}

+ (NSValueTransformer *)appActionsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[SBChoosyAppAction class]];
}

+ (NSValueTransformer *)appURLSchemeJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSString *)appIconFileNameForAppKey:(NSString *)appKey
{
    // TODO: what if scale goes up to @3x or @4x? We need to then show previous-X icons such as @2x.
    NSString *appIconName = [self appIconFileNameWithoutExtensionForAppKey:appKey];

    appIconName = [[appIconName stringByAppendingString:@"."] stringByAppendingString:[self appIconFileExtension]];

    return appIconName;
}

+ (NSString *)appIconFileNameWithoutExtensionForAppKey:(NSString *)appKey
{
    NSString *appIconName = appKey;
    
    // add suffix for retina screens, ex: safari@2x.png
    NSInteger scale = (NSInteger)[[UIScreen mainScreen] scale];
    
    if (scale > 1) appIconName = [appIconName stringByAppendingFormat:@"@%ldx", (long)scale];
    
    return appIconName;
}

+ (NSString *)appIconFileExtension
{
    return _appIconFileExtension;
}

@end
