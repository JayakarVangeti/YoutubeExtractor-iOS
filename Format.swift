//
//  Format.swift
//  MZAESController
//
//  Created by apple on 19/02/18.
//  Copyright © 2018 Ami Technologies. All rights reserved.
//

import UIKit
import Foundation
public class Format: NSObject {
    
    public enum VCodec: String {
        case H263
        case H264
        case MPEG4
        case VP8
        case VP9
        case NONE
    }
    
    public enum ACodec: String {
        case MP3
        case AAC
        case VORBIS
        case OPUS
        case NONE
    }
    
    private var itag:Int?
    private var ext:String?
    private var height:Int?
    private var fps:Int?
    private var vCodec:VCodec?
    private var aCodec:ACodec?
    private var audioBitrate:Int?
    private var dashContainer:Bool?
    private var hlsContent:Bool?
    
    init(itag:Int, ext:String, height:Int, vCodec:VCodec, aCodec:ACodec, isDashContainer:Bool) {
        self.itag = itag;
        self.ext = ext;
        self.height = height;
        self.fps = 30;
        self.audioBitrate = -1;
        self.dashContainer = isDashContainer;
        self.hlsContent = false;
    }
    
    init(itag:Int, ext:String, vCodec:VCodec, aCodec:ACodec, audioBitrate:Int, isDashContainer:Bool) {
        self.itag = itag;
        self.ext = ext;
        self.height = -1;
        self.fps = 30;
        self.audioBitrate = audioBitrate;
        self.dashContainer = isDashContainer;
        self.hlsContent = false;
    }
    
    init(itag:Int, ext:String, height:Int, vCodec:VCodec, aCodec:ACodec, audioBitrate:Int, isDashContainer:Bool) {
        self.itag = itag;
        self.ext = ext;
        self.height = height;
        self.fps = 30;
        self.audioBitrate = audioBitrate;
        self.dashContainer = isDashContainer;
        self.hlsContent = false;
    }
 
    init(itag:Int, ext:String, height:Int, vCodec:VCodec, aCodec:ACodec, audioBitrate:Int, isDashContainer:Bool, isHlsContent:Bool) {
        self.itag = itag;
        self.ext = ext;
        self.height = height;
        self.fps = 30;
        self.audioBitrate = audioBitrate;
        self.dashContainer = isDashContainer;
        self.hlsContent = isHlsContent;
    }

    init(itag:Int, ext:String, height:Int, vCodec:VCodec, fps:Int, aCodec:ACodec, isDashContainer:Bool) {
        self.itag = itag;
        self.ext = ext;
        self.height = height;
        self.fps = fps;
        self.audioBitrate = -1;
        self.dashContainer = isDashContainer;
        self.hlsContent = false;
    }
    

    
    /**
     * Get the frames per second
     */
    public func getFps() -> Int {
        return fps!;
    }

    /**
     * Audio bitrate in kbit/s or -1 if there is no audio track.
     */
    public func getAudioBitrate() -> Int{
    return audioBitrate!;
    }
    
    /**
     * An identifier used by youtube for different formats.
     */
    public func getItag() -> Int{
        return itag!;
    }
    
    /**
     * The file extension and conainer format like "mp4"
     */
    public func getExt() -> String{
        return ext!;
    }
    
    public func isDashContainer() -> Bool{
        return dashContainer!;
    }
    
    public func getAudioCodec() -> ACodec{
        return aCodec!;
    }
    
    public func getVideoCodec() -> VCodec{
        return vCodec!;
    }
    
    public func isHlsContent() -> Bool{
        return hlsContent!;
    }
    
    /**
     * The pixel height of the video stream or -1 for audio files.
     */
    public func getHeight() -> Int{
        return height!;
    }

    // I've a doubt in this method at 146
    override public func isEqual(_ object: Any?) -> Bool {
       
        if let object = object as? Format {
            return self == object
        }else if !(object is Format) || (object == nil)  {
            return false;
        }
        
        let format:Format = (object as? Format)!;
        
        if self.itag != format.itag {
            return false;
        }
        if self.height != format.height {
            return false;
        }
        if self.fps != format.fps {
            return false;
        }
        if self.audioBitrate != format.audioBitrate {
            return false;
        }
        if self.dashContainer != format.dashContainer {
            return false;
        }
        if self.hlsContent != format.hlsContent {
            return false;
        }
        if self.vCodec != format.vCodec {
            return false;
        }
        if self.ext != nil ? self.ext != format.ext : format.ext != nil {
            return false;
        }
        return self.aCodec == format.aCodec;
    }
    
//    public func hashCode() -> Int {
//        var result:Int = itag!;
//        result = 31 * result + (ext != nil ? ext.hashCode() : 0);
//        result = 31 * result + height!;
//        result = 31 * result + fps!;
//        result = 31 * result + (vCodec != nil ? vCodec.hashCode() : 0);
//        result = 31 * result + (aCodec != nil ? aCodec.hashCode() : 0);
//        result = 31 * result + audioBitrate!;
//        result = 31 * result + (dashContainer! ? 1 : 0);
//        result = 31 * result + (hlsContent! ? 1 : 0);
//        return result;
//        return result;
//    }
    
//    @Override
//    public int hashCode() {
//    int result = itag;
//    result = 31 * result + (ext != null ? ext.hashCode() : 0);
//    result = 31 * result + height;
//    result = 31 * result + fps;
//    result = 31 * result + (vCodec != null ? vCodec.hashCode() : 0);
//    result = 31 * result + (aCodec != null ? aCodec.hashCode() : 0);
//    result = 31 * result + audioBitrate;
//    result = 31 * result + (isDashContainer ? 1 : 0);
//    result = 31 * result + (isHlsContent ? 1 : 0);
//    return result;
//    }
//    
//    @Override
//    public String toString() {
//    return "Format{" +
//    "itag=" + itag +
//    ", ext='" + ext + '\'' +
//    ", height=" + height +
//    ", fps=" + fps +
//    ", vCodec=" + vCodec +
//    ", aCodec=" + aCodec +
//    ", audioBitrate=" + audioBitrate +
//    ", isDashContainer=" + isDashContainer +
//    ", isHlsContent=" + isHlsContent +
//    '}';
//    }
}
