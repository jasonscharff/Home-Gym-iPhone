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
@property(nonatomic, strong) NSTimer *timeInSong;
@property(nonatomic)int threshold;

@property(nonatomic, strong) NSArray *playlist;
@property(nonatomic) int lastStepCount;
@property (nonatomic) int timeSinceCall;
@property(nonatomic) int placeInList;
@property (nonatomic) int numberZeroes;

@property(nonatomic) TLMPoseType defaultPosition;

@property (nonatomic, strong) SPTAudioStreamingController *player;

@property (nonatomic) BOOL isPaused;




@end

@implementation ViewController


static NSString * const kClientId = @"2c2e95538e2d46a19ba2cdd910883947";
static NSString * const kCallbackURL = @"jockulus://callback";

static NSString * const kTokenSwapServiceURL = @"http://pennapps.gomurmur.com:1234/swap";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepNavBar];
    self.lastStepCount = -1000;
    self.placeInList = 0;
    self.defaultPosition = 0;
    self.threshold = 40;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(getNumberOfSteps) userInfo:nil repeats:YES];
    
    
    
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
    
    
//    
//        if(pose.type == TLMPoseTypeFist)
//        {
//            [_player setIsPlaying:NO callback:^(NSError *error) {
//                if(error)
//                {
//                    NSLog(@"%@", error);
//                }
//            }];
//        }
//        else if (pose.type == TLMPoseTypeFingersSpread)
//        {
//            [_player setIsPlaying:YES callback:^(NSError *error) {
//                if(error)
//                {
//                    NSLog(@"%@", error);
//                }
//            }];
//        }
    
    
    
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
        NSLog(@"FROM MYO");
        [self nextSong];
    }
    
}


-(void)getNumberOfSteps
{
    self.timeSinceCall++;
    if(self.timeSinceCall == 2)
    {
        self.threshold = 40;
    }
    
    
    
    NSDate *startDate = [[NSDate date] dateByAddingTimeInterval:-8];
    
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
             NSNumber *stepCount;
             if(pedometerData.numberOfSteps.intValue == 0)
             {
                 self.numberZeroes++;
             }
             else
             {
                 self.numberZeroes = 0;
             }
             if(_numberZeroes == 4)
             {
                 stepCount = [[NSNumber alloc]initWithInt:0];
             }
             else
             {
                 stepCount = [[NSNumber alloc] initWithInt:(pedometerData.numberOfSteps.intValue * 7.5)];
             }

             
             
             NSLog(@"Step Count: %@", stepCount);
             
             if (self.lastStepCount > stepCount.intValue + self.threshold || self.lastStepCount < (stepCount.intValue - self.threshold))
             {
                 NSLog(@"Within Threshold");
                 self.timeSinceCall = 0;
                 self.threshold = 80;
                 [self sendToNetwork:stepCount];
                 self.lastStepCount = stepCount.intValue;
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
             
             
             
         }
     }];
    
    
    
    
}



-(BOOL)sendToNetwork : (NSNumber*) steps
{
    __block BOOL toReturn;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"bpm": steps};
    [manager POST:@"http://pennapps.gomurmur.com/get_songs.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Response: %@", responseObject);
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
            if([responseObject count] > 0)
            {
                [self parseSongs:responseObject];
                NSString *value = responseObject[0][@"id"];
                NSLog(@"%@", value);
            }
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
        NSNumber *temp = response[i][@"duration"];
        song.durationInSeconds = temp.doubleValue;
        if([[@"spotify:track:" stringByAppendingString:song.spotify_id]isEqualToString:[self.player currentTrackMetadata][@"SPTAudioStreamingMetadataTrackURI"]])
        {
            startOver = false;
        }
        
        song.echonest_id = response[i][@"echo_nest"];
        [array addObject:song];
    }
    
    
    
    if([self.player isPlaying] == NO || startOver == true)
    {
        self.placeInList = (arc4random() % [array count]);
        
        
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
                
               
                

                
                [self.timeInSong invalidate];
                self.timeInSong = [NSTimer scheduledTimerWithTimeInterval:song.durationInSeconds target:self selector:@selector(nextSong) userInfo:nil repeats:YES];
            }
            
            
        }];
        
        
    }];
    
    
    
}

-(void)nextSong
{
    NSLog(@"Next Song Activated");
    self.placeInList++;
    if(self.placeInList == [self.playlist count])
    {
        self.placeInList = 0;
    }
    
    JCSong *song = self.playlist[self.placeInList];
    NSString *track = @"spotify:track:";
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
            [self.timeInSong invalidate];
            self.timeInSong = [NSTimer scheduledTimerWithTimeInterval:song.durationInSeconds target:self selector:@selector(nextSong) userInfo:nil repeats:NO];
            
        }
        
        
    }];
    

    
    
    
}




@end
