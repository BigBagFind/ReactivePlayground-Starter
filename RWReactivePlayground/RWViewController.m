//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import "ReactiveCocoa.h"

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;


@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.signInService = [RWDummySignInService new];
    // initially hide the failure message
    self.signInFailureText.hidden = YES;

  /*************** UserNameField ******************/
    // if Bool = Yes, subscrbe -> log
    [[[self.usernameTextField.rac_textSignal
       map:^id(NSString *text) {
            return @(text.length);
        }]
       filter:^BOOL(NSNumber *length) {
            return[length integerValue] > 3;
        }]
       subscribeNext:^(id x) {
             NSLog(@"%@", x);
       }];
    
    /***************  line    ******************/
    // create RAC
    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidUsername:text]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];

    // map
    RAC(self.usernameTextField,backgroundColor) = [validUsernameSignal map:^id(NSNumber *usernameValid) {
        return usernameValid.boolValue ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    RAC(self.passwordTextField,backgroundColor) = [validPasswordSignal map:^id(NSNumber *passwordValid) {
        return passwordValid.boolValue ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    // combineSignal
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validUsernameSignal,validPasswordSignal] reduce:^id(NSNumber *usernameValid,NSNumber *passwordValid){
        return @(usernameValid.boolValue && passwordValid.boolValue);
    }];
                                     
    [signUpActiveSignal subscribeNext:^(NSNumber *signupActive) {
        self.signInButton.enabled = signupActive.boolValue;
    }];
    
    // 需要的是signal的value，而不是signal，map将会传出［self signInSignal］的signal
    // 而flattenMap是平级map，调用［self signInSignal］的结果就是createSignal时传出的
    // @（Success）
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
      doNext:^(id x) {
          self.signInButton.enabled = NO;
          self.signInFailureText.hidden = YES;
      }]
      flattenMap:^id(id x){
          return [self signInSignal];
      }]
      subscribeNext:^(NSNumber *signedIn){
          BOOL success = [signedIn boolValue];
          self.signInFailureText.hidden = success;
          if(success){
              [self performSegueWithIdentifier:@"signInSuccess" sender:self];
          }
      }];
    
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}



- (RACSignal *)signInSignal {
    // 创建signal方法的入参是一个block
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
            complete:^(BOOL Success) {
                // error\complete
                [subscriber sendNext:@(Success)];
                [subscriber sendCompleted];
         }];
        return nil;
    }];
}

@end
