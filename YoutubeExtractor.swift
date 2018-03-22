//
//  YoutubeExtractor.swift
//  MZAESController
//
//  Created by apple on 21/02/18.
//  Copyright © 2018 Ami Technologies. All rights reserved.
//

import UIKit
import Foundation
import JavaScriptCore

extension String {
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map { result.rangeAt($0).location != NSNotFound
                ? nsString.substring(with: result.rangeAt($0))
                : ""
            }
        }
    }
    
    func matchingStringEnd(regex: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return "Error" }
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        var rangeStr = " ";
        _ = results.map { result in
            (0..<result.numberOfRanges).map {
                if(result.rangeAt($0).location != NSNotFound){
                    rangeStr = String(result.rangeAt($0).location);
                }
            }
        }
        
        //let resultStr = results[0];
        return rangeStr;
    }
    
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return self[Range(start ..< end)]
    }
    
    
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }
    
    func splitByRegex(pattern:String, toSearch:String) -> [String]{
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        // NSRegularExpression works with objective-c NSString, which are utf16 encoded
        let matches = regex.matches(in: toSearch, range: NSMakeRange(0, toSearch.utf16.count))
        
        // the combination of zip, dropFirst and map to optional here is a trick
        // to be able to map on [(result1, result2), (result2, result3), (result3, nil)]
        let results = zip(matches, matches.dropFirst().map { Optional.some($0) } + [nil]).map { current, next -> String in
            let range = current.rangeAt(0)
            let start = String.UTF16Index(range.location)
            // if there's a next, use it's starting location as the ending of our match
            // otherwise, go to the end of the searched string
            let end = next.map { $0.rangeAt(0) }.map { String.UTF16Index($0.location) } ?? String.UTF16Index(toSearch.utf16.count)
            
            return String(toSearch.utf16[start..<end])!
        }
        return results;
    }
    
}

extension NSRegularExpression {
    typealias GroupNamesSearchResult = (NSTextCheckingResult, NSTextCheckingResult, Int)
    
    private func textCheckingResultsOfNamedCaptureGroups() -> [String:GroupNamesSearchResult] {
        var groupnames = [String:GroupNamesSearchResult]()
        
        guard let greg = try? NSRegularExpression(pattern: "^\\(\\?<([\\w\\a_-]*)>$", options: NSRegularExpression.Options.dotMatchesLineSeparators) else {
            // This never happens but the alternative is to make this method throwing
            return groupnames
        }
        guard let reg = try? NSRegularExpression(pattern: "\\(.*?>", options: NSRegularExpression.Options.dotMatchesLineSeparators) else {
            // This never happens but the alternative is to make this method throwing
            return groupnames
        }
        let m = reg.matches(in: self.pattern, options: NSRegularExpression.MatchingOptions.withTransparentBounds, range: NSRange(location: 0, length: self.pattern.utf16.count))
        for (n,g) in m.enumerated() {
            let r = self.pattern.range(from: g.rangeAt(0))
            let gstring = self.pattern.substring(with: r!)
            let gmatch = greg.matches(in: gstring, options: NSRegularExpression.MatchingOptions.anchored, range: NSRange(location: 0, length: gstring.utf16.count))
            if gmatch.count > 0{
                let r2 = gstring.range(from: gmatch[0].rangeAt(1))!
                groupnames[gstring.substring(with: r2)] = (g, gmatch[0],n)
            }
            
        }
        return groupnames
    }
    
    func indexOfNamedCaptureGroups() throws -> [String:Int] {
        var groupnames = [String:Int]()
        for (name,(_,_,n)) in try self.textCheckingResultsOfNamedCaptureGroups() {
            groupnames[name] = n + 1
        }
        return groupnames
    }
    
    func rangesOfNamedCaptureGroups(match:NSTextCheckingResult) throws -> [String:Range<Int>] {
        var ranges = [String:Range<Int>]()
        for (name,(_,_,n)) in try self.textCheckingResultsOfNamedCaptureGroups() {
            ranges[name] = match.rangeAt(n+1).toRange()
        }
        return ranges
    }
    
    private func nameForIndex(_ index: Int, from: [String:GroupNamesSearchResult]) -> String? {
        for (name,(_,_,n)) in from {
            if (n + 1) == index {
                return name
            }
        }
        return nil
    }
    
    func captureGroups(string: String, options: NSRegularExpression.MatchingOptions = []) -> [String:String] {
        return captureGroups(string: string, options: options, range: NSRange(location: 0, length: string.utf16.count))
    }
    
    func captureGroups(string: String, options: NSRegularExpression.MatchingOptions = [], range: NSRange) -> [String:String] {
        var dict = [String:String]()
        let matchResult = matches(in: string, options: options, range: range)
        let names = try self.textCheckingResultsOfNamedCaptureGroups()
        for (n,m) in matchResult.enumerated() {
            for i in (0..<m.numberOfRanges) {
                let r2 = string.range(from: m.rangeAt(i))!
                let g = string.substring(with: r2)
                if let name = nameForIndex(i, from: names) {
                    dict[name] = g
                }
            }
        }
        return dict
    }

}
public class YoutubeExtractor: NSObject {
    
    /*DispatchQueue.global(qos: .background).async {
            // Background Thread
        DispatchQueue.main.async {
            // Run UI Updates or call completion block
        }
    }*/
    
    private static let CACHING:Bool = true;
    
    static var LOGGING:Bool = false;
    
    private static let LOG_TAG:String = "YouTubeExtractor";
    private static let CACHE_FILE_NAME:String = "decipher_js_funct";
    private static let DASH_PARSE_RETRIES:Int = 5;
    
    //private Context context;   //Commented By me
    private var videoID:String?;
    private var videoMeta:VideoMeta?;
    private var includeWebM:Bool = true;
    private var useHttp:Bool = false;
    private var parseDashManifest:Bool = false;

    private var decipheredSignature:String?;

    private static var decipherJsFileName:String?;
    private static var decipherFunctions:String?;
    private static var decipherFunctionName:String?;

    //private let Lock lock = new ReentrantLock(); //Commented By Me
    private let jsExecuting:NSCondition = NSCondition();
    
    

    private static let USER_AGENT:String = "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.115 Safari/537.36";
    private static let STREAM_MAP_STRING:String = "url_encoded_fmt_stream_map";

    private static let patYouTubePageLink:NSRegularExpression  = try! NSRegularExpression(pattern:"^(http|https)://(www\\.|m.|)youtube\\.com/watch\\?v=(.+?)( |\\z|&)$", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    
    private static let patYouTubeShortLink:NSRegularExpression = try! NSRegularExpression(pattern:"(http|https)://(www\\.|)youtu.be/(.+?)( |\\z|&)", options: NSRegularExpression.Options.dotMatchesLineSeparators);

    private static let patDashManifest1 = try! NSRegularExpression(pattern: "dashmpd=(.+?)(&|\\z)", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patDashManifest2 = try! NSRegularExpression(pattern: "\"dashmpd\":\"(.+?)\"", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patDashManifestEncSig = try! NSRegularExpression(pattern: "/s/([0-9A-F|.]{10,}?)(/|\\z)", options: NSRegularExpression.Options.dotMatchesLineSeparators);

    private static let patTitle = try! NSRegularExpression(pattern: "title=(.*?)(&|\\z)", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patAuthor = try! NSRegularExpression(pattern: "author=(.+?)(&|\\z)", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patChannelId = try! NSRegularExpression(pattern: "ucid=(.+?)(&|\\z)", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patLength = try! NSRegularExpression(pattern: "length_seconds=(\\d+?)(&|\\z)", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patViewCount = try! NSRegularExpression(pattern: "view_count=(\\d+?)(&|\\z)", options: NSRegularExpression.Options.dotMatchesLineSeparators);

    private static let patHlsvp = try! NSRegularExpression(pattern: "hlsvp=(.+?)(&|\\z)", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patHlsItag = try! NSRegularExpression(pattern: "/itag/(\\d+?)/", options: NSRegularExpression.Options.dotMatchesLineSeparators);

    private static let patItag = try! NSRegularExpression(pattern: "itag=([0-9]+?)([&,])", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patEncSig = try! NSRegularExpression(pattern: "s=([0-9A-F|.]{10,}?)([&,\"])", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patIsSigEnc = try! NSRegularExpression(pattern: "s%3D([0-9A-F|.]{10,}?)%26", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patUrl = try! NSRegularExpression(pattern: "url=(.+?)([&,])", options: NSRegularExpression.Options.dotMatchesLineSeparators);

    private static let patVariableFunction = try! NSRegularExpression(pattern: "([{; =])([a-zA-Z$][a-zA-Z0-9$]{0,2})\\.([a-zA-Z$][a-zA-Z0-9$]{0,2})\\(", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patFunction = try! NSRegularExpression(pattern: "([{; =])([a-zA-Z$_][a-zA-Z0-9$]{0,2})\\(", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patDecryptionJsFile1 = try! NSRegularExpression(pattern: "jsbin\\\\/(player-(.+?).js)", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patDecryptionJsFile = try! NSRegularExpression(pattern: "jsbin\\/(player-(.+?).js)", options: NSRegularExpression.Options.dotMatchesLineSeparators);
    private static let patSignatureDecFunction = try! NSRegularExpression(pattern: "([\"\\'])signature\\1\\s*,\\s*([a-zA-Z0-9$]+)\\(", options: NSRegularExpression.Options.dotMatchesLineSeparators);

    private let FORMAT_MAP = NSMutableDictionary();

    //let formatInitializers = {
    // http://en.wikipedia.org/wiki/YouTube#Quality_and_formats
    private func initializeFormats() {
    // Video and Audio
    FORMAT_MAP.setObject(Format(itag:17, ext:"3gp", height:144, vCodec:Format.VCodec.MPEG4, aCodec:	Format.ACodec.AAC, audioBitrate:24, isDashContainer:false), forKey: 17 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:36, ext:"3gp", height:240, vCodec:Format.VCodec.MPEG4, aCodec:    Format.ACodec.AAC, audioBitrate:32, isDashContainer:false), forKey: 36 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:5, ext:"flv", height:240, vCodec:Format.VCodec.H263, aCodec:    Format.ACodec.MP3, audioBitrate:64, isDashContainer:false), forKey: 5 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:43, ext:"webm", height:360, vCodec:Format.VCodec.VP8, aCodec:    Format.ACodec.VORBIS, audioBitrate:128, isDashContainer:false), forKey: 43 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:18, ext:"mp4", height:360, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.AAC, audioBitrate:96, isDashContainer:false), forKey: 18 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:22, ext:"mp4", height:360, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.AAC, audioBitrate:192, isDashContainer:false), forKey: 22 as NSCopying);
        

    // Dash Video
    FORMAT_MAP.setObject(Format(itag:160, ext:"mp4", height:144, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.NONE, isDashContainer:true), forKey: 160 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:133, ext:"mp4", height:240, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.NONE, isDashContainer:true), forKey: 133 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:134, ext:"mp4", height:360, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.NONE, isDashContainer:true), forKey: 134 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:134, ext:"mp4", height:360, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.NONE, isDashContainer:true), forKey: 134 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:135, ext:"mp4", height:480, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.NONE, isDashContainer:true), forKey: 135 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:136, ext:"mp4", height:720, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.NONE, isDashContainer:true), forKey: 136 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:137, ext:"mp4", height:1080, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.NONE, isDashContainer:true), forKey: 137 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:264, ext:"mp4", height:1440, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.NONE, isDashContainer:true), forKey: 264 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:266, ext:"mp4", height:2160, vCodec:Format.VCodec.H264, aCodec:    Format.ACodec.NONE, isDashContainer:true), forKey: 266 as NSCopying);
        

    FORMAT_MAP.setObject(Format(itag:298, ext:"mp4", height:720, vCodec:Format.VCodec.H264, fps:60, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 298 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:299, ext:"mp4", height:1080, vCodec:Format.VCodec.H264, fps:60, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 299 as NSCopying);
        

    // Dash Audio
    FORMAT_MAP.setObject(Format(itag:140, ext:"m4a", vCodec:Format.VCodec.NONE, aCodec:Format.ACodec.AAC, audioBitrate:128, isDashContainer:true), forKey: 140 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:141, ext:"m4a", vCodec:Format.VCodec.NONE, aCodec:Format.ACodec.AAC, audioBitrate:256, isDashContainer:true), forKey: 141 as NSCopying);
   

    // WEBM Dash Video
    FORMAT_MAP.setObject(Format(itag:278, ext:"webm", height:144, vCodec:Format.VCodec.VP9, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 278 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:242, ext:"webm", height:240, vCodec:Format.VCodec.VP9, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 242 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:243, ext:"webm", height:360, vCodec:Format.VCodec.VP9, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 243 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:244, ext:"webm", height:480, vCodec:Format.VCodec.VP9, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 244 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:247, ext:"webm", height:720, vCodec:Format.VCodec.VP9, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 247 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:248, ext:"webm", height:1080, vCodec:Format.VCodec.VP9, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 248 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:271, ext:"webm", height:1440, vCodec:Format.VCodec.VP9, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 271 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:313, ext:"webm", height:2160, vCodec:Format.VCodec.VP9, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 313 as NSCopying);
        
    FORMAT_MAP.setObject(Format(itag:302, ext:"webm", height:720, vCodec:Format.VCodec.H264, fps:60, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 302 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:308, ext:"webm", height:1440, vCodec:Format.VCodec.H264, fps:60, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 308 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:303, ext:"webm", height:1080, vCodec:Format.VCodec.H264, fps:60, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 303 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:315, ext:"webm", height:2160, vCodec:Format.VCodec.H264, fps:60, aCodec:Format.ACodec.NONE, isDashContainer:true), forKey: 315 as NSCopying);

    // WEBM Dash Audio
    FORMAT_MAP.setObject(Format(itag:171, ext:"webm", vCodec:Format.VCodec.NONE, aCodec:Format.ACodec.VORBIS, audioBitrate:128, isDashContainer:true), forKey: 171 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:249, ext:"webm", vCodec:Format.VCodec.NONE, aCodec:Format.ACodec.VORBIS, audioBitrate:48, isDashContainer:true), forKey: 249 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:250, ext:"webm", vCodec:Format.VCodec.NONE, aCodec:Format.ACodec.VORBIS, audioBitrate:64, isDashContainer:true), forKey: 250 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:251, ext:"webm", vCodec:Format.VCodec.NONE, aCodec:Format.ACodec.VORBIS, audioBitrate:160, isDashContainer:true), forKey: 251 as NSCopying);
        
    // HLS Live Stream
    FORMAT_MAP.setObject(Format(itag:91, ext:"mp4", height:144, vCodec:Format.VCodec.H264, aCodec:Format.ACodec.AAC, audioBitrate:48, isDashContainer:false, isHlsContent:true), forKey: 91 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:92, ext:"mp4", height:240, vCodec:Format.VCodec.H264, aCodec:Format.ACodec.AAC, audioBitrate:48, isDashContainer:false, isHlsContent:true), forKey: 92 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:93, ext:"mp4", height:360, vCodec:Format.VCodec.H264, aCodec:Format.ACodec.AAC, audioBitrate:128, isDashContainer:false, isHlsContent:true), forKey: 93 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:94, ext:"mp4", height:480, vCodec:Format.VCodec.H264, aCodec:Format.ACodec.AAC, audioBitrate:128, isDashContainer:false, isHlsContent:true), forKey: 94 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:95, ext:"mp4", height:720, vCodec:Format.VCodec.H264, aCodec:Format.ACodec.AAC, audioBitrate:256, isDashContainer:false, isHlsContent:true), forKey: 95 as NSCopying);
    FORMAT_MAP.setObject(Format(itag:96, ext:"mp4", height:1080, vCodec:Format.VCodec.H264, aCodec:Format.ACodec.AAC, audioBitrate:256, isDashContainer:false, isHlsContent:true), forKey: 96 as NSCopying);
 
    }
//
//    public YouTubeExtractor(Context con) {
//    context = con;
//    }
    
    override init() {
        super.init();
        self.initializeFormats();
    }
    
    private func indexOfLocal(source: String, substring: String) -> Int? {
        let maxIndex = source.characters.count - substring.characters.count
        for index in 0...maxIndex {
            let rangeSubstring = source.startIndex.advanced(by: index)..<source.startIndex.advanced(by:index + substring.characters.count)
             //javascriptFile[range]
            if (source[rangeSubstring] == substring) {
                return index
            }
        }
        return 0
    }
    
    private func writeToTextFile(text:String){
        
        
            do {
                try UserDefaults.standard.set(text, forKey: YoutubeExtractor.CACHE_FILE_NAME)
            }
            catch {/* error handling here */}
            
        
           
        //let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
         //   let fileURL = dir.appendingPathComponent(
    
    }
    
    private func readFromFile() -> String{
        //if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
          //  let fileURL = dir.appendingPathComponent(YoutubeExtractor.CACHE_FILE_NAME)
            //reading
            //do {
//        guard let unwrappedName = userName else {
//            return
//        }
        guard let text2:String =  UserDefaults.standard.string(forKey: YoutubeExtractor.CACHE_FILE_NAME)  else {
            return " ";
        }
        return text2;
        
                //return try text2;
           // }
           // catch {return " "}
        //}
        //return "Error Reading Contents";
    }
    
//
//    @Override
//    protected void onPostExecute(SparseArray<YtFile> ytFiles) {
//    onExtractionComplete(ytFiles, videoMeta);
//    }
//
//
    /**
     * Start the extraction.
     *
     * @param youtubeLink       the youtube page link or video id
     * @param parseDashManifest true if the dash manifest should be downloaded and parsed
     * @param includeWebM       true if WebM streams should be extracted
     */
    public func extract(youtubeLink:String, parseDashManifest:Bool, includeWebM:Bool) {
        self.parseDashManifest = parseDashManifest;
        self.includeWebM = includeWebM;
        self.doInBackground(ytUrl: youtubeLink);
    }
//
//    protected abstract void onExtractionComplete(SparseArray<YtFile> ytFiles, VideoMeta videoMeta);

    public func doInBackground(ytUrl:String) -> NSString{
        videoID = nil;
        //String ytUrl = params[0];
        if (ytUrl == nil) {
            return NSString()//nil;
        }
        if (ytUrl.range(of: YoutubeExtractor.patYouTubePageLink.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) != nil){
            let matchingStrings = ytUrl.matchingStrings(regex:  YoutubeExtractor.patYouTubePageLink.pattern);
            //let match2 = YoutubeExtractor.patYouTubePageLink.captureGroups(string: ytUrl, options: NSRegularExpression.MatchingOptions.anchored);
            videoID = matchingStrings[0][3];
            //print("Printed Video ID: "+videoID!);
        }else if(ytUrl.range(of: YoutubeExtractor.patYouTubeShortLink.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) != nil){
            let matchingStrings = ytUrl.matchingStrings(regex:  YoutubeExtractor.patYouTubeShortLink.pattern);
            //let match2 = YoutubeExtractor.patYouTubePageLink.captureGroups(string: ytUrl, options: NSRegularExpression.MatchingOptions.anchored);
            videoID = matchingStrings[0][3];
            //print("Printed Video ID: "+videoID!);
        }else {
            videoID = ytUrl;
        }
        var ytFilesDictionary:String = String();
        if (videoID != nil) {
           let ytFilesDictionaryTemp = try! getStreamUrls();
            if(ytFilesDictionaryTemp.count == 0){
                return "Url not Found";
            }
            let newDict:YtFile = ytFilesDictionaryTemp.object(forKey: 36 as NSCopying) as! YtFile;
            let newVal:String = newDict.getUrl()
            ytFilesDictionary = newVal;
        }else {
            print(YoutubeExtractor.LOG_TAG+"Wrong YouTube link format");
        }
        
        return ytFilesDictionary as NSString;
    }

    private func getStreamUrls() -> NSMutableDictionary{
        let infoString = "https://youtube.googleapis.com/v/"+videoID!;
        var ytInfoUrl = (useHttp) ? "http://" : "https://";
        ytInfoUrl += "www.youtube.com/get_video_info?video_id=" + videoID! + "&eurl="
            +  infoString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        var dashMpdUrl = "";
        var streamMap:String?;
        var getUrlq = URL(string:ytInfoUrl)
        //print(YoutubeExtractor.LOG_TAG+" infoUrl: "+ytInfoUrl);
        let ytFiles:NSMutableDictionary = NSMutableDictionary();
        
        let request2: URLRequest = URLRequest(url: getUrlq!)
        var response2: AutoreleasingUnsafeMutablePointer<URLResponse?>?
        var dataVal2:Data?
        do{
            dataVal2 = try NSURLConnection.sendSynchronousRequest(request2, returning: response2)
        } catch let error as NSError {
            
        }
        
        //let mainTask = URLSession.shared.dataTask(with: getUrl!) {(data, response, error) in
            streamMap = NSString(data: dataVal2!, encoding: String.Encoding.utf8.rawValue)! as String
            //print(streamMap!)
    
            var curJsFileName:String?;
            var streams:[String]?;
            var encSignatures:NSMutableDictionary?;
            
            self.parseVideoMeta(getVideoInfo: streamMap!);
            
            //If the Current Video is a LiveStream this code is Executed
            if(self.videoMeta?.isLiveStream())!{
                if (streamMap!.range(of: YoutubeExtractor.patHlsvp.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) != nil){
                    let matchingStrings = streamMap!.matchingStrings(regex:  YoutubeExtractor.patHlsvp.pattern);
                    let hlsvp = matchingStrings[0][1];
                    var getUrla = URL(string:hlsvp);
                    var streamMapLiveStream:String?
                    let liveStreamTask = URLSession.shared.dataTask(with: getUrla!) {(data, response, error) in
                        streamMapLiveStream = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
                        let myStrings = streamMapLiveStream?.components(separatedBy: .newlines)

//                        while ((line = reader.readLine()) != null) {
//                            if(line.startsWith("https://") || line.startsWith("http://")){
//                                mat = patHlsItag.matcher(line);
//                                if(mat.find()){
//                                    int itag = Integer.parseInt(mat.group(1));
//                                    YtFile newFile = new YtFile(FORMAT_MAP.get(itag), line);
//                                    ytFiles.put(itag, newFile);
//                                }
//                            }
//                        }
                        //This Part is to Be completed
                    }
                    liveStreamTask.resume();
                }
            }
            
            //If the Video is not a LiveStream Then Execution Continues
            var sigEnc = true;
            if(streamMap != nil && streamMap!.contains(YoutubeExtractor.STREAM_MAP_STRING)){
                let streamMapSub = streamMap?.substring(from:YoutubeExtractor.STREAM_MAP_STRING.startIndex);
                if (streamMapSub?.range(of: YoutubeExtractor.patIsSigEnc.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                    sigEnc = false;
                }
            }
            
            if (sigEnc) {
                // Get the video directly from the youtubepage
                if (YoutubeExtractor.CACHING
                    && (YoutubeExtractor.decipherJsFileName == nil || YoutubeExtractor.decipherFunctions == nil || YoutubeExtractor.decipherFunctionName == nil)) {
                    self.readDecipherFunctFromCache(); //Have to WorkOut
                }
                let getUrlt = URL(string:"https://youtube.com/watch?v="+self.videoID!);
                var streamMapDirectFromYT:String?
                
                let request1: URLRequest = URLRequest(url: getUrlt!)
                var response: AutoreleasingUnsafeMutablePointer<URLResponse?>?
                var dataVal:Data?
                do{
                    dataVal = try NSURLConnection.sendSynchronousRequest(request1, returning: response)
                } catch let error as NSError {
                    
                }
                
                    streamMapDirectFromYT = NSString(data: dataVal!, encoding: String.Encoding.utf8.rawValue)! as String
                    let myStrings = streamMapDirectFromYT?.components(separatedBy: .newlines)
                    var iterator = 0;
                    while( iterator < (myStrings?.count)!){
                        let line = myStrings![iterator];
                        if(line.contains(YoutubeExtractor.STREAM_MAP_STRING)){
                            streamMapDirectFromYT = line.replacingOccurrences(of: "\\u0026", with: "&");
                            break;
                        }
                        iterator = iterator+1;
                    }
                    
                    encSignatures = NSMutableDictionary();
                    
                    let strCompare:String = (streamMapDirectFromYT?.removingPercentEncoding)!; //streamMapDirectFromYT?.stringByReplacingPercentEscapesUsingEncoding  NSUTF8StringEncoding;
                    //print(strCompare);
                    if (strCompare.range(of: YoutubeExtractor.patDecryptionJsFile.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                        let matchingStrings = strCompare.matchingStrings(regex:  YoutubeExtractor.patDecryptionJsFile1.pattern);
                        curJsFileName = matchingStrings[0][1].replacingOccurrences(of: "\\/", with: "/")
                        if (YoutubeExtractor.decipherJsFileName == nil || !(YoutubeExtractor.decipherJsFileName == curJsFileName)) {
                            YoutubeExtractor.decipherFunctions = nil;
                            YoutubeExtractor.decipherFunctionName = nil;
                        }
                        YoutubeExtractor.decipherJsFileName = curJsFileName;
                    }
                
                    if (self.parseDashManifest) {
                        if (strCompare.range(of: YoutubeExtractor.patDashManifest2.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                            let matchingStrings = strCompare.matchingStrings(regex:  YoutubeExtractor.patDashManifest2.pattern);
                            dashMpdUrl = matchingStrings[0][1].replacingOccurrences(of: "\\/", with: "/")
                            if (dashMpdUrl.range(of: YoutubeExtractor.patDashManifestEncSig.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                                let matchingStrings = dashMpdUrl.matchingStrings(regex:  YoutubeExtractor.patDashManifestEncSig.pattern);
                                encSignatures?.setObject(matchingStrings[0][1], forKey: 0 as NSCopying)
                            }else{
                                dashMpdUrl = "";
                            }
                        }
                    }
                let patternStr:String = ",|url_encoded_fmt_stream_map|&adaptive_fmts";
                    //streams = strCompare.components(separatedBy:",|url_encoded_fmt_stream_map|&adaptive_fmts");
                    streams = streamMapDirectFromYT?.splitByRegex(pattern: patternStr, toSearch: streamMapDirectFromYT!)
                    
                    for tmpStream:String in streams! {
                        let encStream:String = tmpStream + ",";
                        if (!encStream.contains("itag%3D")) {
                            continue;
                        }
                        var stream:String?;
                        stream = encStream.removingPercentEncoding;
                        var itag:Int;
                        //stream?.range(of: YoutubeExtractor.patItag.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil
                        let matchingStrings = stream?.matchingStrings(regex:  YoutubeExtractor.patItag.pattern);
                        if (matchingStrings![0].count > 0){
                            itag = Int(matchingStrings![0][1])!;
                            if(YoutubeExtractor.LOGGING){
                                print(YoutubeExtractor.LOG_TAG+"Itag found:"+String(itag));
                            }
                            if(self.FORMAT_MAP.object(forKey: itag) == nil){
                                if(YoutubeExtractor.LOGGING){
                                    print(YoutubeExtractor.LOG_TAG+"Itag not in list: "+String(itag));
                                }
                                continue;
                            }else if (!self.includeWebM){
                                let formatObject:Format = self.FORMAT_MAP.object(forKey: itag) as! Format;
                                if(formatObject.getExt() == "webm") {
                                    continue;
                                }
                            }
                        }else{
                            continue;
                        }
                        
                        if (curJsFileName != nil) {
//                            if (stream?.range(of: YoutubeExtractor.patEncSig.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                            let matchingStringspatEncSig = stream?.matchingStrings(regex:  YoutubeExtractor.patEncSig.pattern);
                             if (matchingStringspatEncSig![0].count > 0){
                                encSignatures?.setObject(matchingStringspatEncSig![0][1], forKey: itag as NSCopying)
                            }
                        }
                        var url:String = "";
//                        if (encStream.range(of: YoutubeExtractor.patUrl.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                            let matchingStringspatUrl = encStream.matchingStrings(regex:  YoutubeExtractor.patUrl.pattern);
                        if (matchingStringspatUrl[0].count > 0){
                            url = matchingStringspatUrl[0][1];
                        }
                        
                        if(url != ""){
                            let formater:Format = self.FORMAT_MAP.object(forKey: itag) as! Format;
                            let finalUrl:String = url.removingPercentEncoding!;
                            var ytFileTemp:YtFile = YtFile(format: formater, url: finalUrl);
                            ytFiles.setObject(ytFileTemp, forKey: itag as NSCopying);
                        }
                    }
                    
                    if (encSignatures != nil) {
                        if(YoutubeExtractor.LOGGING){
                            print(YoutubeExtractor.LOG_TAG+" Decipher signatures");
                        }
                        var signature:String?;
                        self.decipheredSignature = nil;
                        if (self.decipherSignatures(encSignatures: encSignatures!)) { //Change Below Condition
                            //if(encSignatures is Format) {
                            //self.jsExecuting.lock();
                            //self.jsExecuting.wait(until: NSDate(timeIntervalSinceNow: 7) as Date) // await(7, TimeUnit.SECONDS);
                            //self.jsExecuting.unlock();
                            
                        }
                        signature = self.decipheredSignature;
                        if (signature == nil) {
                            //return Dictionary(); This also need to check
                        } else {
                            var sigs:[String] = signature!.components(separatedBy: ",");
                            var iterator1 = 0;
                            let encSignaturesKeysArray:NSArray = encSignatures?.allKeys as! NSArray;
                            while(iterator1 < (encSignatures?.count)! /*&& iterator1 < sigs.count*/){
                                
                                let key:Int = encSignaturesKeysArray[iterator1] as! Int;
                                if(key == 36){
                                    let ytFile:YtFile = ytFiles.object(forKey: key) as! YtFile;
                                    var url:String = ytFile.getUrl();
                                    url += "&signature=" + sigs[0];
                                    let formatNeTemp:Format = self.FORMAT_MAP.object(forKey: key) as! Format;
                                    let newFile:YtFile = YtFile(format:formatNeTemp , url: url);
                                    ytFiles.setObject(newFile, forKey: key as NSCopying)
                                    break;
                                }
//                                if(key == 0) {
//                                    let replaceStr:String = encSignatures?.object(forKey: key) as! String;
//                                    dashMpdUrl = dashMpdUrl.replacingOccurrences(of: "/s/"+replaceStr, with:"/signature/"+sigs[iterator1])
//                                } else {
//                                    let ytFile:YtFile = ytFiles.object(forKey: key) as! YtFile;
//                                    var url:String = ytFile.getUrl();
//                                    url += "&signature=" + sigs[iterator1];
//                                    let formatNeTemp:Format = self.FORMAT_MAP.object(forKey: key) as! Format;
//                                    let newFile:YtFile = YtFile(format:formatNeTemp , url: url);
//                                    ytFiles.setObject(newFile, forKey: key as NSCopying)// (key, newFile);
//                                }
                                iterator1 += 1;
                            }
                        }
                    }
                    
                    if (self.parseDashManifest && dashMpdUrl != "") {
                        for i in 0 ..< YoutubeExtractor.DASH_PARSE_RETRIES {
                            self.parseDashManifestFunc(dashMpdUrl: dashMpdUrl,ytFiles: ytFiles); //There is a condition check
                            //print("")
                            break;
                            if(YoutubeExtractor.LOGGING){
                                print(YoutubeExtractor.LOG_TAG+"Failed to parse dash manifest "+String(i+1));
                            }
                        }
                    }
                    
                    
                    if (ytFiles.count == 0) {
                        if(YoutubeExtractor.LOGGING){
                            print(YoutubeExtractor.LOG_TAG+"Stream Map:"+streamMap!);
                        }
                    }else {
                        //return ytFiles;
                    }
//                }
//                directYTTask.resume();
            } else {
                if (self.parseDashManifest) {
                     if (streamMap?.range(of: YoutubeExtractor.patDashManifest1.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                        let matchingStrings = streamMap?.matchingStrings(regex:  YoutubeExtractor.patDashManifest1.pattern);
                        dashMpdUrl = matchingStrings![0][1].removingPercentEncoding!; //addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                     }
                    streamMap = streamMap?.removingPercentEncoding;// URLDecoder.decode(streamMap, "UTF-8");
                }
            }
            
            
            //return ytFiles;
        //}
        
        //mainTask.resume();
        
        return ytFiles;
    }

    private func decipherSignatures(encSignatures:NSMutableDictionary) -> Bool {
        // Assume the functions don't change that much
        var threadWait:Int = 0;
        if (YoutubeExtractor.decipherFunctionName == nil || YoutubeExtractor.decipherFunctions == nil) {
            let decipherFunctUrl:String = "https://s.ytimg.com/yts/jsbin/"+YoutubeExtractor.decipherJsFileName!;

            var javascriptFile:String = " ";
            let getUrl:URL = URL(string:decipherFunctUrl)!;
            let request1: URLRequest = URLRequest(url: getUrl)
            var response: AutoreleasingUnsafeMutablePointer<URLResponse?>?
            var dataVal:Data?
            do{
                dataVal = try NSURLConnection.sendSynchronousRequest(request1, returning: response)
            } catch let error as NSError {
                
            }
            //let urlDecipherTask = URLSession.shared.dataTask(with: getUrl) {(data, response, error) in
                javascriptFile = NSString(data: dataVal!, encoding: String.Encoding.utf8.rawValue)! as String
                
                if(YoutubeExtractor.LOGGING){
                    print(YoutubeExtractor.LOG_TAG+"Decipher FunctURL: "+decipherFunctUrl);
                }
                //if (javascriptFile.range(of: YoutubeExtractor.patSignatureDecFunction.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                let matchingStrings = javascriptFile.matchingStrings(regex: "([\"\\'])signature\\1\\s*,\\s*([a-zA-Z0-9$]+)\\(");
                if(matchingStrings[0].count > 0) {
                    YoutubeExtractor.decipherFunctionName = matchingStrings[0][2];
                    if(YoutubeExtractor.LOGGING){
                        print(YoutubeExtractor.LOG_TAG+"Decipher Functname: "+YoutubeExtractor.decipherFunctionName!);
                    }
                    
                    let tempPattString:String = "(var |\\s|,|;)"+(YoutubeExtractor.decipherFunctionName?.replacingOccurrences(of: "$", with: "\\$"))!+"(=function\\((.{1,3})\\)\\{)";
                    let patMainVariable:NSRegularExpression  = try! NSRegularExpression(pattern:tempPattString, options: NSRegularExpression.Options.dotMatchesLineSeparators);
                    var mainDecipherFunct:String = " ";
                    //if (javascriptFile.range(of: tempPattString, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                        let matchingStringsTemp = javascriptFile.matchingStrings(regex:  tempPattString);
                        //YoutubeExtractor.decipherFunctionName = matchingStrings[0][1];
                    if(matchingStringsTemp[0].count>0){
                        mainDecipherFunct = "var "+YoutubeExtractor.decipherFunctionName!+matchingStringsTemp[0][2];
                        
                    }else{
                        let tempPattString1:String = "function "+(YoutubeExtractor.decipherFunctionName?.replacingOccurrences(of: "$", with: "\\$"))!+"(\\((.{1,3})\\)\\{)";
                        let patMainFunction:NSRegularExpression  = try! NSRegularExpression(pattern:tempPattString1, options: NSRegularExpression.Options.dotMatchesLineSeparators);
                        if (javascriptFile.range(of: patMainFunction.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                            let matchingStrings = javascriptFile.matchingStrings(regex:  patMainFunction.pattern);
                            mainDecipherFunct = "function "+YoutubeExtractor.decipherFunctionName!+matchingStrings[0][2];
                        }
                        
                    }
                    let count = javascriptFile.matchingStringEnd(regex: tempPattString);
                    var startIndex:Int = Int(count)!;
                    var braces:Int = 1;
                    var i:Int = startIndex;

                    for char in javascriptFile {
                        if (braces == 0 && (startIndex+5) < i) {
                            let lowerBound = String.Index.init(encodedOffset: startIndex)
                            let upperBound = String.Index.init(encodedOffset: i)
                            let mySubstring:String = javascriptFile[lowerBound...upperBound];
                            mainDecipherFunct = mainDecipherFunct+mySubstring+";";
                            break;
                        }
                        if char == "{" {
                            braces += 1
                        } else if char == "}" {
                            braces -= 1
                        }
                        i+=1;
                    }
                    var tempArray = mainDecipherFunct.components(separatedBy: "\n");
                    YoutubeExtractor.decipherFunctions = tempArray[0]
                    ;
                    
                    
                    
                    // Search the main function for extra functions and variables
                    // needed for deciphering
                    // Search for variables
                    let matchingStringsDecipherFunct = mainDecipherFunct.matchingStrings(regex:  YoutubeExtractor.patVariableFunction.pattern);
                    if(matchingStringsDecipherFunct[0].count>0){
                        var iter = 0;
                        let countTenmp = matchingStringsDecipherFunct.count
                        outerLoop: while(iter < countTenmp){
                   
                            let variableDef:String = "var "+matchingStringsDecipherFunct[iter][2]+"={";
                            iter += 1;
                            if (YoutubeExtractor.decipherFunctions?.contains(variableDef))! {
                                continue;
                            }
                           
                           startIndex = self.indexOfLocal(source: javascriptFile, substring: variableDef)! + variableDef.count;
                            if(startIndex == 0){
                                continue;
                            }
                            braces = 1;
                            i=startIndex;
                            
                            for char in javascriptFile {
                                if (braces == 0) {
                                    let lowerBound = String.Index.init(encodedOffset: startIndex)  //1018341 and 1018467
                                    let upperBound = String.Index.init(encodedOffset: startIndex+126)//1017876)//i)
                                    let mySubstring:String = javascriptFile[lowerBound...upperBound];
                                    YoutubeExtractor.decipherFunctions = YoutubeExtractor.decipherFunctions!+variableDef+mySubstring+";";
                                    //break;
                                    break outerLoop;
                                }
                                if char == "{" {
                                    braces += 1
                                } else if char == "}" {
                                    braces -= 1
                                }
                                i+=1;
                            }
                        }//While End
                    }
                    
                    
                    // Search for functions
                    if (mainDecipherFunct.range(of: YoutubeExtractor.patFunction.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                        let matchingStrings = mainDecipherFunct.matchingStrings(regex:  YoutubeExtractor.patFunction.pattern);
                         var functionDef:String = "function "+matchingStrings[0][2]+"(";
                        if (YoutubeExtractor.decipherFunctions?.contains(functionDef))! {
                            //continue;
                        }
                        startIndex = self.indexOfLocal(source: javascriptFile, substring: functionDef)! + functionDef.count;
                        if(startIndex == 0){
                            //continue;
                        }
                        braces = 1;
                        for i in startIndex ..< javascriptFile.count {
                            if (braces == 0) {
                                let start = javascriptFile.index(javascriptFile.startIndex, offsetBy: startIndex);
                                let end = javascriptFile.index(javascriptFile.endIndex, offsetBy: i)
                                let range = start..<end
                                let mySubstring:String = javascriptFile[range];
                                YoutubeExtractor.decipherFunctions = YoutubeExtractor.decipherFunctions!+functionDef+mySubstring+";";
                                break;
                            }
                            let jsFileChars = Array(javascriptFile);
                            if (jsFileChars[i] == "{"){
                                braces = braces+1;
                            }
                                
                            else if (jsFileChars[i] == "}"){
                                braces = braces-1;
                            }
                        }
                    }
                    if(YoutubeExtractor.LOGGING){
                        print(YoutubeExtractor.LOG_TAG+"Decipher Function: " + YoutubeExtractor.decipherFunctions!);
                    }
                    self.decipherViaWebView(encSignatures: encSignatures);
                    if (YoutubeExtractor.CACHING) {
                        self.writeDeciperFunctToChache();
                    }
                    
                    //threadWait == 1;
                    //return true;
                } else{
                     //return false;
                }
            //}
            //urlDecipherTask.resume();
       
        } else {
            self.decipherViaWebView(encSignatures: encSignatures);
            //return false;
        }
        return true;
    }

    private func parseDashManifestFunc(dashMpdUrl:String,ytFiles:NSMutableDictionary){
    
        let tempPattString:String = "<BaseURL yt:contentLength=\"[0-9]+?\">(.+?)</BaseURL>";
        let patBaseUrl:NSRegularExpression  = try! NSRegularExpression(pattern:tempPattString, options: NSRegularExpression.Options.dotMatchesLineSeparators);
        let getUrl:URL = URL(string:dashMpdUrl)!;
        var dashManifest:String = " ";
        let urlDashManifestTask = URLSession.shared.dataTask(with: getUrl) {(data, response, error) in
            dashManifest = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
            
            if (dashManifest == ""){
                return;
            }
            //Here it is while loop not if condition
            if (dashManifest.range(of: patBaseUrl.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                let matchingStrings = dashManifest.matchingStrings(regex:  patBaseUrl.pattern);
                var itag:Int?;
                var url:String = matchingStrings[0][1];
                if (url.range(of: YoutubeExtractor.patItag.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) == nil){
                    let matchingStrings = url.matchingStrings(regex:  YoutubeExtractor.patItag.pattern);
                    itag = Int(matchingStrings[0][1]);
                    let formatObject:Format = self.FORMAT_MAP.object(forKey: itag) as! Format;
                    if(formatObject == nil) {
                        //continue;
                    }
                    if(!self.includeWebM && formatObject.getExt()=="webm"){
                        //continue;
                    }
                    url = url.replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: ",", with: "%2C").replacingOccurrences(of: "mime=audio/", with: "mime=audio%2F").replacingOccurrences(of: "mime=video/", with: "mime=video%2F");
                    let ytFileTemp:YtFile = YtFile(format:formatObject, url:url);
                    ytFiles.setObject(ytFileTemp, forKey: itag! as NSCopying);
                }
            }
        }
        urlDashManifestTask.resume();
        
    }

    
    private func parseVideoMeta(getVideoInfo:String) {
        var isLiveStream = false;
        var title:String = " ";
        var author:String = " ";
        var channelId:String = " ";
        var viewCount:CLongLong = 0;
        var length:CLongLong = 0;
        
        if (getVideoInfo.range(of: YoutubeExtractor.patTitle.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) != nil){
            let matchingStrings = getVideoInfo.matchingStrings(regex:  YoutubeExtractor.patTitle.pattern);
            title = matchingStrings[0][1];
            //print("Printed Title: "+title!);
        }
        if (getVideoInfo.range(of: YoutubeExtractor.patHlsvp.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) != nil){
            isLiveStream = true;
        }
        if (getVideoInfo.range(of: YoutubeExtractor.patAuthor.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) != nil){
            let matchingStrings = getVideoInfo.matchingStrings(regex:  YoutubeExtractor.patAuthor.pattern);
            author = matchingStrings[0][1];
            //print("Printed author: "+author!);
        }
        if (getVideoInfo.range(of: YoutubeExtractor.patChannelId.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) != nil){
            let matchingStrings = getVideoInfo.matchingStrings(regex:  YoutubeExtractor.patChannelId.pattern);
            channelId = matchingStrings[0][1];
            //print("Printed channelId: "+channelId!);
        }
        if (getVideoInfo.range(of: YoutubeExtractor.patLength.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) != nil){
            let matchingStrings = getVideoInfo.matchingStrings(regex:  YoutubeExtractor.patLength.pattern);
            length = NumberFormatter().number(from: matchingStrings[0][1]) as! CLongLong
           // print("Printed length: "+matchingStrings[0][1]);
        }
        if (getVideoInfo.range(of: YoutubeExtractor.patViewCount.pattern, options:String.CompareOptions.regularExpression, range: nil, locale: nil) != nil){
            let matchingStrings = getVideoInfo.matchingStrings(regex:  YoutubeExtractor.patViewCount.pattern);
            viewCount = NumberFormatter().number(from: matchingStrings[0][1]) as! CLongLong
            //print("Printed PVC: "+matchingStrings[0][1]);
        }

        videoMeta = VideoMeta(videoId:videoID!, title:title, author:author, channelId:channelId, videoLength:length, viewCount:viewCount, isLiveStream:isLiveStream);
    }

    
    private func readDecipherFunctFromCache() {
        let textArray:[String] = String(self.readFromFile()).components(separatedBy:"<@SPLITTER@>");
        if(textArray.count < 2){
            YoutubeExtractor.decipherJsFileName = nil
            YoutubeExtractor.decipherFunctionName = nil
            YoutubeExtractor.decipherFunctions = nil
        }else{
            YoutubeExtractor.decipherJsFileName = textArray[0];
            YoutubeExtractor.decipherFunctionName = textArray[1];
            YoutubeExtractor.decipherFunctions = textArray[2];
        }

    }

    /**
     * Parse the dash manifest for different dash streams and high quality audio. Default: false
     */
    public func setParseDashManifest(parseDashManifest:Bool) {
        self.parseDashManifest = parseDashManifest;
    }


    /**
     * Include the webm format files into the result. Default: true
     */
    public func setIncludeWebM(includeWebM:Bool) {
        self.includeWebM = includeWebM;
    }


    /**
     * Set default protocol of the returned urls to HTTP instead of HTTPS.
     * HTTP may be blocked in some regions so HTTPS is the default value.
     * <p/>
     * Note: Enciphered videos require HTTPS so they are not affected by
     * this.
     */
    public func setDefaultHttpProtocol(useHttp:Bool) {
        self.useHttp = useHttp;
    }

    private func writeDeciperFunctToChache() {
        var writeString:String = YoutubeExtractor.decipherJsFileName!+"<@SPLITTER@>"+YoutubeExtractor.decipherFunctionName!+"<@SPLITTER@>"+YoutubeExtractor.decipherFunctions!;
        self.writeToTextFile(text: writeString);
    }

    private func decipherViaWebView(encSignatures:NSMutableDictionary) {
        //if (context == null) {
            //return;
        //}
        var countTmp:Int = YoutubeExtractor.decipherFunctions!.count - 2;
        let lowerBound = String.Index.init(encodedOffset: 0)
        let upperBound = String.Index.init(encodedOffset: countTmp)//i)
        var tempDecipherFunc:String = String();
        tempDecipherFunc = (YoutubeExtractor.decipherFunctions?[lowerBound...upperBound])!;
            var stringBuilder:String = tempDecipherFunc+" function decipher(";
            var stringReturn:[String] = [] ;
            stringBuilder = stringBuilder.replacingOccurrences(of: "(a){a)", with: "(a)")
            stringBuilder = stringBuilder.replacingOccurrences(of: "\n", with: " ")
            stringBuilder += "){return ";
            var eSignatures:NSArray = encSignatures.allKeys as NSArray;
            for  i in 0 ..< eSignatures.count {
                let key:Int = eSignatures.object(at: i) as! Int;
                if (i < eSignatures.count - 1){
                    let appendString:String = encSignatures.object(forKey: key) as! String;
                    
                    //stringReturn.append(""+appendString)
                    //let strTemp:String = String("'"+appendString+"'ca");
                    //let appendString1:String = encSignatures.object(forKey: 0) as! String;
                    if(key == 36) {
                        //stringReturn = stringReturn+appendString+",";
                        stringBuilder = stringBuilder+YoutubeExtractor.decipherFunctionName!+"('"+appendString+"')"+"\n";
                        stringReturn.append(""+appendString+"")
                    }
                    //stringReturn.append(""+appendString+"")
                    //stb.append(decipherFunctionName).append("('").append(encSignatures.get(key)).
                    //append("')+\"\\n\"+");
                }
                else{
//                    let appendString:String = encSignatures.object(forKey: key) as! String;
//                    stringBuilder = stringBuilder+YoutubeExtractor.decipherFunctionName!+"('"+appendString+"')";
//                    stringReturn.append(""+appendString);
                    //stringReturn = stringReturn+appendString+",";
                    //stringReturn[String(i)] = appendString;
                    //stb.append(decipherFunctionName).append("('").append(encSignatures.get(key)).
                    //append("')");
                }
                
            }
        
//            for  i in 0 ..< 1 {
//                let key:Int = eSignatures.object(at: i) as! Int;
//                if (i < eSignatures.count - 1){
//                    let appendString:String = encSignatures.object(forKey: key) as! String;
//                    //stringBuilder = stringBuilder+YoutubeExtractor.decipherFunctionName!+"(\""+appendString+"\")"+"\n";
//                    stringReturn = stringReturn+""+appendString+",";
//                }
//
//            }
            //stringBuilder = stringBuilder+YoutubeExtractor.decipherFunctionName!+"('"+stringReturn+"')";
            stringBuilder += "};decipher();"
            stringBuilder = stringBuilder.replacingOccurrences(of: "\\'", with: "'")
            decipheredSignature = "SIGNATURE NEED TO BE FINALIZED";
            //let ramarao:NSRegularExpression = try! NSRegularExpression(pattern:stringBuilder, options: NSRegularExpression.Options.dotMatchesLineSeparators);
        //                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 let NewStr:String = stringBuildera.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
        
//        let jsSource = "var KK=function(a){a=a.split(\"\");JK.Lw(a,1);JK.nk(a,3);JK.Ew(a,35);JK.nk(a,1);JK.Lw(a,4);JK.Ew(a,54);return a.join(\"\")};var JK={nk:function(a,b){a.splice(0,b)}, Lw:function(a){a.reverse()}, Ew:function(a,b){var c=a[0];a[0]=a[b%a.length];a[b%a.length]=c}}; function decipher(){return KK(\'EFF1800815BBC2118692D2CA6625E2AE651C7892.2D6EC0B4B4E7440C75887290538B749E94D4C9B0FB0F,1599D95AE8EF5A621D3526D4E517C534DFC8BCCB.718F0120278C790DFC0845F0594476AF31B520714714,C053604813C78F4BA6230941AE74B1376FBF1784.33C72AFBB839158EB5BF225C0FD1E8AEC60A748AA8AA,4218C0D08D6EB59564D6E9AD80D33E4AE507BE1E.5F68D8E18E89FAF86D494DB1412D1E5DEA2BF818D18D,0B5570274A7D9AAD697A7849EF559C7B14C53655.A9CE77D78E0B20A47221C74E108A828DCD2CBDE77E77,AB94C0BC21B41E30FA7EEE850200977A0315B95A.5CD400DE70DC64C034F9DB7AD5DEC2A24D78E8B04B04,CB4F81E07338422243E186552A9529A87403314D.59F93966606F1C34E3CF8E7BACD18FA543FB2C690690,6ECE636138A0E4EFA13953397DEB255DCFF108F7.CD73C98E06E1160FA24FA105A0CED0874FCD6919D19D,0C5C3DD0F671EBA990D3423AA9FE44746340AA54.185C68F17F31D0FB43DCD9349CBADEF622FA2F180180,B366530466494D258057DAC20D14F322B324D074.5F9AF3A49F250AFB641E42448B42476DB4EB66330330,1548A0C0CCCEB3EE367DC44928B0FE820716A6D8.07677AE5DF9019B62BE6AF95FB5C35ADA5FF474AF4AF\')};decipher();"
            //let arr = Array(stringReturn.values);
            //print(arr)
            let context = JSContext()
            context?.evaluateScript(stringBuilder)
            print(stringBuilder+"  And  "+stringReturn[0])
            //stringReturn = stringReturn.replacingOccurrences(of: "\'", with: "            ");

            let testFunction = context?.objectForKeyedSubscript(YoutubeExtractor.decipherFunctionName!)
            let result = testFunction?.call(withArguments:stringReturn);// ["EFF1800815BBC2118692D2CA6625E2AE651C7892.2D6EC0B4B4E7440C75887290538B749E94D4C9B0FB0F,1599D95AE8EF5A621D3526D4E517C534DFC8BCCB.718F0120278C790DFC0845F0594476AF31B520714714,C053604813C78F4BA6230941AE74B1376FBF1784.33C72AFBB839158EB5BF225C0FD1E8AEC60A748AA8AA,4218C0D08D6EB59564D6E9AD80D33E4AE507BE1E.5F68D8E18E89FAF86D494DB1412D1E5DEA2BF818D18D,0B5570274A7D9AAD697A7849EF559C7B14C53655.A9CE77D78E0B20A47221C74E108A828DCD2CBDE77E77,AB94C0BC21B41E30FA7EEE850200977A0315B95A.5CD400DE70DC64C034F9DB7AD5DEC2A24D78E8B04B04,CB4F81E07338422243E186552A9529A87403314D.59F93966606F1C34E3CF8E7BACD18FA543FB2C690690,6ECE636138A0E4EFA13953397DEB255DCFF108F7.CD73C98E06E1160FA24FA105A0CED0874FCD6919D19D,0C5C3DD0F671EBA990D3423AA9FE44746340AA54.185C68F17F31D0FB43DCD9349CBADEF622FA2F180180,B366530466494D258057DAC20D14F322B324D074.5F9AF3A49F250AFB641E42448B42476DB4EB66330330,1548A0C0CCCEB3EE367DC44928B0FE820716A6D8.07677AE5DF9019B62BE6AF95FB5C35ADA5FF474AF4AF"])
                print("The testFunc: "+(testFunction?.toString())!+" The Result: "+(result?.toString())!);
                decipheredSignature = (result?.toString())!;
//            new Handler(Looper.getMainLooper()).post(new Runnable() {
//
//            @Override
//            public void run() {
//            new JsEvaluator(context).evaluate(stb.toString(), new JsCallback() {
//            @Override
//            public void onResult(String result) {
//            lock.lock();
//            try {
//            decipheredSignature = result;
//            jsExecuting.signal();
//            } finally {
//            lock.unlock();
//            }
//            }
//
//            @Override
//            public void onError(String errorMessage) {
//            lock.lock();
//            try {
//            if(LOGGING)
//            Log.e(LOG_TAG, errorMessage);
//                jsExecuting.signal();
//            } finally {
//            lock.unlock();
//            }
//            }
//            });
//            }
//            });
    }
    
}//EOF
