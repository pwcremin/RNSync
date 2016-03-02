//
//  ReactSync.h
//  reactCloudantSync
//
//  Created by Patrick cremin on 2/17/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RCTBridgeModule.h"
#import <CloudantSync.h>

@interface RNSync : NSObject <RCTBridgeModule, CDTReplicatorDelegate>
@end