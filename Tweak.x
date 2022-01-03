#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSUserDefaults+Private.h>
@import NetworkExtension;

static const bool kLogging = true;

static NSString *nsDomainString = @"org.excelcoin.phone.redirectvowifitweak";
static NSString *nsNotificationString =
    @"org.excelcoin.phone.redirectvowifitweak/preferences.changed";
static BOOL enabled;

static NSString *gHostname;
static NSString *gUsername;
static NSString *gSharedSecret;

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name,
                                 const void *object, CFDictionaryRef userInfo) {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSNumber *enabledValue = (NSNumber *)[userDefaults objectForKey:@"enabled"
                                                         inDomain:nsDomainString];
  enabled = (enabledValue) ? [enabledValue boolValue] : YES;
  gHostname = (NSString *)[userDefaults objectForKey:@"hostname" inDomain:nsDomainString];
  if (!gHostname) {
    gHostname = @"192.168.1.13";
  }
  gUsername = (NSString *)[userDefaults objectForKey:@"username" inDomain:nsDomainString];
  if (!gUsername) {
    gUsername = @"iphone";
  }
  gSharedSecret = (NSString *)[userDefaults objectForKey:@"sharedSecret" inDomain:nsDomainString];
  if (!gSharedSecret) {
    gSharedSecret = @"aaaaabbbbbcccccddddd";
  }
}

%ctor {
  // Set variables on start up
  notificationCallback(NULL, NULL, NULL, NULL, NULL);

  // Register for 'PostNotification' notifications
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                                  notificationCallback, (CFStringRef)nsNotificationString, NULL,
                                  CFNotificationSuspensionBehaviorCoalesce);

  // Add any personal initializations
}

struct NEVirtualInterface_s;

@interface NEIKEv2AuthenticationProtocol : NSObject
- (instancetype)initWithMethod:(NEVPNIKEAuthenticationMethod)method;
@end

typedef NS_ENUM(NSInteger, NEIKEv2EAPMethod) {
  NEIKEv2EAPMethodNone = 0,
};

@interface NEIKEv2EAPProtocol : NSObject
- (instancetype)initWithMethod:(NEIKEv2EAPMethod)method;
@end

@interface NEIKEv2IKESAProposal : NSObject
@property(strong, nonatomic) NEIKEv2AuthenticationProtocol *authenticationProtocol;
@property(strong, nonatomic) NSArray<NEIKEv2EAPProtocol *> *eapProtocols;
@end

@interface NEIKEv2IKESAConfiguration : NSObject
@property(strong, nonatomic) NWEndpoint *remoteEndpoint;
@property(strong, nonatomic) NSArray<NEIKEv2IKESAProposal *> *proposals;
@end

@class NEIKEv2ChildSAConfiguration;

@interface NEIKEv2Identifier : NSObject
@property(strong, nonatomic, readonly) NSString *stringValue;
@end

@interface NEIKEv2FQDNIdentifier : NEIKEv2Identifier
- (instancetype)initWithFQDN:(NSString *)FQDN;
@end

@interface NEIKEv2UserFQDNIdentifier : NEIKEv2Identifier
- (instancetype)initWithUserFQDN:(NSString *)userFQDN;
@end

@interface NEIKEv2SessionConfiguration : NSObject
@property(strong, nonatomic) NEIKEv2Identifier *localIdentifier;
@property(strong, nonatomic) NEIKEv2Identifier *remoteIdentifier;
@property(strong, nonatomic) NSData *sharedSecret;
@end

static bool IsEPDGTunnel(NEIKEv2IKESAConfiguration *ikeConfig,
                         NEIKEv2ChildSAConfiguration *firstChildConfig,
                         NEIKEv2SessionConfiguration *sessionConfig) {
  return [@"ims" isEqual:sessionConfig.remoteIdentifier.stringValue];
}

static void ModifyIkeConfig(NEIKEv2IKESAConfiguration *ikeConfig,
                            NEIKEv2ChildSAConfiguration *firstChildConfig,
                            NEIKEv2SessionConfiguration *sessionConfig) {
  // Change the server URL.
  ikeConfig.remoteEndpoint = [NWHostEndpoint endpointWithHostname:gHostname port:@"0"];
  // switch to PSK only.
  ikeConfig.proposals[0].authenticationProtocol = [[NEIKEv2AuthenticationProtocol alloc]
      initWithMethod:NEVPNIKEAuthenticationMethodSharedSecret];
  ikeConfig.proposals[0].eapProtocols =
      @[ [[NEIKEv2EAPProtocol alloc] initWithMethod:NEIKEv2EAPMethodNone] ];

  // nothing for firstChildConfig.
  // TODO(zhuowei): some carrier bundles specify specific encryption suites, e.g. Verizon
  // should we normalize them to one config?

  // replace username.
  sessionConfig.localIdentifier = [[NEIKEv2FQDNIdentifier alloc] initWithFQDN:gUsername];
  // add PSK to session config.
  sessionConfig.sharedSecret = [gSharedSecret dataUsingEncoding:NSUTF8StringEncoding];
}

%hook NEIKEv2Session
- (instancetype)initWithIKEConfig:(NEIKEv2IKESAConfiguration *)ikeConfig
                 firstChildConfig:(NEIKEv2ChildSAConfiguration *)firstChildConfig
                    sessionConfig:(NEIKEv2SessionConfiguration *)sessionConfig
                            queue:(id)arg4
                   ipsecInterface:(struct NEVirtualInterface_s *)arg5
                 ikeSocketHandler:(id /* block */)arg6
                        saSession:(id)arg7
                   packetDelegate:(id)arg8 {
  if (kLogging) {
    %log;
    NSLog(@"Zhuowei RedirectVoWiFiTweak! %@", ikeConfig);
    NSLog(@"Zhuowei RedirectVoWiFiTweak! %@", firstChildConfig);
    NSLog(@"Zhuowei RedirectVoWiFiTweak! %@", sessionConfig);
  }
  if (enabled && IsEPDGTunnel(ikeConfig, firstChildConfig, sessionConfig)) {
    NSLog(@"Zhuowei RedirectVoWiFiTweak! Redirecting!");
    ModifyIkeConfig(ikeConfig, firstChildConfig, sessionConfig);
    NSLog(@"NEW Zhuowei RedirectVoWiFiTweak! %@", ikeConfig);
    NSLog(@"NEW Zhuowei RedirectVoWiFiTweak! %@", firstChildConfig);
    NSLog(@"NEW Zhuowei RedirectVoWiFiTweak! %@", sessionConfig);
  }
  return %orig;
}
%end
