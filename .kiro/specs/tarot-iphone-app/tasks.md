
# Implementation Plan: Tarot iPhone App

## Overview

Implementación de la app nativa de Tarot para iPhone usando Swift y SwiftUI con arquitectura MVVM + Clean Architecture. Se parte desde los cimientos (modelos y capa de datos) hasta la UI completa, pasando por la lógica de negocio y los servicios auxiliares.

## Tasks

- [x] 1. Configurar estructura del proyecto y modelos de dominio
  - Crear el proyecto Xcode con los targets `TarotCore`, `TarotData`, `TarotUI`, `TarotNotifications` y `TarotContent`
  - Definir los modelos de dominio en `TarotCore`: `Card`, `Interpretation`, `CardSuit`, `ArcanaType`, `CardGroup`, `Spread`, `SpreadType`, `SpreadPosition`, `SpreadPositionType`, `DrawnCard`, `JournalEntry`, `UserSettings`, `Language`, `CardBackDesign`, `DeckType`
  - Definir el enum `TarotError` con los casos `contentLoadFailed`, `persistenceFailed`, `validationFailed`, `notificationPermissionDenied`
  - Añadir SwiftCheck como dependencia de test (Swift Package Manager)
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 3.1, 6.3, 7.1_

- [x] 2. Implementar el Motor de Aleatorización
  - [x] 2.1 Implementar el protocolo `RandomizationEngine` y `SystemRandomizationEngine` con Fisher-Yates shuffle y asignación de orientación invertida (probabilidad 0.30)
    - Asegurar que el método `drawCards(count:allowReversed:)` devuelve exactamente `count` cartas únicas de la baraja de 78 sin repetición
    - Cuando `allowReversed` es `false`, todas las cartas deben tener `isReversed = false`
    - _Requirements: 1.2, 1.3, 6.3_

  - [x] 2.2 Escribir property test para la Propiedad 1: Selección sin repetición
    - **Property 1: Selección sin repetición**
    - **Validates: Requirements 1.2**
    - Usar `Gen.spreadSize` (1…78) para generar tamaños de tirada arbitrarios
    - Verificar que el count, los IDs únicos y el rango 0..77 son correctos

  - [x] 2.3 Escribir property test para la Propiedad 2: Distribución estadística de cartas invertidas
    - **Property 2: Distribución estadística de cartas invertidas**
    - **Validates: Requirements 1.3**
    - Ejecutar 1000 extracciones de 1 carta con `allowReversed: true` y verificar que la proporción de invertidas está en [0.25, 0.35]

  - [x] 2.4 Escribir property test para la Propiedad 10: Configuración de cartas invertidas afecta la selección
    - **Property 10: Configuración de cartas invertidas afecta la selección**
    - **Validates: Requirements 1.3, 6.3**
    - Para cualquier tamaño de tirada con `allowReversed: false`, verificar que `isReversed == false` para todas las cartas devueltas

- [x] 3. Implementar el Repositorio de Cartas y carga del bundle JSON
  - [x] 3.1 Crear el archivo `cards.json` en `TarotContent` con las 78 cartas del Tarot Rider-Waite, incluyendo nombre, número, palo, tipo de arcano, nombre de imagen, resumen (100-400 palabras) al derecho e invertido, al menos 3 palabras clave por orientación, e interpretaciones contextuales por posición
    - _Requirements: 2.1, 2.2, 2.5, 7.1, 7.2_

  - [x] 3.2 Implementar `BundleCardRepository` que cumpla el protocolo `CardRepository`: carga `cards.json` desde el bundle en memoria al inicio, implementa `allCards()`, `cards(in:)`, `search(query:)` y `interpretation(for:position:orientation:)` con fallback a interpretación general
    - _Requirements: 2.1, 2.2, 2.3, 7.3, 7.4, 7.5_

- [x] 3.3 Escribir property test para la Propiedad 4: Completitud de datos de cartas
    - **Property 4: Completitud de datos de cartas**
    - **Validates: Requirements 2.2, 2.5, 7.1**
    - Usar `Gen.cardId` (0..77) y verificar que nombre, resúmenes y palabras clave no están vacíos y que los textos tienen entre 100 y 400 palabras

- [x] 3.4 Escribir property test para la Propiedad 5: Corrección de búsqueda de cartas
    - **Property 5: Corrección de búsqueda de cartas**
    - **Validates: Requirements 2.3**
    - Para cualquier carta C, buscar por nombre exacto, número o palo debe incluir C en los resultados

- [x] 3.5 Escribir property test para la Propiedad 3: Interpretación siempre disponible (fallback)
    - **Property 3: Interpretación siempre disponible (fallback)**
    - **Validates: Requirements 1.4, 7.5**
    - Para cualquier combinación de cardId (0..77) y posición (incluyendo `nil`), verificar que el texto de interpretación devuelto no está vacío

- [x] 4. Checkpoint — Asegurar que todos los tests del Motor de Aleatorización y del Repositorio de Cartas pasan
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 5. Implementar persistencia con CoreData y el Repositorio de Diario
  - [x] 5.1 Crear el modelo CoreData (`TarotJournal.xcdatamodeld`) con las entidades `JournalEntryCD` y `DrawnCardCD` según el esquema del diseño; configurar `NSPersistentCloudKitContainer` para sincronización automática con iCloud cuando esté disponible
    - _Requirements: 3.3, 3.7_

  - [x] 5.2 Implementar `CoreDataJournalRepository` que cumpla el protocolo `JournalRepository`: `save(entry:)`, `fetchAll()` (orden descendente por fecha), `fetch(id:)` y `delete(id:)` con la estrategia de concurrencia `performBackgroundTask` para escrituras
    - _Requirements: 3.1, 3.3, 3.4, 3.5, 3.6_

  - [x] 5.3 Escribir property test para la Propiedad 6: Persistencia del diario (round-trip)
    - **Property 6: Persistencia del diario (round-trip)**
    - **Validates: Requirements 3.2, 3.3, 3.5**
    - Para cualquier `JournalEntry` generada arbitrariamente (tipo de tirada, cartas y nota ≤ 2000 chars), guardar y recuperar debe producir un objeto equivalente

  - [x] 5.4 Escribir property test para la Propiedad 7: Ordenación cronológica del diario
    - **Property 7: Ordenación cronológica del diario**
    - **Validates: Requirements 3.4**
    - Para cualquier colección de N entradas con timestamps distintos, verificar que `fetchAll()` las devuelve en orden descendente

- [x] 6. Implementar el Servicio de Carta del Día y el Servicio de Notificaciones
  - [x] 6.1 Implementar `DeterministicDailyCardService` que cumpla el protocolo `DailyCardService`: selección determinista usando hash de fecha (año + día del año) como semilla, persistencia del estado "revelada" en `UserDefaults`
    - _Requirements: 4.1, 4.5_

  - [x] 6.2 Escribir property test para la Propiedad 8: Determinismo de la Carta del Día
    - **Property 8: Determinismo de la Carta del Día**
    - **Validates: Requirements 4.1, 4.5**
    - Verificar que múltiples llamadas a `dailyCard(for: D)` con la misma fecha producen siempre la misma carta

  - [x] 6.3 Implementar `LocalNotificationService` que cumpla el protocolo `NotificationService`: `requestPermission()`, `scheduleDailyNotification(hour:)` con `UNCalendarNotificationTrigger` y `repeats: true`, y `cancelDailyNotification()`; validar que `hour` esté en [6, 22]
    - _Requirements: 4.6_

  - [x] 6.4 Escribir property test para la Propiedad 9: Rango válido de notificaciones diarias
    - **Property 9: Rango válido de notificaciones diarias**
    - **Validates: Requirements 4.6**
    - Verificar que horas en [6, 22] se aceptan y horas fuera del rango se rechazan con error

- [x] 7. Implementar el Repositorio de Configuración y los casos de uso
  - [x] 7.1 Implementar `UserDefaultsSettingsRepository` para persistir y leer `UserSettings` (idioma, diseño de dorso, deck activo, hora de notificación, `allowReversedCards`, `notificationsEnabled`)
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [x] 7.2 Escribir property test para la Propiedad 11: Persistencia de preferencias de usuario (round-trip)
    - **Property 11: Persistencia de preferencias de usuario (round-trip)**
    - **Validates: Requirements 6.4**
    - Para cualquier valor de idioma (es/en), diseño de dorso (classic/mystical) y hora [6,22], almacenar y leer debe producir el mismo valor

  - [x] 7.3 Implementar los casos de uso del dominio en `TarotCore`: `DrawCardsUseCase`, `SaveToJournalUseCase`, `DeleteJournalEntryUseCase`, `SearchCardsUseCase`, `GetDailyCardUseCase`, `RevealDailyCardUseCase`
    - _Requirements: 1.2, 1.3, 1.4, 3.1, 3.2, 3.6, 4.1, 4.4, 2.3_

- [x] 8. Checkpoint — Asegurar que todos los tests de servicios y repositorios pasan
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 9. Implementar `AppContainer` y la capa de presentación: ViewModels
  - [x] 9.1 Implementar `AppContainer` que construya el grafo de dependencias completo (repositorios, servicios, casos de uso) y lo inyecte via `.environment` de SwiftUI
    - _Requirements: 5.6_

  - [x] 9.2 Implementar `TiradaViewModel` con estados `idle`, `shuffling`, `revealed`; métodos para iniciar tirada, seleccionar carta y guardar en diario; exposición de `errorState: TarotError?`
    - _Requirements: 1.2, 1.3, 1.4, 1.5, 1.6, 3.1_

  - [x] 9.3 Implementar `BibliotecaViewModel` con búsqueda reactiva (< 500ms), preservación de `scrollPosition` y carga de todas las cartas agrupadas
    - _Requirements: 2.1, 2.3, 2.4_

  - [x] 9.4 Implementar `DiarioViewModel` con carga de entradas ordenadas, selección de entrada y confirmación de borrado
    - _Requirements: 3.4, 3.5, 3.6_

  - [x] 9.5 Implementar `CartaDelDiaViewModel` con estado `isRevealed` y lógica de notificación visual al primer acceso del día
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [x] 9.6 Implementar `SettingsViewModel` con aplicación inmediata de cambios a todos los ajustes
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [x] 9.7 Escribir property test para la Propiedad 12: Indicador de orientación en interpretaciones
    - **Property 12: Indicador de orientación en interpretaciones**
    - **Validates: Requirements 7.3**
    - Para cualquier `DrawnCard` con orientación arbitraria, el ViewModel de interpretación debe exponer un campo de orientación que coincida exactamente con `isReversed`

- [x] 10. Implementar las vistas SwiftUI principales
  - [x] 10.1 Implementar `ContentView` con `TabView` de navegación principal (Tirada, Biblioteca, Carta del Día, Diario, Configuración) y soporte de `Dynamic Type` y VoiceOver (`accessibilityLabel`) en todos los elementos interactivos
    - _Requirements: 5.1, 5.4, 5.5, 5.6_

  - [x] 10.2 Implementar `TiradaView` con la animación de barajado (1-3 segundos, `rotation3DEffect`), layout visual de cartas según `layoutCoordinate` de cada `SpreadPosition`, y navegación al detalle de carta al tocar
    - _Requirements: 1.5, 5.3_

  - [x] 10.3 Implementar `TiradaDetailView` (detalle de carta en tirada) mostrando imagen de alta resolución, interpretación completa con indicador visual de orientación (derecho/invertido) y fallback a placeholder si la imagen no está disponible
    - _Requirements: 1.4, 5.7, 7.3_

  - [x] 10.4 Implementar `BibliotecaView` con lista agrupada (Arcanos Mayores + cuatro palos), buscador que filtra en tiempo real, preservación del scroll al regresar del detalle, y soporte landscape/portrait
    - _Requirements: 2.1, 2.3, 2.4, 5.2_

  - [x] 10.5 Implementar `CartaDelDiaView` con carta boca abajo y animación de flip al revelar (`rotation3DEffect`), notificación visual prominente en primer acceso del día, y soporte de modo oscuro/claro
    - _Requirements: 4.2, 4.3, 4.4, 5.1_

  - [x] 10.6 Implementar `DiarioView` con lista cronológica de entradas (fecha, tipo de tirada, preview de cartas), `DiarioEntryDetailView` con tirada completa y notas, y diálogo de confirmación antes de eliminar
    - _Requirements: 3.4, 3.5, 3.6_

  - [x] 10.7 Implementar `SettingsView` con controles para: diseño de dorso (picker de 2+ opciones), deck activo, toggle de cartas invertidas, selector de idioma, y picker de hora de notificación restringido a [6, 22]
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 4.6_

- [x] 11. Implementar adaptación de temas y accesibilidad
  - [x] 11.1 Aplicar soporte completo de modo oscuro/claro usando `@Environment(\.colorScheme)` y colores semánticos del sistema en todas las vistas; ajustar layout para orientación landscape con `GeometryReader` o `ViewThatFits` donde sea necesario
    - _Requirements: 5.1, 5.2_

  - [x] 11.2 Añadir `accessibilityLabel`, `accessibilityHint` y `accessibilityValue` a los componentes de carta, botones de tirada y controles de configuración; verificar compatibilidad con Dynamic Type aumentando el tamaño de fuente del sistema
    - _Requirements: 5.5_

  - [x] 11.3 Implementar carga diferida de imágenes con versiones de baja resolución como fallback cuando la memoria disponible sea insuficiente
    - _Requirements: 5.7_

- [x] 12. Implementar tests de integración y smoke tests
  - [x] 12.1 Escribir tests de integración de CoreData (`CoreDataPersistenceTests`) verificando que guardar y recuperar entradas del diario funciona end-to-end con una base de datos in-memory
    - _Requirements: 3.3, 3.5_

  - [x] 12.2 Escribir smoke tests de catálogo de cartas (`CardCatalogSmokeTests` y `BundleContentSmokeTests`) verificando que el bundle contiene las 78 cartas con imágenes y que todas las tiradas predefinidas tienen el número correcto de posiciones
    - _Requirements: 1.1, 2.1, 7.4_

  - [x] 12.3 Escribir tests de snapshot para modo oscuro (`DarkModeSnapshots`) y orientación landscape (`LandscapeSnapshots`) en las vistas principales
    - _Requirements: 5.1, 5.2_

  - [x] 12.4 Escribir tests de ejemplo (XCTest) para flujos críticos: confirmación de borrado en el diario, preservación de scroll en la biblioteca, carta del día boca abajo antes de revelar, y propagación inmediata de cambios en Settings
    - _Requirements: 2.4, 3.6, 4.3, 6.5_

- [x] 13. Checkpoint final — Asegurar que todos los tests pasan
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

## Notes

- Las tareas marcadas con `*` son opcionales y pueden omitirse para una MVP más rápida.
- El archivo `cards.json` (tarea 3.1) es el activo de contenido más crítico; debe completarse antes de poder probar el repositorio de cartas.
- La sincronización con iCloud (CloudKit) requiere un Apple Developer Account configurado; los tests de integración correspondientes usan mocks.
- SwiftCheck se añade exclusivamente como dependencia de test, no de producción.
- Cada property test se etiqueta con el comentario `// Feature: tarot-iphone-app, Property N: <descripción>` según la convención del diseño.
- Para el target iOS 16 se usa CoreData + `NSPersistentCloudKitContainer`; SwiftData quedaría para una futura migración a iOS 17+.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["2.1", "3.1"] },
    { "id": 1, "tasks": ["2.2", "2.3", "2.4", "3.2"] },
    { "id": 2, "tasks": ["3.3", "3.4", "3.5", "5.1", "6.1", "7.1"] },
    { "id": 3, "tasks": ["5.2", "6.3", "7.3", "6.2", "7.2"] },
    { "id": 4, "tasks": ["5.3", "5.4", "6.4", "9.1"] },
    { "id": 5, "tasks": ["9.2", "9.3", "9.4", "9.5", "9.6"] },
    { "id": 6, "tasks": ["7.3", "9.7", "10.1"] },
    { "id": 7, "tasks": ["10.2", "10.3", "10.4", "10.5", "10.6", "10.7"] },
    { "id": 8, "tasks": ["11.1", "11.2", "11.3"] },
    { "id": 9, "tasks": ["12.1", "12.2", "12.3", "12.4"] }
  ]
}
```
