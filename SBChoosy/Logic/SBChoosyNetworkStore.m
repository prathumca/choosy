
#import "SBChoosyNetworkStore.h"
#import "SBChoosySerialization.h"
#import "SBChoosyAppInfo.h"
#import "NSString+Network.h"

static NSMutableArray *_appKeysForIconsBeingDownloaded;

@implementation SBChoosyNetworkStore

// TODO: add a queue and checks to avoid sending duplicate requests for the same app type key

#pragma Public

+ (void)downloadAppType:(NSString *)appTypeKey success:(void (^)(SBChoosyAppType *downloadedAppType))successBlock failure:(void(^)(NSError *error))failureBlock
{
    [[SBChoosyNetworkStore new] downloadAppType:appTypeKey success:successBlock failure:failureBlock];
}

+ (void)downloadAppIconForAppKey:(NSString *)appKey success:(void (^)(UIImage *))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [[SBChoosyNetworkStore new] downloadAppIconForAppKey:appKey success:successBlock failure:failureBlock];
}

#pragma Private

- (void)downloadAppType:(NSString *)appTypeKey success:(void (^)(SBChoosyAppType *downloadedAppType))successBlock failure:(void(^)(NSError *error))failureBlock
{
    NSString *fileUrl = [self urlForAppTypeData:appTypeKey];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:fileUrl] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // TODO: on error, if b/c no connection, subscribe to the Connection now Available notification, and pull data when that occurs :P
        if (error) {
            NSLog(@"Error downloading app type data for type '%@'. DATA: %@. RESPONSE: %@. ERROR: %@", appTypeKey, data, response, error);
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        NSArray *appTypes = [SBChoosySerialization deserializeAppTypesFromNSData:data];
        SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:appTypes byKey:appTypeKey];
        appType.dateUpdated = [NSDate date];
        
        if (successBlock) {
            successBlock(appType);
        }
    }] resume];
}

- (void)downloadAppIconForAppKey:(NSString *)appKey success:(void (^)(UIImage *))successBlock failure:(void (^)(NSError *))errorBlock
{
    if ([_appKeysForIconsBeingDownloaded containsObject:appKey]) {
        // aleady downloading app icon for this app key
        return;
    }
    
    @synchronized(self) {
        if (!_appKeysForIconsBeingDownloaded) _appKeysForIconsBeingDownloaded = [NSMutableArray new];
        [_appKeysForIconsBeingDownloaded addObject:appKey];
    }
    
    NSString *fileUrl = [self urlForAppIcon:appKey];
    
    NSLog(@"Downloading app icon for app key: %@, at file URL: %@", appKey, fileUrl);
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:fileUrl] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        [_appKeysForIconsBeingDownloaded removeObject:appKey];
        if ([_appKeysForIconsBeingDownloaded count] == 0) {
            _appKeysForIconsBeingDownloaded = nil; // clean up static variable if all downloads finished
        }
        
        // TODO: on error, subscribe to the Connection now Available notification, and pull data when that occurs :P
        if (error) {
            NSLog(@"Error downloading app icon for app '%@'. DATA: %@. RESPONSE: %@. ERROR: %@", appKey, data, response, error);
            return;
        };
        
//        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
//        NSInteger statusCode = [httpResponse statusCode];
//        NSDictionary *headers = [httpResponse allHeaderFields];
//        NSString *responseExpirationDate = headers[@"Expires"];
        
        UIImage *appIcon = [UIImage imageWithData:data];
        
        if (successBlock) {
            successBlock(appIcon);
        }
    }] resume];
}

- (NSString *)urlForAppTypeData:(NSString *)appTypeKey
{
    NSString *fileUrl = [NSString stringWithFormat:@"https://raw.githubusercontent.com/substantial/choosy-data/master/app-data/%@.json", appTypeKey];
    return fileUrl;
}

- (NSString *)urlForAppIcon:(NSString *)appKey
{
    NSString *appIconName = [SBChoosyAppInfo appIconFileNameForAppKey:appKey];
    NSString *fileUrl = [NSString stringWithFormat:@"https://raw.githubusercontent.com/substantial/choosy-data/master/app-icons/%@", appIconName];
    return fileUrl;
}

@end
