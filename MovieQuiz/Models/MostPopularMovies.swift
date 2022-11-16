//
//  MostPopularMovies.swift
//  MovieQuiz
//
//  Created by Роман Бойко on 11/7/22.
//

import Foundation

struct MostPopularMovies: Decodable {
    let errorMessage: String
    let items: [MostPopularMovie]
}

struct MostPopularMovie: Decodable {
    let rating: String
    let imageURL: URL
    let title: String
    
    var resizedImageURL: URL {
        let urlString = imageURL.absoluteString
        let imageUrlString = urlString.components(separatedBy: "._")[0] + "._V0_UX600_.jpg"
        guard let newURL = URL(string: imageUrlString) else {
            return imageURL
        }
        return newURL
    }
    
    private enum CodingKeys: String, CodingKey {
        case rating = "imDbRating"
        case imageURL = "image"
        case title = "title"
    }
}

