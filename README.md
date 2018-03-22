# YoutubeExtractor-iOS
These are the urls to the YouTube video or audio files, so you can stream or download them. It features an age verification circumvention and a signature deciphering method (mainly for Vevo videos).

**NOTE:**
The Library works fine for getting the dowloadable URL. But the library is in early stages of development and a lot of optimisations and features are to be added.

**Installation:**

1. Download the four swift files and add them to your project.
2. Download RMYoutubeExtractorFiles, include them also in your Project.
3. Call the function like this:



**Objective-C**


```objective-c
import "Appname-Swift.h"

 RMYouTubeExtractor *rmYtExtractor = [RMYouTubeExtractor sharedInstance];    
[rmYtExtractor extractVideoForIdentifier: youtubeID completion:^(NSDictionary *videoDictionary, NSError *error) {
    if(!error){
        NSString *urlReceived = [videoDictionary objectForKey:[NSNumber numberWithInteger:36]];
        return;
    }else{
        NSLog(@"%@",error);
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            //This code is executed background
            YoutubeExtractor *extractor = [[YoutubeExtractor alloc]init];
            NSString *urlReceived = [extractor doInBackgroundWithYtUrl:urlStr];
            if([returnVal isEqualToString:@"Url not Found"]){
                //Notify URL Not found, But it won't happen
                return;
            } else{
                // Do whatever with your url
            }
        });
    }

}];
```


