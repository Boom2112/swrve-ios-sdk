#import "SwrveMigrationsManager.h"

@interface SwrveMigrationsManager ()

@property(nonatomic) ImmutableSwrveConfig *config;
@property(nonatomic) NSString *cacheVersionFilePath;

@end

@implementation SwrveMigrationsManager

const static int SWRVE_SDK_CACHE_VERSION = 2;

@synthesize cacheVersionFilePath;
@synthesize config;

- (id)initWithConfig:(ImmutableSwrveConfig*)swrveConfig{
    self = [super init];
    if (self) {
        self.config = swrveConfig;
        self.cacheVersionFilePath = [SwrveLocalStorage swrveCacheVersionFilePath];
    }
    return self;
}

- (void)checkMigrations {
    @synchronized (self) {
        int oldCacheVersion = [self currentCacheVersion];
        BOOL firstRun = NO;

        // Detect if this is a first time install of the SDK
        if (oldCacheVersion == 0) {
            NSString* userId = [SwrveLocalStorage swrveUserId];
            if (userId == nil) {
                firstRun = YES; // Skip migrations
            }
        }

        if (!firstRun) {
            if (oldCacheVersion < SWRVE_SDK_CACHE_VERSION) {
                [self migrateFromVersion:oldCacheVersion];
            } else {
                DebugLog(@"No cache migration required.");
            }
        }

        if (firstRun || oldCacheVersion != SWRVE_SDK_CACHE_VERSION) {
            [SwrveMigrationsManager markAsMigrated]; // update stored current version so migration doesn't execute again.
        }
    }
}

- (int)currentCacheVersion {
    int currentCacheVersion = 0;

    NSError *error = nil;
    NSString *file_contents = [[NSString alloc] initWithContentsOfFile:cacheVersionFilePath encoding:NSUTF8StringEncoding error:&error];
    if (!error && file_contents) {
        currentCacheVersion = [file_contents intValue];
    }

    return currentCacheVersion;
}

+ (void)markAsMigrated {
    [SwrveMigrationsManager setCurrentCacheVersion:SWRVE_SDK_CACHE_VERSION];
}

+ (void)setCurrentCacheVersion:(int)cacheVersion {
    NSString *_cacheVersionFilePath = [SwrveLocalStorage swrveCacheVersionFilePath];
    NSString *cacheVersionString = [NSString stringWithFormat:@"%i", cacheVersion];
    NSError *error = nil;
    [cacheVersionString writeToFile:_cacheVersionFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        DebugLog(@"Could not set current cache version to %i in filePath:%@. Error: %@ %@", cacheVersion, _cacheVersionFilePath, error, [error userInfo]);
    }
}

- (void)migrateFromVersion:(int)oldVersion {

    int migrateFrom = oldVersion + 1;
    if (oldVersion == 0) {
        migrateFrom = oldVersion; // hack
    }

    // PLEASE READ:
    // do not add break to this switch statement so execution will start at oldVersion + 1, and run straight through to the latest
    switch (migrateFrom) {
        case 0: {
            [self migrate0]; // various migrations before 5.0
        }
        case 1: {
            [self migrate1]; // migrate from 4.11.4 to 5.0
        }
        case 2: {
            [self migrate2]; // migrate from 5.3 to 6.0
        }
    }
}

- (void)migrate0 {
    DebugLog(@"Executing version 0 migration code. Migrate legacy data from cache directory to application data. And change protection level.");
    NSString* cachePath = [SwrveLocalStorage cachePath];
    NSString* applicationSupportPath = [SwrveLocalStorage applicationSupportPath];
    NSString* documentPath = [SwrveLocalStorage documentPath];

    [self migrate_0_delete_olderDeviceIDs];
    [self migrate_0_EventFileFromOldPath:cachePath toNewPath:applicationSupportPath];
    [self migrate_0_InstallTimeFileOldPath:cachePath toNewPath:documentPath];
    [self migrate_0_UserResourcesFileFromOldPath:cachePath toNewPath:applicationSupportPath];
    [self migrate_0_UsersResourcesDiffFileFromOldPath:cachePath toNewPath:applicationSupportPath];
    [self migrate_0_SettingsFromOldPath:cachePath toNewPath:applicationSupportPath];
    [self migrate_0_CampaignsFromOldPath:cachePath toNewPath:applicationSupportPath];
}

- (void)migrate_0_delete_olderDeviceIDs {
    NSString *oldShortDeviceIdKey1 = @"swrve_device_id";
    NSString *oldShortDeviceId1 =  [[NSUserDefaults standardUserDefaults] stringForKey:oldShortDeviceIdKey1];
    if (oldShortDeviceId1 != nil) {
       [[NSUserDefaults standardUserDefaults] removeObjectForKey:oldShortDeviceIdKey1];
    }

    NSString *oldShortDeviceIdKey2 = @"short_device_id";
    NSString *oldShortDeviceId2 =  [[NSUserDefaults standardUserDefaults] stringForKey:oldShortDeviceIdKey2];
    if (oldShortDeviceId2 != nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:oldShortDeviceIdKey2];
    }
}

- (void)migrate_0_EventFileFromOldPath:(NSString *)cachePath toNewPath:(NSString *)applicationSupportPath {
    NSString *eventCacheFile = [applicationSupportPath stringByAppendingPathComponent: @"swrve_events.txt"];
    NSURL *eventFilename = [NSURL fileURLWithPath:eventCacheFile];

    NSString *eventSecondaryFile = [cachePath stringByAppendingPathComponent: @"swrve_events.txt"];
    NSURL *eventSecondaryFilename = [NSURL fileURLWithPath:eventSecondaryFile];

    if ([[NSFileManager defaultManager] isReadableFileAtPath:[eventSecondaryFilename path]]) {
        NSError *error1;
        [[NSFileManager defaultManager] copyItemAtURL:eventSecondaryFilename toURL:eventFilename error:&error1];
        if (error1) {
            DebugLog(@"Event File migration failed while copying to new file. Error: %@", error1);
        }
        NSError *error2;
        [[NSFileManager defaultManager] removeItemAtURL:eventSecondaryFilename error:&error2];
        if (error2) {
            DebugLog(@"Event File migration failed while deleting old file. Error: %@", error2);
        }
    }

    [self migrateFileProtectionAtPath:[eventFilename path]];
}

- (void)migrate_0_InstallTimeFileOldPath:(NSString *)cachePath toNewPath:(NSString *)documentPath {
    NSString *installTimeCacheFile = [documentPath stringByAppendingPathComponent: @"swrve_install.txt"];
    NSString *installTimeCacheSecondaryFile = [cachePath stringByAppendingPathComponent: @"swrve_install.txt"];
    [self migrateOldCacheFile:installTimeCacheSecondaryFile withNewPath:installTimeCacheFile];

    [self migrateFileProtectionAtPath:installTimeCacheFile];
}

- (void)migrate_0_UserResourcesFileFromOldPath:(NSString *)cachePath toNewPath:(NSString *)applicationSupportPath {
    NSString *userResourcesCacheFile = [applicationSupportPath stringByAppendingPathComponent:@"srcngt2.txt"];
    NSString *userResourcesCacheSecondaryFile = [cachePath stringByAppendingPathComponent:@"srcngt2.txt"];
    [self migrateOldCacheFile:userResourcesCacheSecondaryFile withNewPath:userResourcesCacheFile];

    NSString *userResourcesCacheSignatureFile = [applicationSupportPath stringByAppendingPathComponent:@"srcngtsgt2.txt"];
    NSString *userResourcesCacheSignatureSecondaryFile = [cachePath stringByAppendingPathComponent:@"srcngtsgt2.txt"];
    [self migrateOldCacheFile:userResourcesCacheSignatureSecondaryFile withNewPath:userResourcesCacheSignatureFile];
}

- (void)migrate_0_UsersResourcesDiffFileFromOldPath:(NSString *)cachePath toNewPath:(NSString *)applicationSupportPath {
    NSString *userResourcesDiffCacheFile = [applicationSupportPath stringByAppendingPathComponent:@"rsdfngt2.txt"];
    NSString *userResourcesDiffCacheSecondaryFile = [cachePath stringByAppendingPathComponent:@"rsdfngt2.txt"];
    [self migrateOldCacheFile:userResourcesDiffCacheSecondaryFile withNewPath:userResourcesDiffCacheFile];

    NSString *userResourcesDiffCacheSignatureFile = [applicationSupportPath stringByAppendingPathComponent:@"rsdfngtsgt2.txt"];
    NSString *userResourcesDiffCacheSignatureSecondaryFile = [cachePath stringByAppendingPathComponent:@"rsdfngtsgt2.txt"];
    [self migrateOldCacheFile:userResourcesDiffCacheSignatureSecondaryFile withNewPath:userResourcesDiffCacheSignatureFile];
}

- (void)migrate_0_SettingsFromOldPath:(NSString *)cachePath toNewPath:(NSString *)applicationSupportPath {
    NSString *settingsPath = [applicationSupportPath stringByAppendingPathComponent:@"com.swrve.messages.settings.plist"];
    NSString *oldSettingsPath = [cachePath stringByAppendingPathComponent:@"com.swrve.messages.settings.plist"];

    [self migrateOldCacheFile:oldSettingsPath withNewPath:settingsPath];
}

- (void)migrate_0_CampaignsFromOldPath:(NSString *)cachePath toNewPath:(NSString *)applicationSupportPath {
    NSString *campaignCache      = [applicationSupportPath stringByAppendingPathComponent:@"cmcc2.json"];
    NSString* oldCampaignCache      = [cachePath stringByAppendingPathComponent:@"cmcc2.json"];

    NSString *campaignCacheSignature = [applicationSupportPath stringByAppendingPathComponent:@"cmccsgt2.txt"];
    NSString* oldCampaignCacheSignature = [cachePath stringByAppendingPathComponent:@"cmccsgt2.txt"];

    [self migrateOldCacheFile:oldCampaignCache withNewPath:campaignCache];
    [self migrateOldCacheFile:oldCampaignCacheSignature withNewPath:campaignCacheSignature];
}

- (void) migrateOldCacheFile:(NSString*)oldPath withNewPath:(NSString*)newPath {
    // 4.5 migrations
    if ([[NSFileManager defaultManager] isReadableFileAtPath:oldPath]) {
        NSError *error1;
        [[NSFileManager defaultManager] copyItemAtPath:oldPath toPath:newPath error:&error1];
        if (error1) {
            DebugLog(@"Event File migration failed while copying to new file. oldPath:%@ newPath:%@ Error:%@", oldPath, newPath, error1);
        }
        NSError *error2;
        [[NSFileManager defaultManager] removeItemAtPath:oldPath error:&error2];
        if (error2) {
            DebugLog(@"Event File migration failed while deleting old file oldPath:%@ Error: %@", oldPath, error2);
        }
    }
}

- (void)migrateFileProtectionAtPath:(NSString *)path {

    if ([self isProtectedItemAtPath:path]) {
        // part of a bug with 4.7, if the device is locked and we trigger a location campaign.
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone} ofItemAtPath:path error:NULL];
    }
}

- (BOOL)isProtectedItemAtPath:(NSString *)path {
    BOOL result = YES;
    NSDictionary *attributes = nil;
    NSString *protectionAttributeValue = nil;
    NSError *error = nil;

    attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (attributes != nil) {
        protectionAttributeValue = [attributes valueForKey:NSFileProtectionKey];
        if ((protectionAttributeValue == nil) || [protectionAttributeValue isEqualToString:NSFileProtectionNone]) {
            result = NO;
        }
    } else {
        DebugLog(@"There was an issue finding the level of file protection for : %@  \nError: %@", path, error);
    }
    return result;
}

- (void)migrate1 {
    DebugLog(@"Executing version 1 migration code. Migrate data per userId");
    NSString *userId = nil;
    userId = [SwrveLocalStorage swrveUserId];

    if (userId && [userId length] > 0) {
        [self migrate_1_InstallFileWithUserId:userId];
        [self migrate_1_SeqNumWithUserId:userId];
        [self migrate_1_ApplicationSupportFiles:userId];
    } else {
        DebugLog(@"Cannot run userId dependent migrations for v1 because no user logged in.", nil);
    }
}

- (void)migrate_1_InstallFileWithUserId:(NSString *)userId {
    NSString *documentPath = [SwrveLocalStorage documentPath];
    NSString *currentFilePath = [documentPath stringByAppendingPathComponent:@"swrve_install.txt"];
    NSString *newFileName = [userId stringByAppendingString:@"swrve_install.txt"];
    NSString *newFilePath = [documentPath stringByAppendingPathComponent:newFileName];

    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:currentFilePath toPath:newFilePath error:&error];
    if (success == YES) {
        DebugLog(@"Migrated the install date file for userId: %@", userId);
    } else {
        DebugLog(@"There was an issue migrating the install date file for userId: %@", userId);
    }
    if (error) {
        DebugLog(@"There was an issue migrating the install date file for userId: %@  \nError: %@", userId, error);
    }
}

- (void)migrate_1_SeqNumWithUserId:(NSString *)userId {
    NSString *oldSeqNumKey = @"swrve_event_seqnum";
    NSString *newSeqNumKey = [userId stringByAppendingString:oldSeqNumKey];
    NSInteger seqNumValue = [[NSUserDefaults standardUserDefaults] integerForKey:oldSeqNumKey];
    [SwrveLocalStorage saveSeqNum:seqNumValue withCustomKey:newSeqNumKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:oldSeqNumKey];
    BOOL success = [[NSUserDefaults standardUserDefaults] synchronize];
    if (success) {
        DebugLog(@"Migrated the seqnum NSUserDefault for userId: %@", userId);
    } else {
        DebugLog(@"There was an issue migrating the seqnum NSUserDefault for userId: %@", userId);
    }
}

- (void)migrate_1_ApplicationSupportFiles:(NSString *)userId {
    DebugLog(@"Migrating the com.swrve.messages.settings.plist file for userId: %@", userId);
    [self migrate_1_ApplicationSupportFilesForUserId:userId andFileName:@"com.swrve.messages.settings.plist"];

    DebugLog(@"Migrating the cmcc2.json file for userId: %@", userId);
    [self migrate_1_ApplicationSupportFilesForUserId:userId andFileName:@"cmcc2.json"];

    DebugLog(@"Migrating the cmccsgt2.txt file for userId: %@", userId);
    [self migrate_1_ApplicationSupportFilesForUserId:userId andFileName:@"cmccsgt2.txt"];

    DebugLog(@"Migrating the lc.txt file for userId: %@", userId);
    [self migrate_1_ApplicationSupportFilesForUserId:userId andFileName:@"lc.txt"];

    DebugLog(@"Migrating the lcsgt.txt file for userId: %@", userId);
    [self migrate_1_ApplicationSupportFilesForUserId:userId andFileName:@"lcsgt.txt"];

    DebugLog(@"Migrating the srcngt2.txt file for userId: %@", userId);
    [self migrate_1_ApplicationSupportFilesForUserId:userId andFileName:@"srcngt2.txt"];

    DebugLog(@"Migrating the srcngtsgt2.txt file for userId: %@", userId);
    [self migrate_1_ApplicationSupportFilesForUserId:userId andFileName:@"srcngtsgt2.txt"];

    DebugLog(@"Migrating the rsdfngt2.txt file for userId: %@", userId);
    [self migrate_1_ApplicationSupportFilesForUserId:userId andFileName:@"rsdfngt2.txt"];

    DebugLog(@"Migrating the rsdfngtsgt2.txt file for userId: %@", userId);
    [self migrate_1_ApplicationSupportFilesForUserId:userId andFileName:@"rsdfngtsgt2.txt"];

    DebugLog(@"Migrating the swrve_events.txt file for userId: %@", userId);
    [self migrate_1_ApplicationSupportFilesForUserId:userId andFileName:@"swrve_events.txt"];
}

- (void)migrate_1_ApplicationSupportFilesForUserId:(NSString *)userId andFileName:(NSString *)currentFileName {
    // move the file into the swrve sub directory in application support and prefix the name with userId
    NSString *applicationSupport = [SwrveLocalStorage applicationSupportPath];
    NSString *currentFilePath = [applicationSupport stringByAppendingPathComponent:currentFileName];
    NSString *newFileName = [userId stringByAppendingString:currentFileName];
    NSString *swrveAppSupportDir = [SwrveLocalStorage swrveAppSupportDir];
    NSString *newFilePath = [swrveAppSupportDir stringByAppendingPathComponent:newFileName];

    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:currentFilePath toPath:newFilePath error:&error];
    if (success == YES) {
        DebugLog(@"Migrated the %@ file for userId: %@", currentFileName, userId);
    } else {
        DebugLog(@"There was an issue migrating the %@ file for userId: %@", currentFileName, userId);
    }
    if (error) {
        DebugLog(@"There was an issue migrating the %@ file for userId: %@ \nError: %@", currentFileName, userId, error);
    }
}

- (void)migrate2 {
    DebugLog(@"Executing version 2 migration code.");
    NSString *userId = [SwrveLocalStorage swrveUserId];
    if (userId && [userId length] > 0) {
        [self migrate_2_AppInstallDateForUserId:userId];
        [self migrate_2_EtagForUserId:userId];
    }
}

- (void)migrate_2_AppInstallDateForUserId:(NSString *)userId {
    DebugLog(@"Executing version 2 migration code. Copy existing swrve install date from current user to be used as the app install date.");

    NSString *documentPath = [SwrveLocalStorage documentPath];
    NSString *currentUserJoinedFileName = [userId stringByAppendingString:@"swrve_install.txt"];
    NSString *currentUserJoinedFilePath = [documentPath stringByAppendingPathComponent:currentUserJoinedFileName];
    NSString *newFilePath = [documentPath stringByAppendingPathComponent:@"swrve_install.txt"];

    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:currentUserJoinedFilePath toPath:newFilePath error:&error];
    if (success == YES) {
        DebugLog(@"Copied the current user joined date file as app install date", nil);
    } else {
        DebugLog(@"There was an issue copying the current user joined date file as app install date", nil);
    }
    if (error) {
        DebugLog(@"There was an issue copying the current user joined date file as app install date:\nError: %@", error);
    }

    UInt64 installTime = [SwrveLocalStorage userJoinedTimeSeconds:userId];
    if (installTime > 0)  {
        [SwrveLocalStorage saveAppInstallTime:installTime];
        DebugLog(@"Copied current user's joined date as the app install date for all users");
    }
}

- (void)migrate_2_EtagForUserId:(NSString *)userId {
    DebugLog(@"Executing version 2 migration code. Migrate etag");
    NSString *oldETagKey = @"campaigns_and_resources_etag";
    NSString *currentETagValue = [[NSUserDefaults standardUserDefaults] stringForKey:oldETagKey];
    [SwrveLocalStorage saveETag:currentETagValue forUserId:userId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:oldETagKey];
    BOOL success = [[NSUserDefaults standardUserDefaults] synchronize];
    if (success) {
        DebugLog(@"Migrated the etag NSUserDefault for userId: %@", userId);
    } else {
        DebugLog(@"There was an issue migrating the etag NSUserDefault for userId: %@", userId);
    }
}


@end
