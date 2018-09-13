//
//  WebRequester.swift
//  Quest
//
//  Created by MAC-4 on 9/11/17.
//  Copyright © 2017 Prismetric-MD2. All rights reserved.
//

import Foundation
import UIKit

enum Status {
    case SUCCESS, INTERNETNOTCONNECT, WSERROR, TIMEOUT, ERROR, SERVERCONNECTION, NOTFOUND, JSONSERIALIZATION, UNSUPPORTEDURL
    
    func errorMsg() -> String {
        switch self {
        case .SUCCESS:
            return ""
        case .INTERNETNOTCONNECT:
            return "The internet connection appears to be offline."
        case .WSERROR:
            return "Something went wrong please try again later"
        case .TIMEOUT:
            return "Request Timeout please try again later"
        case .ERROR:
            return "Something went wrong please try again later"
        case .SERVERCONNECTION:
            return "Could not connect to server please try again later"
        case .NOTFOUND:
            return "No records founds."
        case .JSONSERIALIZATION:
            return "The data could not be read because it isn't in the correct format"
        case .UNSUPPORTEDURL:
            return "Your URL is not valid"
        }
    }
}

class WebRequester: NSObject {
    
    static let shared = WebRequester()
    
    let session = URLSession.shared
    
    //MARK:- Request with parameter string
    func request(urlStr:String, parameter:String, token:String? = nil, callback:@escaping (_ status:Status, _ result:NSDictionary?) -> Void) {
        
        let url = URL(string: BaseURL + urlStr)
        
        debugPrint("=====================")
        debugPrint(url ?? "")
        debugPrint(parameter)
        debugPrint("=====================")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = parameter.data(using: String.Encoding.utf8)
        
        if token == nil {
            debugPrint("Token :", User.getUser().token)
            request.setValue(User.getUser().token, forHTTPHeaderField: "Authorization")
        }
        else {
            print("Token :", (token ?? ""))
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                self.checkResponse(data: data, error: error, callback: {status, result in
                    debugPrint(status)
                    debugPrint(result ?? "")
                    callback(status, result)
                })
            }
        }
        task.resume()
    }
    
    //MARK:- Request with parameter Dictionary
    func request(urlStr:String, parameter:[String:Any], token:String? = nil, callback:@escaping (_ status:Status, _ data:NSDictionary?) -> Void) {
        
        let url = URL(string: BaseURL + urlStr)
        
        debugPrint("=====================")
        debugPrint(url ?? "")
        debugPrint(parameter)
        debugPrint("=====================")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = parameter.stringFromHttpParameters().data(using: String.Encoding.utf8)
        
        if token == nil {
            debugPrint("Token :", User.getUser().token)
            request.setValue(User.getUser().token, forHTTPHeaderField: "Authorization")
        }
        else {
            print("Token :", (token ?? ""))
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
    
        let task = session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                self.checkResponse(data: data, error: error, callback: {status, result in
                    debugPrint(status)
                    debugPrint(result ?? "")
                    callback(status, result)
                })
            }
        }
        task.resume()
    }
    
    
    //MARK:- Multipart with image
    func multipartRequest(urlStr:String, parameter:[String:Any], image:UIImage?, fileKey:String, callback:@escaping (_ status:Status, _ data:NSDictionary?) -> Void) {
        
        let requestURL = BaseURL + urlStr
        
        debugPrint("=====================")
        debugPrint(requestURL)
        debugPrint(parameter)
        debugPrint("=====================")
        
        var request = URLRequest(url: URL(string:requestURL)!)
        request.httpMethod = "POST"
        request.setValue(User.getUser().token, forHTTPHeaderField: "Authorization")
        
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var imageData:NSData? = nil
        if image != nil {
            imageData = UIImageJPEGRepresentation(image!, 0.9) as NSData?
        }
        
        request.httpBody = createBodyWithParameters(parameters: parameter, filePathKey: fileKey, imageDataKey: imageData, boundary: boundary) as Data
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            DispatchQueue.main.async {
                self.checkResponse(data: data, error: error, callback: {status, result in
                    debugPrint(status)
                    debugPrint(result ?? "")
                    callback(status, result)
                })
            }
        }
        task.resume()
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    func createBodyWithParameters(parameters: [String: Any]?, filePathKey: String?, imageDataKey: NSData?, boundary: String) -> NSData {
        let body = NSMutableData();
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
        }
        
        if imageDataKey != nil {
            let filename = "user-profile.jpeg"
            let mimetype = "image/jpeg"
            
            body.appendString(string: "--\(boundary)\r\n")
            body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
            body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
            body.append(imageDataKey! as Data)
            body.appendString(string: "\r\n")
        }
        
        body.appendString(string: "--\(boundary)--\r\n")
        
        return body
    }
    
    //MARK:- Multipart with multiple-images
    func multipartRequestWithImages(urlStr:String, parameter:[String:Any], images:[UIImage], fileKey:[String], callback:@escaping (_ status:Status, _ data:NSDictionary?) -> Void) {
        
        let requestURL = BaseURL + urlStr
        
        debugPrint("=====================")
        debugPrint(requestURL)
        debugPrint(parameter)
        debugPrint("=====================")
        
        var request = URLRequest(url: URL(string:requestURL)!)
        request.httpMethod = "POST"
//        request.setValue(User.current.getToken(), forHTTPHeaderField: "Authorization")
        
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var imageData:[NSData?] = [NSData?]()
        for image in images {
            imageData.append(UIImageJPEGRepresentation(image, 0.9) as NSData?)
        }
        
        request.httpBody = createBodyWithParametersAndImages(parameters: parameter, filePathKey: fileKey, imageDataKey: imageData as! [NSData], boundary: boundary) as Data
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            DispatchQueue.main.async {
                self.checkResponse(data: data, error: error, callback: {status, result in
                    debugPrint(status)
                    debugPrint(result ?? "")
                    callback(status, result)
                })
            }
        }
        task.resume()
    }
    
    func createBodyWithParametersAndImages(parameters: [String: Any]?, filePathKey: [String], imageDataKey: [NSData], boundary: String) -> NSData {
        let body = NSMutableData();
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
        }
        
        for index in 0..<imageDataKey.count {
            let data = imageDataKey[index]
            
            let filename = "image.jpeg"
            let mimetype = "image/jpeg"
            
            body.appendString(string: "--\(boundary)\r\n")
            body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey[index])\"; filename=\"\(filename)\"\r\n")
            body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
            body.append(data as Data)
            body.appendString(string: "\r\n")
            
        }
        
        body.appendString(string: "--\(boundary)--\r\n")
        
        return body
    }

    
    //MARK:- Check Response
    func checkResponse(data:Data?, error:Error?, callback:(_:Status, _:NSDictionary?) -> Void) {
        if error == nil {
            if data == nil {
                print(Status.ERROR.errorMsg)
                callback(.ERROR, nil)
            }
            else {
                do {
                    let jsonObj = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                    if let dic = jsonObj as? NSDictionary {
                        callback(.SUCCESS, dic)
                    }
                    else {
                        print(Status.JSONSERIALIZATION.errorMsg)
                        callback(.JSONSERIALIZATION, nil)
                    }
                }
                catch {
                    print(Status.JSONSERIALIZATION.errorMsg)
                    callback(.JSONSERIALIZATION, nil)
                }
            }
        }
        else {
            if let err = error as NSError? {
                if err.code == -1009 {
                    print(Status.INTERNETNOTCONNECT.errorMsg)
                    callback(.INTERNETNOTCONNECT, nil)
                }
                else if err.code == -1001 || err.code == 408 {
                    print(Status.TIMEOUT.errorMsg)
                    callback(.TIMEOUT, nil)
                }
                else if err.code == -1004 {
                    print(Status.SERVERCONNECTION.errorMsg)
                    callback(.SERVERCONNECTION, nil)
                }
                else if err.code == -1002 {
                    print(Status.UNSUPPORTEDURL.errorMsg)
                    callback(.UNSUPPORTEDURL, nil)
                }
                else {
                    print(Status.ERROR.errorMsg)
                    callback(.ERROR, nil)
                }
            }
        }
    }
}

extension Dictionary {
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let percentEscapedValue = (value as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joined(separator: "&")
    }
}

extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
