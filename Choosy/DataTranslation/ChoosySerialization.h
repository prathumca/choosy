
#import <Foundation/Foundation.h>
#import "ChoosyAppType.h"

@interface ChoosySerialization : NSObject

/**
 *  Converts NSData into array of ChoosyAppType objects.
 *
 *  @param jsonFormatData NSData representation of ChoosyAppType's JSON.
 *
 *  @return Array of ChoosyAppType objects; nil if no objects found.
 */
+ (NSArray *)deserializeAppTypesFromNSData:(NSData *)jsonFormatData;

+ (NSArray *)deserializeAppTypesFromJSON:(NSArray *)appTypesJSON;

+ (ChoosyAppType *)deserializeAppTypeFromJSON:(NSDictionary *)appTypeJSON;

+ (NSData *)serializeAppTypesToNSData:(NSArray *)appTypes;

@end
