//
//  ViewController.m
//  CatRaceStarter
//
//  Created by Kauserali on 30/12/13.
//  Copyright (c) 2013 Raywenderlich. All rights reserved.
//

#import "GameViewController.h"
#import "GameOverViewController.h"
#import "GameScene.h"
#import "GameKitHelper.h"
#import "MultiplayerNetworking.h"

@implementation GameViewController {
    MultiplayerNetworking *_networkingEngine;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerAuthenticated) name:LocalPlayerIsAuthenticated object:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    // Create and configure the scene.
    GameScene * scene = [GameScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    scene.gameEndedBlock = ^() {

    };
    
    scene.gameOverBlock = ^(BOOL didWin) {
        GameOverViewController *gameOverViewController = (GameOverViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"GameOverViewController"];
        gameOverViewController.didWin = didWin;
        [self.navigationController pushViewController:gameOverViewController animated:YES];
    };
    // Present the scene.
    [skView presentScene:scene];
}

- (void)playerAuthenticated {
    
    SKView *skView = (SKView*)self.view;
    GameScene *scene = (GameScene*)skView.scene;
    
    _networkingEngine = [[MultiplayerNetworking alloc] init];
    _networkingEngine.delegate = scene;
    scene.networkingEngine = _networkingEngine;
    
    [[GameKitHelper sharedGameKitHelper] findMatchWithMinPlayers:2 maxPlayers:2 viewController:self delegate:_networkingEngine];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
