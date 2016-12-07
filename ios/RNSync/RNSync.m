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
#import "ReplicationManager.h";
#import "CloudantSync.h"


@implementation RNSync
{
    CDTDatastore *datastore;
    CDTDatastoreManager *manager;
    CDTReplicator *replicator;
    CDTReplicatorFactory *replicatorFactory;
    NSURL *remoteDatabaseURL;
    RCTResponseSenderBlock replicatorDidCompleteCallback;
    RCTResponseSenderBlock replicatorDidErrorCallback;
    ReplicationManager* replicationManager;
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

// TODO need to let them name their own datastore! else could conflict with other apps?
RCT_EXPORT_METHOD(init: (NSString *)databaseUrl callback:(RCTResponseSenderBlock)callback)
{
    // Create a CDTDatastoreManager using application internal storage path
    NSError *error = nil;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    
    NSURL *documentsDir = [[fileManager URLsForDirectory:NSDocumentDirectory
                                               inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [documentsDir URLByAppendingPathComponent:@"datastores"];
    NSString *path = [storeURL path];
    
    manager = [[CDTDatastoreManager alloc] initWithDirectory:path error:&error];
    
    if(error)
    {
        callback(@[[NSNumber numberWithLong:error.code]]);
        return;
    }
    
    // TODO datastore name needs to be configurable
    datastore = [manager datastoreNamed:@"rnsync_datastore" error:&error];
    
    if(error)
    {
        callback(@[[NSNumber numberWithLong:error.code]]);
        return;
    }
    
    replicatorFactory = [[CDTReplicatorFactory alloc] initWithDatastoreManager:manager];
    
    remoteDatabaseURL = [NSURL URLWithString:databaseUrl];
    
    replicationManager = [[ReplicationManager alloc] initWithData:remoteDatabaseURL datastore:datastore replicatorFactory:replicatorFactory];
    
    callback(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(replicatePush: (RCTResponseSenderBlock)callback)
{
    [replicationManager push: callback];
}

RCT_EXPORT_METHOD(replicatePull: (RCTResponseSenderBlock)callback)
{
    [replicationManager pull: callback];
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
    
    
    if(!body)
    {
        body = @{};
    }
    
    rev.body = body;
    
    // Save the document to the database
    // revision is nil on failure
    CDTDocumentRevision *revision = [datastore createDocumentFromRevision:rev error:&error];
    if(!revision)
    {
        callback(@[@"document failed to save"]);
    }
    else if(!error)
    {
        NSDictionary *dict = @{ @"id" : revision.docId, @"rev" : revision.revId, @"body" : revision.body };
        
        //NSArray *params = @[dict];
        callback(@[[NSNull null], dict]);
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
                                     type:type];         //@"image/jpeg"];
    
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
        
        //NSArray *params = @[dict];
        callback(@[[NSNull null], dict]);
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
        //NSArray *params = @[dict];
        callback(@[[NSNull null], dict]);
    }
    else{
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
}


RCT_EXPORT_METHOD(delete: (NSString *)id callback:(RCTResponseSenderBlock)callback)
{
    if(!id)
    {
        //NSArray *params = @[[NSNumber numberWithBool:deleted]];
        callback(@[@"called delete without specifying the id"]);
        return;
    }
    
    NSError *error = nil;
    
    CDTDocumentRevision *retrieved = [datastore getDocumentWithId:id error:&error];
    
    [datastore deleteDocumentFromRevision:retrieved
                                    error:&error];
    if(!error)
    {
        //NSArray *params = @[[NSNumber numberWithBool:deleted]];
        callback(@[[NSNull null]]);
    }
    else{
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
}

RCT_EXPORT_METHOD(deleteDatastore: (RCTResponseSenderBlock)callback)
{
    NSError *error = nil;
    
    BOOL deleted = [manager deleteDatastoreNamed:@"rnsync_datastore" error: &error];
    
    if(!error)
    {
        //NSArray *params = @[[NSNumber numberWithBool:deleted]];
        callback(@[[NSNull null], [NSNumber numberWithBool:deleted]]);
    }
    else{
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
}


// TODO the results of the query could be huge (run out of memory huge).  Need param for how many items
// to return and paging to get the rest
RCT_EXPORT_METHOD(find: (NSDictionary *)query fields:(NSArray *)fields callback:(RCTResponseSenderBlock)callback)
{
    // TODO waste to new up resultList for every call
    NSMutableArray* resultList = [[NSMutableArray alloc] init];
    
    CDTQResultSet *result = [datastore find:query
                                       skip:0
                                      limit:0
                                     fields:fields
                                       sort:nil];
    
    [result enumerateObjectsUsingBlock:^(CDTDocumentRevision *rev, NSUInteger idx, BOOL *stop)
     {
         NSDictionary *dict = @{ @"id" : rev.docId, @"rev" : rev.revId, @"body" : rev.body };
         
         [resultList addObject: dict];
     }];
    
    //NSArray *params = @[resultList];
    callback(@[[NSNull null], resultList]);
}

@end
