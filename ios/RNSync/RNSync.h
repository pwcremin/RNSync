//
//  RNSync.h
//  RNSync
//
//  Created by Patrick cremin on 11/8/16.
//  Copyright © 2016 Patrick cremin. All rights reserved.
//

#import "RCTBridgeModule.h"
#import "CloudantSync.h"

@interface RNSync : NSObject <RCTBridgeModule, CDTReplicatorDelegate>
@end
