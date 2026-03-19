//
//  RMStoreViewController.m
//  RMStore
//
//  Created by Hermes Pique on 7/30/13.
//  Copyright (c) 2013 Robot Media SL (http://www.robotmedia.net)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RMStoreViewController.h"
#import "RMStore.h"

@implementation RMStoreViewController {
    NSArray *_products;
    BOOL _productsRequestFinished;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Store", @"");

#warning Replace with your product ids.
    _products = @[@"net.robotmedia.test.consumable",
                  @"net.robotmedia.test.nonconsumable",
                  @"net.robotmedia.test.nonconsumable.2"];

#if !TARGET_OS_MACCATALYST
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
    [[RMStore defaultStore] requestProducts:[NSSet setWithArray:_products] success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
#if !TARGET_OS_MACCATALYST
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
        _productsRequestFinished = YES;
        [self.tableView reloadData];
    } failure:^(NSError *error) {
#if !TARGET_OS_MACCATALYST
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Products Request Failed", @"")
                                                                      message:error.localizedDescription
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _productsRequestFinished ? _products.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    NSString *productID = _products[indexPath.row];
    SKProduct *product = [[RMStore defaultStore] productForIdentifier:productID];
    cell.textLabel.text = product.localizedTitle;
    cell.detailTextLabel.text = [RMStore localizedPriceOfProduct:product];
    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![RMStore canMakePayments]) return;

    NSString *productID = _products[indexPath.row];
#if !TARGET_OS_MACCATALYST
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
    [[RMStore defaultStore] addPayment:productID success:^(SKPaymentTransaction *transaction) {
#if !TARGET_OS_MACCATALYST
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
#if !TARGET_OS_MACCATALYST
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Payment Transaction Failed", @"")
                                                                      message:error.localizedDescription
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

@end
