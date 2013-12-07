//
//  LoginViewController.m
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/5/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import "LoginViewController.h"
#import "NXOAuth2AccountStore.h"

#define LOGIN_STATUS_URL_STRING @"http://whi-screensaver.herokuapp.com"
#define LOG_OUT_URL_STRING @"http://whi-screensaver.herokuapp.com/logout"
#define REDIRECT_URL_STRING @"http://whi-screensaver.herokuapp.com/auth/weheartit/callback"

@interface LoginViewController()
{
    NSMutableData *loginStatusData;
    NSURL *finalLoginStatusUrl;
    BOOL loadingLoginStatus;
    BOOL loggingOut;
    NSURL *authURL;
}

@end

@implementation LoginViewController

- (id)init
{
    NSBundle *saverBundle = [NSBundle bundleForClass:[self class]];
    self = [super initWithNibName:@"LoginView" bundle:saverBundle];
    if (self) {
        
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    // hide all the elements, show loading while we initialize
    [self.webView setHidden:YES];
    [self.signInButton setHidden:YES];
    [self.loadingSpinner setHidden:NO];
    [self.loadingSpinner startAnimation:nil];
    [self updateLoginStatus];
}

- (void)logOut
{
    NSLog(@"requesting: %@",LOG_OUT_URL_STRING);
    if (loggingOut || loadingLoginStatus) {
        return;
    }
    loggingOut = YES;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:LOG_OUT_URL_STRING]];
    __unused NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    // also clear cookies
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie *cookie in [cookieJar cookiesForURL:[NSURL URLWithString:LOGIN_STATUS_URL_STRING]]) {
        [cookieJar deleteCookie:cookie];
    }
}

- (void)login
{
    
    NSLog(@"LOAD DELEGATE: %@",self.webView.resourceLoadDelegate);
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *notification){
        // set the current account to this account
        // TODO: store the access token in nsuserdefaults
        NXOAuth2Account *currentUserAccount = [[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"WeHeartIt"] objectAtIndex:0];
        NSLog(@"Logged in with account : %@",currentUserAccount);
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *notification){
        NSError *error = [notification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
        NSLog(@"ERROR SIGNING IN: %@",[error localizedDescription]);
    }];
    [self.signInButton setHidden:YES];
    [self.loadingSpinner setHidden:NO];
    [self.loadingSpinner startAnimation:nil];
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"WeHeartIt" withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
        [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
    }];
}

- (void)updateLoginStatus
{
    if (loadingLoginStatus || loggingOut) {
        // TODO: show an error? queue?
        return;
    }
    loadingLoginStatus = YES;
    NSLog(@"requesting: %@",LOGIN_STATUS_URL_STRING);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:LOGIN_STATUS_URL_STRING]];
    __unused NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)setLoginStatusWithInfo:(NSDictionary *)info
{
    [self setLoginStatusWithInfo:info showingError:NO];
}

- (void)setLoginStatusWithInfo:(NSDictionary *)info showingError:(BOOL)showError
{
    [self.loadingSpinner setHidden:YES];
    BOOL isLoggedIn = [[info objectForKey:@"logged_in"] boolValue];
    if (!isLoggedIn) {
        // set up OAuth stuff
        NSString *loginPath = [info objectForKey:@"login_url"];
        NSLog(@"login path: %@", loginPath);
        authURL = [NSURL URLWithString:loginPath relativeToURL:finalLoginStatusUrl];
        NSLog(@"login url: %@",[authURL absoluteString]);
        NSURL *redirectURL = [NSURL URLWithString:REDIRECT_URL_STRING];
        NSLog(@"Starting with client id: %@",WHI_CLIENT_ID);
        [[NXOAuth2AccountStore sharedStore] setClientID:WHI_CLIENT_ID secret:WHI_CLIENT_SECRET authorizationURL:authURL tokenURL:authURL redirectURL:redirectURL forAccountType:@"WeHeartIt"];
        [self.delegate userLoggedOut];
        [self.signInButton setHidden:NO];
        if (showError) {
            [self.errorLabel setStringValue:@"Login Failed. Please Try again."];
        }
    } else {
        // get user data, store it.
        [[NSUserDefaults standardUserDefaults] setObject:info forKey:@"userInfo"];
        NSLog(@"user is logged in with data: %@",info);
        [self.delegate userLoggedIn];
    }
}

- (void)signInPressed:(id)sender
{
    [self login];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"response : %@",response);
    loginStatusData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"data : %@",data);
    [loginStatusData appendData:data];
}
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    loadingLoginStatus = NO;
    loggingOut = NO;
    [[NSAlert alertWithError:error] runModal];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (loggingOut) {
        loggingOut = NO;
        [self updateLoginStatus];
    } else {
        loadingLoginStatus = NO;
        // LoginStatusData is now the data we're looking for.
        NSError *parseError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:loginStatusData options:NSJSONReadingMutableContainers error:&parseError];
        if (parseError) {
            NSLog(@"parse error. %@",[parseError localizedDescription]);
            // encountered a parse error.
            [[NSAlert alertWithError:parseError] runModal];
        } else if(!jsonData){
            NSLog(@"data error.");
            [NSAlert alertWithError:[NSError errorWithDomain:@"com.weheartit.WeHeartItScreensaver" code:500 userInfo:@{@"message":@"Malformed Response."}]];
        } else {
            // json data received. Send to login status handler.
            [self setLoginStatusWithInfo:jsonData];
        }
    }
    
}
- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    finalLoginStatusUrl = [request URL];
    return request;
}

#pragma mark - WebResourceLoadDelegate

- (void)webView:(WebView *)webView resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
    if ([[self.webView mainFrameURL] rangeOfString:@"https://weheartit.com/oauth/authorize" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        [self.loadingSpinner setHidden:YES];
        [self.webView setHidden:NO];
    } else {
        [self.webView setHidden:YES];
        [self.loadingSpinner setHidden:NO];
        [self.loadingSpinner startAnimation:nil];
        [self updateLoginStatus];
    }
}

- (void)webView:(WebView *)webView resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource
{
    NSLog(@"FAILED TO LOAD URL %@",[self.webView mainFrameURL]);
    [self.webView setHidden:YES];
    [self.signInButton setHidden:NO];
    [self.loadingSpinner setHidden:YES];
    [self.errorLabel setStringValue:[NSString stringWithFormat:@"Failed to load from authorization server. Error: %@",[error localizedDescription]]];
}

@end
