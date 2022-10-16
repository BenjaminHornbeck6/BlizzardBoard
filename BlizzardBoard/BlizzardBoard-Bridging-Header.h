//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Foundation/Foundation.h>
#import "TSUtil.h"

@interface LSApplicationWorkspace : NSObject
- (id)allInstalledApplications;
@end

@interface LSBundleProxy
@property(readonly, nonatomic) NSURL *bundleURL;
@end

@interface LSApplicationProxy : LSBundleProxy
@end

@class BSMonotonicReferenceTime, NSArray, NSNumber, NSString, NSURL, SBSApplicationShortcutService, SBSApplicationShortcutServiceFetchResult;
@interface SBFApplication : NSObject
{
    NSString *_displayName;
}
@property(readonly, nonatomic) NSString *displayName;
- (id)initWithApplicationBundleIdentifier:(id)arg1;
@end
