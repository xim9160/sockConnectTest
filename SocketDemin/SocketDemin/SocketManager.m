//
//  SocketManaher.m
//  SocketDemin
//
//  Created by 肖冯敏 on 2018/11/4.
//  Copyright © 2018 o‘clock. All rights reserved.
//

#import "SocketManager.h"
#import "GCD/GCDAsyncSocket.h"

@interface SocketManager()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) NSMutableArray *inputAry;
@property (nonatomic, assign) int index;
@property (nonatomic, strong) NSMutableDictionary *resultDic;
@property (nonatomic, strong) NSMutableArray *links;
@property (nonatomic, strong) NSMutableArray *queues;
@property (nonatomic, assign) int rp_time;
@property (nonatomic, strong) NSMutableArray *connectStartTime;
@property (nonatomic, assign) int onceConnectIndex;

@end

@implementation SocketManager

+(instancetype)sharedInstance
{
    static SocketManager *singleton = nil;
    static dispatch_once_t onceToken;
    // dispatch_once  无论使用多线程还是单线程，都只执行一次
    dispatch_once(&onceToken, ^{
        singleton = [[SocketManager alloc] init];
    });
    return singleton;
}

- (void)startWithList:(NSMutableArray *)array times:(int)time {
    _resultDic = [NSMutableDictionary dictionary];
    _queues = [NSMutableArray array];
    _links = [NSMutableArray array];
    _inputAry = [array mutableCopy];
    _index = 0;
    _rp_time = time;
    
    for (int i = 0; i < time; i++) {
        dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"socktQueue.%d", time] UTF8String], 0);
        [_queues addObject:queue];
    }
    [self startOnceConnect];
}

- (void)startOnceConnect {
    _connectStartTime = [NSMutableArray array];
    _onceConnectIndex = 0;
    for (int i = 0 ; i < _rp_time; i++) {
        GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_queues[i]];
        [_links addObject:socket];
        NSError *err =0;
        NSString *host = _inputAry[_index][0];
        int port = [_inputAry[_index][1] intValue];
        [socket connectToHost:host onPort:port error:&err];
        if (err) {
            NSString *err_msg = [NSString stringWithFormat:@"%d|%@\r\n", i, err];
            [self updateStringWith:host port:port msg:err_msg];
        }
    }
}

- (void)nextHost {
    if (_onceConnectIndex != _rp_time) {
        return;
    }
    
    @synchronized (self) {
        for (GCDAsyncSocket *socket in _links) {
            [socket disconnect];
        }
        [_links removeAllObjects];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.index ++;
        if (self.index < [self.inputAry count]) {
            [self startOnceConnect];
        } else {
            NSLog(@"DEBUG:END");
        }
    });
}

- (void)updateStringWith:(NSString *)host port:(int)port msg:(NSString *)msg {
    @synchronized (self) {
        _onceConnectIndex ++;
        NSString *key = [NSString stringWithFormat:@"%@:%d", host, port];
        NSString *string = [_resultDic objectForKey:key];
        if (!string) {
            string = @"\r\n";
        }
        
        if (host) {
            NSString *newString = [string stringByAppendingString:msg];
            [_resultDic setObject:newString forKey:key];
        }
        if (_onceConnectIndex == _rp_time) {
            NSLog(@"DEBUG:%@", string);
            [self nextHost];
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSUInteger index = [_links indexOfObject:sock];
    NSString *r_msg = [NSString stringWithFormat:@"%lu|%@:%d\r\n", (unsigned long)index, host, port];
    [self updateStringWith:host port:port msg:r_msg];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if (err) {
        NSUInteger index = [_links indexOfObject:sock];
        NSString *err_msg = [NSString stringWithFormat:@"%lu|%@\r\n", index, err];
        [self updateStringWith:nil port:0 msg:err_msg];
    }
}

@end
