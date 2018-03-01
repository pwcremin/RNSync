//
//  ReactSync.m
//  reactCloudantSync
//
//  Created by Patrick cremin on 2/17/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RNSync.h"
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import "ReplicationManager.h"
#import "CloudantSync.h"
#import "RNSyncDataStore.h"

@implementation RNSync
{
    //CDTDatastore *datastore;
    CDTDatastoreManager *manager;
    //CDTReplicator *replicator;
    //CDTReplicatorFactory *replicatorFactory;
    //NSURL *remoteDatabaseURL;
    //RCTResponseSenderBlock replicatorDidCompleteCallback;
    //RCTResponseSenderBlock replicatorDidErrorCallback;
    //ReplicationManager* replicationManager;
    NSMutableDictionary *datastores;
    NSString *databaseUrl;
}

//@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

+ (id)allocWithZone:(NSZone *)zone
{
    static RNSync *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedInstance = [super allocWithZone:zone]; });
    return sharedInstance;
}

RCT_EXPORT_METHOD(init: (NSString *)databaseUrl databaseName:(NSString *)databaseName callback:(RCTResponseSenderBlock)callback)
{
    self->databaseUrl = databaseUrl;
    
    // Create a CDTDatastoreManager using application internal storage path
    NSError *error = nil;
    NSFileManager *fileManager= [NSFileManager defaultManager];

    NSURL *documentsDir = [[fileManager URLsForDirectory:NSDocumentDirectory
                                               inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [documentsDir URLByAppendingPathComponent:@"datastores"];
    NSString *path = [storeURL path];

    if(!manager)
    {
        manager = [[CDTDatastoreManager alloc] initWithDirectory:path error:&error];
        
        if(error)
        {
            callback(@[[NSNumber numberWithLong:error.code]]);
            return;
        }
    }
    
    if(!datastores)
    {
        datastores = [NSMutableDictionary new];
    }
    
    RNSyncDataStore *datastore = [[RNSyncDataStore alloc] initWithData:databaseName manager:manager databaseUrl:databaseUrl error:&error];
    
    if(error)
    {
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
    else {
        datastores[databaseName] = datastore;
        callback(@[[NSNull null]]);
    }
}

//RCT_EXPORT_METHOD(createStore: (NSString *)storeName callback:(RCTResponseSenderBlock)callback)
//{
//    NSError *error = nil;
//
//    RNSyncDataStore *datastore = [[RNSyncDataStore alloc] initWithData:storeName manager:manager databaseUrl:databaseUrl error:&error];
//
//    if(error)
//    {
//        callback(@[[NSNumber numberWithLong:error.code]]);
//    }
//    else
//    {
//        [datastores setObject:datastore forKey:storeName];
//        callback(@[[NSNull null]]);
//    }
//}


RCT_EXPORT_METHOD(replicatePush: (NSString *)storeName callback: (RCTResponseSenderBlock)callback)
{
    RNSyncDataStore *rnsyncStore = datastores[storeName];
    
    [rnsyncStore.replicationManager push: callback];
}

RCT_EXPORT_METHOD(replicatePull: (NSString *)storeName callback: (RCTResponseSenderBlock)callback)
{
    RNSyncDataStore *rnsyncStore = datastores[storeName];
    
    [rnsyncStore.replicationManager pull: callback];
}

RCT_EXPORT_METHOD(create: (NSString *)storeName body:(NSDictionary *)body id:(NSString*)id callback:(RCTResponseSenderBlock)callback)
{
    RNSyncDataStore *rnsyncStore = datastores[storeName];
    
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
        body =  @{};
    }
    
    rev.body = [body mutableCopy];
    
    // Save the document to the database
    // revision is nil on failure
    CDTDocumentRevision *revision = [rnsyncStore.datastore createDocumentFromRevision:rev error:&error];
    
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

RCT_EXPORT_METHOD(addAttachment: (NSString *)storeName id:(NSString *)id name:(NSString*)name path:(NSString*)path type:(NSString*)type callback:(RCTResponseSenderBlock)callback)
{
    RNSyncDataStore *rnsyncStore = datastores[storeName];
    
    NSError *error = nil;
    
    CDTDocumentRevision *revision = [rnsyncStore.datastore getDocumentWithId:id error:&error];
    
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
    
    CDTDocumentRevision *updated = [rnsyncStore.datastore updateDocumentFromRevision:revision error:&error];
    
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

RCT_EXPORT_METHOD(retrieve: (NSString *)storeName id:(NSString *)id callback:(RCTResponseSenderBlock)callback)
{
    RNSyncDataStore *rnsyncStore = datastores[storeName];
    
    NSError *error = nil;
    
    // Read a document
    CDTDocumentRevision *revision = [rnsyncStore.datastore getDocumentWithId:id error:&error];
    
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

RCT_EXPORT_METHOD(update: (NSString *)storeName id:(NSString *)id rev:(NSString *)rev  body:(NSDictionary *)body callback:(RCTResponseSenderBlock)callback)
{
    RNSyncDataStore *rnsyncStore = datastores[storeName];
    
    NSError *error = nil;
    
    // Read a document
    CDTDocumentRevision *retrieved = [rnsyncStore.datastore getDocumentWithId:id rev:rev error:&error];
    
    retrieved.body = (NSMutableDictionary*)body;
    
    CDTDocumentRevision *updated = [rnsyncStore.datastore updateDocumentFromRevision:retrieved
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


RCT_EXPORT_METHOD(delete: (NSString *)storeName id:(NSString *)id callback:(RCTResponseSenderBlock)callback)
{
    if(!id)
    {
        //NSArray *params = @[[NSNumber numberWithBool:deleted]];
        callback(@[@"called delete without specifying the id"]);
        return;
    }
    
    RNSyncDataStore *rnsyncStore = datastores[storeName];
    
    NSError *error = nil;
    
    CDTDocumentRevision *retrieved = [rnsyncStore.datastore getDocumentWithId:id error:&error];
    
    [rnsyncStore.datastore deleteDocumentFromRevision:retrieved
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

RCT_EXPORT_METHOD(deleteDatastore: (NSString *)storeName callback:(RCTResponseSenderBlock)callback)
{
    // TODO remove from stores[]
    NSError *error = nil;
    
    BOOL deleted = [manager deleteDatastoreNamed:storeName error: &error];
    
    if(!error)
    {
        if(deleted)
        {
            [datastores removeObjectForKey:storeName];
        }
        
        //NSArray *params = @[[NSNumber numberWithBool:deleted]];
        callback(@[[NSNull null], [NSNumber numberWithBool:deleted]]);
    }
    else{
        callback(@[[NSNumber numberWithLong:error.code]]);
    }
}


// TODO the results of the query could be huge (run out of memory huge).  Need param for how many items
// to return and paging to get the rest
RCT_EXPORT_METHOD(find: (NSString *)storeName query:(NSDictionary *)query fields:(NSArray *)fields callback:(RCTResponseSenderBlock)callback)
{
    RNSyncDataStore *rnsyncStore = datastores[storeName];
    
    // TODO waste to new up resultList for every call
    NSMutableArray* resultList = [[NSMutableArray alloc] init];
    
    CDTQResultSet *result = [rnsyncStore.datastore find:query
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
