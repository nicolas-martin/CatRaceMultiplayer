//
//  MyScene.m
//  CatRaceStarter
//
//  Created by Kauserali on 30/12/13.
//  Copyright (c) 2013 Raywenderlich. All rights reserved.
//

#import "GameScene.h"
#import "PlayerSprite.h"

@implementation GameScene {
    NSMutableArray *_players;
    NSUInteger _currentPlayerIndex;
    SKSpriteNode *_cat;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        [self initializeGame];
    }
    return self;
}

- (void)initializeGame {
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"bg"];
    background.anchorPoint = CGPointMake(0, 0);
    [self addChild:background];
    
    _players = [NSMutableArray arrayWithCapacity:2];
    
    
    PlayerSprite *player1 = [[PlayerSprite alloc] initWithType:kPlayerSpriteDog];
    PlayerSprite *player2 = [[PlayerSprite alloc] initWithType:kPlayerSpriteKid];
    CGFloat maxWidth = MAX(player1.size.width, player2.size.width);
    CGFloat playersYOffset = 50;
    CGFloat playersXOffset = -(maxWidth - MIN(player1.size.width, player2.size.width));
    player1.position = CGPointMake(maxWidth - player1.size.width + player1.size.width/2 + playersXOffset, player1.size.height/2);
    player2.position = CGPointMake(maxWidth - player2.size.width + player2.size.width/2 + playersXOffset, player1.size.height/2 + playersYOffset);
    
    SKTextureAtlas *gameAtlas = [SKTextureAtlas atlasNamed:@"sprites"];
    _cat = [SKSpriteNode spriteNodeWithTexture:[gameAtlas textureNamed:@"cat_stand_1"]];
    _cat.position = CGPointMake(self.size.width - _cat.size.width/2, _cat.size.height/2 + 20);
    
    [_players addObject:player1];
    [_players addObject:player2];
    
    [self addChild:player2];
    [self addChild:_cat];
    [self addChild:player1];
    
    _currentPlayerIndex = -1;
}

-(void)update:(CFTimeInterval)currentTime {
    if (self.paused && _currentPlayerIndex == -1) {
        return;
    }
    //Only Player 1 will check for game over condition
    if (_currentPlayerIndex == 0) {
        [_players enumerateObjectsUsingBlock:^(PlayerSprite *playerSprite, NSUInteger idx, BOOL *stop) {
            if(playerSprite.position.x + playerSprite.size.width/2 > _cat.position.x) {
                BOOL didWin = NO;
                if (idx == _currentPlayerIndex) {
                    NSLog(@"Won");
                    didWin = YES;
                } else {
                    //you lost
                    NSLog(@"Lost");
                }
                self.paused = YES;
                _currentPlayerIndex = -1;
                *stop = YES;
                
                [_networkingEngine sendGameEnd:didWin];
                if (self.gameOverBlock) {
                    self.gameOverBlock(didWin);
                }
            }
        }];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_currentPlayerIndex == -1) {
        return;
    }
    [_players[_currentPlayerIndex] moveForward];
    [_networkingEngine sendMove];
}

#pragma mark MultiplayerNetworkingProtocol

- (void)matchEnded {
    if (self.gameEndedBlock) {
        self.gameEndedBlock();
    }
}

- (void)setCurrentPlayerIndex:(NSUInteger)index {
    _currentPlayerIndex = index;
}

- (void)movePlayerAtIndex:(NSUInteger)index {
    [_players[index] moveForward];
}

- (void)gameOver:(BOOL)player1Won {
    BOOL didLocalPlayerWin = YES;
    if (player1Won) {
        didLocalPlayerWin = NO;
    }
    if (self.gameOverBlock) {
        self.gameOverBlock(didLocalPlayerWin);
    }
}

- (void)setPlayerAliases:(NSArray*)playerAliases {
    [playerAliases enumerateObjectsUsingBlock:^(NSString *playerAlias, NSUInteger idx, BOOL *stop) {
        [_players[idx] setPlayerAliasText:playerAlias];
    }];
}
@end
