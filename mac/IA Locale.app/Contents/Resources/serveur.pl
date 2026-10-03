#!/usr/bin/perl
# IA Locale — mini-serveur web local (macOS).
#
# Pourquoi ce serveur : ouverte comme simple fichier (file://), la page envoie
# « Origin: null », qu'Ollama refuse. La version 1.1 contournait le refus en
# réglant OLLAMA_ORIGINS="*", ce qui laissait N'IMPORTE QUEL site web piloter
# l'Ollama de l'utilisateur. Servie depuis http://127.0.0.1, la page est
# acceptée par Ollama sans aucun réglage.
#
# Garde-fous : écoute sur 127.0.0.1 seulement (injoignable depuis le réseau),
# ne sert qu'une liste fermée de fichiers, ne répond qu'à GET et HEAD, et
# s'arrête seul après une longue inactivité.
use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;

my ($racine, $port, $inactivite) = @ARGV;
die "usage: serveur.pl <dossier> <port> [secondes d'inactivité]\n" unless $racine && $port;
$inactivite ||= 8 * 3600;

my %fichiers = (
    '/'                      => ['IA-Locale.html',          'text/html; charset=utf-8'],
    '/IA-Locale.html'        => ['IA-Locale.html',          'text/html; charset=utf-8'],
    '/lib/pdf.min.js'        => ['lib/pdf.min.js',          'text/javascript; charset=utf-8'],
    '/lib/pdf.worker.min.js' => ['lib/pdf.worker.min.js',   'text/javascript; charset=utf-8'],
);

my $ecoute = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => $port, Proto => 'tcp',
    Listen => 16, ReuseAddr => 1,
) or die "IA Locale : impossible d'écouter sur 127.0.0.1:$port ($!)\n";
my $sel = IO::Select->new($ecoute);
$SIG{PIPE} = 'IGNORE';

while (1) {
    my @prets = $sel->can_read($inactivite);
    last unless @prets;    # rien reçu depuis $inactivite secondes : on s'arrête
    my $client = $ecoute->accept or next;
    eval { servir($client) };
    close $client;
}
exit 0;

sub repondre {
    my ($c, $statut, $type, $corps, $tete) = @_;
    my $n = length $corps;
    print $c "HTTP/1.1 $statut\r\nContent-Type: $type\r\nContent-Length: $n\r\n"
           . "Cache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\n\r\n";
    print $c $corps unless $tete;
}

sub servir {
    my $c = shift;
    local $SIG{ALRM} = sub { die "délai\n" };
    alarm 10;
    my $ligne = <$c>;
    alarm 0;
    return unless defined $ligne;
    while (my $h = <$c>) { last if $h =~ /^\r?\n$/; }    # en-têtes ignorés
    my ($methode, $chemin) = $ligne =~ m{^([A-Z]+) (\S+) HTTP/};
    return repondre($c, '400 Bad Request', 'text/plain', "requête invalide\n") unless $methode;
    return repondre($c, '405 Method Not Allowed', 'text/plain', "méthode refusée\n")
        unless $methode eq 'GET' || $methode eq 'HEAD';
    $chemin =~ s/\?.*//;
    my $tete = $methode eq 'HEAD';
    # Carte d'identité : le lanceur s'en sert pour reconnaître SON serveur (et non
    # celui d'une version précédente, installée ailleurs, qui servirait un vieux fichier).
    return repondre($c, '200 OK', 'text/plain', "ia-locale $$ $racine\n", $tete) if $chemin eq '/__ia-locale';
    my $f = $fichiers{$chemin}
        or return repondre($c, '404 Not Found', 'text/plain', "introuvable\n", $tete);
    open my $fh, '<:raw', "$racine/$f->[0]"
        or return repondre($c, '500 Internal Server Error', 'text/plain', "fichier absent\n", $tete);
    local $/; my $corps = <$fh>; close $fh;
    repondre($c, '200 OK', $f->[1], $corps, $tete);
}
