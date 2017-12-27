/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SDWebImage

enum MetadataKeys: String {
    case imageURL = "image"
    case imageDataURI = "image_data_uri"
    case pageURL = "url"
    case title = "title"
    case description = "description"
    case type = "type"
    case provider = "provider"
    case favicon = "icon"
    case keywords = "keywords"
}

/*
 * Value types representing a page's metadata
 */
public struct PageMetadata {
    public let id: Int?
    public let siteURL: String
    public let mediaURL: String?
    public let title: String?
    public let description: String?
    public let type: String?
    public let providerName: String?
    public let faviconURL: String?
    public let keywordsString: String?
    public var keywords: Set<String> {
        guard let string = keywordsString else {
            return Set()
        }

        let strings = string.split(separator: ",", omittingEmptySubsequences: true).map(String.init)
        return Set(strings)
    }

    public init(id: Int?, siteURL: String, mediaURL: String?, title: String?, description: String?, type: String?, providerName: String?, mediaDataURI: String?, faviconURL: String? = nil, keywords: String? = nil, cacheImages: Bool = true) {
        self.id = id
        self.siteURL = siteURL
        self.mediaURL = mediaURL
        self.title = title
        self.description = description
        self.type = type
        self.providerName = providerName
        self.faviconURL = faviconURL
        self.keywordsString = keywords

        if let urlString = mediaURL, let url = URL(string: urlString), cacheImages {
            self.cacheImage(fromDataURI: mediaDataURI, forURL: url)
        }
    }

    public static func fromDictionary(_ dict: [String: Any]) -> PageMetadata? {
        guard let siteURL = dict[MetadataKeys.pageURL.rawValue] as? String else {
            return nil
        }

        return PageMetadata(id: nil, siteURL: siteURL, mediaURL: dict[MetadataKeys.imageURL.rawValue] as? String,
                            title: dict[MetadataKeys.title.rawValue] as? String, description: dict[MetadataKeys.description.rawValue] as? String,
                            type: dict[MetadataKeys.type.rawValue] as? String, providerName: dict[MetadataKeys.provider.rawValue] as? String, mediaDataURI: dict[MetadataKeys.imageDataURI.rawValue] as? String, faviconURL: dict[MetadataKeys.favicon.rawValue] as? String, keywords: dict[MetadataKeys.keywords.rawValue] as? String)
    }

    fileprivate func cacheImage(fromDataURI dataURI: String?, forURL url: URL) {
        let manager = SDWebImageManager.shared()

        func cacheUsingURLOnly() {
            manager.cachedImageExists(for: url) { exists in
                if !exists {
                    self.downloadAndCache(fromURL: url)
                }
            }
        }

        guard let dataURI = dataURI, let dataURL = URL(string: dataURI) else {
            cacheUsingURLOnly()
            return
        }

        manager.cachedImageExists(for: dataURL) { exists in
            if let data = try? Data(contentsOf: dataURL), let image = UIImage(data: data), !exists {
                self.cache(image: image, forURL: url)
            } else {
                cacheUsingURLOnly()
            }
        }
    }

    fileprivate func downloadAndCache(fromURL webUrl: URL) {
        let manager = SDWebImageManager.shared()
        manager.loadImage(with: webUrl, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
            if let image = image {
                self.cache(image: image, forURL: webUrl)
            }
        }
    }

    fileprivate func cache(image: UIImage, forURL url: URL) {
        	SDWebImageManager.shared().saveImage(toCache: image, for: url)
    }
}
