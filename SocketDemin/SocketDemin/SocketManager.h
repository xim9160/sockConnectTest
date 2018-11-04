//
//  SocketManaher.h
//  SocketDemin
//
//  Created by 肖冯敏 on 2018/11/4.
//  Copyright © 2018 o‘clock. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SocketManager : NSObject

- (void)startWithList:(NSMutableArray *)array times:(int)time;

+(instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
