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
#import "AppDelegate.h"
#import <MyoKit/MyoKit.h>
#import "JCSong.h"


@import CoreMotion;

@interface ViewController ()

@property (nonatomic, strong) CMPedometer *counter;
@property(nonatomic, strong) NSTimer *timer;

@property(nonatomic, strong) NSArray *playlist;
@property(nonatomic) int lastStepCount;
@property(nonatomic) int placeInList;

@property(nonatomic) TLMPoseType defaultPosition;

@property (nonatomic, strong) SPTAudioStreamingController *player;




@end

@implementation ViewController


static NSString * const kClientId = @"2c2e95538e2d46a19ba2cdd910883947";
static NSString * const kCallbackURL = @"jockulus://callback";
static NSString * const kTokenSwapServiceURL = @"http://pennapps.gomurmur.com:1234/swap";

- (void)viewDidLoad {
     [super viewDidLoad];
    [self prepNavBar];
    self.lastStepCount = -25;
    self.placeInList = 0;
    self.defaultPosition = 0;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(getNumberOfSteps) userInfo:nil repeats:YES];
    
    
    
    [[TLMHub sharedHub] setLockingPolicy:TLMLockingPolicyNone];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePoseChange:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceivePoseChange:(NSNotification*)notification {
    
    NSLog(@"YOU MOVED");
    TLMPose *pose = notification.userInfo[kTLMKeyPose];
    if(self.defaultPosition == 0)
    {
        self.defaultPosition = pose.type;
    }
    
    if(self.defaultPosition == TLMPoseTypeFist)
    {
        if(pose.type == TLMPoseTypeFist)
        {
            [_player setIsPlaying:YES callback:^(NSError *error) {
                if(error)
                {
                    NSLog(@"%@", error);
                }
            }];
        }
        else if (pose.type == TLMPoseTypeFingersSpread)
        {
            [_player setIsPlaying:NO callback:^(NSError *error) {
                if(error)
                {
                    NSLog(@"%@", error);
                }
            }];
        }
    }
    
    else
    {
        if(pose.type == TLMPoseTypeFist)
        {
            [_player setIsPlaying:NO callback:^(NSError *error) {
                if(error)
                {
                    NSLog(@"%@", error);
                }
            }];
        }
        else if (pose.type == TLMPoseTypeFingersSpread)
        {
            [_player setIsPlaying:YES callback:^(NSError *error) {
                if(error)
                {
                    NSLog(@"%@", error);
                }
            }];
        }

    }
    
    if(pose.type == TLMPoseTypeDoubleTap)
    {
        if ([_player isPlaying])
        {
            [_player setIsPlaying:NO callback:^(NSError *error) {
                if(error)
                {
                    NSLog(@"%@", error);
                }
            }];
        }
        else
        {
            [_player setIsPlaying:YES callback:^(NSError *error) {
                if(error)
                {
                    NSLog(@"%@", error);
                }
            }];
        }
    }
    
    
    else if (pose.type == TLMPoseTypeWaveIn || pose.type == TLMPoseTypeWaveOut)
    {
        if([self.playlist count] >= 1 )
        {
            self.placeInList++;
            if (self.placeInList == [self.playlist count])
            {
                _placeInList = 0;
            }
            
            NSString *track = @"spotify:track:";
            JCSong *song = self.playlist[self.placeInList];
            
            track = [track stringByAppendingString:song.spotify_id];
            [SPTTrack trackWithURI:[NSURL URLWithString:track] session:nil callback:^(NSError *error, id object) {
                if(error != nil)
                {
                    NSLog(@"%@", error);
                }
                else
                {
                    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
                    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                    NSDictionary *parameters = @{@"echo_nest_id": song.echonest_id, @"username" : username};
                    [manager POST:@"http://pennapps.gomurmur.com/update_song.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        //                    NSLog(@"%@", responseObject);
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"Error: %@", error);
                        
                    }];
                    
                    [self.player playTrackProvider:object callback:nil];
                }
                
                
            }];
            

        }
        
    }
    
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
            
             if (self.lastStepCount > stepCount.intValue + 21 || self.lastStepCount < (stepCount.intValue - 21))
             {
                 [self sendToNetwork:stepCount];
             }
             else
             {
                 NSLog(@"here");
                 AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                 NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
                 NSDictionary *parametersSecond = @{@"bpm": stepCount, @"data" : @"update", @"username":username};
                 [manager POST:@"http://pennapps.gomurmur.com/bpm.php" parameters:parametersSecond success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     
                     
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     NSLog(@"Error: %@", error);
                 }];

             }
              self.lastStepCount = stepCount.intValue;
             
             
         }
     }];
    
   
    
    
}



-(BOOL)sendToNetwork : (NSNumber*) steps
{
    __block BOOL toReturn;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"bpm": steps};
    [manager POST:@"http://pennapps.gomurmur.com/get_songs.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        if([responseObject containsObject: @"not moving"] == true)
        {
            [_player setIsPlaying:NO callback:^(NSError *error) {
                if(error)
                {
                    NSLog(@"%@", error);
                }
            }];
        }
        else
        {
            toReturn = true;
            NSLog(@"%@", responseObject);
            [self parseSongs:responseObject];
            NSString *value = responseObject[0][@"id"];
            NSLog(@"%@", value);
        }
        
        
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        toReturn = false;
        
    }];
    
    
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    NSDictionary *parametersSecond = @{@"bpm": steps, @"data" : @"update", @"username":username};
    [manager POST:@"http://pennapps.gomurmur.com/bpm.php" parameters:parametersSecond success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];

    
    

    return toReturn;
}


-(NSArray * )parseSongs : (NSArray *)response
{
    BOOL startOver = true;
    NSMutableArray *array = [[NSMutableArray alloc]initWithCapacity:[response count]];
    for (int i = 0; i < [response count]; i++)
    {
        JCSong *song = [[JCSong alloc]init];
        
        song.spotify_id = response[i][@"id"];
        if([[@"spotify:track:" stringByAppendingString:song.spotify_id]isEqualToString:[self.player currentTrackMetadata][@"SPTAudioStreamingMetadataTrackURI"]])
        {
            startOver = false;
        }
        
        song.echonest_id = response[i][@"echo_nest"];
        [array addObject:song];
    }
    
    
    
    if([self.player isPlaying] == NO || startOver == true)
    {
        self.playlist = array;
        AppDelegate *delegate=(AppDelegate *)[[UIApplication sharedApplication] delegate];
        [self playUsingSession:delegate.session];
    }
    
    
    return array;
                                                                                                  
}


-(void)prepNavBar
{
    
    UIColor *color = [self colorWithHexString:@"ffffff"];
    self.navigationController.navigationBar.tintColor = color;
    
    [self.navigationItem.backBarButtonItem setAction:@selector(perform:)];
    
    
    
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    color,NSForegroundColorAttributeName,
                                    color,NSBackgroundColorAttributeName,[UIFont fontWithName:@"Avenir-Light" size:25.0f],NSFontAttributeName,nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    
    
    self.navigationController.navigationBar.barTintColor = [self colorWithHexString:@"c0392b"];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.title = @"Jockulus";
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) perform:(id)sender {
    
    self.player = nil;

    
    [self.navigationController popViewControllerAnimated:NO];
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




-(void)playUsingSession:(SPTSession *)session {
    
    NSLog(@"Here");
    
    
    // Create a new player if needed
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:kClientId];
    }
    
    [self.player loginWithSession:session callback:^(NSError *error) {
        
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
        
        NSString *track = @"spotify:track:";
        JCSong *song = self.playlist[self.placeInList];
        track = [track stringByAppendingString:song.spotify_id];
        [SPTTrack trackWithURI:[NSURL URLWithString:track] session:nil callback:^(NSError *error, id object) {
            if(error != nil)
            {
                NSLog(@"%@", error);
            }
            else
            {
                NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
                AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                NSDictionary *parameters = @{@"echo_nest_id": song.echonest_id, @"username" : username};
                [manager POST:@"http://pennapps.gomurmur.com/update_song.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSLog(@"%@", responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Error: %@", error);
                    
                }];

                [self.player playTrackProvider:object callback:nil];
            }
            
            
        }];
        
        
    }];
    
    
    
}




@end
