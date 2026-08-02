#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Genera 9 libros esotéricos en PDF con contenido real y extenso
para la biblioteca de la app Tarot.
"""

import os
import struct
import zlib

# ─────────────────────────────────────────────────────────────────────────────
# Utilidad PDF mínima (sin dependencias externas)
# ─────────────────────────────────────────────────────────────────────────────

class SimplePDF:
    """Genera un PDF multi‑página con fuente estándar Type1."""

    def __init__(self):
        self.objects = []   # lista de (id, bytes)
        self.pages   = []   # ids de los objetos Page

    def _add_obj(self, data: bytes) -> int:
        oid = len(self.objects) + 1
        self.objects.append((oid, data))
        return oid

    def _encode_stream(self, text: str) -> bytes:
        """Codifica texto como stream PDF con zlib."""
        raw = text.encode('latin-1', errors='replace')
        compressed = zlib.compress(raw)
        return compressed

    def add_page(self, lines: list[str]):
        """
        Añade una página con las líneas dadas.
        lines: lista de str; las líneas largas se cortan automáticamente.
        """
        # Construir operaciones BT..ET
        ops = []
        y = 750
        ops.append("BT")
        for line in lines:
            # Elegir tamaño de fuente según marcadores
            if line.startswith("##TITLE##"):
                text = line[9:].strip()
                ops.append("/F2 18 Tf")
                ops.append(f"72 {y} Td")
                ops.append(f"({self._esc(text)}) Tj")
                y -= 28
            elif line.startswith("##HEAD##"):
                text = line[8:].strip()
                ops.append("/F2 13 Tf")
                ops.append(f"72 {y} Td")
                ops.append(f"({self._esc(text)}) Tj")
                y -= 22
            elif line.startswith("##SUB##"):
                text = line[7:].strip()
                ops.append("/F2 11 Tf")
                ops.append(f"72 {y} Td")
                ops.append(f"({self._esc(text)}) Tj")
                y -= 18
            elif line == "":
                y -= 12
            else:
                # texto normal, wrap cada 85 chars
                ops.append("/F1 10 Tf")
                chunks = self._wrap(line, 85)
                for chunk in chunks:
                    if y < 60:
                        break
                    ops.append(f"72 {y} Td")
                    ops.append(f"({self._esc(chunk)}) Tj")
                    y -= 14
            if y < 60:
                break
        ops.append("ET")
        stream_text = "\n".join(ops)
        stream_bytes = stream_text.encode('latin-1', errors='replace')
        length = len(stream_bytes)

        # Objeto stream del contenido
        stream_obj = (
            f"<< /Length {length} >>\n"
            f"stream\n"
        ).encode('latin-1') + stream_bytes + b"\nendstream"
        cid = self._add_obj(stream_obj)

        # Objeto Page
        page_dict = (
            f"<< /Type /Page /Parent 99999 0 R "
            f"/MediaBox [0 0 612 842] "
            f"/Contents {cid} 0 R "
            f"/Resources << /Font << "
            f"/F1 901 0 R "
            f"/F2 902 0 R "
            f">> >> >>"
        ).encode('latin-1')
        pid = self._add_obj(page_dict)
        self.pages.append(pid)

    @staticmethod
    def _esc(s: str) -> str:
        return s.replace('\\','\\\\').replace('(','\\(').replace(')','\\)')

    @staticmethod
    def _wrap(text: str, width: int) -> list[str]:
        words = text.split()
        lines, cur = [], ""
        for w in words:
            if len(cur) + len(w) + 1 <= width:
                cur = (cur + " " + w).strip()
            else:
                if cur:
                    lines.append(cur)
                cur = w
        if cur:
            lines.append(cur)
        return lines or [""]

    def save(self, path: str):
        all_objs: list[tuple[int, bytes]] = []

        # Fuentes estándar
        f1 = b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"
        f2 = b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>"
        all_objs.append((901, f1))
        all_objs.append((902, f2))

        # Páginas del contenido
        for oid, data in self.objects:
            all_objs.append((oid, data))

        # Pages dict
        kids = " ".join(f"{pid} 0 R" for pid in self.pages)
        pages_dict = f"<< /Type /Pages /Kids [{kids}] /Count {len(self.pages)} >>".encode()
        all_objs.append((99999, pages_dict))

        # Catalog
        catalog = b"<< /Type /Catalog /Pages 99999 0 R >>"
        all_objs.append((100000, catalog))

        # Serializar
        body = b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n"
        offsets: dict[int, int] = {}

        for oid, data in all_objs:
            offsets[oid] = len(body)
            body += f"{oid} 0 obj\n".encode()
            body += data
            body += b"\nendobj\n"

        # xref
        xref_offset = len(body)
        all_ids = sorted(offsets.keys())
        body += f"xref\n0 1\n0000000000 65535 f \n".encode()
        for oid in all_ids:
            body += f"{oid} 1\n{offsets[oid]:010d} 00000 n \n".encode()

        body += (
            f"trailer\n<< /Size {max(all_ids)+1} /Root 100000 0 R >>\n"
            f"startxref\n{xref_offset}\n%%EOF\n"
        ).encode()

        with open(path, 'wb') as f:
            f.write(body)


# ─────────────────────────────────────────────────────────────────────────────
# Contenido de los libros
# ─────────────────────────────────────────────────────────────────────────────

BOOKS: list[tuple[str, list[list[str]]]] = []

# ── LIBRO 1 ──────────────────────────────────────────────────────────────────
clave_waite = [
    # Página 1 – Portada
    ["##TITLE## La Clave Ilustrada del Tarot",
     "##SUB## Basado en los escritos de Arthur Edward Waite",
     "",
     "Esta obra es una introducción profunda al Tarot Rider-Waite, el mazo más",
     "influyente de la historia del Tarot moderno. A través de sus páginas",
     "exploraremos la simbología oculta, la estructura numerológica y las",
     "correspondencias esotéricas que Waite y Pamela Colman Smith tejieron en",
     "cada una de las 78 láminas.",
     "",
     "##HEAD## Índice de Contenidos",
     "  Capítulo 1: Historia y Origen del Tarot Rider-Waite",
     "  Capítulo 2: Los 22 Arcanos Mayores",
     "  Capítulo 3: Los 56 Arcanos Menores",
     "  Capítulo 4: Numerología y Qabalah en el Tarot",
     "  Capítulo 5: Correspondencias Planetarias y Zodiacales",
     "  Capítulo 6: El Árbol de la Vida y los Arcanos",
     "  Apéndice: Tablas de Correspondencias Completas"],
    # Página 2
    ["##HEAD## Capítulo 1: Historia y Origen del Tarot Rider-Waite",
     "",
     "El Tarot Rider-Waite fue publicado por primera vez en diciembre de 1909 por la",
     "editorial Rider Company de Londres. Su creación fue el resultado de la colaboración",
     "entre Arthur Edward Waite, miembro de la Orden Hermética de la Aurora Dorada, y",
     "Pamela Colman Smith, artista e iniciada en la misma orden.",
     "",
     "Waite, conocido por sus extensos trabajos sobre misterios ocultos, quería crear",
     "un mazo que reflejara fielmente la tradición esotérica occidental. Hasta entonces,",
     "los mazos de Tarot (como el Tarot de Marsella) tenían los Arcanos Menores sin",
     "escenas ilustradas, con símbolos geométricos simples. Waite encargó a Pamela",
     "Colman Smith —conocida cariñosamente como 'Pixie'— que ilustrara escenas completas",
     "y narrativas para cada una de las 78 cartas.",
     "",
     "Esta decisión revolucionó la lectura intuitiva del Tarot, pues las imágenes",
     "facilitan la asociación psicológica y la interpretación arquetípica.",
     "",
     "##SUB## La Orden Hermética de la Aurora Dorada",
     "La Hermetic Order of the Golden Dawn fue fundada en 1888 por William Robert Woodman,",
     "William Wynn Westcott y Samuel Liddell MacGregor Mathers. Esta orden secreta",
     "sintetizó tradiciones de la Qabalah, la alquimia, la astrología, la magia ceremonial",
     "y el Tarot en un sistema cohesivo de enseñanza esotérica.",
     "",
     "Waite y Smith, junto a otros miembros notables como Aleister Crowley y William",
     "Butler Yeats, recibieron instrucción directa sobre el simbolismo del Tarot como",
     "herramienta de meditación y trabajo espiritual."],
    # Página 3
    ["##HEAD## Capítulo 2: Los Arcanos Mayores — Descripción Detallada",
     "",
     "##SUB## 0 - El Loco (The Fool)",
     "Elemento: Aire  |  Planeta: Urano  |  Letra hebrea: Aleph",
     "El Loco representa el alma en el umbral de la existencia, pura potencialidad.",
     "Camina al borde de un precipicio sin mirar, con un pequeño perro —símbolo",
     "del intelecto— ladrando a sus talones. La bolsita que carga contiene las",
     "cuatro virtudes cardinales. Es el número 0: infinito y vacío a la vez.",
     "Upright: Libertad, espontaneidad, nuevos comienzos, inocencia divina.",
     "Reversed: Imprudencia, ingenuidad, falta de dirección.",
     "",
     "##SUB## I - El Mago (The Magician)",
     "Elemento: Aire  |  Planeta: Mercurio  |  Letra hebrea: Beth",
     "Sobre su mesa reposan los cuatro palos del Tarot: la copa, la varita, la espada",
     "y el pentáculo, representando los cuatro elementos. Con una mano señala al cielo",
     "y con la otra a la tierra: 'Como es arriba, es abajo.' Su cinturón es una serpiente",
     "mordiéndose la cola (uróboro), símbolo de la eternidad.",
     "Upright: Voluntad, poder, manifestación, habilidad, concentración.",
     "Reversed: Manipulación, ilusión, talentos desperdiciados.",
     "",
     "##SUB## II - La Suma Sacerdotisa (The High Priestess)",
     "Elemento: Agua  |  Planeta: Luna  |  Letra hebrea: Gimel",
     "Sienta entre dos pilares: Boaz (oscuridad) y Jachin (luz), los pilares del",
     "Templo de Salomón. Sostiene la Torah parcialmente oculta, indicando que la",
     "sabiduría interior se revela solo a los iniciados. La luna a sus pies y la",
     "corona de Isis completan su aspecto de guardiana de los misterios.",
     "Upright: Intuición, sabiduría interior, misterio, conocimiento subconsciente.",
     "Reversed: Secretos guardados, desconexión de la intuición."],
    # Página 4
    ["##SUB## III - La Emperatriz (The Empress)",
     "Elemento: Tierra  |  Planeta: Venus  |  Letra hebrea: Daleth",
     "Rodeada de naturaleza exuberante, la Emperatriz encarna la fertilidad divina",
     "y el amor incondicional. Su vestido porta granadas (fertilidad) y lleva una",
     "corona de 12 estrellas (los signos del zodíaco). El trigo a sus pies simboliza",
     "la abundancia material.",
     "Upright: Fertilidad, abundancia, naturaleza, sensualidad, creación.",
     "Reversed: Dependencia, bloqueo creativo, escasez.",
     "",
     "##SUB## IV - El Emperador (The Emperor)",
     "Elemento: Fuego  |  Signo: Aries  |  Letra hebrea: Heh",
     "Sentado en un trono de piedra con motivos de carneros (Aries), el Emperador",
     "representa la autoridad, la estructura y el orden. Su cetro en forma de ankh",
     "une los principios de vida y poder.",
     "Upright: Autoridad, estructura, estabilidad, paternidad, control.",
     "Reversed: Tiranía, rigidez, falta de control.",
     "",
     "##SUB## V - El Hierofante (The Hierophant)",
     "Elemento: Tierra  |  Signo: Tauro  |  Letra hebrea: Vav",
     "Guardián de la tradición sagrada, el Hierofante hace el gesto de bendición",
     "con dos dedos al cielo y dos a la tierra. Ante él se arrodillan dos monjes,",
     "representando la transmisión exotérica e iniciática del conocimiento.",
     "Upright: Tradición, espiritualidad institucional, guía, conformidad.",
     "Reversed: Rebeldía, heterodoxia, cuestionamiento de dogmas.",
     "",
     "##SUB## VI - Los Amantes (The Lovers)",
     "Elemento: Aire  |  Signo: Géminis  |  Letra hebrea: Zayin",
     "Un ángel —Rafael— bendice a la pareja desde lo alto. Detrás de la mujer: el",
     "Árbol del Conocimiento con la serpiente. Detrás del hombre: el Árbol de la Vida.",
     "La elección consciente entre el camino espiritual y el material.",
     "Upright: Amor, alineación de valores, elecciones, uniones.",
     "Reversed: Desalineación, malas decisiones, conflicto de valores."],
    # Página 5
    ["##HEAD## Capítulo 3: Los Arcanos Menores",
     "",
     "Los 56 Arcanos Menores se dividen en cuatro palos, cada uno asociado a un",
     "elemento, una esfera de vida y un rango de cartas del As al 10 más cuatro",
     "cartas de corte (Paje, Caballero, Reina, Rey).",
     "",
     "##SUB## Palo de Bastos (Wands) — Elemento: Fuego",
     "Los Bastos gobiernan la energía, la creatividad, la pasión y la voluntad.",
     "Están asociados al mundo del trabajo, los proyectos y la ambición.",
     "As de Bastos: Chispa de inspiración, nuevo comienzo con energía pura.",
     "2 de Bastos: Planificación, mirada al futuro, poder personal.",
     "3 de Bastos: Expansión, visión, espera de resultados.",
     "4 de Bastos: Celebración, armonía, hogar y comunidad.",
     "5 de Bastos: Conflicto, competencia, desafíos.",
     "6 de Bastos: Victoria, reconocimiento público, liderazgo.",
     "7 de Bastos: Defensa, perseverancia, posición ganada.",
     "8 de Bastos: Velocidad, acción rápida, comunicación.",
     "9 de Bastos: Resiliencia, guardia, experiencia acumulada.",
     "10 de Bastos: Sobrecarga, responsabilidad excesiva, opresión.",
     "Paje de Bastos: Entusiasmo, exploración, mensajes creativos.",
     "Caballero de Bastos: Aventura, impulsividad, energía en movimiento.",
     "Reina de Bastos: Carisma, confianza, liderazgo femenino.",
     "Rey de Bastos: Visión, emprendimiento, maestría del fuego.",
     "",
     "##SUB## Palo de Copas (Cups) — Elemento: Agua",
     "Las Copas rigen las emociones, las relaciones, los sueños y la intuición.",
     "As de Copas: Amor incondicional, apertura emocional, abundancia espiritual.",
     "2 de Copas: Unión, asociación, atracción mutua.",
     "3 de Copas: Celebración, amistad, abundancia compartida.",
     "4 de Copas: Apatía, contemplación, oportunidades ignoradas.",
     "5 de Copas: Pérdida, luto, enfoque en lo negativo.",
     "6 de Copas: Nostalgia, inocencia, recuerdos del pasado."],
    # Página 6
    ["##SUB## Palo de Espadas (Swords) — Elemento: Aire",
     "Las Espadas representan el intelecto, los conflictos, la verdad y el dolor.",
     "As de Espadas: Claridad mental, verdad cortante, nuevo pensamiento.",
     "2 de Espadas: Punto muerto, decisión bloqueada, negación.",
     "3 de Espadas: Corazón roto, traición, dolor emocional.",
     "4 de Espadas: Descanso, recuperación, retiro temporal.",
     "5 de Espadas: Conflicto, derrota, victoria vacía.",
     "6 de Espadas: Transición, movimiento hacia la calma, viaje.",
     "7 de Espadas: Engaño, hurto, estrategia deshonesta.",
     "8 de Espadas: Restricción, trampa mental, victimización.",
     "9 de Espadas: Ansiedad, pesadillas, mente atormentada.",
     "10 de Espadas: Final doloroso, traición definitiva, crisis.",
     "",
     "##SUB## Palo de Oros/Pentáculos (Pentacles) — Elemento: Tierra",
     "Los Oros gobiernan el mundo material: dinero, salud, trabajo y posesiones.",
     "As de Oros: Oportunidad material, nueva fuente de prosperidad.",
     "2 de Oros: Malabares, adaptabilidad, equilibrio financiero.",
     "3 de Oros: Trabajo en equipo, artesanía, reconocimiento.",
     "4 de Oros: Posesividad, control del dinero, conservadurismo.",
     "5 de Oros: Pobreza, exclusión, dificultades materiales.",
     "6 de Oros: Generosidad, equilibrio dar-recibir.",
     "7 de Oros: Paciencia, evaluación, inversión a largo plazo.",
     "8 de Oros: Diligencia, artesanía, aprendizaje.",
     "9 de Oros: Abundancia, auto-suficiencia, lujo merecido.",
     "10 de Oros: Riqueza familiar, legado, éxito permanente.",
     "",
     "##HEAD## Capítulo 4: Numerología en el Tarot",
     "Cada número del 1 al 10 porta un arquetipo universal:",
     "1 (As): Potencial puro, semilla, unidad primordial.",
     "2: Dualidad, equilibrio, unión de opuestos.",
     "3: Síntesis, creatividad, expresión.",
     "4: Estabilidad, estructura, fundamentos.",
     "5: Cambio, conflicto, adaptación.",
     "6: Armonía, responsabilidad, ajuste.",
     "7: Misterio, introspección, evaluación.",
     "8: Poder, control, ciclos.",
     "9: Completitud, sabiduría, preparación.",
     "10: Fin de ciclo, plenitud, transición."],
]

BOOKS.append(("La_Clave_Ilustrada_del_Tarot.pdf", clave_waite))


# ── LIBRO 2 ──────────────────────────────────────────────────────────────────
guia_tiradas = [
    ["##TITLE## Guía de Tiradas Avanzadas y Simbología",
     "##SUB## Manual completo de spreads para lecturas profesionales",
     "",
     "Este manual reúne más de 20 tiradas del Tarot, desde las más clásicas hasta",
     "las más especializadas, con instrucciones detalladas de posición, enfoque",
     "y técnicas de interpretación integrada.",
     "",
     "##HEAD## Índice",
     "  Parte I: Fundamentos de una Lectura Profesional",
     "  Parte II: Tiradas para el Amor y las Relaciones",
     "  Parte III: Tiradas para el Camino de Vida",
     "  Parte IV: Tiradas de Tiempo y Ciclos",
     "  Parte V: Tiradas Esotéricas Avanzadas",
     "  Apéndice: Protocolos de Limpieza y Consagración del Mazo"],
    ["##HEAD## Parte I: Fundamentos de una Lectura Profesional",
     "",
     "##SUB## La Pregunta como Base de la Tirada",
     "Una lectura de Tarot efectiva comienza con una pregunta bien formulada.",
     "Las preguntas abiertas (¿Qué energías rodean mi situación laboral?)",
     "son más reveladoras que las cerradas (¿Conseguiré el trabajo?).",
     "",
     "##SUB## Preparación del Espacio",
     "1. Limpia el espacio físico y energético: quema incienso de salvia o palo santo.",
     "2. Centra tu mente con 3 respiraciones profundas.",
     "3. Baraja el mazo con intención, visualizando la pregunta.",
     "4. Corta el mazo en tres montones con la mano no dominante.",
     "5. Reúne los montones en el orden que sientas correcto.",
     "",
     "##SUB## Lectura de Cartas Invertidas",
     "Las cartas invertidas o reversas matizan la energía de la carta derecha.",
     "Pueden indicar: energía bloqueada, interiorización del arquetipo,",
     "retraso en la manifestación, o el aspecto sombra del arquetipo.",
     "",
     "##SUB## La Carta Significadora",
     "Antes de algunas lecturas, se selecciona una carta que represente al consultante.",
     "Se puede elegir por: signo solar (corte de la personalidad), intuición del lector,",
     "o por descripción física tradicional."],
    ["##HEAD## Tirada 1: Una Sola Carta (Daily Card)",
     "Uso: Reflexión diaria, pregunta directa.",
     "Método: Extrae una sola carta después de centrar tu intención.",
     "Interpretación: La carta refleja la energía del día o la respuesta más directa.",
     "Consejo: Lleva un diario y anota la carta diaria junto con tus reflexiones.",
     "",
     "##HEAD## Tirada 2: Tres Cartas (Pasado-Presente-Futuro)",
     "Posición 1 (Pasado): Influencias que han dado forma a la situación actual.",
     "Posición 2 (Presente): La energía predominante del momento.",
     "Posición 3 (Futuro): El resultado probable si se mantiene el curso actual.",
     "Variación: También puede usarse como Mente-Cuerpo-Espíritu.",
     "",
     "##HEAD## Tirada 3: La Cruz Celta (Celtic Cross)",
     "La tirada más completa y popular del Tarot occidental.",
     "Posición 1 - La Situación: El tema central de la consulta.",
     "Posición 2 - El Cruce: Lo que complica o apoya la situación.",
     "Posición 3 - Fundamento: Raíces inconscientes del asunto.",
     "Posición 4 - El Pasado: Lo que acaba de quedar atrás.",
     "Posición 5 - Corona: Lo que el consultante aspira o puede lograr.",
     "Posición 6 - Futuro Inmediato: Lo que se acerca en semanas.",
     "Posición 7 - El Consultante: Cómo se ve a sí mismo en la situación.",
     "Posición 8 - Entorno: Influencias externas y personas clave.",
     "Posición 9 - Esperanzas y Miedos: Deseos y temores interiores.",
     "Posición 10 - Resultado Final: La resolución probable de la situación.",
     "",
     "Nota: Se recomienda leer las posiciones 1-6 como el 'corazón' del asunto,",
     "y las posiciones 7-10 como el 'bastón' o contexto más amplio."],
    ["##HEAD## Tirada 4: La Herradura (Horseshoe)",
     "7 cartas en forma de herradura. Ideal para situaciones complejas.",
     "Pos. 1: Pasado. Pos. 2: Presente. Pos. 3: Influencias ocultas.",
     "Pos. 4: Obstáculos. Pos. 5: Actitudes del entorno.",
     "Pos. 6: Mejor curso de acción. Pos. 7: Resultado.",
     "",
     "##HEAD## Tirada 5: El Árbol de la Vida (Tree of Life)",
     "10 cartas colocadas en las posiciones de las Sefirot del Árbol de la Vida.",
     "Kether (1): Propósito superior / esencia del alma.",
     "Chokmah (2): Sabiduría dinámica, lo masculino sagrado.",
     "Binah (3): Entendimiento intuitivo, lo femenino sagrado.",
     "Chesed (4): Misericordia, abundancia, expansión.",
     "Geburah (5): Fuerza, juicio, límites necesarios.",
     "Tiphareth (6): Armonía, el Yo Superior.",
     "Netzach (7): Victoria, deseos, emociones.",
     "Hod (8): Esplendor, mente, comunicación.",
     "Yesod (9): La luna, el inconsciente, los sueños.",
     "Malkuth (10): El reino físico, la manifestación.",
     "",
     "##HEAD## Tirada 6: La Estrella de David (Star of David)",
     "12 cartas en 2 triángulos entrelazados + 1 carta central.",
     "Triángulo superior (espiritual): Mente, Voluntad, Intuición.",
     "Triángulo inferior (material): Cuerpo, Acción, Resultado.",
     "Centro: La energía integradora de la situación.",
     "Las 6 puntas externas: Influencias del entorno en cada área.",
     "Ideal para: consultas holísticas profundas, evaluación anual."],
    ["##HEAD## Parte II: Tiradas para el Amor",
     "",
     "##SUB## Tirada: El Corazón del Amor (5 cartas)",
     "Pos. 1: Cómo me siento respecto a la relación.",
     "Pos. 2: Cómo se siente la otra persona.",
     "Pos. 3: La dinámica actual entre ambos.",
     "Pos. 4: El desafío principal de la relación.",
     "Pos. 5: El potencial de la relación.",
     "",
     "##SUB## Tirada: ¿Volverá? (3 cartas)",
     "Pos. 1: La energía actual de la relación.",
     "Pos. 2: Obstáculos para la reconciliación.",
     "Pos. 3: Posibilidad real de regreso.",
     "",
     "##SUB## Tirada: Alma Gemela (7 cartas)",
     "Pos. 1: Mi estado emocional actual.",
     "Pos. 2: Lo que necesito sanar antes de atraer el amor.",
     "Pos. 3: Tipo de persona que me conviene.",
     "Pos. 4: Cuándo / circunstancias del encuentro.",
     "Pos. 5: El potencial de esa relación.",
     "Pos. 6: Retos a superar juntos.",
     "Pos. 7: Mensaje del universo sobre mi vida amorosa.",
     "",
     "##HEAD## Parte III: Tiradas para el Camino de Vida",
     "",
     "##SUB## Tirada: La Brújula del Alma (8 cartas)",
     "Pos. 1: Quién soy en este momento.",
     "Pos. 2: Mi propósito de vida.",
     "Pos. 3: Mis dones y talentos.",
     "Pos. 4: Mis heridas y sombras.",
     "Pos. 5: Mi misión en el trabajo.",
     "Pos. 6: Mi misión en las relaciones.",
     "Pos. 7: Lo que necesito soltar.",
     "Pos. 8: Mi próximo gran paso."],
]

BOOKS.append(("Guia_Tiradas_Avanzadas.pdf", guia_tiradas))


# ── LIBRO 3 ──────────────────────────────────────────────────────────────────
bohemios_papus = [
    ["##TITLE## El Tarot de los Bohemios",
     "##SUB## Gérard Encausse 'Papus' — Clave absoluta de la ciencia oculta",
     "",
     "Publicado por primera vez en 1889, esta obra es considerada uno de los",
     "estudios más profundos del Tarot desde la perspectiva cabalística. Papus",
     "argumenta que el Tarot es la enciclopedia de los Gitanos de Egipto,",
     "portadora del conocimiento iniciático más antiguo de la humanidad.",
     "",
     "##HEAD## Prólogo",
     "Gérard Encausse, conocido por su nombre esotérico Papus, fue médico,",
     "ocultista y miembro de numerosas sociedades herméticas en el París del",
     "siglo XIX. Fue discípulo de Eliphas Lévi y fundador de la Orden Martinista.",
     "",
     "Para Papus, el Tarot no es un juego de cartas sino el Libro Sagrado que los",
     "iniciados egipcios codificaron para preservar su conocimiento a través de los",
     "siglos. Los 'bohemios' (gitanos) habrían transportado este libro sagrado a",
     "través de Europa desde Egipto hasta occidente."],
    ["##HEAD## Capítulo 1: La Clave del Tarot",
     "",
     "La clave fundamental del Tarot según Papus reside en el alfabeto hebreo.",
     "El Tarot tiene 22 Arcanos Mayores que corresponden exactamente a las 22",
     "letras del alfabeto hebreo. Esta correspondencia no es accidental sino que",
     "demuestra el origen común del Tarot y la Qabalah en la tradición egipcia.",
     "",
     "##SUB## El Nombre Sagrado (Tetragrammaton)",
     "El nombre sagrado de Dios en hebreo: Yod-Heh-Vav-Heh (YHWH o Yahveh)",
     "es la clave de la estructura del Tarot según Papus.",
     "",
     "Yod = El Padre = El Mundo de los Origenes = Arcanos 1-7",
     "Heh (primer) = La Madre = El Mundo de la Formación = Arcanos 8-14",
     "Vav = El Hijo = El Mundo de la Acción = Arcanos 15-21",
     "Heh (segundo) = La Hija = El Mundo Material = El Loco (0/22)",
     "",
     "Esta estructura da al Tarot una jerarquía cósmica que va desde el",
     "principio espiritual más elevado hasta la manifestación más densa.",
     "",
     "##SUB## Los Cuatro Palos y el Tetragrammaton",
     "Bastos = Yod = Fuego = El Padre creador",
     "Copas = Heh = Agua = La Madre receptiva",
     "Espadas = Vav = Aire = El Hijo que actúa",
     "Oros = Heh = Tierra = El resultado material"],
    ["##HEAD## Capítulo 2: Las Correspondencias Cabalísticas",
     "",
     "Cada Arcano Mayor corresponde a una letra hebrea y a un sendero en el",
     "Árbol de la Vida (Sefer Yetzirah).",
     "",
     "0 El Loco    - Aleph  - Sendero 11 - Kether a Chokmah",
     "1 El Mago    - Beth   - Sendero 12 - Kether a Binah",
     "2 Sacerdotisa- Gimel  - Sendero 13 - Kether a Tiphareth",
     "3 La Emperatriz - Daleth - Sendero 14 - Chokmah a Binah",
     "4 El Emperador - Heh  - Sendero 15 - Chokmah a Tiphareth",
     "5 El Hierofante - Vav - Sendero 16 - Chokmah a Chesed",
     "6 Los Amantes - Zayin - Sendero 17 - Binah a Tiphareth",
     "7 El Carro    - Cheth - Sendero 18 - Binah a Geburah",
     "8 La Fuerza   - Teth  - Sendero 19 - Chesed a Geburah",
     "9 El Ermitaño - Yod   - Sendero 20 - Chesed a Tiphareth",
     "10 Rueda Fortuna - Kaph - Sendero 21 - Chesed a Netzach",
     "11 La Justicia - Lamed - Sendero 22 - Geburah a Tiphareth",
     "12 El Colgado  - Mem   - Sendero 23 - Geburah a Hod",
     "13 La Muerte   - Nun   - Sendero 24 - Tiphareth a Netzach",
     "14 La Templanza - Samech - Sendero 25 - Tiphareth a Yesod",
     "15 El Diablo   - Ayin  - Sendero 26 - Tiphareth a Hod",
     "16 La Torre    - Peh   - Sendero 27 - Netzach a Hod",
     "17 La Estrella - Tzaddi - Sendero 28 - Netzach a Yesod",
     "18 La Luna     - Qoph  - Sendero 29 - Netzach a Malkuth",
     "19 El Sol      - Resh  - Sendero 30 - Hod a Yesod",
     "20 El Juicio   - Shin  - Sendero 31 - Hod a Malkuth",
     "21 El Mundo    - Tav   - Sendero 32 - Yesod a Malkuth"],
    ["##HEAD## Capítulo 3: Los Arcanos Menores según Papus",
     "",
     "Para Papus, los 56 Arcanos Menores representan las aplicaciones prácticas",
     "de los principios revelados por los Arcanos Mayores.",
     "",
     "##SUB## Las Cartas de la Corte como Tipos Humanos",
     "Las 16 cartas de la corte representan los cuatro tipos humanos fundamentales,",
     "vistos desde cuatro perspectivas de desarrollo.",
     "",
     "El Paje (Valet): El tipo humano en su forma más joven e inexperta.",
     "  Ambos sexos, joven, aprendiz del elemento de su palo.",
     "",
     "El Caballero (Cavalier): El tipo humano en plena actividad y búsqueda.",
     "  Joven adulto, en movimiento, buscador.",
     "",
     "La Reina (Dame): El principio femenino maduro de cada elemento.",
     "  La madre o figura femenina establecida.",
     "",
     "El Rey (Roi): El principio masculino maduro de cada elemento.",
     "  El padre o figura de autoridad establecida.",
     "",
     "##SUB## Los Ases como Principios",
     "Para Papus, los cuatro Ases son los sellos del Tetragrammaton:",
     "As de Bastos: La primera letra Yod, el principio activo del fuego.",
     "As de Copas: La primera Heh, el principio pasivo del agua.",
     "As de Espadas: La Vav, el principio activo del aire e intelecto.",
     "As de Oros: La segunda Heh, el principio pasivo de la tierra."],
]

BOOKS.append(("Tarot_de_los_Bohemios_Papus.pdf", bohemios_papus))


# ── LIBRO 4 ──────────────────────────────────────────────────────────────────
thoth_alquimia = [
    ["##TITLE## El Libro de Thoth y Simbología Alquímica",
     "##SUB## Aleister Crowley — El Tarot como sistema mágico completo",
     "",
     "El Tarot de Thoth, diseñado por Aleister Crowley e ilustrado por Lady",
     "Frieda Harris entre 1938 y 1943, es la expresión más elaborada del sistema",
     "esotérico de la Thelema. Este libro explora las correspondencias del Tarot",
     "con la alquimia, el I Ching, la astrología y la magia ceremonial.",
     "",
     "##HEAD## Parte I: Thoth — El Señor de la Magia",
     "Thoth es el dios egipcio de la sabiduría, la escritura y la magia.",
     "Equivalente al griego Hermes y al romano Mercurio, Thoth es el inventor",
     "del lenguaje sagrado y el custodio del Libro de la Vida y la Muerte.",
     "El Tarot de Crowley lleva su nombre porque, según la tradición hermética,",
     "el Tarot es el Libro de Thoth: el registro de todos los secretos del universo."],
    ["##HEAD## Los Principios Alquímicos en el Tarot",
     "",
     "La alquimia medieval buscaba la transmutación de los metales vulgares en oro.",
     "A un nivel más profundo, la alquimia espiritual busca la transmutación del",
     "alma humana en su forma más elevada y luminosa.",
     "",
     "##SUB## Los Tres Principios (Tria Prima) de Paracelso",
     "Sulfuro (Azufre): El principio activo, el alma, la esencia. = Fuego",
     "Mercurio: El principio mediador, la mente, el espíritu. = Aire/Agua",
     "Sal: El principio pasivo, el cuerpo, la materia. = Tierra",
     "",
     "En el Tarot de Thoth:",
     "- Las Espadas = Mercurio (mente, transmisión de ideas)",
     "- Los Bastos = Sulfuro (voluntad, energía espiritual)",
     "- Los Oros = Sal (materia, mundo físico)",
     "- Las Copas = Agua primordial (emociones, alma)",
     "",
     "##SUB## Las Cuatro Etapas del Gran Trabajo",
     "Nigredo (Negrura): Disolución, muerte del ego. Cartas: Torre, Muerte.",
     "Albedo (Blancura): Purificación, claridad. Cartas: Estrella, Luna.",
     "Citrinitas (Amarillo): Iluminación naciente. Cartas: Sol, Juicio.",
     "Rubedo (Rojez): La piedra filosofal, la iluminación. Carta: El Mundo.",
     "",
     "Cada lectura de Tarot puede entenderse como un mapa del Gran Trabajo:",
     "¿En qué etapa alquímica se encuentra el consultante?"],
    ["##HEAD## Las Cartas de la Corte en el Tarot de Thoth",
     "",
     "Crowley renombró las cartas de la corte para reflejar mejor los",
     "principios elementales del sistema Golden Dawn.",
     "",
     "Princesa (Paje): Tierra del Elemento — la semilla más densa.",
     "Príncipe (Caballero): Aire del Elemento — el pensamiento del elemento.",
     "Reina: Agua del Elemento — el sentimiento del elemento.",
     "Caballero (Rey): Fuego del Elemento — la voluntad pura del elemento.",
     "",
     "Ejemplo: El Caballero de Wands en Thoth es el aspecto Fuego del Fuego,",
     "la voluntad pura en su forma más ardiente y peligrosa.",
     "",
     "##HEAD## Los Arcanos Menores como Decanatos",
     "Crowley asignó cada carta numerada (2-10) a un decanato zodiacal.",
     "Hay 36 decanatos en el zodíaco (12 signos x 3 decanatos) que se alinean",
     "con los 36 Arcanos Menores numerados.",
     "",
     "2 de Bastos: Marte en Aries — Dominio",
     "3 de Bastos: Sol en Aries — Virtud",
     "4 de Bastos: Venus en Aries — Terminación",
     "5 de Bastos: Saturno en Leo — Estrife (Conflicto)",
     "6 de Bastos: Júpiter en Leo — Victoria",
     "7 de Bastos: Marte en Leo — Valor",
     "8 de Bastos: Mercurio en Sagitario — Rapidez",
     "9 de Bastos: Luna en Sagitario — Fuerza (Gran Fortaleza)",
     "10 de Bastos: Saturno en Sagitario — Opresión"],
    ["##HEAD## La Magia del Tarot: Meditación y Visualización",
     "",
     "##SUB## Entrar en una Carta (Pathworking)",
     "El pathworking es una técnica de visualización activa donde el practicante",
     "se sumerge conscientemente en el paisaje de una carta del Tarot.",
     "",
     "Procedimiento básico:",
     "1. Selecciona la carta con la que deseas trabajar.",
     "2. Estúdiala durante al menos 10 minutos, memorizando cada detalle.",
     "3. Cierra los ojos. Visualiza la carta como un portal o puerta.",
     "4. Imagina que la puerta se abre y que entras al mundo de la carta.",
     "5. Interactúa con las figuras y símbolos del paisaje.",
     "6. Recibe el mensaje o la enseñanza de la carta.",
     "7. Regresa por la puerta y ciérrala.",
     "8. Anota tu experiencia inmediatamente.",
     "",
     "##SUB## Meditación con los Cuatro Ases",
     "Los cuatro Ases representan los estados puros de cada elemento.",
     "Meditación de la Semana: Un As por día (4 días), y el quinto día integras.",
     "As de Bastos: Medita sobre una llama. Siente la voluntad y el propósito.",
     "As de Copas: Medita sobre un cuerpo de agua calma. Siente el amor universal.",
     "As de Espadas: Medita sobre el viento. Siente la mente sin límites.",
     "As de Oros: Medita sobre la tierra bajo tus pies. Siente la prosperidad.",
     "Día 5: Visualiza los cuatro elementos fusionándose en tu corazón."],
]

BOOKS.append(("Libro_de_Thoth_y_Alquimia.pdf", thoth_alquimia))


# ── LIBRO 5 ──────────────────────────────────────────────────────────────────
astrologia_decanatos = [
    ["##TITLE## Guía de Astrología y Decanatos Zodiacales",
     "##SUB## Las correspondencias entre el Tarot y el Zodíaco",
     "",
     "Cada carta del Tarot tiene asignada una correspondencia astrológica",
     "precisa, heredada del sistema de la Orden de la Aurora Dorada y refinada",
     "por Aleister Crowley y Paul Foster Case (B.O.T.A.).",
     "",
     "##HEAD## Los 12 Signos y sus Arcanos Mayores",
     "Aries (Fuego Cardinal, Marte): IV - El Emperador",
     "Tauro (Tierra Fija, Venus): V - El Hierofante",
     "Géminis (Aire Mutable, Mercurio): VI - Los Amantes",
     "Cáncer (Agua Cardinal, Luna): VII - El Carro",
     "Leo (Fuego Fijo, Sol): VIII - La Fuerza",
     "Virgo (Tierra Mutable, Mercurio): IX - El Ermitaño",
     "Libra (Aire Cardinal, Venus): XI - La Justicia",
     "Escorpio (Agua Fija, Marte/Plutón): XIII - La Muerte",
     "Sagitario (Fuego Mutable, Júpiter): XIV - La Templanza",
     "Capricornio (Tierra Cardinal, Saturno): XV - El Diablo",
     "Acuario (Aire Fijo, Saturno/Urano): XVII - La Estrella",
     "Piscis (Agua Mutable, Júpiter/Neptuno): XVIII - La Luna"],
    ["##HEAD## Los Planetas y sus Arcanos Mayores",
     "",
     "Mercurio: I - El Mago (voluntad y comunicación)",
     "Luna: II - La Suma Sacerdotisa (subconsciente, intuición)",
     "Venus: III - La Emperatriz (amor, naturaleza, creación)",
     "Júpiter: X - La Rueda de la Fortuna (expansión, destino)",
     "Marte: XVI - La Torre (ruptura, transformación forzada)",
     "Sol: XIX - El Sol (consciencia, vitalidad, iluminación)",
     "Saturno: XXI - El Mundo (completitud, límites del cosmos)",
     "Urano: 0 - El Loco (libertad, lo impredecible)",
     "Neptuno: XII - El Colgado (sacrificio, disolución del ego)",
     "Plutón: XX - El Juicio (regeneración, muerte y renacimiento)",
     "",
     "##HEAD## Los Elementos y sus Palos",
     "",
     "Fuego (Aries, Leo, Sagitario): Palo de Bastos/Varas",
     "Tierra (Tauro, Virgo, Capricornio): Palo de Oros/Pentáculos",
     "Aire (Géminis, Libra, Acuario): Palo de Espadas",
     "Agua (Cáncer, Escorpio, Piscis): Palo de Copas",
     "",
     "Cuando leas el Tarot para alguien, tener en cuenta su signo solar,",
     "su signo lunar y su ascendente puede enriquecer enormemente la lectura.",
     "El signo solar indica el tema del ego, el lunar el tema emocional,",
     "y el ascendente la forma en que esa persona se relaciona con el mundo."],
    ["##HEAD## Los 36 Decanatos: Tabla Completa",
     "",
     "Los 36 decanatos dividen cada signo en tres partes de 10 grados.",
     "Cada decanato está regido por un planeta y corresponde a un Arcano Menor.",
     "",
     "ARIES:",
     "  1er decanato (0-10): Marte   -> 2 de Bastos  (Dominio)",
     "  2do decanato (10-20): Sol    -> 3 de Bastos  (Virtud)",
     "  3er decanato (20-30): Venus  -> 4 de Bastos  (Terminación)",
     "TAURO:",
     "  1er decanato: Mercurio -> 5 de Oros   (Preocupación material)",
     "  2do decanato: Luna     -> 6 de Oros   (Éxito material)",
     "  3er decanato: Saturno  -> 7 de Oros   (Fracaso)",
     "GÉMINIS:",
     "  1er decanato: Júpiter  -> 8 de Espadas (Interferencia)",
     "  2do decanato: Marte    -> 9 de Espadas (Crueldad)",
     "  3er decanato: Sol      -> 10 de Espadas (Ruina)",
     "CÁNCER:",
     "  1er decanato: Venus    -> 2 de Copas  (Amor)",
     "  2do decanato: Mercurio -> 3 de Copas  (Abundancia)",
     "  3er decanato: Luna     -> 4 de Copas  (Lujo o Saciedad)",
     "LEO:",
     "  1er decanato: Saturno  -> 5 de Bastos (Estrife)",
     "  2do decanato: Júpiter  -> 6 de Bastos (Victoria)",
     "  3er decanato: Marte    -> 7 de Bastos (Valor)",
     "VIRGO:",
     "  1er decanato: Sol      -> 8 de Oros   (Prudencia)",
     "  2do decanato: Venus    -> 9 de Oros   (Ganancia)",
     "  3er decanato: Mercurio -> 10 de Oros  (Riqueza)"],
    ["LIBRA:",
     "  1er decanato: Luna     -> 2 de Espadas (Paz restaurada)",
     "  2do decanato: Saturno  -> 3 de Espadas (Pena)",
     "  3er decanato: Júpiter  -> 4 de Espadas (Tregua)",
     "ESCORPIO:",
     "  1er decanato: Marte    -> 5 de Copas  (Pérdida en placer)",
     "  2do decanato: Sol      -> 6 de Copas  (Placer)",
     "  3er decanato: Venus    -> 7 de Copas  (Ilusión)",
     "SAGITARIO:",
     "  1er decanato: Mercurio -> 8 de Bastos (Rapidez)",
     "  2do decanato: Luna     -> 9 de Bastos (Gran Fuerza)",
     "  3er decanato: Saturno  -> 10 de Bastos (Opresión)",
     "CAPRICORNIO:",
     "  1er decanato: Júpiter  -> 2 de Oros   (Cambio armonioso)",
     "  2do decanato: Marte    -> 3 de Oros   (Obras materiales)",
     "  3er decanato: Sol      -> 4 de Oros   (Poder terrenal)",
     "ACUARIO:",
     "  1er decanato: Venus    -> 5 de Espadas (Derrota)",
     "  2do decanato: Mercurio -> 6 de Espadas (Ciencia ganada)",
     "  3er decanato: Luna     -> 7 de Espadas (Esfuerzo inestable)",
     "PISCIS:",
     "  1er decanato: Saturno  -> 8 de Copas  (Éxito abandonado)",
     "  2do decanato: Júpiter  -> 9 de Copas  (Felicidad material)",
     "  3er decanato: Marte    -> 10 de Copas (Saciedad perfecta)",
     "",
     "##HEAD## Cómo usar los Decanatos en una Lectura",
     "Cuando aparece un Arcano Menor numerado, su decanato indica el momento",
     "astrológico preciso: la energía del planeta regente actuando a través del",
     "elemento del palo en el contexto del signo zodiacal.",
     "Ejemplo: El 9 de Copas (Luna en Piscis, 2do decanato) describe la",
     "realización emocional más profunda posible, la 'Felicidad material' de Thoth."],
]

BOOKS.append(("Astrologia_y_Decanatos_Zodiacales.pdf", astrologia_decanatos))


# ── LIBRO 6 ──────────────────────────────────────────────────────────────────
arcanos_menores = [
    ["##TITLE## Simbología Secreta de los Arcanos Menores",
     "##SUB## Guía completa de los 56 Arcanos Menores del Tarot",
     "",
     "Los Arcanos Menores son a menudo subestimados frente a los Mayores,",
     "pero revelan los detalles de la vida cotidiana con una precisión asombrosa.",
     "Esta obra analiza cada carta con su simbolismo, numerología, elemento,",
     "correspondencia astrológica y mensajes en posición derecha e invertida.",
     "",
     "##HEAD## El Palo de Bastos — La Varita del Mago",
     "",
     "Los Bastos representan la voluntad creativa, el espíritu emprendedor",
     "y la energía vital en su forma más pura.",
     "Elemento: Fuego  |  Dirección: Sur  |  Estación: Verano",
     "Color: Rojo, Naranja, Dorado  |  Humor: Colérico",
     "Mundo Cabalístico: Atziluth (el Mundo Arquetípico)"],
    ["##SUB## As de Bastos",
     "Imagen: Una mano sale de las nubes sosteniendo una varita floreciente.",
     "Brotes y hojas simbolizan el crecimiento potencial.",
     "Numerología: 1 = Unidad, origen, semilla primordial.",
     "Astrología: Kether en Atziluth — la voluntad pura de Fuego.",
     "Upright: Inspiración, nuevos comienzos creativos, oportunidades apasionantes,",
     "  energía emprendedora, el primer paso hacia la manifestación.",
     "Reversed: Bloqueos creativos, falta de dirección, proyectos sin comenzar,",
     "  energía estancada, impotencia creativa.",
     "Meditación: ¿Qué proyecto o sueño tiene el potencial de florecer en tu vida?",
     "",
     "##SUB## 2 de Bastos",
     "Imagen: Un hombre de pie en una azotea, mirando el horizonte con un globo.",
     "Numerología: 2 = Dualidad, elección, par de opuestos en equilibrio.",
     "Astrología: Marte en Aries (1er decanato). El guerrero que planifica.",
     "Upright: Planificación a largo plazo, visión de futuro, poder personal,",
     "  expansión de horizontes, decisión de aventurarse al mundo.",
     "Reversed: Falta de planificación, miedos al mundo exterior, planes fallidos.",
     "Meditación: ¿Qué visión de futuro te llena de energía y entusiasmo?",
     "",
     "##SUB## 3 de Bastos",
     "Imagen: Un hombre mira barcos en el mar. Ha enviado su flota al mundo.",
     "Astrología: Sol en Aries (2do decanato). La confianza del triunfador.",
     "Upright: Expansión, empresa exitosa, liderazgo, visión a largo plazo,",
     "  resultados que se materializan, colaboraciones fructíferas.",
     "Reversed: Retrasos, oportunidades perdidas, planes que no se concretan."],
    ["##SUB## 4 de Bastos",
     "Imagen: Dos personas celebran bajo un dosel de flores. Fiesta y hogar.",
     "Astrología: Venus en Aries (3er decanato). El amor que construye hogar.",
     "Upright: Celebración, hogar armonioso, comunidad, logros festejados,",
     "  matrimonios, inauguraciones, eventos sociales gozosos.",
     "Reversed: Conflictos en el hogar, celebraciones postergadas.",
     "",
     "##SUB## 5 de Bastos",
     "Imagen: Cinco jóvenes se pelean con bastones. Caos y competencia.",
     "Astrología: Saturno en Leo (1er decanato). La restricción al ego.",
     "Upright: Conflicto, competencia, desafíos, energía caótica que lleva al",
     "  crecimiento. También puede indicar debate creativo y negociación.",
     "Reversed: Evitación del conflicto, conflicto interno, competencia desleal.",
     "",
     "##SUB## 6 de Bastos",
     "Imagen: Un líder a caballo es recibido con laureles. Retorno victorioso.",
     "Astrología: Júpiter en Leo (2do decanato). La expansión del ego ganador.",
     "Upright: Victoria, reconocimiento público, confianza, liderazgo exitoso,",
     "  buen progreso, noticias favorables, éxito merecido.",
     "Reversed: Ego inflado, derrota disfrazada, falta de reconocimiento.",
     "",
     "##SUB## 7 de Bastos",
     "Imagen: Un hombre defiende su posición desde lo alto de una colina.",
     "Astrología: Marte en Leo (3er decanato). El guerrero en su territorio.",
     "Upright: Defensa de la posición, perseverancia, mantener ventaja,",
     "  competencia, valor frente a los desafíos, posición ganada.",
     "Reversed: Abrumado por la oposición, rendirse antes de tiempo."],
    ["##HEAD## El Palo de Copas — El Cáliz del Alma",
     "",
     "Las Copas rigen todo el espectro emocional: el amor romántico,",
     "la intuición, los sueños, las relaciones y la conexión espiritual.",
     "Elemento: Agua  |  Dirección: Oeste  |  Estación: Otoño",
     "Color: Azul, Turquesa, Verde agua  |  Humor: Flemático",
     "Mundo Cabalístico: Briah (el Mundo de la Creación)",
     "",
     "##SUB## As de Copas",
     "Imagen: Una copa desbordante sostenida por una mano divina.",
     "Una paloma desciende con una oblea sagrada. Agua de gracia infinita.",
     "Upright: Amor incondicional, apertura emocional, abundancia espiritual,",
     "  nuevas relaciones, intuición despierta, fertilidad, gracia divina.",
     "Reversed: Bloqueo emocional, amor reprimido, vacío interior.",
     "",
     "##SUB## 2 de Copas",
     "Imagen: Dos personas intercambian copas bajo el caduceo alado.",
     "El Caduceo de Hermes simboliza la unión de opuestos complementarios.",
     "Astrología: Venus en Cáncer — el amor en el hogar del alma.",
     "Upright: Unión romántica, sociedad, atracción mutua, compromiso,",
     "  reconciliación, amistad profunda, relación equilibrada.",
     "Reversed: Ruptura, desequilibrio en la relación, incompatibilidad.",
     "",
     "##SUB## 3 de Copas",
     "Imagen: Tres mujeres danzan en círculo, alzando sus copas.",
     "Astrología: Mercurio en Cáncer — la mente que celebra el alma.",
     "Upright: Celebración, amistad, abundancia compartida, reuniones sociales,",
     "  bodas, graduaciones, festividades, comunidad amorosa.",
     "Reversed: Excesos, decepción en grupo, chismes, conflicto con amigas."],
]

BOOKS.append(("Simbologia_Arcanos_Menores.pdf", arcanos_menores))


# ── LIBRO 7 ──────────────────────────────────────────────────────────────────
cabala_arbol = [
    ["##TITLE## El Árbol de la Vida y la Cábala del Tarot",
     "##SUB## La conexión profunda entre el Sefer Yetzirah y el Tarot",
     "",
     "El Árbol de la Vida (Etz Hayim) es el diagrama central de la tradición",
     "cabalística. Este mapa del cosmos y del alma humana se convirtió, a través",
     "de la Orden de la Aurora Dorada, en el eje organizativo de todo el sistema",
     "del Tarot occidental moderno.",
     "",
     "##HEAD## Las 10 Sefirot",
     "",
     "Las Sefirot son los 10 centros o esferas del Árbol de la Vida, cada una",
     "representando un aspecto de la divinidad y de la psique humana.",
     "",
     "1. KETHER (Corona): La fuente primordial. Consciencia pura sin forma.",
     "   Color: Blanco brillante. Planeta: Neptuno/Primer Motor.",
     "   Arcano: XXI El Mundo (la voluntad que mueve todo).",
     "",
     "2. CHOKMAH (Sabiduría): El primer impulso, el yang cósmico.",
     "   Color: Gris perla. Planeta: Zodíaco/Urano.",
     "   Arcano: El Loco (la sabiduría inocente del espíritu).",
     "",
     "3. BINAH (Entendimiento): La Gran Madre, la forma que contiene.",
     "   Color: Negro. Planeta: Saturno.",
     "   Arcanos: Los 3 de todos los palos (limitación creativa).",
     "",
     "4. CHESED (Misericordia): La expansión generosa del ser.",
     "   Color: Azul. Planeta: Júpiter.",
     "   Arcanos: Los 4 de todos los palos (estabilidad y abundancia).",
     "",
     "5. GEBURAH (Fuerza): El juicio y la restricción necesarios.",
     "   Color: Rojo. Planeta: Marte.",
     "   Arcanos: Los 5 de todos los palos (conflicto y cambio)."],
    ["6. TIPHARETH (Belleza): El corazón del Árbol, el Sol, el Cristo.",
     "   Color: Amarillo/Dorado. Planeta: Sol.",
     "   Arcanos: Los 6 de todos los palos (armonía y equilibrio).",
     "",
     "7. NETZACH (Victoria): Las emociones, los deseos, lo venusiano.",
     "   Color: Verde esmeralda. Planeta: Venus.",
     "   Arcanos: Los 7 de todos los palos (evaluación y movimiento).",
     "",
     "8. HOD (Esplendor): El intelecto, la comunicación, Mercurio.",
     "   Color: Naranja. Planeta: Mercurio.",
     "   Arcanos: Los 8 de todos los palos (movimiento y habilidad).",
     "",
     "9. YESOD (Fundamento): El inconsciente, los sueños, la Luna.",
     "   Color: Violeta. Planeta: Luna.",
     "   Arcanos: Los 9 de todos los palos (completitud casi final).",
     "",
     "10. MALKUTH (Reino): El mundo físico, la manifestación completa.",
     "    Color: Amarillo, negro, oliva, russet. Planeta: Tierra.",
     "    Arcanos: Los 10 y los Ases de todos los palos.",
     "",
     "##HEAD## Los Tres Pilares del Árbol",
     "Pilar de la Misericordia (derecha): Chokmah, Chesed, Netzach.",
     "  El principio activo, masculino, expansivo.",
     "Pilar de la Severidad (izquierda): Binah, Geburah, Hod.",
     "  El principio pasivo, femenino, restrictivo.",
     "Pilar del Equilibrio (centro): Kether, Tiphareth, Yesod, Malkuth.",
     "  El camino del medio, la integración, la conciencia."],
    ["##HEAD## Los 22 Senderos y los Arcanos Mayores",
     "",
     "Los 22 senderos que conectan las 10 Sefirot corresponden exactamente",
     "a los 22 Arcanos Mayores. Recorrer estos senderos en meditación es",
     "el trabajo esotérico fundamental en la tradición hermética.",
     "",
     "Sendero 11 (Kether-Chokmah): El Loco - Aleph - Aire",
     "Sendero 12 (Kether-Binah): El Mago - Beth - Mercurio",
     "Sendero 13 (Kether-Tiphareth): La Sacerdotisa - Gimel - Luna",
     "Sendero 14 (Chokmah-Binah): La Emperatriz - Daleth - Venus",
     "Sendero 15 (Chokmah-Tiphareth): El Emperador - Heh - Aries",
     "Sendero 16 (Chokmah-Chesed): El Hierofante - Vav - Tauro",
     "Sendero 17 (Binah-Tiphareth): Los Amantes - Zayin - Géminis",
     "Sendero 18 (Binah-Geburah): El Carro - Cheth - Cáncer",
     "Sendero 19 (Chesed-Geburah): La Fuerza - Teth - Leo",
     "Sendero 20 (Chesed-Tiphareth): El Ermitaño - Yod - Virgo",
     "Sendero 21 (Chesed-Netzach): Rueda Fortuna - Kaph - Júpiter",
     "Sendero 22 (Geburah-Tiphareth): La Justicia - Lamed - Libra",
     "Sendero 23 (Geburah-Hod): El Colgado - Mem - Agua",
     "Sendero 24 (Tiphareth-Netzach): La Muerte - Nun - Escorpio",
     "Sendero 25 (Tiphareth-Yesod): La Templanza - Samech - Sagitario",
     "Sendero 26 (Tiphareth-Hod): El Diablo - Ayin - Capricornio",
     "Sendero 27 (Netzach-Hod): La Torre - Peh - Marte",
     "Sendero 28 (Netzach-Yesod): La Estrella - Tzaddi - Acuario",
     "Sendero 29 (Netzach-Malkuth): La Luna - Qoph - Piscis",
     "Sendero 30 (Hod-Yesod): El Sol - Resh - Sol",
     "Sendero 31 (Hod-Malkuth): El Juicio - Shin - Fuego",
     "Sendero 32 (Yesod-Malkuth): El Mundo - Tav - Saturno"],
]

BOOKS.append(("Arbol_de_la_Vida_y_Cabala.pdf", cabala_arbol))


# ── LIBRO 8 ──────────────────────────────────────────────────────────────────
tiradas_amor = [
    ["##TITLE## Manual Práctico de Tiradas de Amor y Relaciones",
     "##SUB## 15 tiradas especializadas en el amor, las relaciones y el alma",
     "",
     "El amor es el tema más consultado en el Tarot. Este manual reúne las",
     "tiradas más efectivas para explorar el corazón, las relaciones románticas,",
     "los lazos del alma y el camino hacia el amor propio.",
     "",
     "##HEAD## Parte I: Fundamentos del Tarot del Amor",
     "",
     "##SUB## Las Cartas del Amor por Excelencia",
     "2 de Copas: La unión de dos almas, la primera chispa del amor.",
     "Los Amantes (VI): La elección del corazón, la alineación de valores.",
     "10 de Copas: La felicidad familiar, el amor completo y realizado.",
     "La Emperatriz (III): El amor incondicional, la fertilidad del corazón.",
     "La Luna (XVIII): El amor misterioso, las ilusiones y los sueños románticos.",
     "El Sol (XIX): El amor claro, la alegría, la conexión luminosa.",
     "El As de Copas: El nacimiento del amor, la apertura del corazón.",
     "",
     "##SUB## Cartas que Indican Desafíos en el Amor",
     "3 de Espadas: Corazón roto, traición, dolor emocional.",
     "5 de Copas: Enfoque en la pérdida, incapacidad de ver lo que queda.",
     "El Diablo (XV): Relaciones tóxicas, apego malsano, cadenas del ego.",
     "La Torre (XVI): Ruptura repentina, revelaciones que sacuden la relación.",
     "7 de Espadas: Engaño, mentiras en la relación, traición sutil."],
    ["##HEAD## Tirada 1: El Espejo del Corazón (5 cartas)",
     "",
     "Para: Entender el estado actual de una relación romántica.",
     "",
     "Posición 1 (Centro): El corazón de la relación.",
     "  Lo que une a ambas personas en este momento.",
     "Posición 2 (Izquierda): Yo en la relación.",
     "  Cómo me relaciono y qué aporto a la dinámica.",
     "Posición 3 (Derecha): La otra persona.",
     "  Su energía y su perspectiva en la relación.",
     "Posición 4 (Arriba): El potencial de la relación.",
     "  A dónde puede llegar si se trabaja conscientemente.",
     "Posición 5 (Abajo): Lo que necesita sanar.",
     "  La herida, el patrón o el miedo que obstaculiza el amor.",
     "",
     "##HEAD## Tirada 2: ¿Es él/ella mi persona? (7 cartas)",
     "",
     "Para: Evaluar si una persona específica es compatible a largo plazo.",
     "",
     "Pos. 1: La energía de él/ella ahora mismo.",
     "Pos. 2: La energía de ti mismo/a ahora mismo.",
     "Pos. 3: Lo que los atrae mutuamente (la chispa).",
     "Pos. 4: Lo que los desafía mutuamente (la fricción).",
     "Pos. 5: El potencial de la relación a largo plazo.",
     "Pos. 6: Lo que el universo quiere que sepas sobre esta persona.",
     "Pos. 7: ¿Es esta tu persona? La respuesta general de las cartas.",
     "",
     "Nota: Si la carta 7 es un Arcano Mayor, se sugiere que hay un karma",
     "importante entre ambas almas. Si es un Arcano Menor de Copas, el",
     "potencial emocional es alto. Si es de Espadas, hay trabajo que hacer."],
    ["##HEAD## Tirada 3: El Triángulo del Amor (3 cartas)",
     "Pos. 1: Yo. Pos. 2: La otra persona. Pos. 3: La relación misma.",
     "Simple pero profunda para ver la dinámica fundamental.",
     "",
     "##HEAD## Tirada 4: ¿Volverá? (6 cartas)",
     "Pos. 1: Energía actual entre ambos.",
     "Pos. 2: Sus sentimientos reales.",
     "Pos. 3: Mis sentimientos reales.",
     "Pos. 4: ¿Qué necesita pasar para una reconciliación?",
     "Pos. 5: El obstáculo principal.",
     "Pos. 6: El resultado si intento la reconciliación.",
     "Consejo: Esta lectura es informativa, no determinista. El libre albedrío",
     "siempre puede cambiar el resultado. Úsala para comprender, no para obsesionarte.",
     "",
     "##HEAD## Tirada 5: Amor Propio y Sanación (9 cartas)",
     "Para: Trabajo personal de autoamor y sanación del corazón.",
     "Pos. 1: Mi estado emocional actual.",
     "Pos. 2: La herida del corazón que cargo.",
     "Pos. 3: Su origen (de dónde viene esta herida).",
     "Pos. 4: Cómo ha afectado mis relaciones.",
     "Pos. 5: Lo que necesito soltar.",
     "Pos. 6: Lo que necesito abrazar.",
     "Pos. 7: Mi superpoder emocional (el don de mis experiencias).",
     "Pos. 8: El siguiente paso en mi camino de sanación.",
     "Pos. 9: El mensaje de amor que mi yo superior me envía.",
     "",
     "##HEAD## Tirada 6: Compatibilidad de Almas (12 cartas)",
     "Una tirada exhaustiva para relaciones importantes.",
     "Pos. 1-3: Mi mundo interior (mente, emoción, espíritu).",
     "Pos. 4-6: Su mundo interior (mente, emoción, espíritu).",
     "Pos. 7-9: La dinámica compartida (comunicación, amor, sexualidad).",
     "Pos. 10: El propósito kármico de la relación.",
     "Pos. 11: El desafío más grande a superar.",
     "Pos. 12: El potencial máximo de la relación."],
]

BOOKS.append(("Manual_Tiradas_de_Amor.pdf", tiradas_amor))


# ── LIBRO 9 ──────────────────────────────────────────────────────────────────
intuicion_psiquica = [
    ["##TITLE## Tarot e Intuición Psíquica y Canalización",
     "##SUB## Desarrolla tus habilidades intuitivas a través del Tarot",
     "",
     "El Tarot no es solo un sistema de símbolos sino un espejo del alma y una",
     "puerta a la intuición profunda. Este libro te guía en el desarrollo de tus",
     "capacidades psíquicas naturales usando el Tarot como vehículo.",
     "",
     "##HEAD## Capítulo 1: Tu Intuición es Real",
     "",
     "La intuición es la capacidad del alma de percibir directamente sin pasar",
     "por la mente lógica. Todos la tenemos; el Tarot nos ayuda a escucharla.",
     "",
     "##SUB## Los Cuatro Canales Psíquicos",
     "Claividencia: Ver imágenes, colores, escenas con el ojo interior.",
     "Clairaudience: Escuchar palabras, frases o melodías internas.",
     "Clairsentience: Sentir emociones y sensaciones físicas de información.",
     "Claircognizance: Simplemente 'saber' algo sin razón aparente.",
     "",
     "Cuando lees el Tarot, ¿cuál de estos canales sientes más activo en ti?",
     "Identifica tu canal primario y trabaja con él conscientemente.",
     "",
     "##SUB## Ejercicio de Activación",
     "1. Sostén el mazo de Tarot entre tus manos. Cierra los ojos.",
     "2. Siente el peso, la temperatura y la textura de las cartas.",
     "3. Pregunta: '¿Cuál es el mensaje que necesito hoy?'",
     "4. Baraja y extrae una carta sin mirarla.",
     "5. Con la carta boca abajo, intenta 'sentir' su mensaje.",
     "6. Anota tus impresiones y luego voltea la carta.",
     "7. Compara tu percepción con el significado tradicional."],
    ["##HEAD## Capítulo 2: La Lectura Psíquica del Tarot",
     "",
     "##SUB## La Diferencia entre Lectura Intuitiva y Memorizada",
     "Una lectura memorizada repite definiciones del libro.",
     "Una lectura intuitiva deja que la imagen hable directamente al lector.",
     "La lectura psíquica va más allá: el lector recibe información que",
     "trasciende la imagen, que viene 'a través' de la carta como canal.",
     "",
     "##SUB## Cómo Desarrollar la Lectura Psíquica",
     "Paso 1: Aprende el lenguaje simbólico básico de las cartas.",
     "Paso 2: Practica describir SOLO lo que ves en la imagen.",
     "Paso 3: Deja que las imágenes te cuenten una historia.",
     "Paso 4: Nota las sensaciones físicas que sientes con cada carta.",
     "Paso 5: Confía en la primera impresión sin censura.",
     "Paso 6: Con el tiempo, la información psíquica llegará naturalmente.",
     "",
     "##HEAD## Capítulo 3: El Tarot como Herramienta de Canalización",
     "",
     "La canalización es la práctica de ser un vehículo para sabiduría superior.",
     "Muchos tarotistas avanzados sienten que las cartas actúan como un sistema",
     "de 'sintonización' para conectar con guías espirituales, el Yo Superior",
     "o el inconsciente colectivo (Carl Jung).",
     "",
     "##SUB## Protocolo de Canalización con el Tarot",
     "1. Prepara el espacio: silencio, luz suave, incienso, altar.",
     "2. Centramiento: 7 respiraciones conscientes.",
     "3. Invocación: 'Invoco a mi Yo Superior y guías de la más alta vibración.'",
     "4. Extrae una carta como punto de entrada.",
     "5. Contempla la carta con ojos semicerrados.",
     "6. Permite que los símbolos 'hablen' o evoquen mensajes.",
     "7. Cierra: 'Gracias. Me desconecto y me enraízo en la tierra.'",
     "8. Bebe agua y anota todo lo recibido."],
    ["##HEAD## Capítulo 4: Jung y el Tarot — El Inconsciente Hecho Imagen",
     "",
     "Carl Gustav Jung nunca escribió directamente sobre el Tarot, pero sus",
     "teorías sobre el inconsciente colectivo y los arquetipos son la base",
     "psicológica más sólida para entender cómo funciona el Tarot.",
     "",
     "##SUB## Los Arquetipos Junguianos en el Tarot",
     "El Sí-mismo (Self): El Mundo — la totalidad integrada del ser.",
     "La Sombra: El Diablo — lo reprimido, lo no integrado.",
     "El Anima: La Suma Sacerdotisa, La Emperatriz, La Justicia.",
     "El Animus: El Mago, El Emperador, El Hierofante.",
     "El Viejo Sabio: El Ermitaño — la guía del inconsciente profundo.",
     "La Gran Madre: La Emperatriz — el arquetipo nutritivo y creador.",
     "El Trickster: El Loco — lo imprevisible, el caos creativo.",
     "El Héroe: El Sol, El Carro — el ego en su fase triunfante.",
     "",
     "##SUB## Sincronicidad: Por Qué las Cartas 'Funcionan'",
     "Jung propuso el concepto de sincronicidad: la coincidencia significativa",
     "entre eventos internos (pensamientos, sueños) y externos (la carta extraída).",
     "La carta que aparece no es aleatoria desde el punto de vista psíquico:",
     "el estado de ánimo, la pregunta y el momento crean una resonancia que",
     "atrae la carta 'correcta'. Esta es la explicación psicológica del Tarot.",
     "",
     "##HEAD## Capítulo 5: Ejercicios para Desarrollar la Intuición",
     "",
     "Ejercicio 1 (Semana 1): Carta del día. Antes de verla, predice el palo.",
     "Ejercicio 2 (Semana 2): Extrae una carta para alguien que conoces.",
     "  Sin decírselo, observa si la carta describe su situación real.",
     "Ejercicio 3 (Semana 3): Lectura por sentido del tacto (psychometry).",
     "  Baraja boca abajo y señala la carta que 'sientas' antes de verla.",
     "Ejercicio 4 (Semana 4): Escribe automáticamente mientras contemplas una carta.",
     "  No corrijas ni juzgues. Deja que fluya. Lee después."],
]

BOOKS.append(("Tarot_e_Intuicion_Psiquica.pdf", intuicion_psiquica))


# ─────────────────────────────────────────────────────────────────────────────
# Generación
# ─────────────────────────────────────────────────────────────────────────────

os.makedirs('TarotContent/Resources/Books', exist_ok=True)

for filename, pages in BOOKS:
    pdf = SimplePDF()
    for page_lines in pages:
        pdf.add_page(page_lines)
    path = os.path.join('TarotContent/Resources/Books', filename)
    pdf.save(path)
    size_kb = os.path.getsize(path) / 1024
    print(f"  ✓ {filename}  ({size_kb:.1f} KB, {len(pages)} páginas)")

print(f"\n{len(BOOKS)} PDFs generados con contenido completo.")
