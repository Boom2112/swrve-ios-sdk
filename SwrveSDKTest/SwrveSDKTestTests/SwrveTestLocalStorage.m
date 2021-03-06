#import <XCTest/XCTest.h>
#import "SwrveLocalStorage.h"
#import "SwrveTestHelper.h"

@interface SwrveTestLocalStorage : XCTestCase

@end

@implementation SwrveTestLocalStorage

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testApplicationSupportCreatesNewFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString  *appSupportDir = [SwrveLocalStorage applicationSupportPath];
    XCTAssertTrue([fileManager fileExistsAtPath:appSupportDir], @"File is not generated by Application Support");
}

- (void)testApplicationSupportDoesntOverride{
    NSString *path = [NSString pathWithComponents:@[[SwrveLocalStorage applicationSupportPath], @"testFile"]];
    [@"[]" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];


    //call path again, and then check if the written file is still present and unaltered
    path = [NSString pathWithComponents:@[[SwrveLocalStorage applicationSupportPath], @"testFile"]];

    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];

    XCTAssertEqualObjects(content, @"[]", @"testApplicationSupportDoesntOverride: %@ does not equal '[]'", content);
}

- (NSUserDefaults*)defaults {
    return [NSUserDefaults standardUserDefaults];
}

- (void)testFlushFrequencyKey {
    [SwrveLocalStorage saveFlushFrequency:999];
    double result = [SwrveLocalStorage flushFrequency];
    double expected = [[self defaults] doubleForKey:@"swrve_cr_flush_frequency"];
    XCTAssertTrue(result == expected);
}

- (void)testFlushDelayKey {
    [SwrveLocalStorage saveflushDelay:999];
    double result = [SwrveLocalStorage flushDelay];
    double expected = [[self defaults] doubleForKey:@"swrve_cr_flush_delay"];
    XCTAssertTrue(result == expected);
}

- (void)testETagKey {
    [SwrveLocalStorage saveETag:@"SomeETag" forUserId:@"TestUser"];
    NSString * result = [SwrveLocalStorage eTagForUserId:@"TestUser"];
    NSString * expected = [[self defaults] stringForKey:@"TestUsercampaigns_and_resources_etag"];
    XCTAssertTrue([result isEqualToString:expected]);
}

- (void)testDeviceTokenKey {
    [SwrveLocalStorage saveDeviceToken:@"SomeDeviceToken"];
    NSString * result = [SwrveLocalStorage deviceToken];
    NSString * expected = [[self defaults] stringForKey:@"swrve_device_token"];
    XCTAssertTrue([result isEqualToString:expected]);
}

- (void)testDeviceUUIDKey {
    [SwrveLocalStorage saveDeviceUUID:[[NSUUID UUID] UUIDString]];
    NSString * result = [SwrveLocalStorage deviceUUID];
    NSString * expected = [[self defaults] objectForKey:@"swrve_device_uuid"];
    XCTAssertTrue([result isEqualToString: expected]);
}

- (void)testSwrveUserIDKey {
    [SwrveLocalStorage saveSwrveUserId:@"SomeUserID"];
    NSString * result = [SwrveLocalStorage swrveUserId];
    NSString * expected = [[self defaults] objectForKey:@"swrve_user_id"];
    XCTAssertTrue([result isEqualToString:expected]);
}

- (void)testPermissionsKey {
    [SwrveLocalStorage savePermissions:@{@"SomeKey" : @"SomeValue"}];
    NSDictionary * expectedDic = [[self defaults] dictionaryForKey: @"swrve_permission_status"];
    NSString * expected = [expectedDic valueForKey:@"SomeKey"];
    XCTAssertTrue([expected isEqualToString:@"SomeValue"]);
}

- (void)testAskForPermissionsKey {
    [SwrveLocalStorage saveAskedForPushPermission:true];
    bool result = [SwrveLocalStorage askedForPushPermission];
    bool expected = [[self defaults] objectForKey:@"swrve.asked_for_push_permission"];
    XCTAssertTrue(result == expected);
}

/* HELPER METHODS */

- (void)resetDefaults {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self deleteFilesInDirectory:[SwrveLocalStorage applicationSupportPath]];
    [self deleteFilesInDirectory:[SwrveLocalStorage documentPath]];
}

- (void)deleteFilesInDirectory:(NSString *)directory {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:directory error:nil];
    for (NSString *filename in fileArray)  {
        [fileMgr removeItemAtPath:[directory stringByAppendingPathComponent:filename] error:NULL];
    }
}

@end
