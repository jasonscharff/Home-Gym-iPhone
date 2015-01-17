//
//  AppDelegate.h
//  Home Gym
//
//  Created by Jason Scharff on 1/16/15.
//
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <Spotify/Spotify.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;


@property(strong, nonatomic) SPTSession *session;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end
