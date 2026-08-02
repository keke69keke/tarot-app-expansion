import json

def process_cards():
    with open('TarotContent/Resources/cards.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    for card in data['cards']:
        arcana = card.get('arcanaType', '')
        suit = card.get('suit', '')
        name = card.get('name', '')
        number_str = card.get('number', '')
        
        # 1. Yes/No
        if arcana == 'major':
            if name in ['El Sol', 'El Mundo', 'El Mago', 'La Estrella', 'El Emperador', 'La Emperatriz']:
                card['yesNo'] = "Sí, definitivamente."
            elif name in ['La Torre', 'La Muerte', 'El Diablo', 'La Luna']:
                card['yesNo'] = "No, reconsidera tu enfoque."
            else:
                card['yesNo'] = "Tal vez, depende de tus acciones."
        else:
            if suit in ['cups', 'wands']:
                card['yesNo'] = "Sí."
            elif suit == 'pentacles':
                card['yesNo'] = "Sí, pero requerirá paciencia y trabajo."
            else:
                card['yesNo'] = "No, o enfrentará obstáculos (Espadas)."
                
        # 2. Chakras
        if arcana == 'major':
            card['chakras'] = "Chakras Superiores (Tercer Ojo, Corona)"
        else:
            if suit == 'cups':
                card['chakras'] = "Chakra Sacro y Corazón"
            elif suit == 'wands':
                card['chakras'] = "Chakra del Plexo Solar"
            elif suit == 'swords':
                card['chakras'] = "Chakra de la Garganta y Tercer Ojo"
            elif suit == 'pentacles':
                card['chakras'] = "Chakra Raíz"

        # 3. Crystals
        if arcana == 'major':
            card['crystals'] = "Cuarzo Claro, Amatista, Obsidiana"
        else:
            if suit == 'cups':
                card['crystals'] = "Cuarzo Rosa, Aguamarina, Piedra Lunar"
            elif suit == 'wands':
                card['crystals'] = "Cornalina, Citrino, Ojo de Tigre"
            elif suit == 'swords':
                card['crystals'] = "Lapislázuli, Sodalita, Fluorita"
            elif suit == 'pentacles':
                card['crystals'] = "Jade, Esmeralda, Pirita, Turmalina Negra"

        # 4. Affirmation
        if arcana == 'major':
            card['affirmation'] = "Acepto mi destino y la transformación de mi camino."
        else:
            if suit == 'cups':
                card['affirmation'] = "Fluyo con mis emociones y abro mi corazón."
            elif suit == 'wands':
                card['affirmation'] = "Sigo mi pasión y actúo con confianza."
            elif suit == 'swords':
                card['affirmation'] = "Mi mente es clara y mis pensamientos son poderosos."
            elif suit == 'pentacles':
                card['affirmation'] = "Construyo mi futuro sobre bases sólidas."

        # 5. Mythology
        if arcana == 'major':
            card['mythology'] = "Arquetipos universales (El viaje del Héroe)"
        else:
            if suit == 'cups':
                card['mythology'] = "Afrodita, Poseidón (Dioses del Agua y Amor)"
            elif suit == 'wands':
                card['mythology'] = "Apolo, Ares (Dioses del Sol y la Guerra)"
            elif suit == 'swords':
                card['mythology'] = "Atenea (Diosa de la Sabiduría y la Estrategia)"
            elif suit == 'pentacles':
                card['mythology'] = "Deméter (Diosa de la Agricultura y Abundancia)"

        # 6. Zodiacal Decan
        if arcana == 'minor' and number_str not in ['As', 'Page', 'Knight', 'Queen', 'King', 'Sota', 'Caballero', 'Reina', 'Rey']:
            card['zodiacalDecan'] = f"Decanato astrológico según la Aurora Dorada (Asociado a {suit})"
        else:
            if arcana == 'major':
                card['zodiacalDecan'] = "Asociación Zodiacal Directa (Planeta/Signo)"

    with open('TarotContent/Resources/cards.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

if __name__ == '__main__':
    process_cards()
    print("cards.json enriquecido con la Fase 3 con éxito.")
