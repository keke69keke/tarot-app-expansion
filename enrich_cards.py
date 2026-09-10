import json
import os

file_path = "TarotContent/Resources/cards.json"

with open(file_path, "r", encoding="utf-8") as f:
    data = json.load(f)

major_arcana_data = {
    0: {"astro": "Urano (Aire)", "kabbalah": "Sendero 11: Aleph", "num": "0", "elem": "Aire"},
    1: {"astro": "Mercurio", "kabbalah": "Sendero 12: Beth", "num": "1", "elem": "Aire"},
    2: {"astro": "La Luna", "kabbalah": "Sendero 13: Gimel", "num": "2", "elem": "Agua"},
    3: {"astro": "Venus", "kabbalah": "Sendero 14: Daleth", "num": "3", "elem": "Tierra"},
    4: {"astro": "Aries", "kabbalah": "Sendero 15: Heh", "num": "4", "elem": "Fuego"},
    5: {"astro": "Tauro", "kabbalah": "Sendero 16: Vav", "num": "5", "elem": "Tierra"},
    6: {"astro": "Géminis", "kabbalah": "Sendero 17: Zain", "num": "6", "elem": "Aire"},
    7: {"astro": "Cáncer", "kabbalah": "Sendero 18: Cheth", "num": "7", "elem": "Agua"},
    8: {"astro": "Leo", "kabbalah": "Sendero 19: Teth", "num": "8", "elem": "Fuego"},
    9: {"astro": "Virgo", "kabbalah": "Sendero 20: Yod", "num": "9", "elem": "Tierra"},
    10: {"astro": "Júpiter", "kabbalah": "Sendero 21: Kaph", "num": "10", "elem": "Fuego"},
    11: {"astro": "Libra", "kabbalah": "Sendero 22: Lamed", "num": "11", "elem": "Aire"},
    12: {"astro": "Neptuno (Agua)", "kabbalah": "Sendero 23: Mem", "num": "12", "elem": "Agua"},
    13: {"astro": "Escorpio", "kabbalah": "Sendero 24: Nun", "num": "13", "elem": "Agua"},
    14: {"astro": "Sagitario", "kabbalah": "Sendero 25: Samekh", "num": "14", "elem": "Fuego"},
    15: {"astro": "Capricornio", "kabbalah": "Sendero 26: Ayin", "num": "15", "elem": "Tierra"},
    16: {"astro": "Marte", "kabbalah": "Sendero 27: Peh", "num": "16", "elem": "Fuego"},
    17: {"astro": "Acuario", "kabbalah": "Sendero 28: Tzaddi", "num": "17", "elem": "Aire"},
    18: {"astro": "Piscis", "kabbalah": "Sendero 29: Qoph", "num": "18", "elem": "Agua"},
    19: {"astro": "El Sol", "kabbalah": "Sendero 30: Resh", "num": "19", "elem": "Fuego"},
    20: {"astro": "Plutón (Fuego)", "kabbalah": "Sendero 31: Shin", "num": "20", "elem": "Fuego"},
    21: {"astro": "Saturno (Tierra)", "kabbalah": "Sendero 32: Tau", "num": "21", "elem": "Tierra"},
}

suits_map = {
    "wands": {"elem": "Fuego", "astro": "Signos de Fuego"},
    "cups": {"elem": "Agua", "astro": "Signos de Agua"},
    "swords": {"elem": "Aire", "astro": "Signos de Aire"},
    "pentacles": {"elem": "Tierra", "astro": "Signos de Tierra"}
}

for card in data["cards"]:
    if card["arcanaType"] == "major":
        c_id = card["id"]
        if c_id in major_arcana_data:
            card["astrology"] = major_arcana_data[c_id]["astro"]
            card["kabbalah"] = major_arcana_data[c_id]["kabbalah"]
            card["numerology"] = major_arcana_data[c_id]["num"]
            card["element"] = major_arcana_data[c_id]["elem"]
            card["lightShadow"] = "Luz: Consciencia. Sombra: Caos."
    else:
        suit = card.get("suit", "wands")
        s_data = suits_map.get(suit, {"elem": "Desconocido", "astro": "Desconocido"})
        card["element"] = s_data["elem"]
        card["astrology"] = s_data["astro"]
        num = card.get("number", "")
        card["numerology"] = num
        
        sephiroth_map = {
            "1": "Kether", "2": "Chokmah", "3": "Binah",
            "4": "Chesed", "5": "Geburah", "6": "Tiphareth",
            "7": "Netzach", "8": "Hod", "9": "Yesod", "10": "Malkuth"
        }
        
        if num in sephiroth_map:
            card["kabbalah"] = sephiroth_map[num]
        else:
            card["kabbalah"] = f"Expresión de {s_data['elem']} en la Tierra."
            
        card["lightShadow"] = f"Luz: Expresión equilibrada de {s_data['elem']}. Sombra: Desequilibrio de la energía elemental."

    if "aspects" not in card["upright"]: card["upright"]["aspects"] = {}
    card["upright"]["aspects"]["Amor"] = f"En lo sentimental, {card['name']} aporta una energía constructiva y un consejo directo sobre el estado de la relación."
    card["upright"]["aspects"]["Economía"] = f"En economía, esta carta ofrece una visión general que se puede aplicar a los procesos personales y materiales de la vida."
    card["upright"]["aspects"]["Salud"] = f"A nivel físico, sugiere vitalidad y fluidez de la energía del elemento {card.get('element', '')}."
    card["upright"]["aspects"]["Carrera"] = f"Profesionalmente, indica un periodo en sintonía con las características del arcano."

    if "aspects" not in card["reversed"]: card["reversed"]["aspects"] = {}
    card["reversed"]["aspects"]["Amor"] = "Desafíos o bloqueos en la comunicación sentimental. Necesidad de introspección."
    card["reversed"]["aspects"]["Economía"] = "En economía, esta carta ofrece una visión general que se puede aplicar a los procesos personales y materiales de la vida."
    card["reversed"]["aspects"]["Salud"] = "Atención a posibles desequilibrios. Precaución preventiva recomendada."
    card["reversed"]["aspects"]["Carrera"] = "Retrasos o reevaluación de los proyectos actuales."

with open(file_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("cards.json successfully enriched.")
