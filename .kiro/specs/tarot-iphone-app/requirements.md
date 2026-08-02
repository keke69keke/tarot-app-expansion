# Requirements Document

## Introduction

Aplicación nativa para iPhone que permite a los usuarios realizar tiradas de cartas de Tarot, explorar los significados de las 78 cartas del Tarot Rider-Waite, llevar un diario de lecturas y obtener interpretaciones personalizadas. La aplicación combina la tradición del Tarot con una experiencia visual atractiva y una interfaz intuitiva adaptada a iOS.

## Glossary

- **App**: La aplicación de Tarot para iPhone.
- **Baraja**: El conjunto completo de 78 cartas del Tarot (22 Arcanos Mayores + 56 Arcanos Menores).
- **Carta**: Una de las 78 cartas individuales del Tarot, con nombre, imagen, significado al derecho e invertido.
- **Tirada**: Una disposición de cartas seleccionadas aleatoriamente siguiendo un patrón específico con posiciones con significados definidos.
- **Posición**: Lugar específico dentro de una tirada que otorga contexto a la carta ubicada en él (ej.: "pasado", "presente", "futuro").
- **Arcanos Mayores**: Las 22 cartas principales del Tarot (El Loco, El Mago, La Suma Sacerdotisa, etc.).
- **Arcanos Menores**: Las 56 cartas secundarias divididas en cuatro palos: Bastos, Copas, Espadas y Oros.
- **Carta Invertida**: Carta que aparece girada 180°, con un significado alternativo al significado al derecho.
- **Diario**: Registro persistente de las tiradas realizadas por el usuario, con notas personales.
- **Motor de Aleatorización**: Componente responsable de mezclar y seleccionar cartas de forma aleatoria.
- **Interpretación**: Texto que describe el significado de una carta en una posición concreta de una tirada.
- **Mazo_Personalizado**: Conjunto alternativo de imágenes de cartas que el usuario puede seleccionar.
- **User**: La persona que utiliza la App en su iPhone.

---

## Requirements

### Requirement 1: Tiradas de Cartas

**User Story:** As a User, I want to perform different Tarot spreads, so that I can gain insight into different aspects of my life.

#### Acceptance Criteria

1. THE App SHALL ofrecer al menos las siguientes tiradas predefinidas: Carta del Día (1 carta), Tirada de 3 Cartas (pasado-presente-futuro) y Cruz Celta (10 cartas).
2. WHEN el User inicia una nueva Tirada, THE Motor de Aleatorización SHALL seleccionar las cartas de la Baraja completa de 78 cartas sin repetición.
3. WHEN el Motor de Aleatorización selecciona una Carta, THE App SHALL determinar aleatoriamente con una probabilidad del 30% si la Carta aparece Invertida.
4. WHEN el User toca una Carta en la Tirada, THE App SHALL mostrar la Interpretación completa de esa Carta en esa Posición, incluyendo el significado al derecho o invertido según corresponda.
5. WHEN el User completa una Tirada, THE App SHALL mostrar todas las cartas de la Tirada dispuestas visualmente según el patrón correspondiente.
6. IF el User intenta iniciar una Tirada sin conexión a internet, THEN THE App SHALL permitir la Tirada utilizando los datos almacenados localmente sin requerir conectividad.

---

### Requirement 2: Biblioteca de Cartas

**User Story:** As a User, I want to browse and study all 78 Tarot cards, so that I can learn their meanings and symbolism.

#### Acceptance Criteria

1. THE App SHALL proporcionar una biblioteca navegable con las 78 Cartas de la Baraja, ordenadas por Arcanos Mayores y los cuatro palos de los Arcanos Menores.
2. WHEN el User selecciona una Carta de la biblioteca, THE App SHALL mostrar la imagen de alta resolución de la Carta, su nombre, número (si aplica), el palo (si aplica), el significado al derecho y el significado Invertido.
3. THE App SHALL permitir al User buscar una Carta por nombre, número o palo, y mostrar los resultados en menos de 500ms.
4. WHILE el User navega la biblioteca, THE App SHALL mantener la posición de desplazamiento al regresar desde la vista de detalle de una Carta.
5. THE App SHALL mostrar para cada Carta al menos 3 palabras clave asociadas al significado al derecho y al menos 3 palabras clave para el significado Invertido.

---

### Requirement 3: Diario de Lecturas

**User Story:** As a User, I want to save and review my past Tarot readings, so that I can track patterns and reflect on my journey.

#### Acceptance Criteria

1. WHEN el User completa una Tirada, THE App SHALL ofrecer la opción de guardar la Tirada en el Diario con la fecha, hora y tipo de Tirada.
2. WHEN el User guarda una Tirada en el Diario, THE App SHALL permitir añadir una nota de texto de hasta 2000 caracteres con reflexiones personales.
3. THE App SHALL almacenar el Diario localmente en el dispositivo iPhone del User, asegurando que los datos persistan entre sesiones de la App.
4. WHEN el User accede al Diario, THE App SHALL mostrar las entradas ordenadas cronológicamente de la más reciente a la más antigua, con la fecha, tipo de Tirada y una vista previa de las cartas seleccionadas.
5. WHEN el User selecciona una entrada del Diario, THE App SHALL mostrar la Tirada completa tal como fue realizada, incluyendo las Cartas, sus posiciones y las notas guardadas.
6. IF el User intenta eliminar una entrada del Diario, THEN THE App SHALL solicitar confirmación antes de eliminar el registro de forma permanente.
7. WHERE el servicio de iCloud está habilitado en el dispositivo del User, THE App SHALL sincronizar el Diario entre dispositivos del mismo Apple ID usando CloudKit.

---

### Requirement 4: Carta del Día

**User Story:** As a User, I want to receive a daily Tarot card, so that I can start my day with reflection and guidance.

#### Acceptance Criteria

1. THE App SHALL ofrecer una funcionalidad de Carta del Día que seleccione una Carta única de la Baraja completa para cada día calendario.
2. WHEN el User abre la App por primera vez en un día calendario, THE App SHALL mostrar una notificación visual prominente invitando al User a revelar la Carta del Día.
3. WHILE el User no ha revelado la Carta del Día, THE App SHALL mostrar la Carta boca abajo con una animación de "revelar".
4. WHEN el User toca la Carta del Día boca abajo, THE App SHALL animar la revelación de la Carta y mostrar su Interpretación del día.
5. THE App SHALL garantizar que la misma Carta del Día se mantenga consistente durante las 24 horas del mismo día calendario, independientemente de cuántas veces el User abra la App.
6. WHERE el User ha habilitado las notificaciones del sistema iOS, THE App SHALL enviar una notificación push diaria a la hora configurada por el User (entre las 06:00 y las 22:00) recordando revelar la Carta del Día.

---

### Requirement 5: Interfaz Visual y Experiencia de Usuario

**User Story:** As a User, I want a visually immersive and intuitive interface, so that I feel engaged and have a meaningful experience with the app.

#### Acceptance Criteria

1. THE App SHALL soportar tanto el modo claro como el modo oscuro de iOS, adaptando todos los elementos visuales al tema activo en el sistema operativo del dispositivo.
2. THE App SHALL soportar las orientaciones vertical (portrait) y horizontal (landscape) del iPhone, reordenando el layout apropiadamente en cada orientación.
3. WHEN el User realiza una Tirada, THE App SHALL presentar una animación de barajado de cartas de duración entre 1 y 3 segundos antes de revelar las posiciones.
4. THE App SHALL ser compatible con iOS 16 o superior y estar optimizada para todos los modelos de iPhone desde iPhone 12 en adelante.
5. THE App SHALL cumplir con las Human Interface Guidelines de Apple, incluyendo soporte para Dynamic Type (tamaños de fuente accesibles) y VoiceOver.
6. WHEN el User navega entre secciones principales de la App, THE App SHALL completar la transición de pantalla en menos de 300ms.
7. IF el dispositivo del User no cuenta con suficiente memoria para cargar imágenes de alta resolución, THEN THE App SHALL cargar versiones de resolución reducida de las imágenes de las Cartas sin interrumpir la experiencia del User.

---

### Requirement 6: Personalización

**User Story:** As a User, I want to customize my Tarot experience, so that the app feels personal and aligned with my preferences.

#### Acceptance Criteria

1. THE App SHALL permitir al User seleccionar entre al menos 2 diseños de reverso de carta (dorso) para las animaciones de barajado y las cartas boca abajo.
2. WHERE el Mazo_Personalizado está disponible en la App, THE App SHALL permitir al User cambiar el Mazo_Personalizado activo desde la pantalla de Configuración, aplicando el cambio a todas las Tiradas siguientes.
3. THE App SHALL permitir al User configurar si desea incluir Cartas Invertidas en sus Tiradas mediante un ajuste en la pantalla de Configuración.
4. THE App SHALL permitir al User seleccionar el idioma de las Interpretaciones entre español e inglés, almacenando la preferencia de forma persistente.
5. WHEN el User modifica cualquier ajuste de Configuración, THE App SHALL aplicar el cambio de forma inmediata sin requerir reiniciar la App.

---

### Requirement 7: Interpretaciones y Contenido

**User Story:** As a User, I want detailed and meaningful interpretations for each card, so that I can understand the guidance the Tarot offers.

#### Acceptance Criteria

1. THE App SHALL incluir Interpretaciones para las 78 Cartas en español, con textos de entre 100 y 400 palabras por Carta por orientación (derecho e invertido).
2. THE App SHALL incluir Interpretaciones contextuales para cada Carta según la Posición en la Tirada (ej.: cómo se lee "La Torre" en la posición "resultado").
3. WHEN se muestra la Interpretación de una Carta en una Tirada, THE App SHALL indicar visualmente si la Carta está al derecho o Invertida.
4. THE App SHALL almacenar todo el contenido de Interpretaciones de forma local en el dispositivo del User para garantizar disponibilidad sin conexión a internet.
5. IF una Interpretación contextual para la combinación Carta-Posición no está disponible, THEN THE App SHALL mostrar la Interpretación general de la Carta como alternativa.
```
