#import "RNMailCore.h"
#import <MailCore/MailCore.h>
#import <React/RCTConvert.h>
#import <Photos/Photos.h>

@implementation RNMailCore

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()


RCT_EXPORT_METHOD(sendMail:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
    smtpSession.hostname = [RCTConvert NSString:obj[@"hostname"]];
    smtpSession.port = [RCTConvert NSUInteger:obj[@"port"]];
    smtpSession.username = [RCTConvert NSString:obj[@"username"]];
    smtpSession.password = [RCTConvert NSString:obj[@"password"]];
    smtpSession.authType = MCOAuthTypeSASLPlain;
    smtpSession.connectionType = MCOConnectionTypeTLS;
    
    MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
    NSDictionary* fromObj = [RCTConvert NSDictionary:obj[@"from"]];
    MCOAddress *from = [MCOAddress addressWithDisplayName:[RCTConvert NSString:fromObj[@"addressWithDisplayName"]]
                                                  mailbox:[RCTConvert NSString:fromObj[@"mailbox"]]];
    
    NSDictionary* toObj = [RCTConvert NSDictionary:obj[@"to"]];
    MCOAddress *to = [MCOAddress addressWithDisplayName:[RCTConvert NSString:toObj[@"addressWithDisplayName"]]
                                                mailbox:[RCTConvert NSString:toObj[@"mailbox"]]];
    [[builder header] setFrom:from];
    [[builder header] setTo:@[to]];
    [[builder header] setSubject:[RCTConvert NSString:obj[@"subject"]]];
    [builder setTextBody:[RCTConvert NSString:obj[@"textBody"]]];
    NSString *uri = [RCTConvert NSString:obj[@"attachmentUri"]];
    
    if (uri) {
        NSString *const localIdentifier = [uri substringFromIndex:@"ph://".length];
        NSLog(@"IMG localIdentifier: %@",localIdentifier);
        PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];

        PHImageManager *imageManager = [PHImageManager new];

        for (PHAsset *asset in assets) {
            [imageManager requestImageDataForAsset:asset
                                           options:0
                                     resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                         MCOAttachment *att = [MCOAttachment attachmentWithData:imageData filename:[RCTConvert NSString:obj[@"filename"]]];
                                         [builder addAttachment:att];

                                         NSData * rfc822Data = [builder data];

                                         MCOSMTPSendOperation *sendOperation =
                                         [smtpSession sendOperationWithData:rfc822Data];
                                         [sendOperation start:^(NSError *error) {
                                             if(error) {
                                                 NSLog(@"Error sending email: %@", error);
                                                 reject(@"Error", error.localizedDescription, error);
                                             } else {
                                                 NSLog(@"Successfully sent email!");
                                                 NSDictionary *result = @{@"status": @"SUCCESS"};
                                                 resolve(result);
                                             }
                                         }];
                                     }];
        }
    } else {
        NSData * rfc822Data = [builder data];

        MCOSMTPSendOperation *sendOperation =
        [smtpSession sendOperationWithData:rfc822Data];
        [sendOperation start:^(NSError *error) {
            if(error) {
                NSLog(@"Error sending email: %@", error);
                reject(@"Error", error.localizedDescription, error);
            } else {
                NSLog(@"Successfully sent email!");
                NSDictionary *result = @{@"status": @"SUCCESS"};
                resolve(result);
            }
        }];
    }
}

RCT_EXPORT_METHOD(saveImap:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    MCOIMAPSession *session = [[MCOIMAPSession alloc] init];

    @try {
        session.hostname = [RCTConvert NSString:obj[@"hostname"]];
        session.port = [RCTConvert NSUInteger:obj[@"port"]];
        session.username = [RCTConvert NSString:obj[@"username"]];
        session.password = [RCTConvert NSString:obj[@"password"]];
        session.authType = MCOAuthTypeSASLPlain;
        session.connectionType = MCOConnectionTypeTLS;

        MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
        NSDictionary* fromObj = [RCTConvert NSDictionary:obj[@"from"]];
        MCOAddress *from = [MCOAddress addressWithDisplayName:[RCTConvert NSString:fromObj[@"addressWithDisplayName"]]
                                                      mailbox:[RCTConvert NSString:fromObj[@"mailbox"]]];

        NSDictionary* toObj = [RCTConvert NSDictionary:obj[@"to"]];
        MCOAddress *to = [MCOAddress addressWithDisplayName:[RCTConvert NSString:toObj[@"addressWithDisplayName"]]
                                                    mailbox:[RCTConvert NSString:toObj[@"mailbox"]]];
        [[builder header] setFrom:from];
        [[builder header] setTo:@[to]];
        [[builder header] setSubject:[RCTConvert NSString:obj[@"subject"]]];
        [builder setTextBody:[RCTConvert NSString:obj[@"textBody"]]];
        NSString *uri = [RCTConvert NSString:obj[@"attachmentUri"]];
        NSString *audiofile = [RCTConvert NSString:obj[@"audiofile"]];
        NSString *folder = [RCTConvert NSString:obj[@"folder"]];

        if (uri) {
            NSString *const localIdentifier = [uri substringFromIndex:@"ph://".length];
            NSLog(@"IMG localIdentifier: %@",localIdentifier);
            PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
            
            PHImageManager *imageManager = [PHImageManager new];
            
            for (PHAsset *asset in assets) {
                [imageManager requestImageDataForAsset:asset
                                               options:0
                                         resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                             MCOAttachment *att = [MCOAttachment attachmentWithData:imageData filename:[RCTConvert NSString:obj[@"filename"]]];
                                             [builder addAttachment:att];
                                             
                                             NSData * rfc822Data = [builder data];
                                             
                                             MCOIMAPAppendMessageOperation *appendOp =
                                             [session appendMessageOperationWithFolder:folder messageData:rfc822Data flags:MCOMessageFlagNone];
                                             
                                             [appendOp start:^(NSError * _Nullable error, uint32_t createdUID) {
                                                 if (error) {
                                                     NSLog(@"ERROR appendOp: %@", error);
                                                 } else {
                                                     resolve(@"SUCCESS");
                                                 }
                                                 NSLog(@"stored IMAP message: %u", createdUID);
                                             }];
                                         }];
            }
        } else if (audiofile) {
            NSArray *docDirArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *docDir = [[docDirArr objectAtIndex:0] stringByAppendingString:@"/audio/"];
            NSString *audioFilePath = [docDir stringByAppendingString:audiofile];
            MCOAttachment *att = [MCOAttachment attachmentWithContentsOfFile:audioFilePath];
            [att setMimeType:@"audio/m4a"];
            [builder addAttachment:att];
            NSData * rfc822Data = [builder data];
            
            MCOIMAPAppendMessageOperation *appendOp =
            [session appendMessageOperationWithFolder:folder messageData:rfc822Data flags:MCOMessageFlagNone];
            
            [appendOp start:^(NSError * _Nullable error, uint32_t createdUID) {
                if (error) {
                    NSLog(@"ERROR appendOp: %@", error);
                } else {
                    resolve(@"SUCCESS");
                }
                NSLog(@"stored message: %u", createdUID);
            }];
        } else {
            NSData * rfc822Data = [builder data];
            
            MCOIMAPAppendMessageOperation *appendOp =
            [session appendMessageOperationWithFolder:folder messageData:rfc822Data flags:MCOMessageFlagNone];
            
            [appendOp start:^(NSError * _Nullable error, uint32_t createdUID) {
                if (error) {
                    NSLog(@"ERROR appendOp: %@", error);
                } else {
                    resolve(@"SUCCESS");
                }
                NSLog(@"stored message: %u", createdUID);
            }];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        reject(@"500", exception.reason, exception);
    }
    @finally {
        [session.disconnectOperation start:^(NSError * error){
            if (error) {
                NSLog(@"Error closing connection: %@", error);
            }
        }];
    }
}

RCT_EXPORT_METHOD(fetchImap:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    MCOIMAPSession *session = [[MCOIMAPSession alloc] init];
    session.hostname = [RCTConvert NSString:obj[@"hostname"]];
    session.port = [RCTConvert NSUInteger:obj[@"port"]];
    session.username = [RCTConvert NSString:obj[@"username"]];
    session.password = [RCTConvert NSString:obj[@"password"]];
    session.authType = MCOAuthTypeSASLPlain;
    session.connectionType = MCOConnectionTypeTLS;
    NSString *folder = [RCTConvert NSString:obj[@"folder"]];
    NSUInteger *minUid = [RCTConvert NSUInteger:obj[@"minUid"]];
    NSUInteger *length = [RCTConvert NSUInteger:obj[@"length"]];

    MCOIndexSet *uidSet = [MCOIndexSet indexSetWithRange:MCORangeMake(minUid,length)];
    MCOIMAPFetchMessagesOperation *fetchOp =
    [session fetchMessagesOperationWithFolder:folder
                                  requestKind:MCOIMAPMessagesRequestKindUid
                                         uids:uidSet];
    
    [fetchOp start:^(NSError *err, NSArray *msgs, MCOIndexSet *vanished) {
        NSMutableArray *uids = [NSMutableArray new];
        
        for(MCOIMAPMessage * msg in msgs) {
            NSNumber *uid = [NSNumber numberWithUnsignedInt:[msg uid]];
            [uids addObject:uid];
        }
        NSString *res = [uids componentsJoinedByString:@" "];
        NSLog(@"%@", res);
        
        [session.disconnectOperation start:^(NSError * error){
            if (error) {
                NSLog(@"Error closing connection: %@", error);
            }
        }];
        
        resolve(res);
    }];
}

RCT_EXPORT_METHOD(fetchImapByUid:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    MCOIMAPSession *session = [[MCOIMAPSession alloc] init];
    session.hostname = [RCTConvert NSString:obj[@"hostname"]];
    session.port = [RCTConvert NSUInteger:obj[@"port"]];
    session.username = [RCTConvert NSString:obj[@"username"]];
    session.password = [RCTConvert NSString:obj[@"password"]];
    session.authType = MCOAuthTypeSASLPlain;
    session.connectionType = MCOConnectionTypeTLS;
    NSString *folder = [RCTConvert NSString:obj[@"folder"]];
    NSUInteger *uid = [RCTConvert NSUInteger:obj[@"uid"]];
    
    MCOIMAPFetchContentOperation * op = [session fetchMessageOperationWithFolder:folder uid:uid];
    [op start:^(NSError * __nullable error, NSData * messageData) {
        MCOMessageParser * parser = [MCOMessageParser messageParserWithData:messageData];
        NSString *plainTextBody = [parser plainTextBodyRendering];
        //NSLog(@"plainTextBody: %@", plainTextBody);
        NSLog(@"retrieved message: %u", uid);

        NSDictionary *result = @{@"status": @"SUCCESS",
                                 @"body": plainTextBody};
        
        [session.disconnectOperation start:^(NSError * error){
            if (error) {
                NSLog(@"Error closing connection: %@", error);
            }
        }];
        
        resolve(result);
    }];
}

@end
