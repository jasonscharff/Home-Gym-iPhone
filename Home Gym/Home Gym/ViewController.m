//
//  ViewController.m
//  Home Gym
//
//  Created by Jason Scharff on 1/16/15.
//
//

#import "ViewController.h"
#import "AFHTTPRequestOperationManager.h"
#import <Spotify/Spotify.h>
@import CoreMotion;

@interface ViewController ()

@property (nonatomic, strong) CMPedometer *counter;
@property(nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) SPTSession *session;
@property (nonatomic, strong) SPTAudioStreamingController *player;




@end

@implementation ViewController


- (void)viewDidLoad {
     [super viewDidLoad];
    
//    _timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(getNumberOfSteps) userInfo:nil repeats:YES];
    
    
    

    
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}


-(void)spotify
{
    static NSString * const kClientId = @"2c2e95538e2d46a19ba2cdd910883947";
    static NSString * const kCallbackURL = @"jockulus://callback";
    static NSString * const kTokenSwapURL = @"http://localhost:1234/swap";
    
    SPTAuth *auth = [SPTAuth defaultInstance];
    NSURL *loginURL = [auth loginURLForClientId:kClientId
                            declaredRedirectURL:[NSURL URLWithString:kCallbackURL]
                                         scopes:@[SPTAuthStreamingScope]];
    
    // Opening a URL in Safari close to application launch may trigger
    // an iOS bug, so we wait a bit before doing so.
    [UIApplication performSelector:@selector(openURL:)
                      withObject:loginURL afterDelay:0.1];
}



-(void)getNumberOfSteps
{
    NSDate *startDate = [[NSDate date] dateByAddingTimeInterval:-5];
    
    self.counter = [[CMPedometer alloc] init];
    
    [self.counter startPedometerUpdatesFromDate:startDate withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        
    }];
    
    NSDate *endDate = [NSDate date];
    
    [_counter queryPedometerDataFromDate:startDate toDate:endDate withHandler:^(CMPedometerData *pedometerData, NSError *error)
     {
         if (error)
         {
             NSLog(@"%@", error);
         }
         else
         {
       
             NSNumber *stepCount = [[NSNumber alloc] initWithInt:(pedometerData.numberOfSteps.intValue * 20)];
             NSLog(@"%@", stepCount);
             [self sendToNetwork:stepCount];
             
         }
     }];
    
    
    
    
}



-(BOOL)sendToNetwork : (NSNumber*) steps
{
    __block BOOL toReturn;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"bpm": steps};
    [manager POST:@"http://pennapps.gomurmur.com/get_songs.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        toReturn = true;
//        NSLog(@"JSON: %@", responseObject);
        NSLog(@"Here");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        toReturn = false;
    }];

    return toReturn;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
