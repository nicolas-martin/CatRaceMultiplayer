//
//  MyScene.h
//  CatRaceStarter
//

//  Copyright (c) 2013 Raywenderlich. All rights reserved.
//

#import "MultiplayerNetworking.h"

@interface GameScene : SKScene <MultiplayerNetworkingProtocol>
@property (nonatomic, copy) void (^gameOverBlock)(BOOL didWin);
@property (nonatomic, copy) void (^gameEndedBlock)();
@property (nonatomic, strong) MultiplayerNetworking *networkingEngine;
@end
