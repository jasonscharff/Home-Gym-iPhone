//
//  facebookViewController.m
//  Jockulus
//
//  Created by Jason Scharff on 1/18/15.

//  Copyright (c) 2015 Jason Scharff. All rights reserved.

//



#import "facebookViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#import "AppDelegate.h"

#import "AFHTTPRequestOperationManager.h"



@interface facebookViewController ()



@property (nonatomic, assign) BOOL switched;



@end



@implementation facebookViewController

const double CM_PER_STEP = 73.36;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self prepNavBar];
//    NSNumber *steps = [[NSUserDefaults standardUserDefaults] objectForKey:@"steps"];
//    double temp = steps.intValue * CM_PER_STEP / 100;
//    NSNumber *distance = [[NSNumber alloc]initWithDouble:(temp)];
//    NSLog(@"D1 = %f", distance.doubleValue);
//    NSString *tempString = @"You Traveled ";
//    tempString = [tempString stringByAppendingString:[distance stringValue]];
//    tempString = [tempString stringByAppendingString:@"m"];
//    self.travelLabel.text = tempString;
    [self setFBLogIn];
    
    // Do any additional setup after loading the view.
    
}



- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
    
}



-(void)prepNavBar

{
    UIColor *color = [self colorWithHexString:@"ffffff"];
    
    self.navigationController.navigationBar.tintColor = color;
    
    self.navigationController.navigationBar.topItem.title = @"Back";
    
    [self.navigationItem.backBarButtonItem setAction:@selector(perform:)];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    
                                    color,NSForegroundColorAttributeName,
                                    
                                    color,NSBackgroundColorAttributeName,[UIFont fontWithName:@"Avenir-Light" size:25.0f],NSFontAttributeName,nil];
    
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.navigationController.navigationBar.barTintColor = [self colorWithHexString:@"c0392b"];
    
    self.navigationController.navigationBar.translucent = NO;
    
    self.navigationItem.title = @"Jockulus";
    
}



-(void)setFBLogIn

{
    
    NSString *access_token = [[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
    
    
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    
    if (!appDelegate.session_fb.isOpen) {
        
        // create a fresh session object
        
        appDelegate.session_fb = [[FBSession alloc] initWithPermissions:@[@"public_profile", @"email", @"user_friends", @"user_likes", @"publish_actions"]];
        
        
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        
        // occur; we don't want that to happen unless the user clicks the login button, and so
        
        // we check here to make sure we have a token before calling open
        
        if (appDelegate.session_fb.state == FBSessionStateCreatedTokenLoaded) {
            
            // even though we had a cached token, we need to login to make the session usable
            
            [appDelegate.session_fb openWithCompletionHandler:^(FBSession *session,
                                                                
                                                                FBSessionState status,
                                                                
                                                                NSError *error) {
                
                // we recurse here, in order to update buttons and labels
                
                
                
                if (access_token == appDelegate.session_fb.accessTokenData.accessToken)
                    
                {
                    
                    self.switched = YES;
                    
                    [self performSegueWithIdentifier:@"signup" sender:self];
                    
                }
                
                [self updateView];
                
            }];
            
        }
        
    }
    
    
    
}









- (void)updateView {
    
    // get the app delegate, so that we can reference the session property
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    
    if (appDelegate.session_fb.isOpen) {
        
        [FBSession setActiveSession:appDelegate.session_fb];
        
        [FBRequestConnection
         
         startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             
             if (!error) {
                 
                 
                 
                 //NSLog(@"%@", result);
                 
                 [[NSUserDefaults standardUserDefaults] setObject:[result objectForKey:@"id"] forKey:@"id"];
                 
                 [[NSUserDefaults standardUserDefaults] setObject:[result objectForKey:@"first_name"] forKey:@"first_name"];
                 
                 [[NSUserDefaults standardUserDefaults] setObject:[result objectForKey:@"last_name"] forKey:@"last_name"];
                 
                 [[NSUserDefaults standardUserDefaults] setObject:[result objectForKey:@"email"] forKey:@"email"];
                 
                 [[NSUserDefaults standardUserDefaults] setObject: appDelegate.session_fb.accessTokenData.accessToken forKey:@"token"];
                 
                 NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
                 
                 
                 
                 AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                 
                 NSDictionary *parameters = @{@"access_token": appDelegate.session_fb.accessTokenData.accessToken,
                                              
                                              @"username" : username};
                 
                 [manager POST:@"http://pennapps.gomurmur.com/facebook_register.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     
                     NSLog(@"JSON: %@", responseObject);
                     
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     
                     NSLog(@"Error: %@", error);
                     
                 }];
                 
             }
             
         }];
        
        NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
        NSNumber *steps = [[NSUserDefaults standardUserDefaults] objectForKey:@"steps"];
        double temp = steps.intValue * CM_PER_STEP / 100;
        NSNumber *distance = [[NSNumber alloc]initWithDouble:(temp)];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSDictionary *parameters = @{@"username": username, @"distance": distance};
        [manager POST:@"http://pennapps.gomurmur.com/facebook_post.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            [self performSegueWithIdentifier:@"home" sender:self];
            ;        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];

        

        
    } else {
        
        NSLog(@"session is not open");
        [self buttonClickHandler:self];
        
    }
    
}



- (IBAction)buttonClickHandler:(id)sender {
    
    // get the app delegate so that we can access the session property
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    
    
    
    // this button's job is to flip-flop the session from open to closed
    
    if (appDelegate.session_fb.isOpen) {
        
        // if a user logs out explicitly, we delete any cached token information, and next
        
        // time they run the applicaiton they will be presented with log in UX again; most
        
        // users will simply close the app or switch away, without logging out; this will
        
        // cause the implicit cached-token login to occur on next launch of the application
        
        [appDelegate.session_fb closeAndClearTokenInformation];
        
        
        
    } else {
        
        if (appDelegate.session_fb.state != FBSessionStateCreated) {
            
            // Create a new, logged out session.
            
            appDelegate.session_fb = [[FBSession alloc] init];
            
        }
        
        
        
        // if the session isn't open, let's open it now and present the login UX to the user
        
        [appDelegate.session_fb openWithCompletionHandler:^(FBSession *session,
                                                            
                                                            FBSessionState status,
                                                            
                                                            NSError *error) {
            
            // and here we make sure to update our UX according to the new session state
            
            [self updateView];
            
        }];
        
    }
    
}











-(UIColor*)colorWithHexString:(NSString*)hex

{
    
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    
    
    // String should be 6 or 8 characters
    
    if ([cString length] < 6) return [UIColor grayColor];
    
    
    
    // strip 0X if it appears
    
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    
    
    // Separate into r, g, b substrings
    
    NSRange range;
    
    range.location = 0;
    
    range.length = 2;
    
    NSString *rString = [cString substringWithRange:range];
    
    
    
    range.location = 2;
    
    NSString *gString = [cString substringWithRange:range];
    
    
    
    range.location = 4;
    
    NSString *bString = [cString substringWithRange:range];
    
    
    
    // Scan values
    
    unsigned int r, g, b;
    
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    
    
    return [UIColor colorWithRed:((float) r / 255.0f)
            
                           green:((float) g / 255.0f)
            
                            blue:((float) b / 255.0f)
            
                           alpha:1.0f];
    
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
