//
//  igViewController.h
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DemoMode) {
    DemoNative,
    DemoCanvas,
    numberOfModes
};

@interface igViewController : UIViewController<UIWebViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic) DemoMode demoMode;
@property (nonatomic) IBOutlet UIWebView *webView;

@end