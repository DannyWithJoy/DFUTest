//
//  ViewController.m
//  PetKit
//
//  Created by Danny.Xu on 2016/10/19.
//  Copyright © 2016年 Danny.Xu. All rights reserved.
//

#import "ViewController.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import <iOSDFULibrary/iOSDFULibrary-Swift.h>

@interface ViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate, LoggerDelegate, DFUServiceDelegate, DFUProgressDelegate>
@property (weak, nonatomic) IBOutlet UIButton *searchBtn;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) DFUServiceInitiator *initiator;
@property (nonatomic, strong) DFUServiceController *controller;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (IBAction)searchBtnClicked:(id)sender
{
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
}

- (IBAction)downloadBtnClicked:(id)sender
{
    // According to Swift code from nRF Toolbox.
    
    
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"hrs_dfu_s110_8_0_sdk_8_0" withExtension:@"zip"];
    DFUFirmware *firmware = [[DFUFirmware alloc] initWithUrlToZipFile:fileURL];
    if (firmware) {
        [self goodMessage:@"Firmware created."];
    } else {
        [self badMessage:@"Firmware creation failed."];
        return;
    }
    
    self.initiator = [[DFUServiceInitiator alloc] initWithCentralManager:self.centralManager target:self.peripheral];
    [self.initiator withFirmwareFile:firmware];
    // Optional:
    self.initiator.forceDfu = YES; // default NO
//    self.initiator.packetReceiptNotificationParameter = N; // default is 12
    self.initiator.logger = self; // - to get log info
    self.initiator.delegate = self; // - to be informed about current state and errors
    self.initiator.progressDelegate = self; // - to show progress bar
//    self.initiator.peripheralSelector = ... // the default selector is used
    
    self.controller = [self.initiator start];
}


#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self goodMessage:@"Bluetooth power on succeed!"];
        self.searchBtn.enabled = YES;
    } else {
        [self badMessage:@"Bluetooth power on failed!"];
        self.searchBtn.enabled = NO;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([peripheral.name isEqualToString:@"Dong"]) {
        [self goodMessage:@"Found device."];
        [self goodMessage:@"Waiting for command..."];
        self.peripheral = peripheral;
    }
}

#pragma mark - LoggerDelegate
- (void)logWith:(enum LogLevel)level message:(NSString * _Nonnull)message
{
    [self goodMessage:[NSString stringWithFormat:@"[Framework][%ld]:%@", (long)level, message]];
}

#pragma mark - DFUServiceDelegate
- (void)didStateChangedTo:(enum DFUState)state
{
    [self goodMessage:[NSString stringWithFormat:@"[Framework]State changed to:%ld", (long)state]];
}

- (void)didErrorOccur:(enum DFUError)error withMessage:(NSString * _Nonnull)message
{
    [self badMessage:[NSString stringWithFormat:@"[Framework]Error occur:%ld, %@", error, message]];
}

#pragma mark - DFUProgressDelegate
- (void)onUploadProgress:(NSInteger)part totalParts:(NSInteger)totalParts progress:(NSInteger)progress currentSpeedBytesPerSecond:(double)currentSpeedBytesPerSecond avgSpeedBytesPerSecond:(double)avgSpeedBytesPerSecond
{
    [self goodMessage:[NSString stringWithFormat:@"[Framework]Uploading...%ld", (long)progress]];
}

#pragma mark - Private
- (void)goodMessage:(NSString *)goodMessage
{
    NSLog(@"[✅]%@", goodMessage);
    self.logTextView.text = [NSString stringWithFormat:@"%@\n%@", self.logTextView.text, goodMessage];
}

- (void)badMessage:(NSString *)badMessage
{
    NSLog(@"[❌]%@", badMessage);
    self.logTextView.text = [NSString stringWithFormat:@"%@\n%@", self.logTextView.text, badMessage];
    
    [self.centralManager cancelPeripheralConnection:self.peripheral];
    self.peripheral = nil;
}

@end
