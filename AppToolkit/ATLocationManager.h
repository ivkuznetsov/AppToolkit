
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_OPTIONS(NSUInteger, LocationManagerOptions) {
    LocationManagerAccess = 1 << 0,
    LocationManagerLocationUpdate = 1 << 1,
    LocationManagerHeadingUpdate = 1 << 2,
};

@interface ATLocationManager : NSObject

@property (nonatomic, readonly) CLLocationManager *locationManager;
@property (nonatomic, readonly) CLHeading *heading;
@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic) BOOL locationFailed;
@property (nonatomic) BOOL cacheLocation;
@property (nonatomic) BOOL allowLocationByIp; // to make it work you should add to app transport security access to http://ip-api.com
@property (nonatomic, readonly) CLAuthorizationStatus authorizationStatus;

+ (instancetype)sharedInstance;
+ (BOOL)isValidCoordinate:(CLLocationCoordinate2D)coordinate;
+ (BOOL)locationDetectionPermittedByUser;

- (void)restoreLocation;
- (void)addObserver:(id)observer selector:(SEL)selector options:(LocationManagerOptions)options;
- (void)removeObserver:(id)observer options:(LocationManagerOptions)options;
- (void)updateLocationWithCompletion:(void(^)(NSError *error))completion;
    
// these methods don't initiate location tracking
- (void)addPassiveObserver:(id)observer selector:(SEL)selector;
- (void)removePassiveObserver:(id)observer;
    
@end
