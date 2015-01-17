//
//  RewardViewController.m
//  Jockulus
//
//  Created by Kevin Frans on 1/17/15.
//  Copyright (c) 2015 Jason Scharff. All rights reserved.
//

#import "RewardViewController.h"

@interface RewardViewController ()

@end

@implementation RewardViewController

@synthesize reward;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    reward.text
    
    
    NSString *post = @"key1=val1&key2=val2";
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://api.postmates.com/v1/customers/cus_KAfN10iSwQWAcV/delivery_quotes"]];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", @"3a35ad98-bb04-42ff-87dc-58a3bfc1e9da", @""];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    [request setHTTPBody:postData];
    
    //its 60 bucks from best buy, 10-20 for prize
    reward.text = [NSString stringWithFormat:@"$%u",60 + 10 + arc4random_uniform(10)];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
//    [self.data appendData:d];
    reward.text = [NSString stringWithFormat:@"$%u",60 + 10];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
