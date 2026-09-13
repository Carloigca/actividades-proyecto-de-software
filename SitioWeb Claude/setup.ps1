# setup.ps1 — Aterrizar.com
# Crea directorios, convierte imagenes a PNG y genera PDFs de itinerarios

$ErrorActionPreference = "Stop"
$base         = "c:\Users\Carlo\Documents\FACULTAD\4to-año\Proyecto de Software\Actividad 1\SitioWeb Claude"
$artifactsDir = "C:\Users\Carlo\.gemini\antigravity-ide\brain\874b04c6-f7ef-465b-b863-63934f3bb2cb"
$imgDir       = Join-Path $base "imagenes"
$guiasDir     = Join-Path $base "guias"

Write-Host "`n=== Aterrizar.com — Script de Configuracion ===" -ForegroundColor Cyan

# --- 1. Crear directorios ---
Write-Host "`n[1/3] Creando directorios..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $imgDir   | Out-Null
New-Item -ItemType Directory -Force -Path $guiasDir | Out-Null
Write-Host "  OK: imagenes/" -ForegroundColor Green
Write-Host "  OK: guias/"    -ForegroundColor Green

# --- 2. Copiar / convertir imagenes a PNG ---
Write-Host "`n[2/3] Procesando imagenes..." -ForegroundColor Yellow

$images = [ordered]@{
    "mdp"            = "mdp_1789329012646.jpg"
    "punta_del_este" = "punta_del_este_1789329032679.jpg"
    "cancun"         = "cancun_1789329044124.jpg"
    "mendoza"        = "mendoza_1789329055297.jpg"
    "bariloche"      = "bariloche_1789329066919.jpg"
    "cusco"          = "cusco_1789329078307.jpg"
}

$converted = $false
try {
    Add-Type -AssemblyName System.Drawing
    foreach ($name in $images.Keys) {
        $src = Join-Path $artifactsDir $images[$name]
        $dst = Join-Path $imgDir "$name.png"
        if (Test-Path $src) {
            $img = [System.Drawing.Image]::FromFile((Resolve-Path $src).Path)
            $img.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
            $img.Dispose()
            Write-Host "  Convertido: $name.png" -ForegroundColor Green
        } else {
            Write-Host "  AVISO: No se encontro $($images[$name])" -ForegroundColor Red
        }
    }
    $converted = $true
} catch {
    Write-Host "  System.Drawing no disponible, copiando como PNG..." -ForegroundColor DarkYellow
    $converted = $false
}

if (-not $converted) {
    foreach ($name in $images.Keys) {
        $src = Join-Path $artifactsDir $images[$name]
        $dst = Join-Path $imgDir "$name.png"
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dst -Force
            Write-Host "  Copiado: $name.png" -ForegroundColor Green
        } else {
            Write-Host "  AVISO: No se encontro $($images[$name])" -ForegroundColor Red
        }
    }
}

# --- 3. Generar PDFs de itinerarios ---
Write-Host "`n[3/3] Generando PDFs de itinerarios..." -ForegroundColor Yellow

function New-PDF {
    param(
        [string]$OutPath,
        [string]$Titulo,
        [string[]]$Contenido
    )

    $enc = [System.Text.Encoding]::GetEncoding('windows-1252')

    # Construir flujo de contenido PDF (instrucciones de dibujo de texto)
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("BT")
    [void]$sb.AppendLine("/F1 20 Tf")
    [void]$sb.AppendLine("50 750 Td")
    # Escapar el titulo para PDF
    $tEsc = $Titulo -replace '\\','\\' -replace '\(', '\(' -replace '\)', '\)'
    [void]$sb.AppendLine("($tEsc) Tj")
    [void]$sb.AppendLine("/F1 11 Tf")
    [void]$sb.AppendLine("0 -35 Td")
    foreach ($linea in $Contenido) {
        $lEsc = $linea -replace '\\','\\' -replace '\(', '\(' -replace '\)', '\)'
        [void]$sb.AppendLine("($lEsc) Tj")
        [void]$sb.AppendLine("0 -18 Td")
    }
    [void]$sb.Append("ET")

    $stream    = $sb.ToString()
    $streamLen = $enc.GetByteCount($stream)

    # Construir objetos PDF usando array de strings (evitar << que confunde al parser de PS)
    $lt = [char]60   # <
    $gt = [char]62   # >
    $ll = "$lt$lt"   # <<
    $gg = "$gt$gt"   # >>

    $header = "%PDF-1.4`n"
    $obj1   = "1 0 obj`n$ll /Type /Catalog /Pages 2 0 R $gg`nendobj`n"
    $obj2   = "2 0 obj`n$ll /Type /Pages /Kids [3 0 R] /Count 1 $gg`nendobj`n"
    $obj3   = "3 0 obj`n$ll /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources $ll /Font $ll /F1 $ll /Type /Font /Subtype /Type1 /BaseFont /Helvetica $gg $gg $gg /Contents 4 0 R $gg`nendobj`n"
    $obj4   = "4 0 obj`n$ll /Length $streamLen $gg`nstream`n$stream`nendstream`nendobj`n"

    # Calcular offsets de byte para tabla xref
    $off1 = $enc.GetByteCount($header)
    $off2 = $off1 + $enc.GetByteCount($obj1)
    $off3 = $off2 + $enc.GetByteCount($obj2)
    $off4 = $off3 + $enc.GetByteCount($obj3)

    $body       = $header + $obj1 + $obj2 + $obj3 + $obj4
    $xrefOffset = $enc.GetByteCount($body)

    # Tabla de referencias cruzadas
    $xref  = "xref`n"
    $xref += "0 5`n"
    $xref += "0000000000 65535 f `n"
    $xref += "$($off1.ToString('D10')) 00000 n `n"
    $xref += "$($off2.ToString('D10')) 00000 n `n"
    $xref += "$($off3.ToString('D10')) 00000 n `n"
    $xref += "$($off4.ToString('D10')) 00000 n `n"
    $xref += "trailer`n"
    $xref += "$ll /Size 5 /Root 1 0 R $gg`n"
    $xref += "startxref`n"
    $xref += "$xrefOffset`n"
    $xref += "%%EOF"

    $fullContent = $body + $xref
    [System.IO.File]::WriteAllBytes($OutPath, $enc.GetBytes($fullContent))
}

# Definicion de itinerarios
$itinerarios = @(
    @{
        Nombre    = "mdp"
        Titulo    = "Itinerario: Mar del Plata, Argentina"
        Contenido = @(
            "DESTINO: Mar del Plata - Buenos Aires, Argentina",
            "CATEGORIA: Playa | DURACION SUGERIDA: 5 dias",
            "",
            "DIA 1: LLEGADA Y PLAYA BRISTOL",
            "Llegada y check-in en hotel.",
            "Visita a la Playa Bristol y Rambla.",
            "Cena de mariscos en el Puerto.",
            "",
            "DIA 2: CASINO Y CENTRO HISTORICO",
            "Visita al Casino Central y Teatro Colon.",
            "Museo Municipal de Arte Juan Carlos Castagnino.",
            "Noche: vida nocturna en la calle Alem.",
            "",
            "DIA 3: PUERTO Y LOBOS MARINOS",
            "Puerto de Mar del Plata.",
            "Observacion de lobos marinos en la Banquina de Pescadores.",
            "Compra de artesanias y recuerdos.",
            "",
            "DIA 4: PLAYA Y DEPORTES NAUTICOS",
            "Dia libre en la playa.",
            "Opciones: surf, kayak, parasailing.",
            "Paseo por los bosques de Peralta Ramos.",
            "",
            "DIA 5: LAGUNA DE LOS PADRES Y REGRESO",
            "Excursion a la Laguna de los Padres.",
            "Almuerzo de despedida con empanadas.",
            "Regreso.",
            "",
            "INFORMACION UTIL:",
            "Mejor epoca: diciembre - marzo",
            "Moneda: Peso Argentino (ARS)",
            "Clima verano: 25-30 C"
        )
    },
    @{
        Nombre    = "punta_del_este"
        Titulo    = "Itinerario: Punta del Este, Uruguay"
        Contenido = @(
            "DESTINO: Punta del Este - Maldonado, Uruguay",
            "CATEGORIA: Playa | DURACION SUGERIDA: 5 dias",
            "",
            "DIA 1: LLEGADA Y LA MANO",
            "Llegada a Punta del Este. Check-in en resort.",
            "Visita a la escultura La Mano en Playa Brava.",
            "Atardecer desde el Puerto.",
            "",
            "DIA 2: PLAYAS Y CASAPUEBLO",
            "Manana en Playa Mansa (aguas calmas).",
            "Tarde: excursion a Casapueblo (museo y hotel de Paez Vilaro).",
            "Cena frente al mar.",
            "",
            "DIA 3: JOSE IGNACIO Y LAGUNA",
            "Excursion al pueblo de Jose Ignacio.",
            "Visita a la Laguna Garzon.",
            "Almuerzo de pescado fresco.",
            "",
            "DIA 4: ISLA GORRITI",
            "Paseo en lancha a la Isla Gorriti.",
            "Snorkeling y picnic en la isla.",
            "Noche: vida nocturna de Punta del Este.",
            "",
            "DIA 5: SHOPPING Y REGRESO",
            "Compras en el Free Shop.",
            "Almuerzo de despedida con chivito uruguayo.",
            "Regreso.",
            "",
            "INFORMACION UTIL:",
            "Mejor epoca: enero - febrero",
            "Moneda: Peso Uruguayo (UYU)",
            "Clima verano: 24-28 C"
        )
    },
    @{
        Nombre    = "cancun"
        Titulo    = "Itinerario: Cancun, Mexico"
        Contenido = @(
            "DESTINO: Cancun - Quintana Roo, Mexico",
            "CATEGORIA: Playa | DURACION SUGERIDA: 7 dias",
            "",
            "DIA 1: LLEGADA Y ZONA HOTELERA",
            "Llegada al Aeropuerto Internacional de Cancun.",
            "Check-in en resort all-inclusive.",
            "Primera tarde disfrutando la playa turquesa.",
            "",
            "DIA 2: CHICHEN ITZA",
            "Excursion a Chichen Itza (Maravilla del Mundo Moderno).",
            "Visita al Cenote Ik-Kil.",
            "Regreso al hotel.",
            "",
            "DIA 3: ISLA MUJERES",
            "Tour en catamaran a Isla Mujeres.",
            "Snorkeling en arrecifes de coral.",
            "Almuerzo de mariscos frescos.",
            "",
            "DIA 4: TULUM Y CENOTES",
            "Excursion a Tulum: ruinas mayas frente al Mar Caribe.",
            "Nado en cenote Dos Ojos o Gran Cenote.",
            "",
            "DIA 5: PARQUES TEMATICOS",
            "Dia en Xplor: tirolesas y espeleobuceo.",
            "Noche: fiesta mexicana en Xoximilco.",
            "",
            "DIA 6: PLAYA DEL CARMEN",
            "Excursion a la Quinta Avenida.",
            "Shopping y degustacion gastronomica.",
            "",
            "DIA 7: REGRESO",
            "Ultima manana en la playa.",
            "Regreso.",
            "",
            "INFORMACION UTIL:",
            "Mejor epoca: noviembre - abril",
            "Moneda: Peso Mexicano (MXN). Se acepta USD.",
            "Clima: 28-32 C"
        )
    },
    @{
        Nombre    = "mendoza"
        Titulo    = "Itinerario: Mendoza, Argentina"
        Contenido = @(
            "DESTINO: Mendoza - Provincia de Mendoza, Argentina",
            "CATEGORIA: Montana | DURACION SUGERIDA: 5 dias",
            "",
            "DIA 1: LLEGADA Y CENTRO",
            "Llegada. Paseo por el microcentro y Peatonal Sarmiento.",
            "Visita al Parque General San Martin.",
            "Cena con vino Malbec local.",
            "",
            "DIA 2: RUTA DEL VINO - LUJAN DE CUYO",
            "Recorrida por bodegas reconocidas de Argentina.",
            "Catamiento de Malbec, Cabernet Sauvignon y Torrontes.",
            "Almuerzo maridado en bodega.",
            "",
            "DIA 3: ALTA MONTANA Y ACONCAGUA",
            "Excursion por el Circuito de Alta Montana.",
            "Vista al Aconcagua (6.962 m) y Puente del Inca.",
            "Paso Los Libertadores.",
            "",
            "DIA 4: VALLE DE UCO",
            "Excursion al Valle de Uco.",
            "Visita a bodegas boutique y olivares.",
            "Tarde libre para spa o aventura.",
            "",
            "DIA 5: MAIPU Y REGRESO",
            "Visita en bicicleta a las bodegas de Maipu.",
            "Degustacion de aceite de oliva.",
            "Regreso.",
            "",
            "INFORMACION UTIL:",
            "Mejor epoca: marzo-abril (vendimia) o junio-agosto (esqui)",
            "Moneda: Peso Argentino (ARS)",
            "Clima: continental arido, gran amplitud termica"
        )
    },
    @{
        Nombre    = "bariloche"
        Titulo    = "Itinerario: Bariloche, Argentina"
        Contenido = @(
            "DESTINO: San Carlos de Bariloche - Rio Negro, Argentina",
            "CATEGORIA: Montana | DURACION SUGERIDA: 6 dias",
            "",
            "DIA 1: LLEGADA Y CENTRO CIVICO",
            "Llegada al Aeropuerto Internacional de Bariloche.",
            "Visita al Centro Civico y vistas al Lago Nahuel Huapi.",
            "Degustacion de chocolates artesanales en la calle Mitre.",
            "",
            "DIA 2: CIRCUITO CHICO",
            "Recorrida panoramica por el Circuito Chico.",
            "Cerro Campanario: vista de 360 grados.",
            "Llao Llao Hotel y Peninsula San Pedro.",
            "",
            "DIA 3: CERRO CATEDRAL",
            "Dia completo en Cerro Catedral.",
            "Verano: trekking y mountain bike.",
            "Invierno: esqui y snowboard (mas grande de Sudamerica).",
            "",
            "DIA 4: ISLA VICTORIA",
            "Navegacion por el Lago Nahuel Huapi.",
            "Visita a la Isla Victoria.",
            "Bosque de Arrayanes (unico en el mundo).",
            "",
            "DIA 5: TREKKING REFUGIO FREY",
            "Trekking de dificultad media al Refugio Frey.",
            "Vistas de lagos glaciares. Noche libre en Bariloche.",
            "",
            "DIA 6: SIETE LAGOS Y REGRESO",
            "Excursion a Villa La Angostura y los Siete Lagos.",
            "Ultimo almuerzo con trucha patagonica.",
            "Regreso.",
            "",
            "INFORMACION UTIL:",
            "Mejor epoca: julio-agosto (esqui) o diciembre-marzo (verano)",
            "Moneda: Peso Argentino (ARS)",
            "Clima: invierno 0 C, verano 20 C promedio"
        )
    },
    @{
        Nombre    = "cusco"
        Titulo    = "Itinerario: Cusco, Peru"
        Contenido = @(
            "DESTINO: Cusco - Region Cusco, Peru",
            "CATEGORIA: Montana | DURACION SUGERIDA: 6 dias",
            "",
            "DIA 1: LLEGADA Y ACLIMATACION",
            "Llegada. Dia de descanso (altitud: 3.400 m.s.n.m.).",
            "Infusion de mate de coca. Paseo por la Plaza de Armas.",
            "",
            "DIA 2: CIUDAD IMPERIAL",
            "Visita al Templo del Sol (Qoricancha) y la Catedral.",
            "Mercado de San Pedro: artesanias y gastronomia local.",
            "Barrio de San Blas y talleres artesanales.",
            "",
            "DIA 3: VALLE SAGRADO",
            "Excursion al Valle Sagrado de los Incas.",
            "Pisac: mercado indigena y ruinas arqueologicas.",
            "Ollantaytambo: fortaleza inca bien conservada.",
            "",
            "DIA 4: MACHU PICCHU",
            "Amanecer: viaje en tren panoramico a Aguas Calientes.",
            "Visita a la ciudadela de Machu Picchu.",
            "Opcional: ascenso a Montana Huayna Picchu.",
            "Regreso a Cusco.",
            "",
            "DIA 5: SACSAYHUAMAN Y SPA",
            "Visita a la gran fortaleza inca de Sacsayhuaman.",
            "Tarde libre: termas o spa.",
            "Cena: cuy, quinua y pisco sour.",
            "",
            "DIA 6: REGRESO",
            "Manana libre para artesanias.",
            "Regreso.",
            "",
            "INFORMACION UTIL:",
            "Mejor epoca: mayo - octubre (temporada seca)",
            "Moneda: Sol Peruano (PEN)",
            "Altitud: 3.400 m - aclimatarse antes de hacer ejercicio"
        )
    }
)

foreach ($it in $itinerarios) {
    $outPath = Join-Path $guiasDir "$($it.Nombre).pdf"
    New-PDF -OutPath $outPath -Titulo $it.Titulo -Contenido $it.Contenido
    Write-Host "  Creado: $($it.Nombre).pdf" -ForegroundColor Green
}

Write-Host "`n=== Configuracion completada! ===" -ForegroundColor Cyan
Write-Host "Directorios creados: imagenes/ y guias/" -ForegroundColor White
Write-Host "Imagenes: $($images.Count) archivos PNG" -ForegroundColor White
Write-Host "PDFs:     $($itinerarios.Count) itinerarios" -ForegroundColor White
Write-Host ""
