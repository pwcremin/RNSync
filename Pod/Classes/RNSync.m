//
//  ReactSync.m
//  reactCloudantSync
//
//  Created by Patrick cremin on 2/17/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RNSync.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"

@implementation RNSync
{
    CDTDatastore *datastore;
    CDTDatastoreManager *manager;
    CDTReplicator *replicator;
    CDTReplicatorFactory *replicatorFactory;
    NSURL *remoteDatabaseURL;
    RCTResponseSenderBlock replicatorDidCompleteCallback;
    RCTResponseSenderBlock replicatorDidErrorCallback;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

// TODO make sure this is the best way to create an objc singleton
+ (id)allocWithZone:(NSZone *)zone
{
    static RNSync *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedInstance = [super allocWithZone:zone]; });
    return sharedInstance;
}

/**
 * <p>Called when a state transition to COMPLETE or STOPPED is
 * completed.</p>
 *
 * <p>May be called from any worker thread.</p>
 *
 * <p>Continuous replications (when implemented) will never complete.</p>
 *
 * @param replicator the replicator issuing the event.
 */
- (void)replicatorDidComplete:(CDTReplicator *)replicator
{
    if(replicatorDidCompleteCallback)
    {
        replicatorDidCompleteCallback(@[[NSNull null]]);
    }
}

/**
 * <p>Called when a state transition to ERROR is completed.</p>
 *
 * <p>Errors may include things such as:</p>
 *
 * <ul>
 *      <li>incorrect credentials</li>
 *      <li>network connection unavailable</li>
 * </ul>
 *
 *
 * <p>May be called from any worker thread.</p>
 *
 * @param replicator the replicator issuing the event.
 * @param info information about the error that occurred.
 */
- (void)replicatorDidError:(CDTReplicator *)replicator info:(NSError *)error
{
    if(replicatorDidErrorCallback)
    {
        replicatorDidErrorCallback(@[[NSNumber numberWithLong:error.code]]);
    }
}

RCT_EXPORT_METHOD(init: (NSString *)databaseUrl callback:(RCTResponseSenderBlock)callback)
{
    // Create a CDTDatastoreManager using application internal storage path
    NSError *error = nil;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    
    NSURL *documentsDir = [[fileManager URLsForDirectory:NSDocumentDirectory
                                               inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [documentsDir URLByAppendingPathComponent:@"cloudant-sync-datastore"];
    NSString *path = [storeURL path];
    
    manager = [[CDTDatastoreManager alloc] initWithDirectory:path error:&error];
    
    if(error)
    {
        callback(@[[NSNumber numberWithLong:error.code]]);
        return;
    }
    
    datastore = [manager datastoreNamed:@"my_datastore" error:&error];
    
    if(error)
    {
        callback(@[[NSNumber numberWithLong:error.code]]);
        return;
    }
    
    replicatorFactory = [[CDTReplicatorFactory alloc] initWithDatastoreManager:manager];
    
    remoteDatabaseURL = [NSURL URLWithString:databaseUrl];
    
    callback(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(replicate: (RCTResponseSenderBlock)successCallback errorCallback: (RCTResponseSenderBlock)errrorCallback)
{
    replicatorDidCompleteCallback = successCallback;
    replicatorDidErrorCallback = errrorCallback;
    
    // Replicate from the local to remote database
    CDTPushReplication *pushReplication = [CDTPushReplication replicationWithSource:datastore
                                                                             target:remoteDatabaseURL];
    NSError *error;
    
    replicator = [replicatorFactory oneWay:pushReplication error:&error];
    replicator.delegate = self;
    
    [replicator startWithError: &error];
}

RCT_EXPORT_METHOD(create: body id:(NSString*)id callback:(RCTResponseSenderBlock)callback)
{
    NSError *error = nil;
    
    CDTDocumentRevision *rev;
    
    // Create a document
    if(id)
    {
        rev = [CDTDocumentRevision revisionWithDocId: id];
    }
    else{
        rev = [CDTDocumentRevision revision];
    }
    
    // Use [CDTDocumentRevision revision] to get an ID generated for you on saving
    //  rev.body = [@{
    //                @"description": @"Buy milk",
    //                @"completed": @NO,
    //                @"type": @"com.cloudant.sync.example.task"
    //                } mutableCopy];
    
    if(!body)
    {
        body = @{};
    }
    
    rev.body = body;
    
    // Save the document to the database
    CDTDocumentRevision *revision = [datastore createDocumentFromRevision:rev error:&error];
    
    if(!error)
    {
        NSDictionary *dict = @{ @"id" : revision.docId, @"rev" : revision.revId, @"body" : revision.body };
        
        NSArray *params = @[dict];
        callback(@[[NSNull null], params]);
    }
    else{
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
    
}

RCT_EXPORT_METHOD(addAttachment: id name:(NSString*)name path:(NSString*)path type:(NSString*)type callback:(RCTResponseSenderBlock)callback)
{
    NSError *error = nil;
    
    CDTDocumentRevision *revision = [datastore getDocumentWithId:id error:&error];
    
    if(error)
    {
        callback(@[[NSNumber numberWithLong:error.code]]);
        return;
    }
    
    // Add an attachment -- binary data like a JPEG
    CDTUnsavedFileAttachment *att = [[CDTUnsavedFileAttachment alloc]
                                     initWithPath:path   //@"/path/to/image.jpg"
                                     name:name           //@"cute_cat.jpg"
                                     type:type];           //@"image/jpeg"];
    
    revision.attachments[att.name] = att;
    
    CDTDocumentRevision *updated = [datastore updateDocumentFromRevision:revision error:&error];
    
    NSDictionary *dict = @{ @"id" : updated.docId, @"rev" : updated.revId, @"body" : updated.body };
    
    if(!error)
    {
        NSArray *params = @[dict];
        callback(@[[NSNull null], params]);
    }
    else{
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
}

RCT_EXPORT_METHOD(retrieve: (NSString *)id callback:(RCTResponseSenderBlock)callback)
{
    NSError *error = nil;
    
    // Read a document
    CDTDocumentRevision *revision = [datastore getDocumentWithId:id error:&error];
    
    if(!error)
    {
        NSDictionary *dict = @{ @"id" : revision.docId, @"rev" : revision.revId, @"body" : revision.body };
        
        NSArray *params = @[dict];
        callback(@[[NSNull null], params]);
    }
    else{
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
}

RCT_EXPORT_METHOD(update: (NSString *)id rev:(NSString *)rev  body:(NSDictionary *)body callback:(RCTResponseSenderBlock)callback)
{
    NSError *error = nil;
    
    // Read a document
    CDTDocumentRevision *retrieved = [datastore getDocumentWithId:id rev:rev error:&error];
    
    retrieved.body = (NSMutableDictionary*)body;
    
    CDTDocumentRevision *updated = [datastore updateDocumentFromRevision:retrieved
                                                                   error:&error];
    
    NSDictionary *dict = @{ @"id" : updated.docId, @"rev" : updated.revId, @"body" : updated.body };
    
    if(!error)
    {
        NSArray *params = @[dict];
        callback(@[[NSNull null], params]);
    }
    else{
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
}


RCT_EXPORT_METHOD(delete: (NSString *)id callback:(RCTResponseSenderBlock)callback)
{
    NSError *error = nil;
    
    CDTDocumentRevision *retrieved = [datastore getDocumentWithId:id error:&error];
    
    BOOL deleted = [datastore deleteDocumentFromRevision:retrieved
                                                   error:&error];
    if(!error)
    {
        NSArray *params = @[[NSNumber numberWithBool:deleted]];
        callback(@[[NSNull null], params]);
    }
    else{
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
}

// TODO this results of the query could be huge (run out of memory huge).  Need param for how many items
// to return and paging to get the rest
RCT_EXPORT_METHOD(find: (NSDictionary *)query callback:(RCTResponseSenderBlock)callback)
{
    // TODO waste to new up resultList for every call
    NSMutableArray* resultList = [[NSMutableArray alloc] init];
    
    CDTQResultSet *result = [datastore find:query];
    [result enumerateObjectsUsingBlock:^(CDTDocumentRevision *rev, NSUInteger idx, BOOL *stop)
     {
         NSDictionary *dict = @{ @"id" : rev.docId, @"rev" : rev.revId, @"body" : rev.body };
         
         [resultList addObject: dict];
     }];
    
    NSArray *params = @[resultList];
    callback(@[[NSNull null], params]);
}

@end