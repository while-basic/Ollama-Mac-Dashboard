//
//  OllamaModel.swift
//  Ollama Mac Dashboard
//
//  Created by Christopher Celaya on 4/8/25.
//

import Foundation

struct OllamaModel: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let modifiedAt: Date
    let size: Int64
    let digest: String
    let details: ModelDetails
    
    enum CodingKeys: String, CodingKey {
        case name
        case modifiedAt = "modified_at"
        case size
        case digest
        case details
    }
}

struct ModelDetails: Codable, Hashable {
    let format: String
    let family: String
    let families: [String]?
    let parameterSize: String
    let quantizationLevel: String
    
    enum CodingKeys: String, CodingKey {
        case format
        case family
        case families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }
}

struct OllamaModelList: Codable {
    let models: [OllamaModel]
}

struct RunningModel: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let model: String
    let size: Int64
    let digest: String
    let details: ModelDetails
    let expiresAt: Date
    let sizeVram: Int64
    
    enum CodingKeys: String, CodingKey {
        case name
        case model
        case size
        case digest
        case details
        case expiresAt = "expires_at"
        case sizeVram = "size_vram"
    }
}

struct RunningModelList: Codable {
    let models: [RunningModel]
}
