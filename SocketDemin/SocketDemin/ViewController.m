//
//  ViewController.m
//  SocketDemin
//
//  Created by 肖冯敏 on 2018/11/4.
//  Copyright © 2018 o‘clock. All rights reserved.
//

#import "ViewController.h"
#import "SocketManager.h"

#define REP_TIMES  10

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *hostLists;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _hostLists = [self loadFile];
    // Do any additional setup after loading the view, typically from a nib.
}

- (NSMutableArray *)loadFile {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"csv" ofType:@"csv"];
    NSError *err = nil;
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
    NSString *needContent = [fileContent stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",，"]];
    NSArray *defaultList = [needContent componentsSeparatedByString:@"\n"];
    NSMutableArray *returnList = [NSMutableArray array];
    for (NSString *hostString in defaultList) {
        NSArray *hostObj = [hostString componentsSeparatedByString:@":"];
        if ([hostObj count] == 2) {
            [returnList addObject:hostObj];
        }
    }
    return returnList;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[SocketManager sharedInstance] startWithList:_hostLists times:REP_TIMES];
}

@end
