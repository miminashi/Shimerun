//
//  ViewController.m
//  Shimerun
//
//  Created by miminashi on 2016/08/09.
//  Copyright © 2016年 miminashi. All rights reserved.
//

#import "ViewController.h"

#import <AWSCore/AWSCore.h>
#import <AWSIoT/AWSIoT.h>
#import <FontAwesome/UIFont+FontAwesome.h>
#import <FontAwesome/NSString+FontAwesome.h>

static NSString *const kThingName = @"shimerun";
static NSString *const kShimerunLockStatsuOpen = @"open";
static NSString *const kShimerunLockStatsuClose = @"close";

@interface ViewController ()

@property (nonatomic) BOOL connected;

@end

@implementation ViewController

- (void)applicationDidBecomeActive
{
    if (self.connected) {
        [self showProgress];
        [self.iotDataManager getShadow:kThingName];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.connected = NO;
    
    self.lockStateLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:200];
    self.lockStateLabel.text = @"";

    self.iotDataManager = [AWSIoTDataManager defaultIoTDataManager];
    [self AWSIoTMQTTConnect];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self showProgress];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)openButtonDidTap:(id)sender {
    [self showProgress];
    [self requestShimerun:kShimerunLockStatsuOpen];
}

- (IBAction)closeButtonDidTap:(id)sender {
    [self showProgress];
    [self requestShimerun:kShimerunLockStatsuClose];
}

- (void)showProgress
{
    self.lockStateLabel.text = @"";
    self.lockStateUpdateActivityIndicator.hidden = NO;
    [self.lockStateUpdateActivityIndicator startAnimating];
}

- (void)dismissProgress
{
    self.lockStateUpdateActivityIndicator.hidden = YES;
    [self.lockStateUpdateActivityIndicator stopAnimating];
}

- (void)AWSIoTMQTTConnect
{
    [self.iotDataManager connectUsingWebSocketWithClientId:[NSUUID UUID].UUIDString cleanSession:true statusCallback:^(AWSIoTMQTTStatus status) {
        NSLog(@"AWSIoTMQTTConnect callback status: %ld", (long)status);
        if (status == AWSIoTMQTTStatusConnected) {
            NSLog(@"MQTT Connected");
            self.connected = YES;
            [self AWSIoTMQTTDidConnect];
        }
        else if (status == AWSIoTMQTTStatusDisconnected) {
            NSLog(@"MQTT Disconnected");
            self.connected = NO;
        }
    }];
}

- (void)AWSIoTMQTTDidConnect
{
    [self.iotDataManager registerWithShadow:kThingName eventCallback:^(NSString *name, AWSIoTShadowOperationType operation, AWSIoTShadowOperationStatusType status, NSString *clientToken, NSData *payload) {
        NSLog(@"operation: %ld, status: %ld, payload: %@", (long)operation, (long)status, [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding]);
        NSDictionary *payloadDic = [self dictionaryFromJsonData:payload];
        if (operation == AWSIoTShadowOperationTypeGet) {
            if (status == AWSIoTShadowOperationStatusTypeAccepted) {
                [self getRequestDidAccept:payloadDic];
            }
        }
        else if (operation == AWSIoTShadowOperationTypeUpdate) {
            if (status == AWSIoTShadowOperationStatusTypeDelta) {
                [self deltaDidUpdate:payloadDic];
            }
        }
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.iotDataManager getShadow:kThingName];
    });
}

- (void)getRequestDidAccept:(NSDictionary *)payload
{
    if (payload[@"state"] && payload[@"state"][@"reported"] && payload[@"state"][@"reported"][@"lock"]) {
        NSString *lockState = payload[@"state"][@"reported"][@"lock"];
        if ([lockState isEqualToString:@"open"]) {
            [self setLockStateOpen];
        }
        else if ([lockState isEqualToString:@"close"]) {
            [self setLockStateLock];
        }
    }
}

- (void)deltaDidUpdate:(NSDictionary *)payload
{
    if (payload[@"state"] && payload[@"state"][@"lock"]) {
        NSString *lockState = payload[@"state"][@"lock"];
        if ([lockState isEqualToString:@"open"]) {
            [self setLockStateOpen];
        }
        else if ([lockState isEqualToString:@"close"]) {
            [self setLockStateLock];
        }
    }
}

- (void)setLockStateLock
{
    self.lockStateLabel.text = [NSString fontAwesomeIconStringForIconIdentifier:@"fa-lock"];
    [self dismissProgress];
}

- (void)setLockStateOpen
{
    self.lockStateLabel.text = [NSString fontAwesomeIconStringForIconIdentifier:@"fa-unlock"];
    [self dismissProgress];
}

- (NSDictionary *)dictionaryFromJsonData:(NSData *)data
{
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
}

- (NSString *)jsonStringFromDictionary:(NSDictionary *)dictionary
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", jsonString);
    return jsonString;
}

- (void)requestShimerun:(NSString *)lockState
{
    NSDictionary *requestDic = @{
                                 @"state": @{
                                         @"desired": @{
                                                 @"lock": lockState
                                                 }
                                         }
                                 };
    NSString *requestStateJson = [self jsonStringFromDictionary:requestDic];
    [self.iotDataManager updateShadow:@"shimerun" jsonString:requestStateJson];
}

@end
