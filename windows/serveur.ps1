# IA Locale — mini-serveur web local (Windows, PowerShell 5.1 ou plus).
#
# Pourquoi ce serveur : ouverte comme simple fichier (file://), la page envoie
# « Origin: null », qu'Ollama refuse. La version 1.1 contournait le refus en
# réglant OLLAMA_ORIGINS="*", ce qui laissait N'IMPORTE QUEL site web piloter
# l'Ollama de l'utilisateur. Servie depuis http://127.0.0.1, la page est
# acceptée par Ollama sans aucun réglage.
#
# Garde-fous : écoute sur 127.0.0.1 seulement (injoignable depuis le réseau),
# ne sert qu'une liste fermée de fichiers, ne répond qu'à GET et HEAD, et
# s'arrête seul après une longue inactivité. TcpListener plutôt que
# HttpListener : ce dernier exige des droits d'administrateur pour certaines
# adresses, TcpListener jamais.
param(
    [Parameter(Mandatory = $true)][string]$Racine,
    [int]$Port = 11500,
    [int]$Inactivite = 28800
)

$fichiers = @{
    '/'                      = @('IA-Locale.html',        'text/html; charset=utf-8')
    '/IA-Locale.html'        = @('IA-Locale.html',        'text/html; charset=utf-8')
    '/lib/pdf.min.js'        = @('lib/pdf.min.js',        'text/javascript; charset=utf-8')
    '/lib/pdf.worker.min.js' = @('lib/pdf.worker.min.js', 'text/javascript; charset=utf-8')
}
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Repondre($flux, [string]$statut, [string]$type, [byte[]]$corps, [bool]$tete) {
    $entete = "HTTP/1.1 $statut`r`nContent-Type: $type`r`nContent-Length: $($corps.Length)`r`n" +
              "Cache-Control: no-store`r`nX-Content-Type-Options: nosniff`r`nConnection: close`r`n`r`n"
    $octets = $utf8.GetBytes($entete)
    $flux.Write($octets, 0, $octets.Length)
    if (-not $tete -and $corps.Length -gt 0) { $flux.Write($corps, 0, $corps.Length) }
    $flux.Flush()
}

function Texte([string]$s) { return ,$utf8.GetBytes($s) }

$ecoute = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
$ecoute.Start()
$derniere = Get-Date

try {
    while ($true) {
        if (-not $ecoute.Pending()) {
            if (((Get-Date) - $derniere).TotalSeconds -gt $Inactivite) { break }
            Start-Sleep -Milliseconds 100
            continue
        }
        $derniere = Get-Date
        $client = $ecoute.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 10000
            $flux = $client.GetStream()
            $lecteur = New-Object System.IO.StreamReader($flux, $utf8, $false, 4096, $true)
            $ligne = $lecteur.ReadLine()
            if ($null -eq $ligne) { continue }
            while ($true) { $h = $lecteur.ReadLine(); if ([string]::IsNullOrEmpty($h)) { break } }
            $parties = $ligne.Split(' ')
            if ($parties.Count -lt 3) { Repondre $flux '400 Bad Request' 'text/plain' (Texte "requete invalide`n") $false; continue }
            $methode = $parties[0]
            $chemin = $parties[1].Split('?')[0]
            $tete = ($methode -eq 'HEAD')
            if ($methode -ne 'GET' -and -not $tete) { Repondre $flux '405 Method Not Allowed' 'text/plain' (Texte "methode refusee`n") $false; continue }
            if ($chemin -eq '/__ia-locale') {
                # Carte d'identité : le lanceur reconnaît SON serveur (et non celui
                # d'une autre copie de l'application, qui servirait un vieux fichier).
                Repondre $flux '200 OK' 'text/plain' (Texte "ia-locale $PID $Racine`n") $tete; continue
            }
            if (-not $fichiers.ContainsKey($chemin)) { Repondre $flux '404 Not Found' 'text/plain' (Texte "introuvable`n") $tete; continue }
            $f = $fichiers[$chemin]
            $plein = Join-Path $Racine $f[0]
            if (-not (Test-Path -LiteralPath $plein)) { Repondre $flux '500 Internal Server Error' 'text/plain' (Texte "fichier absent`n") $tete; continue }
            Repondre $flux '200 OK' $f[1] ([System.IO.File]::ReadAllBytes($plein)) $tete
        } catch {
            # Une connexion qui échoue (navigateur fermé en cours de route…) ne doit pas arrêter le serveur.
        } finally {
            $client.Close()
        }
    }
} finally {
    $ecoute.Stop()
}
