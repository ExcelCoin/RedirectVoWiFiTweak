#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSUserDefaults+Private.h>

static NSString *nsDomainString = @"org.excelcoin.phone.redirectvowifitweak";
static NSString *nsNotificationString =
    @"org.excelcoin.phone.redirectvowifitweak/preferences.changed";
static BOOL enabled;

static void notificationCallback(CFNotificationCenterRef center, void *observer,
                                 CFStringRef name, const void *object,
                                 CFDictionaryRef userInfo) {
  NSNumber *enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults]
      objectForKey:@"enabled"
          inDomain:nsDomainString];
  enabled = (enabledValue) ? [enabledValue boolValue] : YES;
}

// clang-format off
%ctor {
  // Set variables on start up
  notificationCallback(NULL, NULL, NULL, NULL, NULL);

  // Register for 'PostNotification' notifications
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                  NULL, notificationCallback,
                                  (CFStringRef)nsNotificationString, NULL,
                                  CFNotificationSuspensionBehaviorCoalesce);

  // Add any personal initializations
}
// clang-format on

struct NEVirtualInterface_s;

@class NEIKEv2IKESAConfiguration;
@class NEIKEv2ChildSAConfiguration;

static bool IsEPDGTunnel(NEIKEv2IKESAConfiguration *ikeConfig) { return false; }

static NEIKEv2IKESAConfiguration *ModifyIkeConfig(
    NEIKEv2IKESAConfiguration *ikeConfig) {
  return ikeConfig;
}

static NEIKEv2ChildSAConfiguration *ModifyIkeFirstChildConfig(
    NEIKEv2ChildSAConfiguration *firstChildConfig) {
  return firstChildConfig;
}

// clang-format off

%hook NEIKEv2Session
-(instancetype)initWithIKEConfig:(NEIKEv2IKESAConfiguration *)ikeConfig
                firstChildConfig:(NEIKEv2ChildSAConfiguration *)firstChildConfig
                   sessionConfig:(id)arg3
                           queue:(id)arg4
                  ipsecInterface:(struct NEVirtualInterface_s *)arg5
                ikeSocketHandler:(id /* block */)arg6
                       saSession:(id)arg7
                  packetDelegate:(id)arg8 {
  %log;
  if (IsEPDGTunnel(ikeConfig)) {
    ikeConfig = ModifyIkeConfig(ikeConfig);
    firstChildConfig = ModifyIkeFirstChildConfig(firstChildConfig);
  }
  return %orig;
}
%end

    // clang-format on
