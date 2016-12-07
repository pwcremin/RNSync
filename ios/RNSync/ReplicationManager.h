//
//  Replicator.h
//  Pods
//
//  Created by Patrick cremin on 12/4/16.
//
//

#ifndef ReplicationManager_h
#define ReplicationManager_h

#import "CloudantSync.h"
#import "RCTEventDispatcher.h"

@class Replicator;

@interface ReplicationManager : NSObject
-(id)initWithData:(NSURL *)remoteDatabaseURL datastore:(CDTDatastore *)datastore replicatorFactory:(CDTReplicatorFactory *)replicatorFactory;
- (void)pull: (RCTResponseSenderBlock)callback;
- (void)push: (RCTResponseSenderBlock)callback;
-(void)done:(Replicator *)replicator;
@end



#endif /* ReplicationManager_h */
