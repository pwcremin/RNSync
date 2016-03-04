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
    NSError *outError = nil;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    
    NSURL *documentsDir = [[fileManager URLsForDirectory:NSDocumentDirectory
                                               inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [documentsDir URLByAppendingPathComponent:@"cloudant-sync-datastore"];
    NSString *path = [storeURL path];
    
    manager = [[CDTDatastoreManager alloc] initWithDirectory:path
                                                       error:&outError];
    
    datastore = [manager datastoreNamed:@"my_datastore"
                                  error:&outError];
    
    // Create and start the replicator -- -start is essential!
    CDTReplicatorFactory *replicatorFactory =
    [[CDTReplicatorFactory alloc] initWithDatastoreManager:manager];
    
    //NSString *s = @"https://apikey:apipassword@username.cloudant.com/my_database";
    //NSString *s = @"https://ce589353-511f-447e-921b-6235fec33ae9-bluemix:2d076e2e5760e09a9ca64e9b1f42341cc336457fb926dff83436a61041e8a25e@ce589353-511f-447e-921b-6235fec33ae9-bluemix.cloudant.com/users";
    
    NSURL *remoteDatabaseURL = [NSURL URLWithString:databaseUrl];
    //  CDTDatastore *datastore = [manager datastoreNamed:@"my_datastore"];
    
    // Replicate from the local to remote database
    CDTPushReplication *pushReplication = [CDTPushReplication replicationWithSource:datastore
                                                                             target:remoteDatabaseURL];
    NSError *error;
    replicator = [replicatorFactory oneWay:pushReplication error:&error];
    
    replicator.delegate = self;
    
    if(error)
    {
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
    else
    {
        callback(@[[NSNull null]]);
    }
    
}

RCT_EXPORT_METHOD(replicate: (RCTResponseSenderBlock)successCallback errorCallback: (RCTResponseSenderBlock)errrorCallback)
{
    replicatorDidCompleteCallback = successCallback;
    replicatorDidErrorCallback = errrorCallback;
    
    NSError *error;
    
    [replicator startWithError: &error];
}

RCT_EXPORT_METHOD(setReplicatorDidCompleteCallback: (RCTResponseSenderBlock)callback)
{
    replicatorDidCompleteCallback = callback;
}

RCT_EXPORT_METHOD(setReplicatorDidErrorCallback: (RCTResponseSenderBlock)callback)
{
    replicatorDidErrorCallback = callback;
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
    
    // Add an attachment -- binary data like a JPEG
    //CDTUnsavedFileAttachment *att = [[CDTUnsavedFileAttachment alloc]
    //                                  initWithPath:@"/path/to/image.jpg"
    //                                  name:@"cute_cat.jpg"
    //                                 type:@"image/jpeg"];
    // rev.attachments[att.name] = att;
    
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


@end