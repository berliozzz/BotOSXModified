//
//  ViewController.h
//  BotOSX
//
//  Created by Nikolay Berlioz on 16.12.15.
//  Copyright © 2015 Nikolay Berlioz. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AFNetworking/AFNetworking.h>
#import "ItemClass.h"

@interface MainViewController : NSViewController

@property (weak) IBOutlet NSTextField *outLabel;
@property (weak) IBOutlet NSTextField *inURLField;
@property (weak) IBOutlet NSTextField *minPriceField;
@property (weak) IBOutlet NSTextField *delayField;
@property (weak) IBOutlet NSTextField *keyAPIField;
@property (weak) IBOutlet NSTextField *countFoundLabel;
@property (weak) IBOutlet NSTextField *countItemField;

@property (weak) IBOutlet NSImageView *startPauseImageView;

//минимальная сумма покупки
@property (assign, nonatomic) NSInteger priceForBuy;


- (IBAction)actionStart:(NSButton *)sender;
- (IBAction)actionStop:(NSButton *)sender;

- (IBAction)actionDelRow:(NSButton *)sender;



@end

