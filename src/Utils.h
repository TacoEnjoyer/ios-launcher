#import "Localization.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utils : NSObject
+ (NSString*)gdBundleName;
+ (NSString*)launcherBundleName;
+ (NSString*)getGeodeVersion;

+ (NSString*)docPath;

+ (void)updateGeodeVersion:(NSString*)newVer;
+ (BOOL)isJailbroken;
+ (NSString*)getGeodeReleaseURL;
+ (NSString*)getGeodeLauncherURL;
+ (UIImageView*)imageViewFromPDF:(NSString*)pdfName;
+ (NSURL*)pathToMostRecentLogInDirectory:(NSString*)directoryPath;
+ (void)showErrorGlobal:(NSString*)title error:(NSError*)error;
+ (void)showError:(UIViewController*)root title:(NSString*)title error:(NSError*)error;
+ (void)showNoticeGlobal:(NSString*)title;
+ (void)showNotice:(UIViewController*)root title:(NSString*)title;
+ (NSString*)archName;
+ (void)toggleKey:(NSString*)key;
+ (NSString*)sha256sum:(NSString*)path;
+ (NSString*)getGDBinaryHash;
+ (NSString*)getGDDocPath;
+ (NSString*)getGDBinaryPath;
+ (NSString*)getGDBundlePath;
+ (NSUserDefaults*)getPrefs;
+ (NSUserDefaults*)getPrefsGC;
+ (BOOL)isSandboxed;
+ (BOOL)isContainerized;
+ (const char*)getKillAllPath;
+ (void)increaseLaunchCount;
+ (void)tweakLaunch_withSafeMode:(BOOL)safemode;
+ (NSString*)colorToHex:(UIColor*)color;

+ (NSData*)encryptData:(NSData*)data withKey:(NSString*)key;
+ (NSData*)decryptData:(NSData*)data withKey:(NSString*)key;
@end
