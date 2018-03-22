//
//  YtFile.swift
//  MZAESController
//
//  Created by apple on 19/02/18.
//  Copyright © 2018 Ami Technologies. All rights reserved.
//

import UIKit
import Foundation
public class YtFile: NSObject {
  
    private var format:Format;
    private var url:String = "";
    
    init(format:Format, url:String) {
        self.format = format;
        self.url = url;
    }
    
    /**
     * The url to download the file.
     */
    public func getUrl() -> String{
        return url;
    }
    
    /**
     * Format data for the specific file.
     */
    public func getFormat() -> Format{
        return format;
    }
    
    /**
     * Format data for the specific file.
     */
    @available(*, deprecated)
    public func  getMeta() -> Format{
        return format;
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        
        if let object = object as? YtFile {
            return self == object
        }else if !(object is YtFile) || (object == nil)  {
            return false;
        }
        
        let ytFile:YtFile = (object as? YtFile)!;
        
        if (format != nil ? !format.isEqual(ytFile.format) : ytFile.format != nil){
            return false;
        }
        
        return url != nil ? url.isEqual(ytFile.url) : ytFile.url == nil;
    }
    
    
    
    
//    @Override
//    public boolean equals(Object o) {
//    if (this == o) return true;
//    if (o == null || getClass() != o.getClass()) return false;
//
//    YtFile ytFile = (YtFile) o;
//
//    if (format != null ? !format.equals(ytFile.format) : ytFile.format != null) return false;
//    return url != null ? url.equals(ytFile.url) : ytFile.url == null;
//    }
//
//    @Override
//    public int hashCode() {
//    int result = format != null ? format.hashCode() : 0;
//    result = 31 * result + (url != null ? url.hashCode() : 0);
//    return result;
//    }
//
//    @Override
//    public String toString() {
//    return "YtFile{" +
//    "format=" + format +
//    ", url='" + url + '\'' +
//    '}';
//    }

}
