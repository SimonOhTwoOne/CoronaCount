#import <WebKit/WebKit.h>
#import "QuartzCore/QuartzCore.h"
#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>

HBPreferences *pfs;
NSString * country;

#define trigger @"com.megadev.coronacount/trigger"
#define changecolor @"com.megadev.coronacount/changecolor"

UIColor *statuscolor;

@interface UIStatusBarWindow : UIWindow
@property (nonatomic, retain) NSString *cases;
@property (nonatomic, retain) NSString *recovered;
@property (nonatomic, retain) NSString *deaths;
@property (nonatomic, strong) UILabel *label;

- (void) ccTapRecognizerEvent;

- (void) updateCoronaValues;
@end

NSNumber *cases;
NSNumber *recovered;
NSNumber *deaths;
NSNumber *currentNumber;

int type;
int lastType;

static bool customcountry;
static bool enabled;

%group corona

%hook UIStatusBarWindow
%property(nonatomic, strong) UILabel *label;

-(void)setStatusBar:(id)arg1{
  %orig;

  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(refresh:) 
    name:@"ccTrigger"
    object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(updatecolor:) 
    name:@"ccChangeColor"
    object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(setLoading:) 
    name:@"ccSetLoading"
    object:nil];

  type = [[[NSUserDefaults alloc] initWithSuiteName:@"com.megadev.coronacount"] integerForKey:@"type"];

  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter]
    addObserver:self selector:@selector(orientationChanged:)
    name:UIDeviceOrientationDidChangeNotification
    object:[UIDevice currentDevice]];

  [self updateCoronaValues];

  NSNumberFormatter *formatter = [NSNumberFormatter new];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    CGRect coronaframe;
    CGFloat screenBounds = [UIScreen mainScreen].bounds.size.height;
    
    // X, XS, 11 Pro
    if(screenBounds == 812){
      coronaframe =  CGRectMake([UIScreen mainScreen].bounds.size.width - 95 , 26, 90, 20);
    }

    // 11 Pro Max and XS Max
    if(screenBounds > 812){
      coronaframe = CGRectMake([UIScreen mainScreen].bounds.size.width - 106 , 26, 90, 20);
    }

    // 8, 7 and 6  
    if(screenBounds < 812){
      if(screenBounds > 700){
        coronaframe = CGRectMake([UIScreen mainScreen].bounds.size.width - 90 , 12, 90, 20);
      }else{
        coronaframe =  CGRectMake([UIScreen mainScreen].bounds.size.width - 85 , 10, 90, 20);
      }
    }

    UILabel *label = [[UILabel alloc] initWithFrame:coronaframe];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    [label setFont:[UIFont systemFontOfSize:10]];
    label.textColor = statuscolor;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.text = [NSString stringWithFormat:@"Loading"];

    [label setUserInteractionEnabled:YES];
    [label addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ccTapRecognizerEvent)]];

    [self addSubview:label];
    self.label = label;
  });
}

%new
- (void) orientationChanged:(NSNotification *)note {
  if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
    self.label.hidden = YES;
  } else {
    self.label.hidden = NO;
  }
}

%new
- (void) refresh:(NSNotification *) notification{

  [self updateCoronaValues];
  if(cases){
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle]; 

    NSString *outputString = @"";
    NSNumber *currentValue = nil;

    switch(type) {
      case 0:
        currentValue = cases;
        outputString = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:currentValue], @"cases"];
        break;

      case 1:
        currentValue = deaths;
        outputString = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:currentValue], @"deaths"];
        break;

      case 2:
        currentValue = recovered;
        outputString = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:currentValue], @"cured"];
        break;

      default:
        break;
    }

    if(![outputString hasPrefix:@"("]){
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (currentValue > currentNumber || type != lastType) {
          if(type != lastType){
            self.label.text = [NSString stringWithFormat:@"%@", outputString];
          } else {
            [UIView animateWithDuration:1.0 delay:0.2 options:0 animations:^{
              self.label.textColor = [UIColor redColor];
            } completion:^(BOOL finished) {
              self.label.text = [NSString stringWithFormat:@"%@", outputString];
            }];
          }

          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.label.textColor = statuscolor;
          });

          lastType = true;
          currentNumber = currentValue;
        }
      });
    }
  }
}

%new
- (void)updatecolor:(NSNotification *) notification{
  self.label.textColor = statuscolor;
}

%new
- (void)setLoading:(NSNotification *) notification{
  self.label.text = @"Loading";
}

%new
- (void)updateCoronaValues {
  
  NSURL *URL;

  if(customcountry){
    NSString *comburl = [NSString stringWithFormat:@"https://corona.lmao.ninja/countries/%@", [country stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    URL = [NSURL URLWithString:[comburl lowercaseString]];
  }else{
    URL = [NSURL URLWithString:@"https://corona.lmao.ninja/all"];
  }
  
  NSURLRequest *request = [NSURLRequest requestWithURL:URL];
  [NSURLConnection sendAsynchronousRequest: request
    queue: [NSOperationQueue mainQueue]
    completionHandler: ^(NSURLResponse *urlResponse, NSData *responseData, NSError *requestError) {
    if (requestError || !responseData) {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error!"
        message:[NSString stringWithFormat:@"Unable to fetch data for %@. Could not connect to server.", country]
        delegate:self
        cancelButtonTitle:@"OK"
        otherButtonTitles:nil];
      [alert show];
    } else {
      NSDictionary *s = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:NULL];

      @try {
        cases = [s objectForKey:@"cases"];
        deaths = [s objectForKey:@"deaths"];
        recovered = [s objectForKey:@"recovered"];
      }
      @catch (NSException *exception) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Country Not found!"
          message:[NSString stringWithFormat:@"%@ not found. Reset country and respring to fix! (May be due to connection or API)", country]
          delegate:self
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil];
        [alert show];
      }
    }
  }];
}

%new
-(void) ccTapRecognizerEvent {
  type = (type + 1) % 3;

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:@"ccSetLoading" 
    object:self];

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:@"ccTrigger" 
    object:self];
}

%end

%hook _UIStatusBar 

-(void)setForegroundColor:(id)arg1{
  %orig;

  statuscolor =  MSHookIvar<UIColor *>(self, "_foregroundColor");
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:@"ccChangeColor" 
    object:self];
}

%end

// Credits to Smokin1337 for suggesting to hook this event
%hook SBUIController
- (void)updateBatteryState:(id)arg1 {
  %orig;

  [[NSNotificationCenter defaultCenter] 
    postNotificationName:@"ccTrigger" 
    object:self];
}

%end

%end

%ctor {
  pfs = [[HBPreferences alloc] initWithIdentifier:@"com.megadev.coronacount"];
  [pfs registerBool:&enabled default:YES forKey:@"enabled"];
  [pfs registerBool:&customcountry default:NO forKey:@"customcountry"];
  [pfs registerObject:&country default:@"USA" forKey:@"country"];

  if(enabled){
    %init(corona);
  }
}