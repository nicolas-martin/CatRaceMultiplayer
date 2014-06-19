//
//  MultiplayerNetworking.m
//  CatRaceStarter
//
//  Created by Kauserali on 06/01/14.
//  Copyright (c) 2014 Raywenderlich. All rights reserved.
//

#import "MultiplayerNetworking.h"

#define playerIdKey @"PlayerId"
#define randomNumberKey @"randomNumber"

typedef NS_ENUM(NSUInteger, GameState) {
    kGameStateWaitingForMatch = 0,
    kGameStateWaitingForRandomNumber,
    kGameStateWaitingForStart,
    kGameStateActive,
    kGameStateDone
};

typedef NS_ENUM(NSUInteger, MessageType) {
    kMessageTypeRandomNumber = 0,
    kMessageTypeGameBegin,
    kMessageTypeMove,
    kMessageTypeGameOver
};

typedef struct {
    MessageType messageType;
} Message;

typedef struct {
    Message message;
    uint32_t randomNumber;
} MessageRandomNumber;

typedef struct {
    Message message;
} MessageGameBegin;

typedef struct {
    Message message;
} MessageMove;

typedef struct {
    Message message;
    BOOL player1Won;
} MessageGameOver;

@implementation MultiplayerNetworking {
    uint32_t _ourRandomNumber;
    GameState _gameState;
    BOOL _isPlayer1, _receivedAllRandomNumbers;
    
    NSMutableArray *_orderOfPlayers;
}

- (id)init
{
    if (self = [super init]) {
        _ourRandomNumber = arc4random();
        _gameState = kGameStateWaitingForMatch;
        _orderOfPlayers = [NSMutableArray array];
        [_orderOfPlayers addObject:@{playerIdKey : [GKLocalPlayer localPlayer].playerID,
                                     randomNumberKey : @(_ourRandomNumber)}];
    }
    return self;
}

- (void)sendData:(NSData*)data
{
    NSError *error;
    GameKitHelper *gameKitHelper = [GameKitHelper sharedGameKitHelper];
    
    BOOL success = [gameKitHelper.match
                    sendDataToAllPlayers:data
                    withDataMode:GKMatchSendDataReliable
                    error:&error];
    
    if (!success) {
        NSLog(@"Error sending data:%@", error.localizedDescription);
        [self matchEnded];
    }
}

- (void)sendMove {
    MessageMove messageMove;
    messageMove.message.messageType = kMessageTypeMove;
    NSData *data = [NSData dataWithBytes:&messageMove
                                  length:sizeof(MessageMove)];
    [self sendData:data];
}

- (void)sendRandomNumber
{
    MessageRandomNumber message;
    message.message.messageType = kMessageTypeRandomNumber;
    message.randomNumber = _ourRandomNumber;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageRandomNumber)];
    [self sendData:data];
}

- (void)sendGameBegin {
    
    MessageGameBegin message;
    message.message.messageType = kMessageTypeGameBegin;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageGameBegin)];
    [self sendData:data];
    
}

- (void)sendGameEnd:(BOOL)player1Won {
    MessageGameOver message;
    message.message.messageType = kMessageTypeGameOver;
    message.player1Won = player1Won;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageGameOver)];
    [self sendData:data];
}

- (NSUInteger)indexForLocalPlayer
{
    NSString *playerId = [GKLocalPlayer localPlayer].playerID;
    
    return [self indexForPlayerWithId:playerId];
}

- (NSUInteger)indexForPlayerWithId:(NSString*)playerId
{
    __block NSUInteger index = -1;
    [_orderOfPlayers enumerateObjectsUsingBlock:^(NSDictionary
                                                  *obj, NSUInteger idx, BOOL *stop){
        NSString *pId = obj[playerIdKey];
        if ([pId isEqualToString:playerId]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (void)tryStartGame
{
    if (_isPlayer1 && _gameState == kGameStateWaitingForStart) {
        _gameState = kGameStateActive;
        [self sendGameBegin];
        
        //first player
        [self.delegate setCurrentPlayerIndex:0];
        [self processPlayerAliases];
    }
}

- (BOOL)allRandomNumbersAreReceived
{
    NSMutableArray *receivedRandomNumbers =
    [NSMutableArray array];
    
    for (NSDictionary *dict in _orderOfPlayers) {
        [receivedRandomNumbers addObject:dict[randomNumberKey]];
    }
    
    NSArray *arrayOfUniqueRandomNumbers = [[NSSet setWithArray:receivedRandomNumbers] allObjects];
    
    if (arrayOfUniqueRandomNumbers.count ==
        [GameKitHelper sharedGameKitHelper].match.playerIDs.count + 1) {
        return YES;
    }
    return NO;
}

-(void)processReceivedRandomNumber:(NSDictionary*)randomNumberDetails {
    //1
    if([_orderOfPlayers containsObject:randomNumberDetails]) {
        [_orderOfPlayers removeObjectAtIndex:
         [_orderOfPlayers indexOfObject:randomNumberDetails]];
    }
    //2
    [_orderOfPlayers addObject:randomNumberDetails];
    
    //3
    NSSortDescriptor *sortByRandomNumber =
    [NSSortDescriptor sortDescriptorWithKey:randomNumberKey
                                  ascending:NO];
    NSArray *sortDescriptors = @[sortByRandomNumber];
    [_orderOfPlayers sortUsingDescriptors:sortDescriptors];
    
    //4
    if ([self allRandomNumbersAreReceived]) {
        _receivedAllRandomNumbers = YES;
    }
}

- (void)processPlayerAliases {
    if ([self allRandomNumbersAreReceived]) {
        NSMutableArray *playerAliases = [NSMutableArray arrayWithCapacity:_orderOfPlayers.count];
        for (NSDictionary *playerDetails in _orderOfPlayers) {
            NSString *playerId = playerDetails[playerIdKey];
            [playerAliases addObject:((GKPlayer*)[GameKitHelper sharedGameKitHelper].playersDict[playerId]).alias];
        }
        if (playerAliases.count > 0) {
            [self.delegate setPlayerAliases:playerAliases];
        }
    }
}

- (BOOL)isLocalPlayerPlayer1
{
    NSDictionary *dictionary = _orderOfPlayers[0];
    if ([dictionary[playerIdKey]
         isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
        NSLog(@"I'm player 1");
        return YES;
    }
    return NO;
}

#pragma mark GameKitHelper delegate methods

- (void)matchStarted {
    NSLog(@"Match has started successfully");
    if (_receivedAllRandomNumbers) {
        _gameState = kGameStateWaitingForStart;
    } else {
        _gameState = kGameStateWaitingForRandomNumber;
    }
    [self sendRandomNumber];
    [self tryStartGame];
}

- (void)matchEnded {
    NSLog(@"Match has ended");
    [_delegate matchEnded];
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data
   fromPlayer:(NSString *)playerID {
    //1
    Message *message = (Message*)[data bytes];
    if (message->messageType == kMessageTypeRandomNumber) {
        MessageRandomNumber *messageRandomNumber = (MessageRandomNumber*)[data bytes];
        
        NSLog(@"Received random number:%d", messageRandomNumber->randomNumber);
        
        BOOL tie = NO;
        if (messageRandomNumber->randomNumber == _ourRandomNumber) {
            //2
            NSLog(@"Tie");
            tie = YES;
            _ourRandomNumber = arc4random();
            [self sendRandomNumber];
        } else {
            //3
            NSDictionary *dictionary = @{playerIdKey : playerID,
                                         randomNumberKey : @(messageRandomNumber->randomNumber)};
            [self processReceivedRandomNumber:dictionary];
        }
        
        //4
        if (_receivedAllRandomNumbers) {
            _isPlayer1 = [self isLocalPlayerPlayer1];
        }
        
        if (!tie && _receivedAllRandomNumbers) {
            //5
            if (_gameState == kGameStateWaitingForRandomNumber) {
                _gameState = kGameStateWaitingForStart;
            }
            [self tryStartGame];
        }
    } else if (message->messageType == kMessageTypeGameBegin) {
        NSLog(@"Begin game message received");
        _gameState = kGameStateActive;
        [self.delegate setCurrentPlayerIndex:[self indexForLocalPlayer]];
        [self processPlayerAliases];
    } else if (message->messageType == kMessageTypeMove) {
        NSLog(@"Move message received");
        MessageMove *messageMove = (MessageMove*)[data bytes];
        [self.delegate movePlayerAtIndex:[self indexForPlayerWithId:playerID]];
    } else if(message->messageType == kMessageTypeGameOver) {
        NSLog(@"Game over message received");
        MessageGameOver * messageGameOver = (MessageGameOver *) [data bytes];
        [self.delegate gameOver:messageGameOver->player1Won];
    }
}
@end
