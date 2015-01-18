//
//  JCSong.h
//  Home Gym
//
//  Created by Jason Scharff on 1/17/15.
//
//

#import <Foundation/Foundation.h>

@interface JCSong : NSObject

@property(strong, nonatomic) NSString *spotify_id;
@property(strong, nonatomic) NSString *echonest_id;
@property(nonatomic) double durationInSeconds;

@end
