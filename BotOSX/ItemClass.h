//
//  ItemClass.h
//  BotOSX
//
//  Created by Nikolay Berlioz on 23.12.15.
//  Copyright © 2015 Nikolay Berlioz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ItemClass : NSObject

@property (copy) NSString *itemName;
@property (copy) NSString *itemHash;
@property (assign, nonatomic) NSInteger itemCount;
@property (assign, nonatomic) NSInteger itemBuyPrice;
@property (assign, nonatomic) NSInteger itemCurrentPrice;

@end
