#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gen_pdfs.py — Genera PDFs validos de itinerarios para Aterrizar.com
"""
import os
import struct

GUIAS_DIR = r"c:\Users\Carlo\Documents\FACULTAD\4to-anio\Proyecto de Software\Actividad 1\SitioWeb Claude\guias"

# ── Generador de PDF minimo valido ─────────────────────────────────────────
def make_pdf(title: str, lines: list[str]) -> bytes:
    """Genera un PDF valido de una sola pagina con texto."""

    # --- Stream de contenido PDF ---
    content_lines = ["BT", "/F1 18 Tf", "50 750 Td"]
    safe_title = title.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
    content_lines.append(f"({safe_title}) Tj")
    content_lines.append("/F1 11 Tf")
    content_lines.append("0 -30 Td")
    for line in lines:
        safe = line.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
        content_lines.append(f"({safe}) Tj")
        content_lines.append("0 -17 Td")
    content_lines.append("ET")
    stream_content = "\n".join(content_lines)
    stream_bytes   = stream_content.encode("latin-1", errors="replace")
    stream_len     = len(stream_bytes)

    # --- Objetos PDF ---
    obj1 = b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
    obj2 = b"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
    obj3 = (
        b"3 0 obj\n"
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792]\n"
        b"   /Resources << /Font << /F1 << /Type /Font /Subtype /Type1"
        b" /BaseFont /Helvetica >> >> >>\n"
        b"   /Contents 4 0 R >>\nendobj\n"
    )
    obj4_header = f"4 0 obj\n<< /Length {stream_len} >>\nstream\n".encode("latin-1")
    obj4 = obj4_header + stream_bytes + b"\nendstream\nendobj\n"

    header = b"%PDF-1.4\n"

    # --- Calcular offsets ---
    off1 = len(header)
    off2 = off1 + len(obj1)
    off3 = off2 + len(obj2)
    off4 = off3 + len(obj3)

    body = header + obj1 + obj2 + obj3 + obj4
    xref_offset = len(body)

    # --- Tabla xref ---
    xref = b"xref\n0 5\n"
    xref += b"0000000000 65535 f \n"
    xref += f"{off1:010d} 00000 n \n".encode()
    xref += f"{off2:010d} 00000 n \n".encode()
    xref += f"{off3:010d} 00000 n \n".encode()
    xref += f"{off4:010d} 00000 n \n".encode()
    xref += b"trailer\n<< /Size 5 /Root 1 0 R >>\n"
    xref += f"startxref\n{xref_offset}\n%%EOF".encode()

    return body + xref


# ── Definicion de itinerarios ──────────────────────────────────────────────
ITINERARIOS = [
    {
        "nombre": "mdp",
        "titulo": "Itinerario - Mar del Plata, Argentina",
        "lineas": [
            "DESTINO: Mar del Plata - Buenos Aires, Argentina",
            "CATEGORIA: Playa  |  DURACION: 5 dias",
            "",
            "DIA 1: LLEGADA Y PLAYA BRISTOL",
            "  Llegada y check-in en hotel.",
            "  Visita a la Playa Bristol y la Rambla.",
            "  Cena de mariscos en el Puerto.",
            "",
            "DIA 2: CASINO Y CENTRO HISTORICO",
            "  Visita al Casino Central y Teatro Colon.",
            "  Museo Municipal de Arte Juan Carlos Castagnino.",
            "  Noche: vida nocturna en Calle Alem.",
            "",
            "DIA 3: PUERTO Y LOBOS MARINOS",
            "  Puerto de Mar del Plata.",
            "  Observacion de lobos marinos en la Banquina de Pescadores.",
            "  Compra de artesanias y recuerdos.",
            "",
            "DIA 4: PLAYA Y DEPORTES NAUTICOS",
            "  Dia libre en la playa. Surf, kayak, parasailing.",
            "  Paseo por los bosques de Peralta Ramos.",
            "",
            "DIA 5: LAGUNA DE LOS PADRES Y REGRESO",
            "  Excursion a la Laguna de los Padres.",
            "  Almuerzo de despedida con empanadas tipicas.",
            "  Regreso.",
            "",
            "INFORMACION UTIL:",
            "  Mejor epoca: diciembre - marzo",
            "  Moneda: Peso Argentino (ARS)",
            "  Clima en verano: 25-30 grados C",
        ],
    },
    {
        "nombre": "punta_del_este",
        "titulo": "Itinerario - Punta del Este, Uruguay",
        "lineas": [
            "DESTINO: Punta del Este - Maldonado, Uruguay",
            "CATEGORIA: Playa  |  DURACION: 5 dias",
            "",
            "DIA 1: LLEGADA Y LA MANO",
            "  Check-in en resort. Visita a la escultura La Mano en Playa Brava.",
            "  Atardecer desde el Puerto.",
            "",
            "DIA 2: PLAYAS Y CASAPUEBLO",
            "  Manana en Playa Mansa (aguas calmas).",
            "  Excursion a Casapueblo, museo del artista Paez Vilaro.",
            "  Cena frente al mar.",
            "",
            "DIA 3: JOSE IGNACIO Y LAGUNA GARZON",
            "  Excursion al pintoresco pueblo de Jose Ignacio.",
            "  Visita a la Laguna Garzon. Almuerzo de pescado fresco.",
            "",
            "DIA 4: ISLA GORRITI",
            "  Paseo en lancha a la Isla Gorriti.",
            "  Snorkeling y picnic en la isla.",
            "  Noche: vida nocturna de Punta del Este.",
            "",
            "DIA 5: SHOPPING Y REGRESO",
            "  Compras en el Free Shop.",
            "  Almuerzo de despedida con chivito uruguayo.",
            "  Regreso.",
            "",
            "INFORMACION UTIL:",
            "  Mejor epoca: enero - febrero",
            "  Moneda: Peso Uruguayo (UYU)",
            "  Clima en verano: 24-28 grados C",
        ],
    },
    {
        "nombre": "cancun",
        "titulo": "Itinerario - Cancun, Mexico",
        "lineas": [
            "DESTINO: Cancun - Quintana Roo, Mexico",
            "CATEGORIA: Playa  |  DURACION: 7 dias",
            "",
            "DIA 1: LLEGADA Y ZONA HOTELERA",
            "  Llegada. Check-in en resort all-inclusive.",
            "  Primera tarde en la playa turquesa del Caribe.",
            "",
            "DIA 2: CHICHEN ITZA",
            "  Excursion a Chichen Itza (Maravilla del Mundo Moderno).",
            "  Visita al Cenote Ik-Kil.",
            "",
            "DIA 3: ISLA MUJERES",
            "  Tour en catamaran a Isla Mujeres.",
            "  Snorkeling en arrecifes de coral.",
            "  Almuerzo de mariscos frescos en la isla.",
            "",
            "DIA 4: TULUM Y CENOTES",
            "  Excursion a Tulum: ruinas mayas frente al Mar Caribe.",
            "  Nado en cenote Dos Ojos o Gran Cenote.",
            "",
            "DIA 5: PARQUES TEMATICOS",
            "  Dia en Xplor: tirolesas y espeleobuceo.",
            "  Noche: fiesta mexicana en Xoximilco.",
            "",
            "DIA 6: PLAYA DEL CARMEN",
            "  Excursion a la Quinta Avenida.",
            "  Shopping y degustacion gastronomica.",
            "",
            "DIA 7: REGRESO",
            "  Ultima manana en la playa.",
            "  Regreso.",
            "",
            "INFORMACION UTIL:",
            "  Mejor epoca: noviembre - abril (temporada seca)",
            "  Moneda: Peso Mexicano (MXN). Se acepta USD.",
            "  Clima: 28-32 grados C",
        ],
    },
    {
        "nombre": "mendoza",
        "titulo": "Itinerario - Mendoza, Argentina",
        "lineas": [
            "DESTINO: Mendoza - Provincia de Mendoza, Argentina",
            "CATEGORIA: Montana  |  DURACION: 5 dias",
            "",
            "DIA 1: LLEGADA Y CENTRO",
            "  Paseo por el microcentro y Peatonal Sarmiento.",
            "  Visita al Parque General San Martin.",
            "  Cena con vino Malbec local.",
            "",
            "DIA 2: RUTA DEL VINO - LUJAN DE CUYO",
            "  Recorrida por bodegas reconocidas de Argentina.",
            "  Catamiento de Malbec, Cabernet Sauvignon y Torrontes.",
            "  Almuerzo maridado en bodega.",
            "",
            "DIA 3: ALTA MONTANA Y ACONCAGUA",
            "  Excursion por el Circuito de Alta Montana.",
            "  Vista al Aconcagua y Puente del Inca.",
            "  Paso Los Libertadores.",
            "",
            "DIA 4: VALLE DE UCO",
            "  Excursion al Valle de Uco.",
            "  Visita a bodegas boutique y olivares.",
            "  Tarde libre para spa o actividades de aventura.",
            "",
            "DIA 5: MAIPU Y REGRESO",
            "  Visita en bicicleta a las bodegas de Maipu.",
            "  Degustacion de aceite de oliva.",
            "  Regreso.",
            "",
            "INFORMACION UTIL:",
            "  Mejor epoca: marzo-abril (vendimia) o junio-agosto (esqui)",
            "  Moneda: Peso Argentino (ARS)",
            "  Clima: continental arido con gran amplitud termica",
        ],
    },
    {
        "nombre": "bariloche",
        "titulo": "Itinerario - Bariloche, Argentina",
        "lineas": [
            "DESTINO: San Carlos de Bariloche - Rio Negro, Argentina",
            "CATEGORIA: Montana  |  DURACION: 6 dias",
            "",
            "DIA 1: LLEGADA Y CENTRO CIVICO",
            "  Llegada al Aeropuerto Internacional de Bariloche.",
            "  Visita al Centro Civico y vistas al Lago Nahuel Huapi.",
            "  Degustacion de chocolates artesanales.",
            "",
            "DIA 2: CIRCUITO CHICO",
            "  Recorrida panoramica por el Circuito Chico.",
            "  Cerro Campanario: vistas de 360 grados.",
            "  Llao Llao Hotel y Peninsula San Pedro.",
            "",
            "DIA 3: CERRO CATEDRAL",
            "  Dia completo en Cerro Catedral.",
            "  Verano: trekking y mountain bike.",
            "  Invierno: esqui y snowboard (mas grande de Sudamerica).",
            "",
            "DIA 4: ISLA VICTORIA Y BOSQUE DE ARRAYANES",
            "  Navegacion por el Lago Nahuel Huapi.",
            "  Visita a la Isla Victoria.",
            "  Bosque de Arrayanes, unico en el mundo.",
            "",
            "DIA 5: TREKKING REFUGIO FREY",
            "  Trekking de dificultad media al Refugio Frey.",
            "  Vistas de lagos glaciares.",
            "  Noche libre en Bariloche.",
            "",
            "DIA 6: SIETE LAGOS Y REGRESO",
            "  Excursion a Villa La Angostura y los Siete Lagos.",
            "  Ultimo almuerzo con trucha patagonica.",
            "  Regreso.",
            "",
            "INFORMACION UTIL:",
            "  Mejor epoca: julio-agosto (esqui) o diciembre-marzo (verano)",
            "  Moneda: Peso Argentino (ARS)",
            "  Temperatura: invierno 0 grados C, verano 20 grados C",
        ],
    },
    {
        "nombre": "cusco",
        "titulo": "Itinerario - Cusco, Peru",
        "lineas": [
            "DESTINO: Cusco - Region Cusco, Peru",
            "CATEGORIA: Montana  |  DURACION: 6 dias",
            "",
            "DIA 1: LLEGADA Y ACLIMATACION",
            "  Llegada. Dia de descanso (altitud: 3.400 m.s.n.m.).",
            "  Infusion de mate de coca. Paseo leve por la Plaza de Armas.",
            "",
            "DIA 2: CIUDAD IMPERIAL DEL CUSCO",
            "  Visita al Templo del Sol y la Catedral.",
            "  Mercado de San Pedro: artesanias y gastronomia local.",
            "  Barrio de San Blas y talleres artesanales.",
            "",
            "DIA 3: VALLE SAGRADO DE LOS INCAS",
            "  Excursion al Valle Sagrado.",
            "  Pisac: mercado indigena y ruinas arqueologicas.",
            "  Ollantaytambo: fortaleza inca bien conservada.",
            "",
            "DIA 4: MACHU PICCHU",
            "  Amanecer: tren panoramico a Aguas Calientes.",
            "  Visita a la ciudadela de Machu Picchu.",
            "  Opcional: ascenso a Montana Huayna Picchu.",
            "  Regreso al Cusco.",
            "",
            "DIA 5: SACSAYHUAMAN Y RELAX",
            "  Visita a la gran fortaleza inca de Sacsayhuaman.",
            "  Tarde libre: termas o spa.",
            "  Cena de despedida con cuy, quinua y pisco sour.",
            "",
            "DIA 6: REGRESO",
            "  Manana libre para compra de artesanias.",
            "  Regreso.",
            "",
            "INFORMACION UTIL:",
            "  Mejor epoca: mayo - octubre (temporada seca)",
            "  Moneda: Sol Peruano (PEN)",
            "  Altitud: 3.400 m - aclimatarse antes de actividades fisicas",
        ],
    },
]


# ── Generar todos los PDFs ─────────────────────────────────────────────────
os.makedirs(GUIAS_DIR, exist_ok=True)

for it in ITINERARIOS:
    data = make_pdf(it["titulo"], it["lineas"])
    path = os.path.join(GUIAS_DIR, f"{it['nombre']}.pdf")
    with open(path, "wb") as f:
        f.write(data)
    print(f"  Creado: {it['nombre']}.pdf  ({len(data)} bytes)")

print("\nTodos los PDFs generados exitosamente.")
