import Foundation
import CoreGraphics

/// Defines a specific location within a spread (e.g., "The Past", "The Goal").
public struct SpreadPosition: Identifiable, Hashable {
    public let id = UUID()
    public let type: SpreadPositionType?
    public var name: String
    public var displayName: String
    public var description: String?
    public var layoutCoordinate: CGPoint?

    // Custom initializer for easy creation
    public init(name: String, displayName: String? = nil, description: String? = nil, layoutCoordinate: CGPoint? = nil) {
        self.type = SpreadPositionType(rawValue: name)
        self.name = name
        self.displayName = displayName ?? name
        self.description = description
        self.layoutCoordinate = layoutCoordinate
    }

    // Compatibility initializer for older tests and modules.
    public init(id: SpreadPositionType, displayName: String, layoutCoordinate: CGPoint = .zero, description: String? = nil) {
        self.type = id
        self.name = id.rawValue
        self.displayName = displayName
        self.description = description
        self.layoutCoordinate = layoutCoordinate
    }
}

/// A lightweight set of common spread presets used across the app.
public enum SpreadType: String, CaseIterable, Codable {
    case dailyCard
    case threeCard
    case celticCross
    case fiveCard
    case horseshoe
    case relationship
    case twelveMonth
    case decision
    case pathOfLife
    
    // Phase 3 Extensions
    case astrological
    case chakraSpread
    case hexagram

    // Phase 4 — Esoteric Spreads
    case temperance       // La Templanza — Equilibrio Alquímico (6 cards)
    case treeOfLife       // Árbol de la Vida — 10 Sefirot Cabalísticas
    case starDavid        // Estrella de David — Hexagrama Sagrado (7 cards)
    case soulMirror       // Espejo del Alma — Sanación profunda (9 cards)
    case alchemyPath      // Gran Obra Alquímica — Nigredo→Rubedo (4 cards)
    case moonCycle        // Ciclo Lunar — 4 fases lunares

    /// Returns the canonical positions for this spread type.
    public var positions: [SpreadPosition] {
        switch self {
        case .dailyCard:
            return [SpreadPosition(name: "Diario", description: "La energía que guía tu día")]
        case .threeCard:
            return [
                SpreadPosition(name: "Pasado", description: "Lo que ha dado forma a tu situación actual"),
                SpreadPosition(name: "Presente", description: "La energía dominante en este momento"),
                SpreadPosition(name: "Futuro", description: "El camino que se abre ante ti")
            ]
        case .celticCross:
            return [
                SpreadPosition(name: "Presente", description: "El corazón de la cuestión"),
                SpreadPosition(name: "Desafío", description: "Lo que se cruza en tu camino"),
                SpreadPosition(name: "Pasado", description: "Influencias del pasado reciente"),
                SpreadPosition(name: "Futuro", description: "Lo que se aproxima en el horizonte"),
                SpreadPosition(name: "Encima", description: "Tu objetivo consciente o ideal"),
                SpreadPosition(name: "Debajo", description: "La base inconsciente de la situación"),
                SpreadPosition(name: "Consejo", description: "La acción recomendada"),
                SpreadPosition(name: "Entorno", description: "Influencias externas y personas clave"),
                SpreadPosition(name: "Esperanzas", description: "Tus esperanzas y temores secretos"),
                SpreadPosition(name: "Resultado", description: "El desenlace probable si continúas este camino")
            ]
        case .fiveCard:
            return [
                SpreadPosition(name: "Situación", description: "El contexto central"),
                SpreadPosition(name: "Obstáculo", description: "Lo que bloquea tu avance"),
                SpreadPosition(name: "Acción", description: "La acción más poderosa que puedes tomar"),
                SpreadPosition(name: "Resultado", description: "El fruto de tu acción"),
                SpreadPosition(name: "Consejo", description: "Sabiduría del Arcano Mayor")
            ]
        case .horseshoe:
            return [
                SpreadPosition(name: "Pasado", description: "Influencias del pasado lejano"),
                SpreadPosition(name: "Presente", description: "El estado actual"),
                SpreadPosition(name: "Oculto", description: "Lo que permanece velado"),
                SpreadPosition(name: "Consejo", description: "El consejo del Tarot"),
                SpreadPosition(name: "Futuro Cercano", description: "Lo que viene en semanas"),
                SpreadPosition(name: "Futuro Lejano", description: "El horizonte a largo plazo"),
                SpreadPosition(name: "Resultado", description: "El resultado final")
            ]
        case .relationship:
            return [
                SpreadPosition(name: "Tú", description: "Tu energía en la relación"),
                SpreadPosition(name: "Pareja", description: "La energía de tu pareja"),
                SpreadPosition(name: "Fortalezas", description: "Los pilares que sostienen la relación"),
                SpreadPosition(name: "Desafíos", description: "Las tensiones a trabajar"),
                SpreadPosition(name: "Camino Mutuo", description: "El camino que construís juntos"),
                SpreadPosition(name: "Consejo", description: "Lo que el Tarot recomienda"),
                SpreadPosition(name: "Resultado", description: "El potencial de la relación")
            ]
        case .twelveMonth:
            return (1...12).map { i in
                let months = ["Enero","Febrero","Marzo","Abril","Mayo","Junio",
                              "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"]
                return SpreadPosition(name: "Mes \(i)", displayName: months[i-1],
                                      description: "Energía dominante en \(months[i-1])")
            }
        case .decision:
            return [
                SpreadPosition(name: "Situación", description: "El núcleo de tu dilema"),
                SpreadPosition(name: "Elección", description: "La naturaleza de la decisión que enfrentas"),
                SpreadPosition(name: "Consecuencia", description: "El resultado probable de tu elección"),
                SpreadPosition(name: "Consejo", description: "La sabiduría superior que te guía")
            ]
        case .pathOfLife:
            return [
                SpreadPosition(name: "Pasado", description: "Las raíces de tu camino"),
                SpreadPosition(name: "Presente", description: "El punto donde te encuentras"),
                SpreadPosition(name: "Futuro", description: "A dónde te dirige el camino"),
                SpreadPosition(name: "Desafío", description: "El mayor obstáculo a superar"),
                SpreadPosition(name: "Fortaleza", description: "Tu don más poderoso"),
                SpreadPosition(name: "Consejo", description: "La acción sabia a tomar"),
                SpreadPosition(name: "Resultado", description: "El destino al que te encaminas"),
                SpreadPosition(name: "Oculto", description: "Lo que aún no ves pero influye"),
                SpreadPosition(name: "Guía", description: "El arquetipo que te acompaña")
            ]
        case .astrological:
            return [
                SpreadPosition(name: "Casa 1: Yo", description: "Tu identidad, apariencia y comienzos"),
                SpreadPosition(name: "Casa 2: Dinero", description: "Recursos, valores y posesiones"),
                SpreadPosition(name: "Casa 3: Comunicación", description: "Mente, hermanos, viajes cortos"),
                SpreadPosition(name: "Casa 4: Hogar", description: "Familia, raíces, el pasado"),
                SpreadPosition(name: "Casa 5: Creatividad", description: "Placeres, romance, creatividad"),
                SpreadPosition(name: "Casa 6: Salud", description: "Trabajo, salud, servicio"),
                SpreadPosition(name: "Casa 7: Pareja", description: "Relaciones, socios, el 'otro'"),
                SpreadPosition(name: "Casa 8: Transformación", description: "Muerte, regeneración, lo oculto"),
                SpreadPosition(name: "Casa 9: Filosofía", description: "Creencias, viajes largos, enseñanzas"),
                SpreadPosition(name: "Casa 10: Carrera", description: "Reputación, vocación, éxito público"),
                SpreadPosition(name: "Casa 11: Amigos", description: "Comunidad, esperanzas, ideales"),
                SpreadPosition(name: "Casa 12: Subconsciente", description: "Lo oculto, karma, limitaciones")
            ]
        case .chakraSpread:
            return [
                SpreadPosition(name: "Chakra Raíz", description: "Seguridad, supervivencia, tierra. Color: Rojo"),
                SpreadPosition(name: "Chakra Sacro", description: "Creatividad, sexualidad, emociones. Color: Naranja"),
                SpreadPosition(name: "Chakra del Plexo Solar", description: "Poder personal, voluntad, ego. Color: Amarillo"),
                SpreadPosition(name: "Chakra del Corazón", description: "Amor, compasión, sanación. Color: Verde"),
                SpreadPosition(name: "Chakra de la Garganta", description: "Comunicación, verdad, expresión. Color: Azul"),
                SpreadPosition(name: "Chakra del Tercer Ojo", description: "Intuición, visión, sabiduría. Color: Índigo"),
                SpreadPosition(name: "Chakra Corona", description: "Conexión divina, conciencia pura. Color: Violeta")
            ]
        case .hexagram:
            return [
                SpreadPosition(name: "Pasado", description: "Las causas que originaron la situación"),
                SpreadPosition(name: "Presente", description: "La energía actual"),
                SpreadPosition(name: "Futuro", description: "El potencial que se despliega"),
                SpreadPosition(name: "Consejo Oculto", description: "La sabiduría que permanece velada"),
                SpreadPosition(name: "Entorno", description: "Las fuerzas externas que actúan"),
                SpreadPosition(name: "Esperanzas/Temores", description: "Lo que anhelas y lo que temes"),
                SpreadPosition(name: "Resultado Final", description: "La síntesis y desenlace")
            ]

        // MARK: Phase 4 — Esoteric Spreads

        case .temperance:
            return [
                SpreadPosition(name: "Agua — Lo Fluido", description: "Tu naturaleza emocional, receptiva, femenina. El río que cedes."),
                SpreadPosition(name: "Fuego — Lo Activo", description: "Tu voluntad, acción, impulso creativo. La llama que avanza."),
                SpreadPosition(name: "Cuerpo — Tierra", description: "El plano físico, la salud, las necesidades materiales."),
                SpreadPosition(name: "Espíritu — Éter", description: "Tu dimensión espiritual, alma, propósito superior."),
                SpreadPosition(name: "Desequilibrio", description: "Lo que actualmente está fuera de balance en tu vida."),
                SpreadPosition(name: "Templanza — Síntesis", description: "La alquimia que une los opuestos. El punto de equilibrio perfecto.")
            ]

        case .treeOfLife:
            return [
                SpreadPosition(name: "Kether — La Corona", description: "Conciencia pura, unidad con lo divino. El punto de origen."),
                SpreadPosition(name: "Chokmah — Sabiduría", description: "La fuerza creativa masculina, el Padre. Impulso primordial."),
                SpreadPosition(name: "Binah — Comprensión", description: "La forma receptiva femenina, la Madre. La Gran Mar."),
                SpreadPosition(name: "Chesed — Misericordia", description: "Amor, abundancia, generosidad. El rey benevolente."),
                SpreadPosition(name: "Geburah — Fuerza", description: "Poder, rigor, disciplina. La espada que corta lo innecesario."),
                SpreadPosition(name: "Tiphareth — Belleza", description: "El corazón del árbol. El Sol, el Cristo, el ser solar."),
                SpreadPosition(name: "Netzach — Victoria", description: "Emociones, deseos, naturaleza, Arte y Venus."),
                SpreadPosition(name: "Hod — Esplendor", description: "Intelecto, comunicación, magia ceremonial. Mercurio."),
                SpreadPosition(name: "Yesod — Fundamento", description: "El inconsciente, la Luna, los sueños, la memoria astral."),
                SpreadPosition(name: "Malkuth — El Reino", description: "La tierra, el cuerpo físico, la manifestación material.")
            ]

        case .starDavid:
            return [
                SpreadPosition(name: "Punto Norte — Fuego", description: "Tu voluntad ascendente, aspiración y propósito espiritual."),
                SpreadPosition(name: "Punto Sureste — Agua", description: "Tus emociones profundas, el inconsciente que fluye."),
                SpreadPosition(name: "Punto Suroeste — Tierra", description: "Tu fundamento material, recursos y realidad tangible."),
                SpreadPosition(name: "Punto Sur — Aire", description: "Tu mente, pensamientos y comunicación actuales."),
                SpreadPosition(name: "Punto Noreste — Espíritu", description: "Tu conexión con lo divino y la guía superior."),
                SpreadPosition(name: "Punto Noroeste — Tiempo", description: "El ciclo temporal: qué debe terminar y qué comenzar."),
                SpreadPosition(name: "Centro — Integración", description: "La síntesis alquímica de todos los elementos. Tu verdad central.")
            ]

        case .soulMirror:
            return [
                SpreadPosition(name: "Máscara — Persona", description: "La cara que muestras al mundo. Tu identidad social."),
                SpreadPosition(name: "Sombra — Inconsciente", description: "Lo que niegas o reprimes. Tu lado oscuro integrable."),
                SpreadPosition(name: "Anima/Animus", description: "Tu principio femenino/masculino interno. El complemento interior."),
                SpreadPosition(name: "Herida de Infancia", description: "El dolor temprano que aún condiciona tus respuestas."),
                SpreadPosition(name: "Don Oculto", description: "La fortaleza escondida bajo tu herida. Tu superpoder invisible."),
                SpreadPosition(name: "Patrón Kármico", description: "El ciclo que se repite en tu vida. El tema de tu alma."),
                SpreadPosition(name: "Llamado del Alma", description: "Tu vocación profunda. Para qué viniste a este mundo."),
                SpreadPosition(name: "Obstáculo Principal", description: "El mayor bloqueo a tu evolución espiritual actual."),
                SpreadPosition(name: "Integración — El Sí Mismo", description: "El arquetipo central. Quién eres cuando todo se integra.")
            ]

        case .alchemyPath:
            return [
                SpreadPosition(name: "Nigredo — Putrefacción", description: "La oscuridad, el caos, la disolución. ¿Qué debe morir en ti?"),
                SpreadPosition(name: "Albedo — Purificación", description: "La limpieza, la claridad emergente. ¿Qué se purifica en ti?"),
                SpreadPosition(name: "Citrinitas — Iluminación", description: "La conciencia solar, el amanecer del alma. ¿Qué se ilumina?"),
                SpreadPosition(name: "Rubedo — Perfección", description: "La Piedra Filosofal, la transmutación completa. ¿Quién emerges?")
            ]

        case .moonCycle:
            return [
                SpreadPosition(name: "Luna Nueva — Semilla", description: "Lo que planta su semilla en tu vida. Nuevos comienzos e intenciones."),
                SpreadPosition(name: "Luna Creciente — Acción", description: "Lo que crece y pide tu acción y esfuerzo activo."),
                SpreadPosition(name: "Luna Llena — Plenitud", description: "Lo que llega a su máxima expresión. La revelación y la cosecha."),
                SpreadPosition(name: "Luna Menguante — Liberación", description: "Lo que debe soltarse, liberarse y transformarse antes del nuevo ciclo.")
            ]
        }
    }

    public var label: String {
        switch self {
        case .dailyCard:    return "Carta del día"
        case .threeCard:    return "Tres cartas"
        case .celticCross:  return "Cruz celta"
        case .fiveCard:     return "Cinco cartas"
        case .horseshoe:    return "Herradura (7)"
        case .relationship: return "Relaciones"
        case .twelveMonth:  return "12 meses"
        case .decision:     return "Decisión"
        case .pathOfLife:   return "Camino de vida"
        case .astrological: return "Astrológica (12 casas)"
        case .chakraSpread: return "Alineación de Chakras"
        case .hexagram:     return "Hexagrama"
        case .temperance:   return "✦ La Templanza"
        case .treeOfLife:   return "✦ Árbol de la Vida"
        case .starDavid:    return "✦ Estrella de David"
        case .soulMirror:   return "✦ Espejo del Alma"
        case .alchemyPath:  return "✦ Gran Obra Alquímica"
        case .moonCycle:    return "✦ Ciclo Lunar"
        }
    }

    /// Short esoteric description shown in the spread selector.
    public var esotericDescription: String {
        switch self {
        case .dailyCard:    return "Una carta para enfocar tu energía diaria"
        case .threeCard:    return "Pasado, Presente y Futuro en tres cartas"
        case .celticCross:  return "La tirada más completa y profunda del Tarot"
        case .fiveCard:     return "Situación, obstáculo, acción y resultado"
        case .horseshoe:    return "Siete cartas en arco para visión completa"
        case .relationship: return "Dinámica profunda de pareja y vínculos"
        case .twelveMonth:  return "Un año completo, mes a mes"
        case .decision:     return "Claridad ante una elección importante"
        case .pathOfLife:   return "Tu camino vital en 9 cartas"
        case .astrological: return "Las 12 casas de tu cielo natal"
        case .chakraSpread: return "El estado de tus 7 centros energéticos"
        case .hexagram:     return "La Estrella de 6 puntas y el destino"
        case .temperance:   return "Equilibrio alquímico entre opuestos — Arcano XIV"
        case .treeOfLife:   return "Las 10 Sefirot del Árbol Cabalístico"
        case .starDavid:    return "Los 6 elementos sagrados + el centro integrador"
        case .soulMirror:   return "Exploración profunda del inconsciente y la sombra"
        case .alchemyPath:  return "Nigredo → Albedo → Citrinitas → Rubedo"
        case .moonCycle:    return "Las 4 fases lunares como guía espiritual"
        }
    }

    /// Symbol emoji for display in UI
    public var symbol: String {
        switch self {
        case .dailyCard:    return "☀️"
        case .threeCard:    return "🃏"
        case .celticCross:  return "✝️"
        case .fiveCard:     return "⭐"
        case .horseshoe:    return "🧲"
        case .relationship: return "💞"
        case .twelveMonth:  return "🗓️"
        case .decision:     return "⚖️"
        case .pathOfLife:   return "🛤️"
        case .astrological: return "♈"
        case .chakraSpread: return "🔮"
        case .hexagram:     return "✡️"
        case .temperance:   return "⚗️"
        case .treeOfLife:   return "🌳"
        case .starDavid:    return "🌟"
        case .soulMirror:   return "🪞"
        case .alchemyPath:  return "🜂"
        case .moonCycle:    return "🌙"
        }
    }
}

public extension SpreadPositionType {
    static func from(_ rawValue: String) -> SpreadPositionType? {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "daily", "diario": return .daily
        case "past", "pasado": return .past
        case "present", "presente": return .present
        case "future", "futuro": return .future
        case "advice", "consejo": return .advice
        case "outcome", "resultado": return .outcome
        case "challenge", "desafío", "desafio": return .challenge
        case "strength", "fortaleza": return .strength
        case "shadow", "sombra": return .shadow
        case "environment", "entorno": return .environment
        case "unknown", "desconocido": return .unknown
        default: return nil
        }
    }

    var displayName: String {
        switch self {
        case .daily: return "Diario"
        case .past: return "Pasado"
        case .present: return "Presente"
        case .future: return "Futuro"
        case .advice: return "Consejo"
        case .outcome: return "Resultado"
        case .challenge: return "Desafío"
        case .strength: return "Fortaleza"
        case .shadow: return "Sombra"
        case .environment: return "Entorno"
        case .unknown: return "Desconocido"
        }
    }
}

/// Represents a collection of positions that define the structure of a reading.
public struct Spread {
    /// Optional spread metadata kept for compatibility with older code: a spread may have a type and creation date.
    public var type: SpreadType?
    public var createdAt: Date?

    /// The standard, predefined positions (e.g., Past, Present, Future).
    public var standardPositions: [SpreadPosition]
    
    /// Optional list of custom/advanced positions defined by the user for this specific spread.
    /// If present, these take precedence or are added to the standard set.
    public var customPositions: [SpreadPosition]?

    /// Compatibility: some older code expects a list of drawn cards attached to the spread.
    public var drawnCards: [DrawnCard] = []

    // MARK: Initializers
    
    /// Initializes a Spread with only standard positions (e.g., 3-Card Spread).
    public init(standardPositions: [SpreadPosition]) {
        self.standardPositions = standardPositions
        self.customPositions = nil
        self.type = nil
        self.createdAt = nil
    }
    
    /// Initializes a Spread with custom positions, overriding or augmenting the standard set.
    public init(customPositions: [SpreadPosition], standardPositions: [SpreadPosition] = []) {
        self.customPositions = customPositions
        // If no standard positions are provided, use an empty array; otherwise, merge them.
        self.standardPositions = standardPositions.isEmpty ? [] : standardPositions
        self.type = nil
        self.createdAt = nil
    }

    /// Compatibility initializer: build a Spread from a SpreadType, drawn cards and createdAt.
    public init(type: SpreadType, drawnCards: [DrawnCard], createdAt: Date = Date()) {
        self.type = type
        self.createdAt = createdAt
        self.standardPositions = type.positions
        self.customPositions = nil
        self.drawnCards = drawnCards
    }

    /// Helper to get all unique positions in the spread, sorted by display name.
    public var allPositions: [SpreadPosition] {
        var positions = self.standardPositions
        if let custom = self.customPositions {
            // Add custom ones, ensuring no duplicates if a standard position was also customized
            for customPos in custom where !positions.contains(where: { $0.id == customPos.id }) {
                positions.append(customPos)
            }
        }
        return positions.sorted { $0.displayName < $1.displayName }
    }
}
