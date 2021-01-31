//
//  UIImageView+Extension.swift
//  AsyncAwaitDemo
//
//  Created by yochidros on 2021/01/31.
//

import _Concurrency
import UIKit

extension UIImageView {
    @asyncHandler func downloadImage(urlString: String) {
        let imageData: UIImage? = await withUnsafeContinuation { continuation in
            URLSession.shared.dataTask(with: URL(string: urlString)!, completionHandler: { data, response, error in
                if let data = data {
                    continuation.resume(returning: UIImage(data: data))
                } else {
                    continuation.resume(returning: nil)
                }
            }).resume()
        }
        DispatchQueue.main.async {
            self.image = imageData
        }
    }
}
