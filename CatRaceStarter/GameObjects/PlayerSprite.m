//
//  PlayerSprite.m
//  CatRaceStarter
//
//  Created by Kauserali on 30/12/13.
//  Copyright (c) 2013 Raywenderlich. All rights reserved.
//

#import "PlayerSprite.h"

#define kMoveAnimationKey @"move_animation"
#define kMoveActionKey @"translate_action"
#define kPlayerAliasLabelName @"player_alias"

@implementation PlayerSprite {
    BOOL _isMoving;
    CGPoint _moveTarget;
}

- (instancetype)initWithType:(enum PlayerSpriteType)playerType {
    
    SKTextureAtlas *gameAtlas = [SKTextureAtlas atlasNamed:@"sprites"];
    
    NSString *textureName = @"dog_1";
    NSMutableArray *textureFrames = @[@"dog_1", @"dog_2", @"dog_3", @"dog_4"].mutableCopy;
    
    if(playerType == kPlayerSpriteKid) {
        textureName = @"kid_on_trike_1";
        textureFrames = @[@"kid_on_trike_1", @"kid_on_trike_2", @"kid_on_trike_3", @"kid_on_trike_4"].mutableCopy;
    }
    
    self = [super initWithTexture:[gameAtlas textureNamed:textureName]];
    if (self) {
        _playerType = playerType;
        
        NSMutableArray *textures = [NSMutableArray arrayWithCapacity:textureFrames.count];
        
        for (NSString *textureName in textureFrames) {
            SKTexture *texture = [gameAtlas textureNamed:textureName];
            [textures addObject:texture];
        }
        
        SKLabelNode *playerAlias = [[SKLabelNode alloc] initWithFontNamed:@"Arial"];
        playerAlias.fontSize = 20;
        playerAlias.fontColor = [SKColor redColor];
        playerAlias.position = CGPointMake(0, 40);
        playerAlias.name = kPlayerAliasLabelName;
        [self addChild:playerAlias];
        _moveAnimation = [SKAction repeatActionForever:[SKAction animateWithTextures:textures timePerFrame:0.1]];
    }
    return self;
}

- (void)moveForward {
    
    // Start animating the player if he isn't already
    if (!_isMoving) {
        _isMoving = YES;
        [self runAction:_moveAnimation withKey:kMoveAnimationKey];
    }
    
    // Stop old move action
    [self removeActionForKey:kMoveActionKey];
    
    // Set new position to move too and create new sequence
    SKAction *moveToAction = [SKAction moveTo:CGPointMake(self.position.x + 40, self.position.y) duration:1];
    SKAction *moveToComplete = [SKAction performSelector:@selector(moveDone) onTarget:self];
    SKAction *sequence = [SKAction sequence:@[moveToAction, moveToComplete]];

    // Run new move sequence
    [self runAction:sequence withKey:kMoveActionKey];
}

- (void)moveDone {
    _isMoving = NO;
    [self removeActionForKey:kMoveAnimationKey];
}

- (void)setPlayerAliasText:(NSString*)playerAlias; {
    SKLabelNode *playerAliasLabel = (SKLabelNode*)[self childNodeWithName:kPlayerAliasLabelName];
    playerAliasLabel.text = playerAlias;
}
@end
