//
//  SMMenuViewController.m
//  I Bike CPH
//
//  Created by Tobias Due Munk on 03/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

#import "SMMenuViewController.h"

#import "SMContactsCell.h"
#import "SMContactsHeader.h"

#import "SMUtil.h"
#import "SMAddFavoriteCell.h"
#import "SMEmptyFavoritesCell.h"

#import "DAKeyboardControl.h"
#import "SMFavoritesUtil.h"
#import "SMAPIRequest.h"

#import "SMReminderTableViewCell.h"
#import "UIView+LocateSubview.h"

typedef enum {
    menuFavorites = 0,
    menuAccount = 1,
    menuInfo = 2
} MenuType;

typedef enum {
    typeFavorite,
    typeHome,
    typeWork,
    typeSchool,
    typeNone
} FavoriteType;

// TODO: Delete class file when all parts have been moved to other classes e.g. MenuViewController

@interface SMMenuViewController () <SMMenuCellDelegate, SMFavoritesDelegate, UITextFieldDelegate> {
    
    MenuType menuOpen;
    FavoriteType currentFav;
}

@property (nonatomic, strong) NSMutableArray *favoritesList;
@property (nonatomic, strong) NSMutableArray *favorites;
@property (weak, nonatomic) IBOutlet UITableView *favoritesTableView;
@property (weak, nonatomic) IBOutlet UIButton *favEditStart;
@property (weak, nonatomic) IBOutlet UIButton *favEditDone;
@property (weak, nonatomic) IBOutlet UIView *accHeader;
@property (weak, nonatomic) IBOutlet UIView *infoHeader;
@property (weak, nonatomic) IBOutlet UIView *remindersHeader;

@property (weak, nonatomic) IBOutlet UILabel *accountLabel;

@property (weak, nonatomic)  IBOutlet UIView *favHeader;

@property (nonatomic, strong) FavoriteItem *locItem;
@property NSInteger locIndex;

//@property (weak, nonatomic) IBOutlet UIButton *btnReminders;
//@property (weak, nonatomic) IBOutlet UIButton *btnFavorites;
@property (weak, nonatomic) IBOutlet UIImageView *imgReminders;

@property (nonatomic, strong) SMContacts *contacts;
@property BOOL reminderFolded;

/**
 * properties for table
 */
@property (nonatomic, strong) IBOutlet SMAddFavoriteCell *tableFooter;

//@property NSInteger locIndex;
//@property (nonatomic, strong) NSString *favName;

@property (nonatomic, strong) SMFavoritesUtil *favoritesUtil;

@end

@implementation SMMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([self isLoggedIn]) {
        self.favoritesList = [SMFavoritesUtil getFavorites];
        self.favoritesUtil = [[SMFavoritesUtil alloc] initWithDelegate:self];
        [self.favoritesUtil fetchFavoritesFromServer];
    } else {
        // TODO
//        [self favoritesChanged:nil];
    }
    
    self.tableFooter = [SMAddFavoriteCell getFromNib];
    [self.tableFooter setDelegate:self];
    [self.tableFooter.text setText:@"cell_add_favorite".localized];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(favoritesChanged:) name:kFAVORITES_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidToken:) name:@"invalidToken" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self checkLoginStatus];
}

#pragma mark - IBActions

- (IBAction)doneButtonTapped:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -

- (void)invalidToken:(NSNotification*)notification {
    [SMFavoritesUtil saveFavorites:@[]];
    [self checkLoginStatus];
}


- (BOOL)isLoggedIn {
    return self.appDelegate.appSettings[@"auth_token"] != nil;
}

- (void)checkLoginStatus {
    if ([self isLoggedIn]) {
        self.accountLabel.text = @"account".localized;
    } else {
        [SMFavoritesUtil saveFavorites:@[]];
        self.accountLabel.text = @"account_login".localized;
    }
    self.favoritesList = [SMFavoritesUtil getFavorites];
}


#pragma mark - Fav

- (CGFloat)heightForFavorites {
    if ([self.favoritesList count] == 0) {
        return [SMEmptyFavoritesCell getHeight] + 45.0f;
    } else {
        CGFloat startY = self.favHeader.frame.origin.y;
        CGFloat maxHeight = self.view.frame.size.height - startY;
        return MIN(self.favoritesTableView.contentSize.height + 45.0f, maxHeight - 2 * 45.0f);
    }
    return 45.0f;
}

- (void)openMenu:(NSInteger)menuType {
    CGFloat startY = self.favHeader.frame.origin.y;
    CGFloat maxHeight = self.view.frame.size.height - startY;
    [self.favoritesTableView reloadData]; // TODO
    switch (menuType) {
        case menuInfo: {
            [self.favEditDone setHidden:YES];
            [self.favEditStart setHidden:YES];
            CGRect frame = self.infoHeader.frame;
            frame.origin.y = startY + 2 * 45.0f;
            frame.size.height = maxHeight - 2 * 45.0f;
            [self.infoHeader setFrame:frame];

            frame = self.favHeader.frame;
            frame.origin.y = startY;
            frame.size.height = 45.0f;
            [self.favHeader setFrame:frame];

            frame = self.accHeader.frame;
            frame.origin.y = startY + 45.0f;
            frame.size.height = 45.0f;
            [self.accHeader setFrame:frame];
        }
            break;
        case menuAccount: {
            [self.favEditDone setHidden:YES];
            [self.favEditStart setHidden:YES];
            CGRect frame = self.accHeader.frame;
            frame.origin.y = startY + 45.0f;
            frame.size.height = maxHeight - 2 * 45.0f;
            [self.accHeader setFrame:frame];

            frame = self.favHeader.frame;
            frame.origin.y = startY;
            frame.size.height = 45.0f;
            [self.favHeader setFrame:frame];

            frame = self.infoHeader.frame;
            frame.origin.y = self.accHeader.frame.size.height + self.accHeader.frame.origin.y;
            frame.size.height = 45.0f;
            [self.infoHeader setFrame:frame];
        }
            break;
        case menuFavorites: {
            if ([self.favoritesList count] == 0) {
                [self.favEditDone setHidden:YES];
                [self.favEditStart setHidden:YES];
            } else {
                if (self.favoritesTableView.isEditing) {
                    [self.favEditDone setHidden:NO];
                    [self.favEditStart setHidden:YES];
                } else {
                    [self.favEditDone setHidden:YES];
                    [self.favEditStart setHidden:NO];
                }
            }
            CGRect frame = self.favHeader.frame;
            frame.origin.y = startY;
            frame.size.height = [self heightForFavorites];
            [self.favHeader setFrame:frame];
            frame = self.accHeader.frame;
            frame.origin.y = startY + self.favHeader.frame.size.height;
            frame.size.height = 45.0f;
            [self.accHeader setFrame:frame];
            frame = self.infoHeader.frame;
            frame.origin.y = self.accHeader.frame.origin.y + 45.0f;
            frame.size.height = 45.0f;
            [self.infoHeader setFrame:frame];

            if (self.favHeader.frame.size.height < self.favoritesTableView.contentSize.height) {
                [self.favoritesTableView setBounces:YES];
            } else {
                [self.favoritesTableView setBounces:NO];
            }
        }
            break;
        default:
            break;
    }
}

- (IBAction)tapFavorites:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [self openMenu:menuFavorites];
    }];
}

- (IBAction)onSelectAccount:(UIButton *)sender {
    [self tapAccount:sender];
}

- (IBAction)tapAccount:(id)sender {
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        [self performSegueWithIdentifier:@"menuToAccount" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"menuToLogin" sender:nil];
    }
}

- (IBAction)onSelectInfo:(UIButton *)sender {
    [self tapInfo:sender];
}

- (IBAction)tapInfo:(id)sender {
    [self performSegueWithIdentifier:@"menuToAbout" sender:nil];
}


#pragma mark - Fav

- (IBAction)editFavoriteShow:(id)sender {
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
    }];

    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        // TODO: Move to SMFavoritesViewController
//        addFavAddress.text = self.locItem.address;
//        addFavName.text = self.locItem.name;
//        editTitle.text = @"edit_favorite".localized;
//        [addSaveButton setHidden:YES];
//        [editSaveButton setHidden:NO];
//        [editDeleteButton setHidden:NO];
//
//        switch (self.locItem.origin) {
//            case FavoriteItemTypeHome:
//                currentFav = typeHome;
//                [self addSelectHome:nil];
//                break;
//            case FavoriteItemTypeWork:
//                currentFav = typeWork;
//                [self addSelectWork:nil];
//                break;
//            case FavoriteItemTypeSchool:
//                currentFav = typeSchool;
//                [self addSelectSchool:nil];
//                break;
//            case FavoriteItemTypeUnknown:
//                currentFav = typeFavorite;
//                [self addSelectFavorite:nil];
//                break;
//        }
//        [self animateEditViewShow];
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:@"error_not_logged_in".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
    }
}

- (IBAction)addFavoriteShow:(id)sender {
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
    }];


    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        self.locItem = nil;
        // TODO: Move to SMFavoritesViewController
//        addFavAddress.text = @"";
//        addFavName.text = @"";
//        currentFav = typeFavorite;
//        [self addSelectFavorite:nil];
//        editTitle.text = @"add_favorite".localized;
//        [addSaveButton setHidden:NO];
//        [editSaveButton setHidden:YES];
//        [editDeleteButton setHidden:YES];
//        [self animateEditViewShow];
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:@"error_not_logged_in".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
    }
}

// TODO
//- (void)animateEditViewShow {
//    CGRect frame = mainMenu.frame;
//    frame.origin.x = 0.0f;
//    [mainMenu setFrame:frame];
//
//    frame.origin.x = 260.0f;
//    [addMenu setFrame:frame];
//    [addMenu setHidden:NO];
//
//    [UIView animateWithDuration:0.4f animations:^{
//        CGRect frame = mainMenu.frame;
//        frame.origin.x = -260.0f;
//        [mainMenu setFrame:frame];
//        frame = addMenu.frame;
//        frame.origin.x = 0.0f;
//        [addMenu setFrame:frame];
//    } completion:^(BOOL finished) {
//    }];
//}

- (IBAction)addFavoriteHide:(id)sender{
    [self.view hideKeyboard];
    [self.view removeKeyboardControl];
    // TODO
//    [UIView animateWithDuration:0.4f animations:^{
//        CGRect frame = mainMenu.frame;
//        frame.origin.x = 0.0f;
//        [mainMenu setFrame:frame];
//        frame = addMenu.frame;
//        frame.origin.x = 260.0f;
//        [addMenu setFrame:frame];
//    } completion:^(BOOL finished) {
//        [mainMenu setHidden:NO];
//        [addMenu setHidden:YES];
//        [self setFavoritesList:[SMFavoritesUtil getFavorites]];
//        if ([self.favoritesList count] == 0) {
//            [self.favoritesTableView setEditing:NO];
//        }
//        [UIView animateWithDuration:0.4f animations:^{
//            [self openMenu:menuFavorites];
//        }];
//    }];
}


// TODO
//- (IBAction)stopEdit:(id)sender {
//    [self.favoritesTableView setEditing:NO];
//    int i = 0;
//    NSMutableArray * arr = [NSMutableArray array];
//    for (FavoriteItem *item in self.favoritesList) {
//        [arr addObject:@{
//         @"id" : item.identifier,
//         @"position" : [NSString stringWithFormat:@"%d", i]
//         }];
//        i += 1;
//    }
//    self.request = [[SMAPIRequest alloc] initWithDelegeate:self];
//    [self.request executeRequest:API_SORT_FAVORITES withParams:@{@"auth_token" : [self.appDelegate.appSettings objectForKey:@"auth_token"], @"pos_ary" : arr}];
//}


#pragma mark - 

- (IBAction)toggleReminders:(UIButton *)sender {
    self.reminderFolded = !self.reminderFolded;

    if (self.remindersHeader.frame.size.height <= 50) {
        self.reminderFolded = YES;
    }

    CGFloat maxHeight = self.view.frame.size.height - 0;//startY;
    if ( self.reminderFolded ) {

        [UIView animateWithDuration:0.4f animations:^{
            //[self openMenu:menuReminders];

            [self.imgReminders setImage:[UIImage imageNamed:@"reminders_arrow_up"]];

            [self.favEditDone setHidden:YES];
            [self.favEditStart setHidden:YES];
            CGRect frame = self.favHeader.frame;
            frame.size.height = 45.0f;
            [self.favHeader setFrame:frame];

            frame = self.remindersHeader.frame;
            frame.origin.y = self.favHeader.frame.origin.y + 45.0f;
            frame.size.height = maxHeight - 3 * 45.0f;
            [self.remindersHeader setFrame:frame];

            float startY = self.remindersHeader.frame.origin.y + 6*45; //self.remindersHeader.frame.size.height;

            frame = self.favHeader.frame;
            //frame.origin.y = 0; //startY;
            frame.size.height = 45.0f;
            [self.favHeader setFrame:frame];

            frame = self.accHeader.frame;
            frame.origin.y = startY;
            frame.size.height = 45.0f;
            [self.accHeader setFrame:frame];

            frame = self.infoHeader.frame;
            frame.origin.y = startY + 45.0f;
            frame.size.height = 45.0f;
            [self.infoHeader setFrame:frame];

        }];
    } else {
        [UIView animateWithDuration:0.4f animations:^{
             [self.imgReminders setImage:[UIImage imageNamed:@"reminders_arrow_down"]];
            [self openMenu:menuFavorites];
        }];

    }
}

#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    if (tableView == self.favoritesTableView) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (tableView == self.favoritesTableView) {
        if (section == 0) {
            if ([self.favoritesList count] > 0) {
                return [self.favoritesList count];
            } else {
                return 1;
            }
            return [self.favoritesList count];
        } else {
            if ( self.reminderFolded ){
                return 0;
            } else {
                return 0;
            }
        }
    }
    
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.favoritesTableView) {
        if ([self.favoritesList count] > 0) {
            if (self.favoritesTableView.isEditing) {
                FavoriteItem *currentItem = self.favoritesList[indexPath.row];
                SMMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesCell"];
                [cell.image setContentMode:UIViewContentModeCenter];
                [cell setDelegate:self];
                [cell.image setImage:[UIImage imageNamed:@"favReorder"]];
                [cell.editBtn setHidden:NO];
                cell.text.text = currentItem.name;
                return cell;
            } else {
                FavoriteItem *currentItem = self.favoritesList[indexPath.row];
                SMMenuCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesCell"];
                [cell.image setContentMode:UIViewContentModeCenter];
                [cell setDelegate:self];
                [cell setIndentationLevel:2];
                switch (currentItem.origin) {
                    case FavoriteItemTypeHome:
                        [cell.image setImage:[UIImage imageNamed:@"favHomeGrey"]];
                        [cell.image setHighlightedImage:[UIImage imageNamed:@"favHomeWhite"]];
                        break;
                    case FavoriteItemTypeWork:
                        [cell.image setImage:[UIImage imageNamed:@"favWorkGrey"]];
                        [cell.image setHighlightedImage:[UIImage imageNamed:@"favWorkWhite"]];
                        break;
                    case FavoriteItemTypeSchool:
                        [cell.image setImage:[UIImage imageNamed:@"favSchoolGrey"]];
                        [cell.image setHighlightedImage:[UIImage imageNamed:@"favSchoolWhite"]];
                        break;
                    default:
                        [cell.image setImage:[UIImage imageNamed:@"favStarGreySmall"]];
                        [cell.image setHighlightedImage:[UIImage imageNamed:@"favStarWhiteSmall"]];
                        break;
                }
                [cell.editBtn setHidden:YES];
                cell.text.text = currentItem.name;

                UIView * v = [cell viewWithTag:10001];
                if (v) {
                    [v removeFromSuperview];
                }
                return cell;
            }
        } else {
            SMEmptyFavoritesCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesEmptyCell"];
            [cell.text setText:@"cell_add_favorite".localized];
            if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
                [cell.addFavoritesText setText:@"cell_empty_favorite_text".localized];
                [cell.addFavoritesText setTextColor:[UIColor whiteColor]];
                [cell.text setTextColor:[UIColor colorWithRed:0.0f/255.0f green:174.0f/255.0f blue:239.0f/255.0f alpha:1.0f]];
                [cell.addFavoritesSymbol setImage:[UIImage imageNamed:@"favAdd"]];
            } else {
                [cell.addFavoritesText setText:@"favorites_login".localized];
                [cell.addFavoritesText setTextColor:[UIColor colorWithRed:123.0f/255.0f green:123.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
                [cell.text setTextColor:[UIColor colorWithRed:123.0f/255.0f green:123.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
                [cell.addFavoritesSymbol setImage:[UIImage imageNamed:@"fav_plus_none_grey"]];

            }

            return cell;
        }
    }
    UITableViewCell * cell;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.favoritesTableView && indexPath.section == 0) {
        if ([self.favoritesList count] == 0) {
            if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
                /**
                 * add favorite
                 */
                [self addFavoriteShow:nil];
            }
        } else {
            if (self.favoritesTableView.isEditing) {
                /**
                 * edit favorite
                 */
                self.locItem = self.favoritesList[indexPath.row];
                self.locIndex = indexPath.row;
                [self editFavoriteShow:nil];
            } else {
                /**
                 * navigate to favorite
                 */
                if (indexPath.row < [self.favoritesList count]) {
                    FavoriteItem *currentItem = self.favoritesList[indexPath.row];

                    // TODO: Go to favorites
                    [self performSegueWithIdentifier:@"menuToFavorites" sender:self];
                    if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Menu" withLabel:@"Favorites" withValue:0]) {
                        debugLog(@"error in trackEvent");
                    }
                    
//                    CLLocation * cEnd = currentItem.location;
//                    CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
//
//                    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
//                    r.requestIdentifier = @"rowSelectRoute";
//                    r.auxParam = currentItem.name;
//                    [r findNearestPointForStart:cStart andEnd:cEnd];
                } else {
                    /**
                     * add favorite
                     */
                    [self addFavoriteShow:nil];
                }
            }
        }
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView == self.favoritesTableView) {
        if ([self.favoritesList count] == 0) {
            if ( indexPath.section == 0 ) {
                return [SMEmptyFavoritesCell getHeight];
            } else if ( indexPath.section == 1) {
                return 45.0f;
            }
        } else {
            return [SMMenuCell getHeight];
        }
    }
    return 45.0f;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (tableView == self.favoritesTableView) {
        if ([self.favoritesList count] == 0) {
            return;
        }
        NSDictionary * src = [self.favoritesList objectAtIndex:sourceIndexPath.row];
        [self.favoritesList removeObjectAtIndex:sourceIndexPath.row];
        [self.favoritesList insertObject:src atIndex:destinationIndexPath.row];
        [SMFavoritesUtil saveFavorites:self.favoritesList];
    }
    [tableView reloadData];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView* view = [cell subviewWithClassName:@"UITableViewCellReorderControl"];

    if (view) {
        [view setExclusiveTouch:NO];
        UIView* resizedGripView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetMaxX(view.frame), CGRectGetMaxY(view.frame))];
        resizedGripView.exclusiveTouch = YES;
        [resizedGripView addSubview:view];
        [cell addSubview:resizedGripView];


        CGSize sizeDifference = CGSizeMake(resizedGripView.frame.size.width - view.frame.size.width, resizedGripView.frame.size.height - view.frame.size.height);
        CGSize transformRatio = CGSizeMake(resizedGripView.frame.size.width / view.frame.size.width, resizedGripView.frame.size.height / view.frame.size.height);

        //	Original transform
        CGAffineTransform transform = CGAffineTransformIdentity;

        //	Scale custom view so grip will fill entire cell
        transform = CGAffineTransformScale(transform, transformRatio.width, transformRatio.height);

        //	Move custom view so the grip's top left aligns with the cell's top left
        transform = CGAffineTransformTranslate(transform, -sizeDifference.width / 2.0, -sizeDifference.height / 2.0);

        [resizedGripView setTransform:transform];

        for(UIImageView* cellGrip in view.subviews) {
            if([cellGrip isKindOfClass:[UIImageView class]]) {
                [cellGrip setImage:nil];
            }
        }

        UIView * v = [cell viewWithTag:10001];
        if (v == nil) {
            UIButton * btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn2 setFrame:CGRectMake(52.0f, 0.0f, 156.0f, cell.frame.size.height)];
            [btn2 setTag:10001];
            [cell addSubview:btn2];
        }


        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(208.0f, 0.0f, 52.0f, cell.frame.size.height)];
        [btn setTag:indexPath.row];
        [btn addTarget:self action:@selector(rowSelected:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:btn];

    } else {
        UIView * v = [cell viewWithTag:10001];
        if (v) {
            [v removeFromSuperview];
        }
    }
}

- (IBAction)rowSelected:(id)sender {
    [self tableView:self.favoritesTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:((UIButton*)sender).tag inSection:0]];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (tableView == self.favoritesTableView && section == 0) {
        if (tableView.isEditing) {
            return [[UIView alloc] initWithFrame:CGRectZero];
        } else {
            if ([self.favoritesList count] > 0) {
                return self.tableFooter;
            } else {
                return [[UIView alloc] initWithFrame:CGRectZero];
            }
        }
    } else {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ( section == 0 ) {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    } else {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // TODO: What the
    if (tableView == self.favoritesTableView) {
        if (section == 0) {
            return 0;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView == self.favoritesTableView && section == 0) {
        if (tableView.isEditing) {
            return 0.0f;
        } else {
            if ([self.favoritesList count] > 0) {
                return [SMAddFavoriteCell getHeight];
            } else {
                return 0.0f;
            }
        }
    } else {
        return 0.0f;
    }
}


#pragma mark - observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.favoritesTableView && [keyPath isEqualToString:@"editing"]) {
        if (self.favoritesTableView.editing) {
            [self.favEditDone setHidden:NO];
            [self.favEditStart setHidden:YES];
        } else {
            [self.favEditDone setHidden:YES];
            [self.favEditStart setHidden:NO];
        }
        [UIView animateWithDuration:0.4f animations:^{
            [self openMenu:menuFavorites];
        }];
    }
}

#pragma mark - menu header delegate

- (void)editFavorite:(SMMenuCell *)cell {
    NSInteger ind = [self.favoritesTableView indexPathForCell:cell].row;
    debugLog(@"%ld", (long)ind);
}


// TODO
//#pragma mark - Add cell delegate
//
//- (void)viewTapped:(id)view {
//    [self addFavoriteShow:nil];
//}
//
//#pragma mark - custom methods
//
//- (void)inputKeyboardWillHide:(NSNotification *)notification {
//    CGRect frame = addMenu.frame;
//    frame.size.height = menuView.frame.size.height;
//    [addMenu setFrame:frame];
//}

#pragma mark - notifications

- (void)favoritesChanged:(NSNotification*) notification {
    self.favoritesList = [SMFavoritesUtil getFavorites];
    [self openMenu:menuFavorites];
}


#pragma mark - UIStatusBarStyle

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
