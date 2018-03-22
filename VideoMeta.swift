//
//  VideoMeta.swift
//  MZAESController
//
//  Created by apple on 21/02/18.
//  Copyright © 2018 Ami Technologies. All rights reserved.
//

import UIKit
import Foundation
public class VideoMeta: NSObject {
    
    private static let IMAGE_BASE_URL:String = "http://i.ytimg.com/vi/";

    private var videoId:String;
    private var title:String;

    private var author:String;
    private var channelId:String;

    private var videoLength:CLongLong;
    private var viewCount:CLongLong;

    private var liveStream:Bool;

    init(videoId:String, title:String, author:String, channelId:String, videoLength:CLongLong, viewCount:CLongLong, isLiveStream:Bool){
        self.videoId = videoId;
        self.title = title;
        self.author = author;
        self.channelId = channelId;
        self.videoLength = videoLength;
        self.viewCount = viewCount;
        self.liveStream = isLiveStream;
    }
    
    // 120 x 90
    public func getThumbUrl() -> String{
        return VideoMeta.IMAGE_BASE_URL + videoId + "/default.jpg";
    }

    // 320 x 180
    public func getMqImageUrl() -> String {
        return VideoMeta.IMAGE_BASE_URL + videoId + "/mqdefault.jpg";
    }

    // 480 x 360
    public func getHqImageUrl() -> String {
        return VideoMeta.IMAGE_BASE_URL + videoId + "/hqdefault.jpg";
    }

    // 640 x 480
    public func getSdImageUrl() -> String {
        return VideoMeta.IMAGE_BASE_URL + videoId + "/sddefault.jpg";
    }

    // Max Res
    public func getMaxResImageUrl() -> String {
        return VideoMeta.IMAGE_BASE_URL + videoId + "/maxresdefault.jpg";
    }

    public func getVideoId() -> String {
        return videoId;
    }

    public func getTitle() -> String {
        return title;
    }

    public func getAuthor() -> String {
        return author;
    }

    public func getChannelId() -> String {
        return channelId;
    }

    public func isLiveStream() -> Bool {
        return liveStream;
    }

    /**
     * The video length in seconds.
     */
    public func getVideoLength() -> CLongLong{
        return videoLength;
    }

    public func getViewCount() -> CLongLong {
        return viewCount;
    }

    public override func isEqual(_ object: Any?) -> Bool {
        
        if let object = object as? VideoMeta {
            return self == object
        }else if !(object is VideoMeta) || (object == nil)  {
            return false;
        }
        
        let videoMeta:VideoMeta = (object as? VideoMeta)!;
        
        if self.videoLength != videoMeta.videoLength {
            return false;
        }
        if self.viewCount != videoMeta.viewCount {
            return false;
        }
        if self.liveStream != videoMeta.liveStream {
            return false;
        }
        if self.videoId != nil ? self.videoId != videoMeta.videoId : videoMeta.videoId != nil {
            return false;
        }
        if self.title != videoMeta.title {
            return false;
        }
        if self.author != nil ? self.author != videoMeta.author : videoMeta.author != nil {
            return false;
        }
        return self.channelId != nil ? self.channelId != videoMeta.channelId : videoMeta.channelId != nil;
    }
//
//    @Override
//    public int hashCode() {
//    int result = videoId != null ? videoId.hashCode() : 0;
//    result = 31 * result + (title != null ? title.hashCode() : 0);
//    result = 31 * result + (author != null ? author.hashCode() : 0);
//    result = 31 * result + (channelId != null ? channelId.hashCode() : 0);
//    result = 31 * result + (int) (videoLength ^ (videoLength >>> 32));
//    result = 31 * result + (int) (viewCount ^ (viewCount >>> 32));
//    result = 31 * result + (isLiveStream ? 1 : 0);
//    return result;
//    }
//
//    @Override
//    public String toString() {
//    return "VideoMeta{" +
//    "videoId='" + videoId + '\'' +
//    ", title='" + title + '\'' +
//    ", author='" + author + '\'' +
//    ", channelId='" + channelId + '\'' +
//    ", videoLength=" + videoLength +
//    ", viewCount=" + viewCount +
//    ", isLiveStream=" + isLiveStream +
//    '}';
//    }
}
