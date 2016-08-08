//
//  SMBreakRouteViewController.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#if defined(CYKEL_PLANEN)

#import "SMBreakRouteViewController.h"
#import "SMSingleRouteInfo.h"

#import "SMBikeWaypointCell.h"
#import "SMBreakRouteButtonCell.h"
#import "SMBreakRouteHeader.h"
#import "SMGeocoder.h"
#import "SMRouteInfoViewController.h"
#import "SMTransportation.h"
#import "SMTransportationCell.h"
@interface SMBreakRouteViewController () {
    NSArray *sourceStations;
    NSArray *sourceStationsFiltered;
    NSArray *destinationStations;
    NSArray *pickerModel;
    SMAddressPickerView *addressPickerView;

    SMRoute *tempStartRoute;
    SMRoute *tempFinishRoute;

    float startDistance;
    NSInteger startTime;
    float endDistance;
    NSInteger endTime;
}

@property(strong, nonatomic) NSMutableArray *stationNames;
@property(strong, nonatomic) NSMutableArray *destStationNames;

@end

@implementation SMBreakRouteViewController {
    BOOL breakRouteFailed;
    BOOL displayed;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    breakRouteFailed = NO;
    displayed = NO;

    self.title = @"break_route_title".localized;

    self.tableView.rowHeight = UITableViewAutomaticDimension;

    // initialize AddressPickerView
    addressPickerView = [[SMAddressPickerView alloc] initWithFrame:self.view.bounds];
    addressPickerView.pickerView.delegate = addressPickerView;
    addressPickerView.pickerView.dataSource = self;
    addressPickerView.delegate = self;

    [self.view addSubview:addressPickerView];
    CGRect frm = addressPickerView.frame;
    frm.origin.y = self.view.frame.size.height;
    addressPickerView.frame = frm;

    if (self.tripRoute) {
        self.tripRoute.delegate = self;

        [self.tripRoute breakRoute];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"breakRouteToRouteInfo"]) {
        SMRouteInfoViewController *destVC = segue.destinationViewController;

        NSArray *st =
            [sourceStations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation == %@ AND SELF.destStation == %@",
                                                                                         self.sourceStation, self.destinationStation]];
        NSAssert(st.count == 1, @"Invalid route");
        SMSingleRouteInfo *singleRouteInfo = st[0];

        destVC.singleRouteInfo = singleRouteInfo;
    }
}

- (void)displayBreakRouteError
{
    UIAlertView *noRouteAlertView = [[UIAlertView alloc] initWithTitle:@"break_route_no_route".localized
                                                               message:@"break_route_cant_break".localized
                                                              delegate:self
                                                     cancelButtonTitle:@"OK".localized
                                                     otherButtonTitles:nil];
    [noRouteAlertView show];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (breakRouteFailed) {
        [self displayBreakRouteError];
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            return 90;
        case 2:
            return 90;
        case 1:
            return 130;
        case 3:
            return 64;
    }
    return UITableViewAutomaticDimension;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        SMBreakRouteHeader *header = [tableView dequeueReusableCellWithIdentifier:@"breakRouteHeader"];
        [header.title setText:@"break_route_header_title".localized];
        [header.title sizeToFit];
        CGRect frame = header.title.frame;
        CGRect newFrame = header.routeDistance.frame;
        newFrame.origin.x = frame.origin.x + frame.size.width;

        float breakRouteDistance = startDistance + endDistance;
        // self.appDelegate.breakRouteDistance = breakRouteDistance;
        float tripDistance = self.tripRoute.fullRoute.estimatedRouteDistance;
        if (breakRouteDistance < self.tripRoute.fullRoute.estimatedRouteDistance && breakRouteDistance > 0) {
            tripDistance = breakRouteDistance;
        }

        NSString *routeDistanceFormat = @" %4.1f km";
        if (tripDistance / 1000 < 10) {
            routeDistanceFormat = @"%4.1f km";
        }

        NSLog(@"Break route distance: %f", breakRouteDistance);
        NSString *routeDistance = [NSString stringWithFormat:routeDistanceFormat, tripDistance / 1000.0];

        header.routeDistance.text = routeDistance;
        header.routeDistance.frame = newFrame;
        return header;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 42.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellId;
    switch (indexPath.row) {
        case 0: {
            CellId = @"SourceCell";
            SMBikeWaypointCell *wpCell = [tableView dequeueReusableCellWithIdentifier:CellId];
            [wpCell setupWithString:self.sourceName];

            float fDistance = startDistance / 1000.0;
            NSInteger fTime = startTime / 60;
            NSString *distance = @"";
            if (fDistance != 0 || fTime != 0) {
                distance = [NSString stringWithFormat:@"%4.1f km  %ld min.", fDistance, (long)fTime];
            }
            [wpCell.labelDistance setText:distance];

            wpCell.labelAddressBottom.text = self.sourceAddress;

            return wpCell;
        }
        case 1: {
            CellId = @"TransportCell";
            SMTransportationCell *tCell = [tableView dequeueReusableCellWithIdentifier:CellId];
            tCell.selectionStyle = UITableViewCellSelectionStyleNone;

            // Translatations
            [tCell.buttonAddressInfo setTitle:@"route_plan_button".localized forState:UIControlStateNormal];

            CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(self.sourceStation.latitude, self.sourceStation.longitude);
            [SMGeocoder reverseGeocode:coord
                           synchronous:NO
                     completionHandler:^(KortforItem *item, NSError *error) {
                       NSString *streetName = item.street;

                       if ([streetName isEqualToString:@""]) {
                           streetName = [NSString stringWithFormat:@"%f, %f", coord.latitude, coord.longitude];
                       }
                     }];

            coord = CLLocationCoordinate2DMake(self.destinationStation.latitude, self.destinationStation.longitude);
            [SMGeocoder reverseGeocode:coord
                           synchronous:NO
                     completionHandler:^(KortforItem *item, NSError *error) {
                       NSString *streetName = item.street;
                       if ([streetName isEqualToString:@""]) {
                           streetName = [NSString stringWithFormat:@"%f, %f", coord.latitude, coord.longitude];
                       }
                     }];

            UIImage *sourceIcon = [UIImage imageNamed:@"metro_icon.png"];
            if (self.sourceStation.type == SMStationInfoTypeTrain) {
                sourceIcon = [UIImage imageNamed:@"station_icon.png"];
            }
            else if (self.sourceStation.type == SMStationInfoTypeMetro) {
                sourceIcon = [UIImage imageNamed:@"metro_logo_pin.png"];
            }
            else if (self.sourceStation.type == SMStationInfoTypeLocalTrain) {
                sourceIcon = [UIImage imageNamed:@"local_train_icon.png"];
            }
            else if (self.sourceStation.type == SMStationInfoTypeUndefined) {
                sourceIcon = [UIImage imageNamed:@"metro_icon.png"];
            }

            UIImage *destIcon = nil;
            if (self.destinationStation.type == SMStationInfoTypeTrain) {
                destIcon = [UIImage imageNamed:@"station_icon.png"];
            }
            else if (self.sourceStation.type == SMStationInfoTypeMetro) {
                destIcon = [UIImage imageNamed:@"metro_logo_pin.png"];
            }
            else if (self.sourceStation.type == SMStationInfoTypeLocalTrain) {
                destIcon = [UIImage imageNamed:@"local_train_icon.png"];
            }
            else if (self.sourceStation.type == SMStationInfoTypeUndefined) {
                destIcon = [UIImage imageNamed:@"metro_icon.png"];
            }

            if (self.sourceStation) {
                [tCell.buttonAddressSource setEnabled:YES];
                [tCell.buttonAddressSource setTitle:self.sourceStation.name forState:UIControlStateNormal];
                [tCell.sourceActivityIndicator setHidden:YES];
                [tCell.sourceStationIcon setImage:sourceIcon];
            }
            else {
                [tCell.buttonAddressSource setEnabled:NO];
                [tCell.buttonAddressSource setTitle:@"" forState:UIControlStateNormal];
                [tCell.sourceActivityIndicator setHidden:NO];
                [tCell.sourceActivityIndicator startAnimating];
            }

            if (self.destinationStation) {
                [tCell.buttonAddressDestination setEnabled:YES];
                [tCell.buttonAddressDestination setTitle:self.destinationStation.name forState:UIControlStateNormal];
                [tCell.destinationActivityIndicator setHidden:YES];
                [tCell.destStationIcon setImage:destIcon];
            }
            else {
                [tCell.buttonAddressDestination setEnabled:NO];
                [tCell.buttonAddressDestination setTitle:@"" forState:UIControlStateNormal];
                [tCell.destinationActivityIndicator setHidden:NO];
                [tCell.destinationActivityIndicator startAnimating];
            }

            tCell.buttonAddressInfo.enabled = self.sourceStation && self.destinationStation;

            return tCell;
        }
        case 2: {
            CellId = @"DestinationCell";
            SMBikeWaypointCell *wpCell = [tableView dequeueReusableCellWithIdentifier:CellId];
            [wpCell setupWithString:self.destinationName];

            float fDistance = endDistance / 1000.0;
            ;
            NSInteger fTime = endTime / 60;
            NSString *distance = @"";
            if (fDistance != 0 || fTime != 0) {
                distance = [NSString stringWithFormat:@"%4.1f km  %ld min.", fDistance, (long)fTime];
            }
            else {
                distance = @"";
            }
            wpCell.labelDistance.text = distance;
            wpCell.labelAddressBottom.text = self.destinationAddress;

            return wpCell;
        }
        case 3: {
            CellId = @"ButtonCell";
            SMBreakRouteButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
            [cell.btnBreakRoute setTitle:@"break_route_title".localized forState:UIControlStateNormal];
            cell.btnBreakRoute.enabled = self.sourceStation && self.destinationStation;
            return cell;
        }
        default:
            break;
    }
    return nil;
}

- (NSString *)formatAddressComponent:(NSString *)comp
{
    NSString *trimmed = [comp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSInteger i = 0;

    while ((i < [trimmed length]) && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[trimmed characterAtIndex:i]]) {
        i++;
    }
    return [trimmed substringFromIndex:i];
}

- (void)dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (IBAction)onSourceAddressButtonTap:(id)sender
{
    [self displayAddressViewWithAddressType:AddressTypeSource model:sourceStationsFiltered];
}

- (void)displayAddressViewWithAddressType:(AddressType)pAddressType model:(NSArray *)pModel
{
    addressPickerView.addressType = pAddressType;

    pickerModel = [pModel sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
      if (![a isKindOfClass:[SMStationInfo class]] || ![b isKindOfClass:[SMStationInfo class]]) {
          return NO;
      }
      else {
          SMStationInfo *stationA = (SMStationInfo *)a;
          SMStationInfo *stationB = (SMStationInfo *)b;
          return [stationA.name compare:stationB.name];
      }
    }];

    [addressPickerView displayAnimated];
}

- (IBAction)onDestinationAddressButtonTap:(id)sender
{
    [self displayAddressViewWithAddressType:AddressTypeDestination model:destinationStations];
}

#pragma mark - picker view

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return pickerModel.count;
}

- (IBAction)onBreakRoute:(id)sender
{
    SMBrokenRouteInfo *brokenRouteInfo = [[SMBrokenRouteInfo alloc] init];
    brokenRouteInfo.sourceStation = self.sourceStation;
    ;
    brokenRouteInfo.destinationStation = self.destinationStation;

    NSArray *st = [sourceStations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation == %@ AND SELF.destStation == %@",
                                                                                               self.sourceStation, self.destinationStation]];
    NSAssert(st.count == 1, @"Invalid route");
    SMSingleRouteInfo *singleRouteInfo = st[0];
    brokenRouteInfo.transportationLine = singleRouteInfo.transportationLine;

    self.tripRoute.brokenRouteInfo = brokenRouteInfo;
}

- (NSString *)addressView:(SMAddressPickerView *)pAddressPickerView titleForRow:(NSInteger)row
{
    SMStationInfo *info = pickerModel[row];
    return info.name;
}

- (void)didFinishBreakingRoute:(SMTripRoute *)route
{
    [self.tableView reloadData];
    [SMUser user].tripRoute = self.tripRoute;
    [SMUser user].route = self.fullRoute;
    [self dismiss];
}

- (void)addressView:(SMAddressPickerView *)pAddressPickerView didSelectItemAtIndex:(NSInteger)index forAddressType:(AddressType)pAddressType
{
    NSAssert(pAddressType != AddressTypeUndefined, @"Address type is undefined");
    if (pAddressType == AddressTypeDestination) {
        self.destinationStation = pickerModel[index];
    }
    else if (pAddressType == AddressTypeSource) {
        self.sourceStation = pickerModel[index];

        addressPickerView.destinationCurrentIndex = 0;
        destinationStations = [self endStationsForSourceStation:self.sourceStation];
        self.destinationStation = destinationStations[0];
    }
    [self.tableView reloadData];
}

#pragma mark - break route delegate

- (void)didStartBreakingRoute:(SMTripRoute *)route
{
}

- (void)didFailBreakingRoute:(SMTripRoute *)route
{
}

- (void)didCalculateRouteDistances:(SMTripRoute *)route
{
    NSArray *arr = [route.transportationRoutes valueForKey:@"sourceStation"];
    NSMutableArray *temp = [NSMutableArray new];
    for (NSInteger i = 0; i < arr.count; i++) {
        SMStationInfo *station = [arr objectAtIndex:i];
        if (![temp containsObject:station]) {
            [temp addObject:station];
        }
    }
    sourceStationsFiltered = [NSArray arrayWithArray:temp];
    sourceStations = [NSArray arrayWithArray:route.transportationRoutes];

    for (SMSingleRouteInfo *routeInfo in route.transportationRoutes) {
        NSLog(@"%@ - %@ - %lf", routeInfo.sourceStation.name, routeInfo.destStation.name, routeInfo.bikeDistance);
    }

    if (route.transportationRoutes.count > 0) {
        SMSingleRouteInfo *routeInfo = [route.transportationRoutes objectAtIndex:0];

        destinationStations = [self endStationsForSourceStation:routeInfo.sourceStation];
        [self performSelectorOnMainThread:@selector(setSourceStation:) withObject:routeInfo.sourceStation waitUntilDone:YES];

        [self performSelectorOnMainThread:@selector(setDestinationStation:) withObject:routeInfo.destStation waitUntilDone:YES];
    }
    else {
        if (displayed) {
            [self displayBreakRouteError];
        }
        else {
            breakRouteFailed = YES;
        }
    }
    [self.tableView reloadData];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self dismiss];
}

- (NSArray *)endStationsForSourceStation:(SMStationInfo *)pSourceStation
{
    return [[self.tripRoute.transportationRoutes
        filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation == %@", pSourceStation]] valueForKey:@"destStation"];
}

#pragma mark - getters and setters

- (void)setSourceStation:(SMStationInfo *)pSourceStation
{
    _sourceStation = pSourceStation;

    if (pSourceStation.type == SMStationInfoTypeLocalTrain) {
        NSLog(@"LocalTrain");
    }

    CLLocationCoordinate2D start = self.tripRoute.start.coordinate;
    CLLocationCoordinate2D end = pSourceStation.location.coordinate;

    if (tempStartRoute) {
        [tempStartRoute removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedRouteDistance))];
        [tempStartRoute removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedTimeForRoute))];
    }

    tempStartRoute = [[SMRoute alloc] initWithRouteStart:start end:end delegate:nil];
    [tempStartRoute addObserver:self
                     forKeyPath:NSStringFromSelector(@selector(estimatedRouteDistance))
                        options:NSKeyValueObservingOptionNew
                        context:(__bridge void *)(tempStartRoute)];
    [tempStartRoute addObserver:self
                     forKeyPath:NSStringFromSelector(@selector(estimatedTimeForRoute))
                        options:NSKeyValueObservingOptionNew
                        context:(__bridge void *)(tempStartRoute)];

    addressPickerView.sourceCurrentIndex = [sourceStationsFiltered indexOfObject:pSourceStation];
}

- (void)setDestinationStation:(SMStationInfo *)pDestinationStation
{
    _destinationStation = pDestinationStation;
    NSLog(@"Destination station set to %@", self.destinationStation.name);
    CLLocationCoordinate2D start = pDestinationStation.location.coordinate;
    CLLocationCoordinate2D end = self.tripRoute.end.coordinate;
    if (tempFinishRoute) {
        [tempFinishRoute removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedRouteDistance))];
        [tempFinishRoute removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedTimeForRoute))];
    }

    tempFinishRoute = [[SMRoute alloc] initWithRouteStart:start end:end delegate:nil];
    [tempFinishRoute addObserver:self
                      forKeyPath:NSStringFromSelector(@selector(estimatedRouteDistance))
                         options:NSKeyValueObservingOptionNew
                         context:(__bridge void *)(tempFinishRoute)];
    [tempFinishRoute addObserver:self
                      forKeyPath:NSStringFromSelector(@selector(estimatedTimeForRoute))
                         options:NSKeyValueObservingOptionNew
                         context:(__bridge void *)(tempFinishRoute)];

    addressPickerView.destinationCurrentIndex = [destinationStations indexOfObject:pDestinationStation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedRouteDistance))]) {
        // distance changedΩΩ

        if (context == (__bridge void *)(tempStartRoute)) {
            NSLog(@"Start route distance changed to %ld", (long)tempStartRoute.estimatedRouteDistance);
            startDistance = tempStartRoute.estimatedRouteDistance;
        }
        else if (context == (__bridge void *)(tempFinishRoute)) {
            NSLog(@"Finish route distance changed to %ld", (long)tempFinishRoute.estimatedRouteDistance);
            endDistance = tempFinishRoute.estimatedRouteDistance;
        }

        [self distanceChanged];
    }
    else if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedTimeForRoute))]) {
        // time changed

        if (context == (__bridge void *)(tempStartRoute)) {
            NSLog(@"Start route distance changed to %ld", (long)tempStartRoute.estimatedRouteDistance);
            startTime = tempStartRoute.estimatedTimeForRoute;
        }
        else if (context == (__bridge void *)(tempFinishRoute)) {
            NSLog(@"Finish route distance changed to %ld", (long)tempFinishRoute.estimatedRouteDistance);
            endTime = tempFinishRoute.estimatedTimeForRoute;
        }

        [self timeChanged];
    }
}

- (void)timeChanged
{
    [self.tableView reloadData];
}

- (void)distanceChanged
{
    [self.tableView reloadData];
}

- (void)dealloc
{
    [tempFinishRoute removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedRouteDistance))];
    [tempFinishRoute removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedTimeForRoute))];
    [tempStartRoute removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedRouteDistance))];
    [tempStartRoute removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedTimeForRoute))];

    tempStartRoute = nil;
    tempFinishRoute = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end

#endif
