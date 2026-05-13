import Foundation

enum CellState: Codable, Sendable, Equatable {
    case empty
    case filled(Character)
    case revealed(Character)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case char
    }

    private enum CellType: String, Codable {
        case empty
        case filled
        case revealed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(CellType.self, forKey: .type)
        switch type {
        case .empty:
            self = .empty
        case .filled:
            let charString = try container.decode(String.self, forKey: .char)
            guard let char = charString.first else {
                throw DecodingError.dataCorruptedError(
                    forKey: .char,
                    in: container,
                    debugDescription: "Expected a non-empty string for char"
                )
            }
            self = .filled(char)
        case .revealed:
            let charString = try container.decode(String.self, forKey: .char)
            guard let char = charString.first else {
                throw DecodingError.dataCorruptedError(
                    forKey: .char,
                    in: container,
                    debugDescription: "Expected a non-empty string for char"
                )
            }
            self = .revealed(char)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .empty:
            try container.encode(CellType.empty, forKey: .type)
        case .filled(let char):
            try container.encode(CellType.filled, forKey: .type)
            try container.encode(String(char), forKey: .char)
        case .revealed(let char):
            try container.encode(CellType.revealed, forKey: .type)
            try container.encode(String(char), forKey: .char)
        }
    }
}
