//
//  ViewController.m
//  BotOSX
//
//  Created by Nikolay Berlioz on 16.12.15.
//  Copyright © 2015 Nikolay Berlioz. All rights reserved.
//

#import "MainViewController.h"
#import <AFNetworking/AFNetworking.h>

static NSString *kSaveApiKey   = @"api";
static NSString *kSaveURL      = @"url";
static NSString *kSaveMinPrice = @"price";
static NSString *kSaveDelay    = @"delay";
static NSString *kSaveCount    = @"count";

@interface MainViewController() <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *linkTableView;
@property (nonatomic, strong) NSMutableArray *linkStorage;
- (IBAction)addNewLink:(id)sender;


@end

@implementation MainViewController
{
    //переменные для метода getJSON
    __block NSInteger countFound;
    __block NSInteger buyTotal;
    NSString *hash;
    NSInteger minPriceInt;
    NSInteger minPriceForBuy;
    NSString *stringURL;
    AFHTTPSessionManager *manager;
    
    //переменные для метода getCorrectURLstring
    NSString *stringWithClassAndInstanceId;
    NSCharacterSet *set;
    NSString *classId;
    NSString *instanceId;
    
    NSString *name;
    
    //timer
    NSTimer *requestsTimer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadData]; //загружем данные
    
    self.startPauseImageView.image = [NSImage imageNamed:@"pause.png"];
    //ссылка для получения JSON
    
    manager = [AFHTTPSessionManager manager];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark - Save and Load

//сохраняем данные из текстовых полей, чтобы не вводить снова при запуске
- (void) saveData
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:self.keyAPIField.stringValue forKey:kSaveApiKey];
    [userDefaults setObject:self.inURLField.stringValue forKey:kSaveURL];
    [userDefaults setObject:self.minPriceField.stringValue forKey:kSaveMinPrice];
    [userDefaults setObject:self.delayField.stringValue forKey:kSaveDelay];
    [userDefaults setObject:self.countItemField.stringValue forKey:kSaveCount];
    
    [userDefaults synchronize];
}

//загружаем данные в текстовые поля
- (void) loadData
{
    self.linkStorage = [NSMutableArray new];
    
    self.keyAPIField.stringValue = [self getValueFromDefaultWith:kSaveApiKey];
    self.inURLField.stringValue = [self getValueFromDefaultWith:kSaveURL];
    self.minPriceField.stringValue = [self getValueFromDefaultWith:kSaveMinPrice];
    self.delayField.stringValue = [self getValueFromDefaultWith:kSaveDelay];
    self.countItemField.stringValue = [self getValueFromDefaultWith:kSaveCount];
}

- (NSString *)getValueFromDefaultWith:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *result = [userDefaults objectForKey:key];
    
    return result.length > 0 ? result : @""; //если длинна строки меньше 0, возвр пустую строку
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
    if (tableView == self.linkTableView)
    {
        return self.linkStorage.count; //количество строк в таблице
    }
    
    return NO;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row;
{
    if (tableView == self.linkTableView)
    {
        NSString *ident = tableColumn.identifier; // Получаем значение Identifier колонки
        
        ItemClass* item = [self.linkStorage objectAtIndex:row]; // получаем объект данных для строки
        
        return [item valueForKey:ident]; // Возвращаем значение соответствующего свойства
    }
    
    return nil;
}

- (void) tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(row != -1)
    {
        if(tableView == self.linkTableView)
        {
            NSString* ident = tableColumn.identifier;
            ItemClass* item = [self.linkStorage objectAtIndex:row];
            [item setValue:object forKey:ident]; //Устанавливаем значение для соответствующего свойства
        }
    }
}

#pragma mark - Private methods

- (NSString*) getCorrectURLstring
{
    //получаем из текст филда ссылку на предмет
    stringWithClassAndInstanceId = self.inURLField.stringValue;
    set = [NSCharacterSet decimalDigitCharacterSet];
    
    //ищем начало classid и instanceid (first digit)
    NSRange range = [stringWithClassAndInstanceId rangeOfCharacterFromSet:set];
    //если нашли такой элемент обрезаем начало строки
    if (range.location != NSNotFound)
    {
        stringWithClassAndInstanceId = [stringWithClassAndInstanceId substringFromIndex:range.location];
    }
    
    range = [stringWithClassAndInstanceId rangeOfString:@"-"];
    //если нашли "-" обрезаем по него и получаем classid
    if (range.location != NSNotFound)
    {
        classId = [stringWithClassAndInstanceId substringToIndex:range.location];
        stringWithClassAndInstanceId = [stringWithClassAndInstanceId substringFromIndex:range.location + 1];
    }
    
    range = [stringWithClassAndInstanceId rangeOfString:@"-"];
    //если нашли "-" обрезаем от него и получаем instanceId
    if (range.location != NSNotFound)
    {
        instanceId = [stringWithClassAndInstanceId substringToIndex:range.location];
    }
    
    //собираем готовую строку для запроса
    NSString *resultString = [NSString stringWithFormat:@"https://csgo.tm/api/ItemInfo/%@_%@/ru/?key=%@",
                                                classId, instanceId, self.keyAPIField.stringValue];
    
    return resultString;
}

- (void)itemPurchaseRequestSent
{
    NSString *stringGetRequest = [NSString stringWithFormat:@"https://csgo.tm/api/Buy/%@_%@/%li/%@/?key=%@",
                        classId, instanceId, (long)minPriceForBuy, hash, self.keyAPIField.stringValue];
    
    [manager GET:stringGetRequest parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        ;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        //в случае успеха выводим сообщение о покупке и прибавляем 1 к счетчику найденных
        [self.outLabel setStringValue:[NSString stringWithFormat:@"Купил за %.2f рублей", (float)minPriceInt / 100]];
        [self.countFoundLabel setStringValue:[NSString stringWithFormat:@"found: %li", ++countFound]];
        [self.countItemField setStringValue:[NSString stringWithFormat:@"%li", --buyTotal]];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error for buy!");
    }];
}

- (void)printMinPriceValuesWithName:(NSString *)nameItem minPrice:(NSInteger)minPrice itemsFoundCount:(NSInteger)count
{
    //выводим название вещи и её минимальную цену
    [self.outLabel setStringValue:[NSString stringWithFormat:@"%@\nМинимальная цена = %.2f рублей", nameItem, (float)minPriceInt / 100]];
    [self.countFoundLabel setStringValue:[NSString stringWithFormat:@"found: %li", countFound]];
}

- (void)parseItemListResponseObject:(NSDictionary *)responseObject
{
    //достаем нужные значениия из JSON
    hash = responseObject[@"hash"];
    name = responseObject[@"market_name"];
    minPriceInt = [responseObject[@"min_price"] integerValue];
    minPriceForBuy = [self.minPriceField.stringValue integerValue];
    buyTotal = [self.countItemField.stringValue integerValue];
    
    [self printMinPriceValuesWithName:name minPrice:minPriceInt itemsFoundCount:countFound];
}

- (void)getJSON
{
    stringURL = [self getCorrectURLstring];
    
    [manager GET:stringURL parameters:nil progress:^(NSProgress * _Nonnull downloadProgress)
     {
         ;
    } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *  _Nullable responseObject) {
        
        NSLog(@"success");
        [self parseItemListResponseObject:responseObject];
        
        //если меньше указанной суммы, покупаем
//        if (minPriceInt <= minPriceForBuy && buyTotal > 0)
//        {
//            [self itemPurchaseRequestSent];
//        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Bad response");
    }];
}

- (void) getDataForTableView
{
    stringURL = [self getCorrectURLstring];
    
    [manager GET:stringURL parameters:nil progress:^(NSProgress * _Nonnull downloadProgress)
     {
         ;
     } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *  _Nullable responseObject) {
         
         ItemClass *item = [[ItemClass alloc] init];
         
         item.itemName = responseObject[@"market_name"];
         item.itemCount = 0;
         item.itemBuyPrice = 0;
         item.itemCurrentPrice = [responseObject[@"min_price"] integerValue];
         item.itemHash = responseObject[@"hash"];
         
         [self.linkStorage addObject:item];
         
         [self.linkTableView reloadData];
         
     } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         NSLog(@"Bad response");
     }];
}

#pragma mark - Actions

- (IBAction)actionStart:(NSButton *)sender
{
    CGFloat delay = [self.delayField.stringValue floatValue];
    
    requestsTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(getJSON) userInfo:nil repeats:YES];
    
    self.startPauseImageView.image = [NSImage imageNamed:@"play.png"];
    
    [self saveData];
}

- (IBAction)actionStop:(NSButton *)sender
{
    if ([requestsTimer isValid]) {
        [requestsTimer invalidate];
    }
    
    countFound = 0;
    [self.countFoundLabel setStringValue:[NSString stringWithFormat:@"found: %li", countFound]];
    self.startPauseImageView.image = [NSImage imageNamed:@"pause.png"];
}

- (IBAction)addNewLink:(id)sender
{
    NSString *value = self.inURLField.stringValue;
    if(value.length)
    {
        [self getDataForTableView];
    }
}

/* 
 * кнопка удаления выбранной строки в таблице
 */
- (IBAction)actionDelRow:(NSButton *)sender
{
    NSInteger row = self.linkTableView.selectedRow;//Узнаем отмеченную строку
    
    if(row != -1)
    {
        [self.linkTableView abortEditing];
        [self.linkStorage removeObjectAtIndex:row];
        [self.linkTableView reloadData];
    }
}









@end
