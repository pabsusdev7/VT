//
//  FlickrClient.swift
//  VT
//
//  Created by Pablo Albuja on 7/13/20.
//  Copyright © 2020 Ingenuity Applications. All rights reserved.
//

import Foundation

class FlickrClient {
    
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest"
        
        static let apiKey = "9cd19c6a3176d48270e04024e70b5ecf"
        
        case getLocationPhotos(Double,Double)
        case getPhoto(Int,String,String,String)
        
        var stringValue: String {
            switch self {
            case .getLocationPhotos(let lat, let lon): return Endpoints.base + "/?method=flickr.photos.search&api_key=" + FlickrClient.Endpoints.apiKey + "&format=json&lat=\(lat)&lon=\(lon)"
            case .getPhoto(let farm, let server, let id, let secret): return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
                
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
        
        var choky: Bool{
            switch self {
            case .getLocationPhotos:
                return true
            default:
                return false
            }
        }
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(endpoint: Endpoints, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask{
        let task = URLSession.shared.dataTask(with: endpoint.url) { data, response, error in
            guard var data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let httpStatusCode = (response as? HTTPURLResponse)?.statusCode else {
                return
            }
            //debugPrint(String(decoding: data, as: UTF8.self))
            if httpStatusCode >= 200 && httpStatusCode < 300 {
                if endpoint.choky {
                    let range = 14..<data.count-1
                    data = data.subdata(in: range)
                }
                
                let decoder = JSONDecoder()
                do {
                    let responseObject = try decoder.decode(ResponseType.self, from: data)
                    DispatchQueue.main.async {
                        completion(responseObject, nil)
                    }
                } catch {
                    debugPrint(error)
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
            else{
                completion(nil, error)
            }
            
            
        }
        task.resume()
        
        return task
    }
    
    class func getPhoto(photo: Picture, completion: @escaping (Data?, Error?) -> ()) {
        
        let task = URLSession.shared.dataTask(with: Endpoints.getPhoto(photo.farm, photo.server, photo.id, photo.secret).url){ data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let httpStatusCode = (response as? HTTPURLResponse)?.statusCode else {
                return
            }
            if httpStatusCode >= 200 && httpStatusCode < 300 {
                DispatchQueue.main.async {
                    completion(data, error)
                }
            }
            else{
                completion(nil, error)
            }
            
            
        }
        task.resume()
    }
    
    class func getLocationPhotos(lat: Double, lon: Double,completion: @escaping ([Picture], Error?) -> Void) {
        
        taskForGETRequest(endpoint: Endpoints.getLocationPhotos(lat, lon), responseType: LocationPhotoResponse.self, completion: {(response, error)
            in
            if let response=response{
                print(response.photos.total)
                completion(response.photos.photo,nil)
            }else{
                completion([], error)
            }
        })
    }
    
}
