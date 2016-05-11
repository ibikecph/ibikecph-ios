//
//  SMAPIRequest.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 03/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "Reachability.h"
#import "SMAPIRequest.h"
#import "SMNetworkErrorView.h"

@interface SMAPIRequest ()
@property(nonatomic, strong) NSDictionary *serviceParams;
@property(nonatomic, strong) NSDictionary *serviceURL;

@property(nonatomic, strong) NSURLConnection *conn;
@property(nonatomic, strong) NSMutableData *responseData;
@property(nonatomic, weak) UIView *waitingView;
@end

@implementation SMAPIRequest

- (id)initWithDelegeate:(id<SMAPIRequestDelegate>)dlg
{
    self = [super init];
    if (self) {
        [self setDelegate:dlg];
        self.manualRemove = NO;
    }
    return self;
}

- (BOOL)serverReachable
{
    Reachability *r = [Reachability reachabilityWithHostName:REACHABILITY_CHECK_HOSTNAME];
    NetworkStatus s = [r currentReachabilityStatus];
    if (s == NotReachable) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(serverNotReachable)]) {
            [self.delegate serverNotReachable];
        }
        [self hideWaitingView];
        NSMutableDictionary *details = [NSMutableDictionary dictionary];
        [details setValue:@"Network error!" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:details];
        if (self.delegate && [self.delegate respondsToSelector:@selector(request:failedWithError:)]) {
            [self.delegate request:self failedWithError:error];
        }
        return NO;
    }
    return YES;
}

- (void)executeRequest:(NSDictionary *)request withParams:(NSDictionary *)params
{
    [self setServiceParams:params];
    [self setServiceURL:request];

    if ([self serverReachable] == NO) {
        return;
    }

    if ([request[@"transferMethod"] isEqualToString:@"GET"]) {
        [self executeGetRequestWithParams:params andURL:request];
    }
    else {
        [self executePostRequestWithParams:params andURL:request];
    }
}

/**
 * Executes GET type request (GET) with given parameters and service URL
 */
- (void)executeGetRequestWithParams:(NSDictionary *)params andURL:(NSDictionary *)service
{
    if (service) {
        NSString *urlString = [NSString stringWithFormat:@"%@/%@", [SMRouteSettings sharedInstance].api_base_url, service[@"service"]];
        BOOL first = NO;
        NSRange range = [urlString rangeOfString:@"?"];
        if (range.location == NSNotFound) {
            first = YES;
        }

        NSMutableArray *d = [[NSMutableArray alloc] initWithCapacity:[[params allKeys] count]];
        for (NSString *key in [params allKeys]) {
            if ([params[key] isKindOfClass:[NSString class]]) {
                [d addObject:[NSString stringWithFormat:@"%@=%@", key, [params[key] urlEncode]]];
            }
            else {
                if ([params[key] isKindOfClass:[NSNull class]]) {
                    [d addObject:[NSString stringWithFormat:@"%@=", key]];
                }
                else {
                    [d addObject:[NSString stringWithFormat:@"%@=%@", key, [params[key] stringValue]]];
                }
            }
        }
        NSString *urlP = [d componentsJoinedByString:@"&"];

        if (first) {
            urlString = [urlString stringByAppendingFormat:@"?%@", urlP];
        }
        else {
            urlString = [urlString stringByAppendingFormat:@"&%@", urlP];
        }

        debugLog(@"*** %@ %@", service[@"transferMethod"], urlString);

        //        NSData * data = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];

        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        //        [req setHTTPBody:data];
        [req setHTTPMethod:service[@"transferMethod"]];
        for (NSDictionary *d in service[@"headers"]) {
            [req setValue:d[@"value"] forHTTPHeaderField:d[@"key"]];
        }

        debugLog(@"*** Headers: %@", req.allHTTPHeaderFields);

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *language = [defaults stringForKey:@"appLanguage"];
        if ([language isEqualToString:@"en"]) {
            [req setValue:@"en" forHTTPHeaderField:@"LANGUAGE_CODE"];
        }
        else if ([language isEqualToString:@"dk"]) {
            [req setValue:@"da" forHTTPHeaderField:@"LANGUAGE_CODE"];
        }

        if (self.conn) {
            [self.conn cancel];
            self.conn = nil;
        }
        self.responseData = [NSMutableData data];
        NSURLConnection *c = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
        self.conn = c;
        [self.conn start];
    }
    else {
        return;
    }
}

/**
 * Executes POST type request (POST/PUT/DELETE) with given parameters and service URL
 */
- (void)executePostRequestWithParams:(NSDictionary *)params andURL:(NSDictionary *)service
{
    if (service) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];

        NSLog(@"POST DATA: %@", data);
        NSLog(@"PARAMS: %@", params);

        NSMutableURLRequest *req =
            [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [SMRouteSettings sharedInstance].api_base_url, service[@"service"]]]];
        [req setHTTPMethod:service[@"transferMethod"]];
        [req setHTTPBody:data];
        for (NSDictionary *d in service[@"headers"]) {
            [req setValue:d[@"value"] forHTTPHeaderField:d[@"key"]];
        }

        debugLog(@"*** %@ %@", service[@"transferMethod"], req.URL);

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *language = [defaults stringForKey:@"appLanguage"];
        if ([language isEqualToString:@"en"]) {
            [req setValue:@"en" forHTTPHeaderField:@"LANGUAGE_CODE"];
        }
        else if ([language isEqualToString:@"dk"]) {
            [req setValue:@"da" forHTTPHeaderField:@"LANGUAGE_CODE"];
        }

        debugLog(@"*** Headers: %@", req.allHTTPHeaderFields);

        if (self.conn) {
            [self.conn cancel];
            self.conn = nil;
        }
        self.responseData = [NSMutableData data];
        NSURLConnection *c = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];

        self.conn = c;
        [self.conn start];
    }
    else {
        return;
    }
}

- (void)showTransparentWaitingIndicatorInView:(UIView *)view
{
    UIView *v = [[UIView alloc] initWithFrame:view.frame];
    CGRect frame = v.frame;
    frame.origin = CGPointZero;
    [v setFrame:frame];
    [v setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.7f]];

    UIActivityIndicatorView *av = [[UIActivityIndicatorView alloc] init];
    [av setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    frame.origin.x = floorf((frame.size.width - av.frame.size.width) / 2.0f);
    frame.origin.y = floorf((frame.size.height - av.frame.size.height) / 2.0f);
    frame.size = av.frame.size;
    [av setFrame:frame];
    [av setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin |
                            UIViewAutoresizingFlexibleBottomMargin];
    [av startAnimating];

    [v addSubview:av];
    [v setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    if (self.waitingView) {
        [self.waitingView removeFromSuperview];
    }
    [self setWaitingView:v];
    [view addSubview:self.waitingView];

    [v setAlpha:0.0f];

    [UIView animateWithDuration:0.2f
                     animations:^{
                       [self.waitingView setAlpha:1.0f];
                     }];
}

- (void)hideWaitingView
{
    if (self.waitingView) {
        [UIView animateWithDuration:0.2f
            animations:^{
              [self.waitingView setAlpha:0.0f];
            }
            completion:^(BOOL finished) {
              [self.waitingView removeFromSuperview];
            }];
    }
}

#pragma mark - url connection delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.manualRemove == NO) {
        [self hideWaitingView];
    }
    NSError *error = NULL;
    NSString *s = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    debugLog(@"API response: %@", s);
    NSDictionary *d =
        [NSJSONSerialization JSONObjectWithData:[s dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(request:failedWithError:)]) {
            [self.delegate request:self failedWithError:error];
        }
        return;
    }
    if (d[@"invalid_token"]) {
        [UserHelper logout];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"invalidToken" object:nil];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(request:completedWithResult:)]) {
        debugLog(@"%@", d);
        [self.delegate request:self completedWithResult:d];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.manualRemove == NO) {
        [self hideWaitingView];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(request:failedWithError:)]) {
        [self.delegate request:self failedWithError:error];
    }
}

@end
