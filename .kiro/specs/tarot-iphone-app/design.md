# Documento de Diseño Técnico: Tarot iPhone App

## Resumen de Investigación

Antes de abordar el diseño, se investigaron los siguientes dominios técnicos:

- **Arquitectura iOS moderna**: MVVM + Clean Architecture con SwiftUI es el patrón dominante para apps iOS escalables en 2024-2025. La capa de dominio permanece agnóstica al framework, las dependencias fluyen siempre hacia adentro ([iOS Clean Architecture](https://medium.com/@macwansaumya2/ios-clean-architecture-the-field-guide-5fe25217b187)).
- **Persistencia y sincronización**: SwiftData (iOS 17+) con integración nativa CloudKit es la solución idiomática de Apple para persistencia local + sync iCloud ([HackingWithSwift SwiftData/iCloud](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud)). Para el target iOS 16 se usará Core Data + NSPersistentCloudKitContainer.
- **Animaciones de carta**: `rotation3DEffect` con eje Y en SwiftUI implementa flip 3D nativo sin dependencias externas. Se combina con `ZStack` para mostrar anverso/reverso.
- **Notificaciones locales**: `UNUserNotificationCenter` con `UNCalendarNotificationTrigger` permite scheduling diario a hora configurada por el usuario.
- **Property-based testing**: [SwiftCheck](https://cocoapods.org/pods/SwiftCheck) es la librería de property-based testing más establecida para Swift/iOS (inspirada en QuickCheck).

---

## Overview

La aplicación de Tarot para iPhone es una app nativa iOS desarrollada en Swift y SwiftUI. Ofrece un conjunto completo de funcionalidades de Tarot: tiradas predefinidas, biblioteca de 78 cartas con interpretaciones, diario personal de lecturas, carta del día y personalización. La arquitectura prioriza:

- **Disponibilidad offline total**: todo el contenido (cartas, interpretaciones) reside en el bundle de la app o en almacenamiento local.
- **Experiencia visual inmersiva**: animaciones nativas SwiftUI para barajado, flip de cartas y transiciones.
- **Sincronización opcional con iCloud**: el diario se sincroniza vía CloudKit cuando el usuario tiene iCloud habilitado.
- **Testabilidad**: la lógica de negocio está desacoplada de la UI mediante casos de uso y repositorios con protocolos, permitiendo tests unitarios y de propiedades.

---

## Architecture

La aplicación adopta **MVVM + Clean Architecture** en tres capas con dependencias unidireccionales hacia adentro:

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                      │
│  SwiftUI Views ←→ ViewModels (@Observable)              │
│  (TiradaView, BibliotecaView, DiarioView, etc.)        │
└────────────────────┬────────────────────────────────────┘
                     │ usa
┌────────────────────▼────────────────────────────────────┐
│                   Domain Layer                           │
│  Use Cases (protocolos + implementaciones)               │
│  Domain Models (Card, Spread, JournalEntry, etc.)       │
│  Repository Interfaces (protocolos)                      │
└────────────────────┬────────────────────────────────────┘
                     │ implementa
┌────────────────────▼────────────────────────────────────┐
│                    Data Layer                            │
│  Repositories (CoreData/SwiftData, Bundle JSON)         │
│  CoreData + NSPersistentCloudKitContainer               │
│  NotificationService (UNUserNotificationCenter)         │
│  UserDefaults (preferencias de usuario)                 │
└─────────────────────────────────────────────────────────┘
```

### Flujo de datos

```mermaid
graph LR
    View[SwiftUI View] -->|user action| VM[ViewModel]
    VM -->|executes| UC[Use Case]
    UC -->|calls| Repo[Repository Protocol]
    Repo -->|implemented by| DataRepo[Data Repository]
    DataRepo -->|reads/writes| CD[CoreData / Bundle JSON]
    CD -->|results| DataRepo
    DataRepo -->|entities| UC
    UC -->|domain models| VM
    VM -->|@Published state| View
```

### Módulos principales

| Módulo | Responsabilidad |
|--------|----------------|
| `TarotCore` | Modelos de dominio, protocolos de repositorio, casos de uso |
| `TarotData` | Implementaciones CoreData, parsers JSON, CloudKit sync |
| `TarotUI` | Vistas SwiftUI, ViewModels, componentes visuales |
| `TarotNotifications` | Servicio de notificaciones locales (UNUserNotificationCenter) |
| `TarotContent` | Bundle de recursos: imágenes de cartas, JSONs de interpretaciones |

---

## Components and Interfaces

### Motor de Aleatorización

```swift
protocol RandomizationEngine {
    /// Draws `count` unique cards from the full 78-card deck.
    /// - Parameter count: Number of cards to draw (1...78)
    /// - Parameter allowReversed: Whether reversed cards are allowed
    /// - Returns: Array of DrawnCard with orientation assigned
    func drawCards(count: Int, allowReversed: Bool) -> [DrawnCard]
}

struct DrawnCard {
    let card: Card
    let isReversed: Bool
    let position: SpreadPosition
}
```

La implementación usa `SystemRandomizationEngine` que hace shuffle de Fisher-Yates sobre el deck de 78 cartas y luego asigna orientación invertida con probabilidad 0.30 por carta usando `Bool.random(using:)` con probabilidad ponderada:

```swift
let isReversed = allowReversed && Double.random(in: 0..<1) < 0.30
```

### Repositorio de Cartas

```swift
protocol CardRepository {
    /// Returns all 78 cards.
    func allCards() -> [Card]
    /// Returns cards filtered by suit/arcana group.
    func cards(in group: CardGroup) -> [Card]
    /// Searches cards by name, number, or suit. Returns results sorted by relevance.
    func search(query: String) -> [Card]
    /// Returns interpretation for a card in a specific spread position.
    /// Falls back to general interpretation if contextual one is unavailable.
    func interpretation(for card: Card, position: SpreadPosition?, orientation: CardOrientation) -> Interpretation
}
```

Las cartas y sus interpretaciones se almacenan como JSON embebido en el bundle (`cards.json`), cargado una sola vez en un caché en memoria. La búsqueda opera sobre ese caché con filtrado local en O(n).

### Repositorio de Diario

```swift
protocol JournalRepository {
    func save(entry: JournalEntry) throws
    func fetchAll() -> [JournalEntry]   // sorted descending by date
    func fetch(id: UUID) -> JournalEntry?
    func delete(id: UUID) throws
}
```

Implementado sobre **CoreData** con `NSPersistentCloudKitContainer`. Cuando iCloud está disponible, la sincronización es automática. Cuando no lo está, opera en modo local.

### Servicio de Carta del Día

```swift
protocol DailyCardService {
    /// Returns the daily card for the given date. Deterministic: same date → same card.
    func dailyCard(for date: Date) -> Card
    /// Returns whether the card for today has been revealed by the user.
    func isRevealed(for date: Date) -> Bool
    /// Marks today's card as revealed.
    func markRevealed(for date: Date)
}
```

La selección determinista usa el hash del día calendario (año + día del año) como semilla para un generador pseudo-aleatorio, garantizando consistencia independientemente de cuántas veces se llame.

### Servicio de Notificaciones

```swift
protocol NotificationService {
    /// Schedules a daily local notification at the given hour (6...22).
    /// Replaces any previously scheduled daily notification.
    func scheduleDailyNotification(hour: Int) async throws
    func cancelDailyNotification() async
    func requestPermission() async -> Bool
}
```

Usa `UNCalendarNotificationTrigger` con `dateComponents` fijando la hora configurada y `repeats: true`.

### ViewModels principales

```swift
@Observable final class TiradaViewModel {
    var spreadType: SpreadType
    var drawnCards: [DrawnCard] = []
    var selectedCard: DrawnCard?
    var state: TiradaState = .idle
    
    // Dependencies injected
    private let drawCardsUseCase: DrawCardsUseCase
    private let saveToJournalUseCase: SaveToJournalUseCase
}

@Observable final class BibliotecaViewModel {
    var cards: [Card] = []
    var searchQuery: String = ""
    var scrollPosition: CardGroup?
    
    private let cardRepository: CardRepository
}

@Observable final class DiarioViewModel {
    var entries: [JournalEntry] = []
    var selectedEntry: JournalEntry?
    
    private let journalRepository: JournalRepository
}

@Observable final class CartaDelDiaViewModel {
    var dailyCard: Card?
    var isRevealed: Bool = false
    
    private let dailyCardService: DailyCardService
}

@Observable final class SettingsViewModel {
    var allowReversedCards: Bool
    var selectedLanguage: Language
    var cardBackDesign: CardBackDesign
    var activeDeck: DeckType
    var notificationHour: Int
    
    private let settingsRepository: SettingsRepository
}
```

### Inyección de Dependencias

Se usa un `AppContainer` centralizado que construye el grafo de dependencias al arrancar la app. Las dependencias se pasan a los ViewModels mediante el entorno SwiftUI (`.environment(\.appContainer, container)`) o mediante inicializadores directos.

---

## Data Models

### Modelos de Dominio

```swift
struct Card: Identifiable, Hashable {
    let id: Int                        // 0...77
    let name: String                   // "El Loco", "As de Bastos", etc.
    let number: String?                // "0", "I", "X", etc. (nil for minor arcana numbered cards)
    let suit: CardSuit?                // nil for Major Arcana
    let arcanaType: ArcanaType         // .major | .minor
    let imageName: String              // asset catalog name
    let uprightMeaning: Interpretation
    let reversedMeaning: Interpretation
}

struct Interpretation {
    let summary: String                // 100-400 palabras
    let keywords: [String]             // >= 3
    let contextual: [SpreadPositionType: String]  // override por posición
}

enum CardSuit: String, CaseIterable {
    case wands      // Bastos
    case cups       // Copas
    case swords     // Espadas
    case pentacles  // Oros
}

enum ArcanaType { case major, minor }

enum CardGroup {
    case majorArcana
    case minorArcana(suit: CardSuit)
}
```

```swift
struct Spread: Identifiable {
    let id: UUID
    let type: SpreadType
    let drawnCards: [DrawnCard]
    let createdAt: Date
}

enum SpreadType: String, CaseIterable {
    case dailyCard      // 1 carta
    case threeCard      // 3 cartas: pasado, presente, futuro
    case celticCross    // 10 cartas
    
    var positions: [SpreadPosition] { ... }
    var cardCount: Int { positions.count }
}

struct SpreadPosition: Identifiable {
    let id: SpreadPositionType
    let displayName: String
    let layoutCoordinate: CGPoint     // coordenada normalizada para el layout visual
}

enum SpreadPositionType: String {
    // Three Card
    case past, present, future
    // Celtic Cross
    case situation, challenge, subconscious, past_, future_, goal,
         selfPosition, environment, hopes, outcome
    // Daily
    case daily
}
```

```swift
struct JournalEntry: Identifiable {
    let id: UUID
    let spread: Spread
    let savedAt: Date
    var notes: String              // max 2000 chars
    var isSyncedToCloud: Bool
}
```

```swift
struct UserSettings {
    var allowReversedCards: Bool = true
    var selectedLanguage: Language = .spanish
    var cardBackDesign: CardBackDesign = .classic
    var activeDeck: DeckType = .riderWaite
    var dailyNotificationHour: Int = 8    // 6...22
    var notificationsEnabled: Bool = false
}

enum Language: String { case spanish = "es", english = "en" }
enum CardBackDesign: String, CaseIterable { case classic, mystical }
enum DeckType: String, CaseIterable { case riderWaite, thoth }
```

### Modelo CoreData (Diario)

```
JournalEntryCD
├── id: UUID
├── savedAt: Date
├── notes: String
├── spreadType: String
├── spreadCreatedAt: Date
└── drawnCards: [DrawnCardCD]  (to-many, ordered)

DrawnCardCD
├── cardId: Int32
├── positionId: String
├── isReversed: Bool
└── orderIndex: Int32
```

### Estructura del Bundle JSON de cartas

```json
{
  "cards": [
    {
      "id": 0,
      "name": "El Loco",
      "number": "0",
      "arcanaType": "major",
      "imageName": "card_00_the_fool",
      "upright": {
        "summary": "...",
        "keywords": ["nuevos comienzos", "espontaneidad", "aventura"],
        "contextual": {
          "past": "...",
          "present": "...",
          "future": "..."
        }
      },
      "reversed": {
        "summary": "...",
        "keywords": ["imprudencia", "caos", "ingenuidad"],
        "contextual": {}
      }
    }
  ]
}
```

---

## Correctness Properties

*Una propiedad es una característica o comportamiento que debe ser verdadero en todas las ejecuciones válidas del sistema — esencialmente, una afirmación formal sobre lo que el sistema debe hacer. Las propiedades sirven como puente entre las especificaciones legibles por humanos y las garantías de corrección verificables por máquina.*

---

### Property 1: Selección sin repetición

*Para cualquier* tipo de tirada con N cartas (donde 1 ≤ N ≤ 78), la función de selección del Motor de Aleatorización debe devolver exactamente N cartas, todas pertenecientes a la baraja de 78 cartas y sin ninguna repetición.

**Validates: Requirements 1.2**

---

### Property 2: Distribución estadística de cartas invertidas

*Para cualquier* muestra grande de cartas seleccionadas con la opción de cartas invertidas habilitada (N ≥ 1000), la proporción de cartas invertidas debe estar en el intervalo [0.25, 0.35], validando la distribución probabilística del 30%.

**Validates: Requirements 1.3**

---

### Property 3: Interpretación siempre disponible (fallback)

*Para cualquier* combinación de carta (id 0..77) y posición de tirada (incluyendo posiciones para las que no existe interpretación contextual), el resolvedor de interpretaciones debe devolver siempre un texto no vacío — ya sea la interpretación contextual específica o la interpretación general como alternativa.

**Validates: Requirements 1.4, 7.5**

---

### Property 4: Completitud de datos de cartas

*Para cualquier* carta en la baraja de 78 cartas, los siguientes campos deben ser no nulos y no vacíos: nombre, significado al derecho (resumen), significado invertido (resumen), al menos 3 palabras clave al derecho, al menos 3 palabras clave invertidas. Además, los textos de interpretación deben tener entre 100 y 400 palabras.

**Validates: Requirements 2.2, 2.5, 7.1**

---

### Property 5: Corrección de búsqueda de cartas

*Para cualquier* carta C de la baraja, buscar por el nombre exacto de C, por su número (si aplica) o por su palo (si aplica) debe devolver un conjunto de resultados que incluya a C.

**Validates: Requirements 2.3**

---

### Property 6: Persistencia del diario (round-trip)

*Para cualquier* entrada de diario válida (con cualquier tipo de tirada, cualquier conjunto de cartas seleccionadas y cualquier nota de hasta 2000 caracteres), guardar la entrada y recuperarla inmediatamente del repositorio debe producir un objeto equivalente al original (mismos campos, mismas cartas, mismas notas).

**Validates: Requirements 3.2, 3.3, 3.5**

---

### Property 7: Ordenación cronológica del diario

*Para cualquier* colección de N entradas de diario con marcas de tiempo distintas, la lista devuelta por el repositorio debe estar ordenada de forma que cada entrada tenga una fecha igual o posterior a la entrada siguiente (orden descendente, más reciente primero).

**Validates: Requirements 3.4**

---

### Property 8: Determinismo de la Carta del Día

*Para cualquier* fecha calendario D, llamar a `dailyCard(for: D)` en múltiples instancias o múltiples veces durante el mismo día debe devolver siempre la misma carta. Para dos fechas distintas D1 y D2, el sistema no debe restringir que la carta sea diferente (pero puede serlo).

**Validates: Requirements 4.1, 4.5**

---

### Property 9: Rango válido de notificaciones diarias

*Para cualquier* hora H en el rango [6, 22] (inclusive), el servicio de notificaciones debe aceptar el scheduling sin error. Para cualquier hora fuera de ese rango (H < 6 o H > 22), el servicio debe rechazar el scheduling o devolver un error de validación.

**Validates: Requirements 4.6**

---

### Property 10: Configuración de cartas invertidas afecta la selección

*Para cualquier* tirada con la opción de cartas invertidas deshabilitada, la función de selección del Motor de Aleatorización debe devolver cartas todas con `isReversed = false`, independientemente del tamaño de la tirada.

**Validates: Requirements 1.3, 6.3**

---

### Property 11: Persistencia de preferencias de usuario (round-trip)

*Para cualquier* valor de preferencia de usuario (idioma: es/en, diseño de dorso: classic/mystical, hora de notificación: 6..22), almacenar el valor y leerlo de vuelta del almacenamiento persistente debe producir el mismo valor.

**Validates: Requirements 6.4**

---

### Property 12: Indicador de orientación en interpretaciones

*Para cualquier* carta seleccionada con cualquier orientación (derecho o invertida), el modelo de vista de interpretación debe contener un campo de orientación que coincida exactamente con la orientación asignada a la carta en la tirada.

**Validates: Requirements 7.3**

---

## Error Handling

### Estrategia general

La app opera en modo offline-first. Los errores críticos se presentan al usuario con mensajes claros. Los errores no críticos se loguean silenciosamente.

### Categorías de error

| Error | Severidad | Manejo |
|-------|-----------|--------|
| Fallo al cargar bundle JSON de cartas | Crítico | Pantalla de error con instrucción de reinstalar |
| Fallo al guardar en CoreData | Alto | Alert modal con opción de reintentar |
| Fallo de sincronización CloudKit | Bajo | Indicador visual silencioso, sin interrupción |
| Imagen de carta no disponible | Bajo | Placeholder de carta genérica |
| Permiso de notificaciones denegado | Informativo | Mensaje explicativo en Settings con link a Preferencias del sistema |
| Nota de diario supera 2000 caracteres | Validación | Error inline en el campo de texto |
| Hora de notificación fuera de rango | Validación | Slider/picker forzado al rango válido, imposible ingresar valor inválido |

### Patrones de propagación de errores

```swift
enum TarotError: Error {
    case contentLoadFailed(underlying: Error)
    case persistenceFailed(operation: String, underlying: Error)
    case validationFailed(field: String, reason: String)
    case notificationPermissionDenied
}
```

Los ViewModels exponen `var errorState: TarotError?` que las vistas observan para mostrar alerts. Los Use Cases propagan errores tipados que los ViewModels convierten a mensajes de usuario localizados.

### CoreData concurrencia

Se usa `NSManagedObjectContext` con `.mainQueueConcurrencyType` para operaciones de lectura en UI y `performBackgroundTask` para escrituras, evitando bloqueos en el hilo principal.

---

## Testing Strategy

### Enfoque dual

Se combinan **tests de ejemplo** (XCTest) para comportamientos específicos y casos edge, con **tests de propiedades** (SwiftCheck) para validar invariantes universales.

### Property-Based Testing con SwiftCheck

La librería elegida es [SwiftCheck](https://github.com/typelift/SwiftCheck) (inspirada en QuickCheck), la más establecida para Swift. Cada test de propiedad ejecuta mínimo **100 iteraciones** con inputs generados aleatoriamente.

Cada test de propiedad se etiqueta con el formato:
```
// Feature: tarot-iphone-app, Property N: <descripción de la propiedad>
```

**Generadores personalizados necesarios:**

```swift
// Generador de IDs de carta (0...77)
extension Gen {
    static var cardId: Gen<Int> { .choose((0, 77)) }
    static var spreadSize: Gen<Int> { .choose((1, 78)) }
    static var validHour: Gen<Int> { .choose((6, 22)) }
    static var invalidHour: Gen<Int> {
        Gen.one(of: [.choose((0, 5)), .choose((23, 23))])
    }
    static var noteText: Gen<String> {
        // Strings de longitud variable hasta 2000 chars
        String.arbitrary.map { String($0.prefix(2000)) }
    }
}
```

**Tests de propiedades (uno por propiedad):**

```swift
// Feature: tarot-iphone-app, Property 1: Selección sin repetición
func testCardSelectionNoRepetition() {
    property("Drawing N cards produces N unique cards from the 78-card deck") <- forAll(.spreadSize) { n in
        let engine = SystemRandomizationEngine()
        let drawn = engine.drawCards(count: n, allowReversed: false)
        let uniqueIds = Set(drawn.map { $0.card.id })
        return drawn.count == n && uniqueIds.count == n && uniqueIds.allSatisfy { (0...77).contains($0) }
    }
}

// Feature: tarot-iphone-app, Property 2: Distribución estadística de cartas invertidas
func testReversedCardDistribution() {
    let engine = SystemRandomizationEngine()
    let drawn = engine.drawCards(count: 78, allowReversed: true)
    // With 78 samples we test structural ability; statistical test uses 1000 draws
    // (re-run multiple times in the property loop)
    property("~30% of cards are reversed over large samples") <- forAll(Gen.pure(1000)) { n in
        let allCards = (0..<n).flatMap { _ in engine.drawCards(count: 1, allowReversed: true) }
        let reversedCount = allCards.filter { $0.isReversed }.count
        let ratio = Double(reversedCount) / Double(n)
        return ratio >= 0.25 && ratio <= 0.35
    }
}
```

### Estructura de targets de test

```
TarotTests/
├── Unit/
│   ├── RandomizationEngineTests.swift        // Properties 1, 2, 10
│   ├── InterpretationResolverTests.swift      // Property 3
│   ├── CardRepositoryTests.swift              // Properties 4, 5
│   ├── JournalRepositoryTests.swift           // Properties 6, 7
│   ├── DailyCardServiceTests.swift            // Property 8
│   ├── NotificationServiceTests.swift         // Property 9
│   └── SettingsRepositoryTests.swift          // Property 11
├── Integration/
│   ├── CoreDataPersistenceTests.swift
│   └── CloudKitSyncTests.swift                // Req 3.7
├── Snapshot/
│   ├── DarkModeSanapshots.swift               // Req 5.1
│   └── LandscapeSnapshots.swift               // Req 5.2
└── Smoke/
    ├── CardCatalogSmokeTests.swift             // Reqs 1.1, 2.1, 7.4
    └── BundleContentSmokeTests.swift
```

### Tests de ejemplo (XCTest)

- Verificar que la opción de guardado aparece al completar una tirada (Req 3.1)
- Verificar que la confirmación de borrado se presenta antes de eliminar (Req 3.6)
- Verificar que el estado de scroll se preserva en la biblioteca (Req 2.4)
- Verificar que la carta del día se muestra boca abajo antes de revelar (Req 4.3)
- Verificar que los cambios en Settings se propagan de forma inmediata (Req 6.5)
- Verificar accesibilidad: labels de VoiceOver en cartas (Req 5.5)

### Tests de rendimiento

- Búsqueda de cartas debe completarse en < 500ms (Req 2.3): `measure { cardRepository.search(query: "copa") }`
- Transición de navegación: verificar con instrumentación Xcode que no supera 300ms (Req 5.6)

### Consideraciones de accesibilidad en tests

Los tests de snapshot usan `assertSnapshot(as: .accessibilityDescription)` para verificar que los elementos principales tienen `accessibilityLabel` definidos. La validación completa de VoiceOver requiere pruebas manuales con el asistente activado.
