#import "SwrveConfig.h"

@implementation SwrveConfig

@synthesize orientation;
@synthesize prefersIAMStatusBarHidden;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize contentServer;
@synthesize identityServer;
@synthesize language;
@synthesize appVersion;
@synthesize autoDownloadCampaignsAndResources;
@synthesize inAppMessageBackgroundColor;
@synthesize newSessionInterval;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS
@synthesize pushEnabled;
@synthesize provisionalPushNotificationEvents;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize notificationCategories;
@synthesize pushResponseDelegate;
#endif //!defined(SWRVE_NO_PUSH)
@synthesize appGroupIdentifier;
@synthesize autoShowMessagesMaxDelay;
@synthesize stack;
@synthesize abTestDetailsEnabled;
@synthesize permissionsDelegate;

-(id) init
{
    if ( self = [super init] ) {
        httpTimeoutSeconds = 60;
        autoDownloadCampaignsAndResources = YES;
        orientation = SWRVE_ORIENTATION_BOTH;
        prefersIAMStatusBarHidden = YES;
        language = [[NSLocale preferredLanguages] objectAtIndex:0];
        newSessionInterval = 30;

        self.autoSendEventsOnResume = YES;
        self.autoSaveEventsOnResign = YES;
#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS
        self.pushEnabled = NO;
        self.provisionalPushNotificationEvents = nil;
        self.pushNotificationEvents = [NSSet setWithObject:@"Swrve.session.start"];
        self.autoCollectDeviceToken = YES;
#endif //!defined(SWRVE_NO_PUSH)
        self.autoShowMessagesMaxDelay = 5000;
        self.resourcesUpdatedCallback = ^() {
            // Do nothing by default.
        };
        self.stack = SWRVE_STACK_US;
    }
    return self;
}

@end

@implementation ImmutableSwrveConfig

@synthesize orientation;
@synthesize prefersIAMStatusBarHidden;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize contentServer;
@synthesize identityServer;
@synthesize language;
@synthesize appVersion;
@synthesize autoDownloadCampaignsAndResources;
@synthesize inAppMessageBackgroundColor;
@synthesize newSessionInterval;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS
@synthesize pushEnabled;
@synthesize provisionalPushNotificationEvents;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize notificationCategories;
@synthesize pushResponseDelegate;
#endif //!defined(SWRVE_NO_PUSH)
@synthesize appGroupIdentifier;
@synthesize autoShowMessagesMaxDelay;
@synthesize stack;
@synthesize abTestDetailsEnabled;
@synthesize permissionsDelegate;

- (id)initWithMutableConfig:(SwrveConfig*)config
{
    if (self = [super init]) {
        orientation = config.orientation;
        prefersIAMStatusBarHidden = config.prefersIAMStatusBarHidden;
        httpTimeoutSeconds = config.httpTimeoutSeconds;
        eventsServer = config.eventsServer;
        contentServer = config.contentServer;
        identityServer = config.identityServer;
        language = config.language;
        appVersion = config.appVersion;
        autoDownloadCampaignsAndResources = config.autoDownloadCampaignsAndResources;
        inAppMessageBackgroundColor = config.inAppMessageBackgroundColor;
        newSessionInterval = config.newSessionInterval;
        resourcesUpdatedCallback = config.resourcesUpdatedCallback;
        autoSendEventsOnResume = config.autoSendEventsOnResume;
        autoSaveEventsOnResign = config.autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS
        pushEnabled = config.pushEnabled;
        provisionalPushNotificationEvents = config.provisionalPushNotificationEvents;
        pushNotificationEvents = config.pushNotificationEvents;
        autoCollectDeviceToken = config.autoCollectDeviceToken;
        notificationCategories = config.notificationCategories;
        pushResponseDelegate = config.pushResponseDelegate;
#endif //!defined(SWRVE_NO_PUSH)
        appGroupIdentifier = config.appGroupIdentifier;
        autoShowMessagesMaxDelay = config.autoShowMessagesMaxDelay;
        stack = config.stack;
        abTestDetailsEnabled = config.abTestDetailsEnabled;
        permissionsDelegate = config.permissionsDelegate;
    }

    return self;
}

@end
