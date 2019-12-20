
#import "ATLocationManager.h"

#define kLocationAccessUpdate @"kLocationAccessUpdate"
#define kLocationPositionUpdate @"kLocationPositionUpdate"
#define kLocationHeadingUpdate @"kLocationHeadingUpdate"

@interface ATLocationManager () <CLLocationManagerDelegate> {
	NSMutableArray *_headingObservers;
	NSMutableArray *_locationObservers;
}

@property (nonatomic) CLHeading *heading;
@property (nonatomic) CLLocation *location;
@property (nonatomic) CLAuthorizationStatus authorizationStatus;
@property (nonatomic) NSMutableArray *updateLocationBlocks;

@end

@implementation ATLocationManager

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
        [sharedInstance prepareAll];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _updateLocationBlocks = [NSMutableArray array];
    }
    return self;
}

- (void)prepareAll {
	_headingObservers = [NSMutableArray array];
	_locationObservers = [NSMutableArray array];
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.headingOrientation = CLDeviceOrientationFaceUp;
    _locationManager.distanceFilter = 0.01;
    _authorizationStatus = CLLocationManager.authorizationStatus;
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization];
    }
}

- (void)restoreLocation {
    _location = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"location"]];
    _heading = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"heading"]];
}

+ (BOOL)isValidCoordinate:(CLLocationCoordinate2D)coordinate {
	return coordinate.latitude != 0 && coordinate.longitude != 0;
}

+ (BOOL)locationDetectionPermittedByUser {
    BOOL result = [CLLocationManager locationServicesEnabled] && kCLAuthorizationStatusDenied != [ATLocationManager sharedInstance].authorizationStatus;
    return result;
}

- (void)addPassiveObserver:(id)observer selector:(SEL)selector {
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:kLocationPositionUpdate object:nil];
}
    
- (void)removePassiveObserver:(id)observer {
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:kLocationPositionUpdate object:nil];
}
    
- (void)addObserver:(id)observer selector:(SEL)selector options:(LocationManagerOptions)options {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    if (options & LocationManagerAccess) {
        [nc addObserver:observer selector:selector name:kLocationAccessUpdate object:nil];
    }
	NSValue *value = [NSValue valueWithNonretainedObject:observer];
    if (options & LocationManagerHeadingUpdate) {
		if (![_headingObservers containsObject:value]) {
			[_headingObservers addObject:value];
		}
        if (_headingObservers.count == 1 && [CLLocationManager headingAvailable]) {
            [_locationManager startUpdatingHeading];
        }
        [nc addObserver:observer selector:selector name:kLocationHeadingUpdate object:nil];
    }
    if (options & LocationManagerLocationUpdate) {
		if (![_locationObservers containsObject:value]) {
			[_locationObservers addObject:value];
		}
		if (_locationObservers.count == 1) {
            [_locationManager startUpdatingLocation];
        }
        [nc addObserver:observer selector:selector name:kLocationPositionUpdate object:nil];
    }
}

- (void)removeObserver:(id)observer options:(LocationManagerOptions)options {
    NSNotificationCenter *nc =[NSNotificationCenter defaultCenter];
    if (options & LocationManagerAccess) {
        [nc removeObserver:observer name:kLocationAccessUpdate object:nil];
    }
	NSValue *value = [NSValue valueWithNonretainedObject:observer];
    if (options & LocationManagerHeadingUpdate) {
		[_headingObservers removeObject:value];
        if (_headingObservers.count < 1) {
            [_locationManager stopUpdatingHeading];
        }
        [nc removeObserver:observer name:kLocationHeadingUpdate object:nil];
    }
    if (options & LocationManagerLocationUpdate) {
		[_locationObservers removeObject:value];
        if (_locationObservers.count < 1) {
            [_locationManager stopUpdatingLocation];
        }
        [nc removeObserver:observer name:kLocationPositionUpdate object:nil];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    _authorizationStatus = status;
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationAccessUpdate object:self];
    
    if ([CLLocationManager headingAvailable]) {
        [_locationManager startUpdatingHeading];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading {
    _heading = heading;
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationHeadingUpdate object:self];
    if (_cacheLocation) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_heading] forKey:@"heading"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    _locationFailed = NO;
    _location = locations.lastObject;
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationPositionUpdate object:self];
    if (_cacheLocation) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_location] forKey:@"location"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    _locationFailed = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationPositionUpdate object:self];
}

- (void)updateLocationWithCompletion:(void(^)(NSError *error))completion {
    if (![self.class locationDetectionPermittedByUser]) {
        if (_allowLocationByIp) {
            [self getLocationById:^(CLLocation *location, NSError *error) {
                if (error || !location) {
                    completion(error);
                } else {
                    [self locationManager:self.locationManager didUpdateLocations:@[location]];
                    completion(nil);
                }
            }];
        } else {
            completion([NSError errorWithDomain:@"com.amlocationmanager" code:NSURLErrorUserAuthenticationRequired userInfo:@{NSLocalizedDescriptionKey : @"Location update is not permitted by user"}]);
        }
        return;
    }
    
    [_updateLocationBlocks addObject:completion];
    if (_updateLocationBlocks.count > 1) {
        return;
    }
    [self addObserver:self selector:@selector(locationUpdated:) options:LocationManagerAccess | LocationManagerLocationUpdate];
}

- (void)locationUpdated:(NSNotification *)notification {
    if (![self.class locationDetectionPermittedByUser]) {
        [self runBlocksWithError:[NSError errorWithDomain:@"com.amlocationmanager" code:NSURLErrorUserAuthenticationRequired userInfo:@{NSLocalizedDescriptionKey : @"Location update is not permitted by user"}]];
    } else if (self.locationFailed) {
        [self runBlocksWithError:[NSError errorWithDomain:@"com.amlocationmanager" code:NSURLErrorUserAuthenticationRequired userInfo:@{NSLocalizedDescriptionKey : @"Failed to determine location"}]];
    } else if (self.location) {
        [self runBlocksWithError:nil];
    }
}

- (void)runBlocksWithError:(NSError *)error {
    for (void(^block)(NSError *error) in _updateLocationBlocks) {
        block(error);
    }
    [_updateLocationBlocks removeAllObjects];
    [self removeObserver:self options:LocationManagerAccess | LocationManagerLocationUpdate];
}

- (void)getLocationById:(void(^)(CLLocation *, NSError *))completion {
    NSURL *url = [NSURL URLWithString:@"http://ip-api.com/json"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                completion(nil, error);
            } else {
                if (data) {
                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                    double lat = [dict[@"lat"] doubleValue];
                    double lon = [dict[@"lon"] doubleValue];
                    CLLocation *location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
                    completion(location, nil);
                } else {
                    completion(nil, nil);
                }
            }
        });
    }] resume];
}

@end
