#!/usr/bin/env python3
import json, os, re, zipfile, io

json_path = "/Users/nicole/Downloads/Tarot/scratch/book_ocr_text.json"
epub_out_path = "/Users/nicole/Downloads/Tarot_Rider_Waite_Guia_Definitiva.epub"
resource_epub_path = "/Users/nicole/Downloads/Tarot/TarotContent/Resources/Tarot_Guia_Definitiva.epub"
resource_json_path = "/Users/nicole/Downloads/Tarot/TarotContent/Resources/book_chapters.json"

if not os.path.exists(json_path):
    print("Waiting for OCR JSON file...")
    exit(0)

with open(json_path, "r", encoding="utf-8") as f:
    pages = json.load(f)

print(f"Loaded {len(pages)} OCR pages.")

# Clean up page text: remove standalone page numbers, header/footer noise
cleaned_pages = []
for p in pages:
    p_num = p["page"]
    lines = p["text"].split("\n")
    filtered = []
    for line in lines:
        s = line.strip()
        # Filter out standalone page numbers
        if s.isdigit() and int(s) == p_num:
            continue
        if re.match(r"^\d{1,3}\s*$", s) and abs(int(s) - p_num) <= 2:
            continue
        filtered.append(line)
    cleaned_pages.append("\n".join(filtered))

full_text = "\n\n".join(cleaned_pages)

# Detect major chapters and sections
chapter_title_patterns = [
    r"^(10 razones para escribir este libro)",
    r"^(Una interpretación del Tarot sencilla y clara)",
    r"^(Las 10 mejores definiciones del Tarot)",
    r"^(Los 10 datos más importantes del Tarot)",
    r"^(Las 10 mejores maneras de utilizar una única carta)",
    r"^(Las 10 tiradas principales)",
    r"^(Las 10 normas más importantes de la interpretación)",
    r"^(10 consejos útiles para la interpretación)",
    r"^(Un repaso a los Arcanos Mayores y Menores)",
    r"^(Símbolos e interpretaciones importantes)",
    r"^(Arcanos Mayores)",
    r"^(Bastos)",
    r"^(Copas)",
    r"^(Espadas)",
    r"^(Oros)",
    r"^(Tarot y astrología)",
    r"^(Acerca de los autores)"
]

# Structure into chapters
chapters = []
current_title = "Portada e Introducción"
current_lines = []

for line in full_text.split("\n"):
    s = line.strip()
    is_heading = False
    for pat in chapter_title_patterns:
        if re.search(pat, s, re.IGNORECASE):
            if current_lines:
                chapters.append({
                    "title": current_title,
                    "content": "\n".join(current_lines).strip()
                })
                current_lines = []
            current_title = s
            is_heading = True
            break
    if not is_heading:
        current_lines.append(line)

if current_lines:
    chapters.append({
        "title": current_title,
        "content": "\n".join(current_lines).strip()
    })

print(f"Structured into {len(chapters)} chapters.")

# Also save chapters JSON for built-in Swift eBook Reader
structured_book_json = []
for idx, ch in enumerate(chapters):
    structured_book_json.append({
        "id": idx + 1,
        "title": ch["title"],
        "content": ch["content"]
    })

os.makedirs(os.path.dirname(resource_json_path), exist_ok=True)
with open(resource_json_path, "w", encoding="utf-8") as f:
    json.dump(structured_book_json, f, ensure_ascii=False, indent=2)

print(f"Saved structured book JSON to {resource_json_path}")

# Build EPUB file in memory / zip
def create_epub(out_file_path):
    with zipfile.ZipFile(out_file_path, "w", zipfile.ZIP_DEFLATED) as z:
        # 1. mimetype (MUST be uncompressed and first file in zip)
        z.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)

        # 2. META-INF/container.xml
        container_xml = """<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    </rootfiles>
</container>"""
        z.writestr("META-INF/container.xml", container_xml)

        # 3. OEBPS/styles.css
        css = """body {
    font-family: "Georgia", "Times New Roman", serif;
    font-size: 1.1em;
    line-height: 1.6;
    color: #2C2C2C;
    background-color: #FAFAFA;
    margin: 5% 8%;
    padding: 0;
}
h1, h2, h3 {
    font-family: "Cinzel", "Helvetica Neue", sans-serif;
    color: #5B2C6F;
    text-align: center;
    margin-top: 1.5em;
    margin-bottom: 0.8em;
}
h1 { font-size: 1.8em; border-bottom: 2px solid #D4AC0D; padding-bottom: 0.3em; }
h2 { font-size: 1.4em; }
p {
    text-indent: 1.5em;
    margin-top: 0;
    margin-bottom: 0.8em;
    text-align: justify;
}
.subtitle {
    text-align: center;
    font-style: italic;
    color: #7D3C98;
    margin-bottom: 2em;
}
"""
        z.writestr("OEBPS/styles.css", css)

        # 4. Chapters HTML & Manifest entries
        manifest_items = [
            '<item id="css" href="styles.css" media-type="text/css"/>',
            '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>',
            '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'
        ]
        spine_items = []
        toc_ncx_items = []
        nav_html_items = []

        for idx, ch in enumerate(chapters):
            ch_id = f"chap_{idx+1}"
            ch_file = f"{ch_id}.xhtml"
            ch_title = ch["title"]

            manifest_items.append(f'<item id="{ch_id}" href="{ch_file}" media-type="application/xhtml+xml"/>')
            spine_items.append(f'<itemref idref="{ch_id}"/>')

            toc_ncx_items.append(f"""  <navPoint id="{ch_id}" playOrder="{idx+1}">
    <navLabel><text>{ch_title}</text></navLabel>
    <content src="{ch_file}"/>
  </navPoint>""")

            nav_html_items.append(f'<li><a href="{ch_file}">{ch_title}</a></li>')

            # Build chapter HTML
            paras = ch["content"].split("\n\n")
            html_paras = []
            for p_text in paras:
                clean_p = p_text.strip().replace("<", "&lt;").replace(">", "&gt;")
                if clean_p:
                    html_paras.append(f"<p>{clean_p}</p>")

            chapter_xhtml = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="es" lang="es">
<head>
    <title>{ch_title}</title>
    <link rel="stylesheet" type="text/css" href="styles.css"/>
</head>
<body>
    <h1>{ch_title}</h1>
    {"".join(html_paras)}
</body>
</html>"""
            z.writestr(f"OEBPS/{ch_file}", chapter_xhtml)

        # 5. OEBPS/toc.ncx
        toc_ncx = f"""<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
<head>
  <meta name="dtb:uid" content="urn:uuid:tarot-rider-waite-guia-definitiva"/>
  <meta name="dtb:depth" content="1"/>
  <meta name="dtb:totalPageCount" content="0"/>
  <meta name="dtb:maxPageNumber" content="0"/>
</head>
<docTitle><text>Tarot Rider-Waite: Guía Definitiva</text></docTitle>
<navMap>
{"".join(toc_ncx_items)}
</navMap>
</ncx>"""
        z.writestr("OEBPS/toc.ncx", toc_ncx)

        # 6. OEBPS/nav.xhtml
        nav_xhtml = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="es" lang="es">
<head>
    <title>Índice</title>
    <link rel="stylesheet" type="text/css" href="styles.css"/>
</head>
<body>
    <nav epub:type="toc" id="toc">
        <h1>Índice de Contenido</h1>
        <ol>
            {"".join(nav_html_items)}
        </ol>
    </nav>
</body>
</html>"""
        z.writestr("OEBPS/nav.xhtml", nav_xhtml)

        # 7. OEBPS/content.opf
        content_opf = f"""<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="3.0">
    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        <dc:identifier id="BookId">urn:uuid:tarot-rider-waite-guia-definitiva</dc:identifier>
        <dc:title>Tarot Rider-Waite: Guía Definitiva</dc:title>
        <dc:creator>Johannes Fiebig y Evelin Bürger</dc:creator>
        <dc:language>es</dc:language>
        <meta property="dcterms:modified">2026-07-31T12:00:00Z</meta>
    </metadata>
    <manifest>
        {"".join(manifest_items)}
    </manifest>
    <spine toc="ncx">
        {"".join(spine_items)}
    </spine>
</package>"""
        z.writestr("OEBPS/content.opf", content_opf)

create_epub(epub_out_path)
create_epub(resource_epub_path)

print(f"Successfully generated EPUB at {epub_out_path}")
print(f"Successfully copied EPUB to {resource_epub_path}")
