//
//  igViewController.m
//

#import <AVFoundation/AVFoundation.h>
#import "igViewController.h"

@interface igViewController () <AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_input;
    AVCaptureVideoDataOutput *_output;
    AVCaptureVideoPreviewLayer *_prevLayer;
    CGRect screenRect;
    CGContextRef context;
    UIView *_highlightView;
    UILabel *_label;
    UIImageView *_imageView;
    
    UIImage *_image;
    NSString *_base64imgCmd;
    
    NSString *_htmlFile;
    NSString *_htmlContent;
//    UIWebView *_webView;
}
@end

@implementation igViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSError *error = nil;

    //init
    screenRect = [[UIScreen mainScreen] bounds];
    
    //setup gesture for single tap
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapHandler:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    /*
    _highlightView = [[UIView alloc] init];
    _highlightView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
    _highlightView.layer.borderColor = [UIColor greenColor].CGColor;
    _highlightView.layer.borderWidth = 3;
    [self.view addSubview:_highlightView];
     */
    
    //setup the webView
    
    self.webView.delegate = self;
    self.webView = [[UIWebView alloc] init];
    self.webView.hidden = true;
    //_webView.delegate = self;
    self.webView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    _htmlFile = [[NSBundle mainBundle] pathForResource:@"webviewContent" ofType:@"html"];
    _htmlContent = [[NSString alloc] initWithContentsOfFile:_htmlFile encoding:NSUTF8StringEncoding error:&error];
    [self.webView loadHTMLString:_htmlContent baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    
    [self.view addSubview:self.webView];

    // setup the native imageView
    _imageView = [[UIImageView alloc] init];
    _imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _imageView.backgroundColor = [UIColor blueColor];
    [self.view addSubview:_imageView];
    
    // setup the label
    _label = [[UILabel alloc] init];
    _label.frame = CGRectMake(0, self.view.bounds.size.height - 40, self.view.bounds.size.width, 40);
    _label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _label.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
    _label.textColor = [UIColor whiteColor];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.text = @"Native";
    [self.view addSubview:_label];

    _session = [[AVCaptureSession alloc] init];
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (_input) {
        [_session addInput:_input];
    } else {
        NSLog(@"Error: %@", error);
    }

    //_prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    //_prevLayer.frame = self.view.bounds;
    //_prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //[self.view.layer addSublayer:_ prevLayer];
    
    _output = [[AVCaptureVideoDataOutput alloc] init];
    
    // create a queue to run the capture on
    dispatch_queue_t captureQueue=dispatch_queue_create("captureQueue", NULL);
    
    // setup output delegate
    [_output setSampleBufferDelegate:self queue:captureQueue];
    
    // configure the pixel format
    _output.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey, nil];
    //_output.videoSettings =  @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    //_output.videoSettings =
    //_output.alwaysDiscardsLateVideoFrames=YES;

    [_session addOutput:_output];
    
    [_session startRunning];

    //[self.view bringSubviewToFront:_highlightView];
    [self.view bringSubviewToFront:self.webView];
    //[self.view bringSubviewToFront:_imageView];
    [self.view bringSubviewToFront:_label];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *requestURLString = [[request URL] absoluteString];
    
    if ([requestURLString hasPrefix:@"js-call:"]) {
        
        NSArray *components = [requestURLString componentsSeparatedByString:@":"];
        
        NSString *commandName = (NSString*)[components objectAtIndex:1];
        NSString *argsAsString = [(NSString*)[components objectAtIndex:2]
                                  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        NSData *argsData = [argsAsString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *args = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:argsData options:kNilOptions error:&error];
        
        NSLog(@"Command: %@ - %@", commandName, [args description]);
        
        if ([commandName isEqualToString:@"error"]) {
            NSLog(@"JS-ERROR: ");
        } else if ([commandName isEqualToString:@"nextDemo"]) {
            [self switchDemoMode];
        }

        return NO;
    } else {
        return YES;
    }
}

- (void)tapHandler:(UITapGestureRecognizer *)sender {
    NSLog(@"Switching demo mode to: %@", self.switchDemoMode);
}

// Switch to next demo mode and return it as string
- (NSString*)switchDemoMode {
    self.demoMode = (self.demoMode + 1) % numberOfModes;
    switch (self.demoMode) {
        case DemoNative:
            _label.text = @"Fully Native";
            _webView.hidden = true;
            return @"Fully Native";
            break;
        case DemoCanvas:
            _label.text = @"Web View";
            _imageView.hidden = true;
            _webView.hidden = false;
            return @"Canvas in default webview";
            break;
        default:
            return @"not defined";
            break;
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    _image = imageFromSampleBuffer(sampleBuffer);

    switch (self.demoMode) {
        case DemoNative:
            //start a graphic context
        /*
            UIGraphicsBeginImageContext(screenRect.size);
            context = UIGraphicsGetCurrentContext();
            CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextSetLineWidth(context, 1.0);
            CGContextSetTextDrawingMode(context, kCGTextFill);
            CGContextDrawImage(context, screenRect, image.CGImage);
            //[image drawInRect:screenRect];
            UIGraphicsEndImageContext();
        */
        
            //[_imageView setImage:image];
            //[_imageView setNeedsDisplay];
            //[_imageView ]
        
            //NSLog(@"image size: %f, %f", image.size.width, image.size.height);
            break;
        case DemoCanvas:
            //Let the canvas magic begin!
            //_base64imgCmd = [NSString stringWithFormat:@"draw('data:image/png;base64,%@');", [self encodeToBase64StringPNG:_image]];
            _base64imgCmd = [NSString stringWithFormat:@"draw('data:image/png;base64,%@');", [self encodeToBase64StringJPEG:_image]];
            [self.webView stringByEvaluatingJavaScriptFromString:_base64imgCmd];
            break;
        default:
            NSLog(@"Undefined mode");
            break;
    }
}


//TODO: add this method to interface
UIImage *imageFromSampleBuffer(CMSampleBufferRef sampleBuffer) {
    // This example assumes the sample buffer came from an AVCaptureOutput,
    // so its image buffer is known to be a pixel buffer.
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    // Get the number of bytes per row for the pixel buffer.
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space.
    static CGColorSpaceRef colorSpace = NULL;
    if (colorSpace == NULL) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace == NULL) {
            // Handle the error appropriately.
            return nil;
        }
    }

    // Get the base address of the pixel buffer.
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    // Create a Quartz direct-access data provider that uses data we supply.
    CGDataProviderRef dataProvider =
      CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    
    // Create a bitmap image from data supplied by the data provider.
    CGImageRef cgImage =
      CGImageCreate(width, height, 8, 32, bytesPerRow,
                    colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                    dataProvider, NULL, true, kCGRenderingIntentDefault);
    
    CGDataProviderRelease(dataProvider);
    // Create and return an image object to represent the Quartz image.
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return image;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"memort warning");
    // Dispose of any resources that can be recreated.
}

- (NSString *)encodeToBase64StringPNG:(UIImage *)image {
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (NSString *)encodeToBase64StringJPEG:(UIImage *)image {
    return [UIImageJPEGRepresentation(image, 0.1) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

@end