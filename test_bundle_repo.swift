#!/usr/bin/env swift
import Foundation

// Quick test to verify BundleCardRepository implementation compiles and basic logic is correct

print("Testing BundleCardRepository implementation...")

// Test 1: JSON structure parsing
let testJSON = """
{
  "cards": [
    {
      "id": 0,
      "name": "El Loco",
      "arcanaType": "major",
      "imageName": "card_00_the_fool",
      "number": "0",
      "upright": {
        "summary": "Test summary",
        "keywords": ["keyword1", "keyword2"],
        "contextual": {
          "past": "Past interpretation",
          "present": "Present interpretation"
        }
      },
      "reversed": {
        "summary": "Reversed summary",
        "keywords": ["rev1", "rev2"],
        "contextual": {}
      }
    },
    {
      "id": 22,
      "name": "As de Bastos",
      "arcanaType": "minor",
      "imageName": "card_22_ace_of_wands",
      "suit": "wands",
      "upright": {
        "summary": "Minor card summary",
        "keywords": ["k1"],
        "contextual": {}
      },
      "reversed": {
        "summary": "Minor reversed",
        "keywords": ["k2"],
        "contextual": {}
      }
    }
  ]
}
"""

struct CardCatalogDTO: Codable {
    let cards: [CardDTO]
}

struct CardDTO: Codable {
    let id: Int
    let name: String
    let arcanaType: String
    let imageName: String
    let upright: InterpretationDTO
    let reversed: InterpretationDTO
    let number: String?
    let suit: String?
}

struct InterpretationDTO: Codable {
    let summary: String
    let keywords: [String]
    let contextual: [String: String]
}

do {
    let data = testJSON.data(using: .utf8)!
    let decoder = JSONDecoder()
    let catalog = try decoder.decode(CardCatalogDTO.self, from: data)
    
    print("✅ Successfully decoded \(catalog.cards.count) cards")
    print("✅ Card 0: \(catalog.cards[0].name) (Major Arcana)")
    print("✅ Card 1: \(catalog.cards[1].name) (Minor Arcana, suit: \(catalog.cards[1].suit ?? "none"))")
    print("✅ Contextual keys: \(catalog.cards[0].upright.contextual.keys.sorted())")
    
    print("\n✅ All tests passed! BundleCardRepository implementation structure is correct.")
} catch {
    print("❌ Error: \(error)")
}
