//
//  ApiClient.m
//  We Heart It Screensaver
//
//  Created by Jesse Ditson on 12/6/13.
//  Copyright (c) 2013 We Heart It. All rights reserved.
//

#import "ApiClient.h"
#import "NSURL+QueryStringAdditions.h"

@implementation ApiClient

static ApiClient *sharedSingleton;

static NSOperationQueue *apiQueue;
// caches
static NSMutableDictionary *currentUser;
static int currentErrors;
// constants
#define API_REQUEST_RETRY_RATE 1
#define API_MAX_FAILURES 1

+ (void) initialize {
    NSLog(@"initializing We Heart It api");
    static BOOL initialized = NO;
    if(!initialized){
        initialized = YES;
        sharedSingleton = [[ApiClient alloc] init];
        apiQueue = [[NSOperationQueue alloc] init];
        // make api queue serial
        apiQueue.maxConcurrentOperationCount = 1;
        currentUser = [[NSMutableDictionary alloc] init];
    }
}

+ (void)updateCurrentUser:(callbackHandler)callback
{
    [self getURL:@"v2/user" callback:^(NSDictionary *user, NSError *error){
        if (!error && user) {
            currentUser = [NSMutableDictionary dictionaryWithDictionary:user];
        }
        callback(currentUser,error);
    }];
}

+ (void)getCurrentUserCollections:(callbackHandler)callback
{
    [self getCurrentUserCollectionsWithUrl:[NSString stringWithFormat:@"v2/users/%@/collections",[currentUser objectForKey:@"id"]] callback:callback currentCollections:nil];
}

+ (void)getCurrentUserCollectionsWithUrl:(NSString *)urlString callback:(callbackHandler)callback currentCollections:(NSArray *)collections
{
    if (!collections) {
        collections = @[];
    }
    [self getURL:urlString callback:^(NSDictionary *response, NSError *error){
        if (error) {
            return callback(nil,error);
        } else {
            NSArray *newCollections = [response objectForKey:@"collections"];
            NSArray *currentCollections = [collections arrayByAddingObjectsFromArray:newCollections];
            NSDictionary *meta = [response objectForKey:@"meta"];
            NSString *nextPage = [meta objectForKey:@"next_page_url"];
            if (newCollections && [newCollections count] > 0 && nextPage) {
                [ApiClient getCurrentUserCollectionsWithUrl:nextPage callback:callback currentCollections:currentCollections];
            } else {
                callback(currentCollections,nil);
            }
        }
    }];
}

+ (void)getRecentEntries:(callbackHandler)callback
{
    [self getURL:@"v2/entries" callback:^(NSDictionary *response, NSError *error){
        if (error) {
            return callback(nil,error);
        } else {
            callback([response objectForKey:@"entries"],error);
        }
    }];
}
+ (void)getUserEntries:(callbackHandler)callback
{
    NSString *queryUrl = [NSString stringWithFormat:@"v2/users/%@/entries?limit=%d",[currentUser objectForKey:@"id"],24];
    [self getURL:queryUrl callback:^(NSDictionary *response, NSError *error){
        if (error) {
            return callback(nil,error);
        } else {
            callback([response objectForKey:@"entries"],error);
        }
    }];
}
+ (void)getEntriesForQuery:(NSString *)query callback:(callbackHandler)callback
{
    NSString *queryUrl = [NSString stringWithFormat:@"v2/search/entries?query=%@&limit=%d",query,24];
    [self getURL:queryUrl callback:^(NSDictionary *response, NSError *error){
        if (error) {
            return callback(nil,error);
        } else {
            callback([response objectForKey:@"entries"],error);
        }
    }];
}
+ (void)getEntriesInCollection:(NSString *)collectionId callback:(callbackHandler)callback
{
    NSString *queryUrl = [NSString stringWithFormat:@"v2/collections/%@",collectionId];
    [self getURL:queryUrl callback:^(NSDictionary *response, NSError *error){
        if (error) {
            return callback(nil,error);
        } else {
            callback([response objectForKey:@"recent_entries"],error);
        }
    }];
}

# pragma mark - low level apis - used by above methods

+ (void) doRequest:(NSURLRequest *)request withCallback:(callbackHandler)callback {
    
    // add the access token if it's not there.
    if ([[request.URL absoluteString] rangeOfString:@"access_token="].location == NSNotFound) {
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"];
        NSString *accessToken;
        if (![userInfo objectForKey:@"token"]) {
            callback(nil,[NSError errorWithDomain:ERROR_DOMAIN code:401 userInfo:@{@"message":@"Not logged in."}]);
            return;
        } else {
            accessToken = [userInfo objectForKey:@"token"];
        }
        // append the access token
        NSURL *newURL = [[request URL] URLByAppendingQueryString:[NSString stringWithFormat:@"access_token=%@",accessToken]];
        request = [NSURLRequest requestWithURL:newURL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
    }
    // show our status
    [[NSNotificationCenter defaultCenter] postNotificationName:@"api:loading" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                  @"Loading...", @"message",
                                                                                                  nil]];
    NSLog(@"Requesting url: %@.",[[request URL] absoluteString]);
    [NSURLConnection sendAsynchronousRequest:request queue:apiQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        int statusCode = (int)[(NSHTTPURLResponse *)response statusCode];
        id json;
        if(statusCode < 400){
            if (API_LOG_EXTENDED) NSLog(@"got response %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            // parse the response
            NSError *jsonError;
            if(data != nil){
                json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            }
            if(jsonError){
                json = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSString stringWithFormat:@"Bad JSON response : %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]],@"error",
                        nil];
            }
        } else {
            NSString *errorDescription = [NSString stringWithFormat:@"Bad HTTP status code : %d",statusCode];
            json = [NSDictionary dictionaryWithObjectsAndKeys:
                    errorDescription,@"error",
                    [NSNumber numberWithInt:statusCode], @"code",
                    nil];
            error = [NSError errorWithDomain:ERROR_DOMAIN code:statusCode userInfo:@{NSLocalizedDescriptionKey:errorDescription}];
        }
        [self returnResponse:json andError:error forRequest:request toCallback:callback];
    }];
}

+ (void) returnResponse:(id)response andError:(NSError *)error forRequest:(NSURLRequest *)request toCallback:(callbackHandler)callback {
    if(error){
        NSLog(@"Encountered error calling WHI API: %@",[error localizedDescription]);
        // fail completely on errors, try again in a bit.
        // show our status
        [[NSNotificationCenter defaultCenter] postNotificationName:@"api:error" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                      @"Error contacting WHI Server.", @"message",
                                                                                                      @"error", @"type",
                                                                                                      nil]];
        currentErrors++;
        if(currentErrors <= API_MAX_FAILURES){
            NSLog(@"Failed to contact url: %@. Attempt %d of %d. Retrying in %d.",[[request URL] absoluteString],currentErrors,API_MAX_FAILURES,API_REQUEST_RETRY_RATE);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * API_REQUEST_RETRY_RATE), dispatch_get_main_queue(), ^(void){
                [self doRequest:request withCallback:callback];
            });
        } else {
            currentErrors = 0;
            NSLog(@"Failed to contact url: %@. Attempt %d of %d. Permanent Failure.",[[request URL] absoluteString],currentErrors,API_MAX_FAILURES);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"api:error" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                          @"Offline.", @"message",
                                                                                                          @"error", @"type",
                                                                                                          nil]];
            // return callback to preserve expectations
            if( callback ){
                callback(response,error);
            }
        }
    } else {
        currentErrors = 0;
        // show our status
        [[NSNotificationCenter defaultCenter] postNotificationName:@"api:complete" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
         @"Updated.", @"message",
         @"complete", @"type",
         nil]];
        // callback with it
        if(callback != nil){
            callback(response, error);
        }
    }
}

+ (void) getURL:(NSString *)pathname callback:(callbackHandler)callback {
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:pathname relativeToURL:[NSURL URLWithString:WHI_API_BASE_PATH]]];
    
    // set app specific headers
    [request setValue:@"YES" forHTTPHeaderField:@"x-weheartit-screensaver"];
    
    [self doRequest:request withCallback:callback];
}

+ (void) postURL:(NSString *)pathname withRequest:(NSMutableURLRequest *)request callback:(callbackHandler)callback {
    // show our status
    [[NSNotificationCenter defaultCenter] postNotificationName:@"api:loading" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                  @"Loading...", @"message",
                                                                                                  nil]];
    
    // make a POST
    [request setHTTPMethod:@"POST"];
    // set app specific headers
    [request setValue:@"YES" forHTTPHeaderField:@"x-whi-screensaver"];
    
    [self doRequest:request withCallback:callback];
}

+ (void) postURL:(NSString *)pathname callback:(callbackHandler)callback {
    [self postURL:pathname withData:nil callback:callback];
}

+ (void) postURL:(NSString *)pathname withData:(NSDictionary *)body callback:(callbackHandler)callback {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:pathname relativeToURL:[NSURL URLWithString:WHI_API_BASE_PATH]]];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
    
    // set data
    NSData *postbody = nil;
    if(body != nil){
        postbody = [self encodeDictionary:body];
        [request setHTTPBody:postbody];
    }
    //NSLog(@"POSTING DATA: %@, %@",[body description],[[NSString alloc] initWithData:postbody encoding:NSUTF8StringEncoding]);
    NSString *contentLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postbody length]];
    [request addValue:contentLength forHTTPHeaderField:@"Content-Length"];
    
    [self postURL:pathname withRequest:request callback:callback];
}
+ (void) postURL:(NSString *)pathname withData:(NSDictionary *)body andFilename:(NSString *)filename withFileData:(NSData *)fileData callback:(callbackHandler)callback {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:pathname relativeToURL:[NSURL URLWithString:WHI_API_BASE_PATH]]];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449OMGLOL";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    NSMutableData *postbody = [NSMutableData data];
    
    // set post body
    if(body != nil && [body count] > 0){
        [postbody appendData:[[self dictionaryToFormData:body withBoundary:boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    // add the image
    if(filename != nil){
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
        //[postbody appendData:[@"Content-Transfer-Encoding: binary\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[NSData dataWithData:fileData]];
    }
    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //NSString *contentLength = [NSString stringWithFormat:@"%d",[postbody length]];
    //[request addValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postbody];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    [self postURL:pathname withRequest:request callback:callback];
}

+ (NSString *)dictionaryToFormData:(NSDictionary *)dictionary withBoundary:(NSString *)boundary {
    NSString *formdata = @"";
    for(NSString *key in [dictionary allKeys]){
        id value = [dictionary valueForKey:key];
        formdata = [formdata stringByAppendingString:[self formDataForItem:value forName:key withBoundary:boundary]];
    }
    return formdata;
}
+ (NSString *)formDataForItem:(id)item forName:(NSString *)name withBoundary:(NSString *)boundary {
    NSString *formdata = @"";
    if([item isKindOfClass:[NSArray class]]){
        for(id subItem in item){
            formdata = [formdata stringByAppendingString:[self formDataForItem:subItem forName:[NSString stringWithFormat:@"%@[]",name] withBoundary:boundary]];
        }
    } else if([item isKindOfClass:[NSDictionary class]]){
        for(NSString *subKey in [item allKeys]){
            formdata = [formdata stringByAppendingString:[self formDataForItem:[item objectForKey:subKey] forName:[NSString stringWithFormat:@"%@[%@]",name,subKey] withBoundary:boundary]];
        }
    } else if([item isKindOfClass:[NSString class]]){
        formdata = [NSString stringWithFormat:@"\r\n--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",boundary,name,item];
    } else {
        NSLog(@"attempted to encode an incompatible object: %@",[item description]);
    }
    return formdata;
}

+ (NSData *)encodeDictionary:(NSDictionary *)dictionary {
    NSString *encodedDictionary = [self dictionaryToQueryString:dictionary];
    NSLog(@"encoded : %@",[encodedDictionary description]);
    return [encodedDictionary dataUsingEncoding:NSUTF8StringEncoding];
}
+ (NSString *)dictionaryToQueryString:(NSDictionary *)dictionary {
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    for (NSString *key in dictionary) {
        id item = [dictionary objectForKey:key];
        [parts addObject:[self itemToQueryString:item forKey:key]];
    }
    return [parts componentsJoinedByString:@"&"];
}
+ (NSString *)stringToQueryString:(NSString *)item forKey:(NSString *)key {
    NSString *encodedValue = [self encodeString:item];
    NSString *encodedKey = [self encodeString:key];
    NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
    return part;
}
+ (NSString *)itemToQueryString:(id)item forKey:(NSString *)key {
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    if([item isKindOfClass:[NSArray class]]){
        for(id subItem in item){
            [parts addObject:[self itemToQueryString:subItem forKey:[NSString stringWithFormat:@"%@[]",key]]];
        }
    } else if([item isKindOfClass:[NSDictionary class]]){
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        for(NSString *subKey in item){
            [dict setObject:[item objectForKey:subKey] forKey:[NSString stringWithFormat:@"%@[%@]",key,subKey]];
        }
        [parts addObject:[self dictionaryToQueryString:dict]];
    } else if([item isKindOfClass:[NSString class]]){
        [parts addObject:[self stringToQueryString:item forKey:key]];
    } else if([item isKindOfClass:[NSNumber class]]){
        [parts addObject:[self stringToQueryString:[(NSNumber*)item stringValue] forKey:key]];
    } else {
        NSLog(@"attempted to encode an incompatible object: %@",[item description]);
    }
    return [parts componentsJoinedByString:@"&"];
}

// apple's encoding is fucking stupid
+ (NSString *)encodeString:(NSString *)unencodedString {
    NSString * encodedString = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                            NULL,
                                                                                            (CFStringRef)unencodedString,
                                                                                            NULL,
                                                                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                            kCFStringEncodingUTF8 );
    return encodedString;
}

@end
