Mavenmainator
==========================
En el temps que porto fent de professor de Java deixo que els alumnes facin servir el IDE que vulguin (Eclipse, IntelliJ IDEA, Netbeans, ...). Això era un problema a l'hora de corregir perquè he de crear projectes nous, cercar les llibreries, etc ...

Per aconseguir independència de l'IDE els demano que m'entreguin projectes en Maven (http://maven.apache.org/)

D'aquesta forma no necessito tenir el mateix IDE que ells i puc executar els programes fàcilment. El problema més gran d'aquest enfoc és que com que bàsicament fem programes cal definir la classe que té el main en el POM.XML. 

A pesar de repetir-ho diverses vegades, els alumnes sovint no defineixen el 'main' en el pom.xml o bé el JAR generat no es pot executar perquè no conté totes les dependències ... A l'hora de corregir això m'obliga a fer més feina de la necessària: editar el POM per posar-hi la configuració que falta. Com que és una tasca repetitiva m'he decidit a automatitzar-la.

Aquest és un script que es limita a:

1. Configurar el POM.XML afegint-hi el main de dues formes:
    - Fent servir maven-jar-plugin (per programes als que no els hi calen llibreries externes)
    - Fent servir maven-shade-plugin (per programes que tenen llibreries entre les dependències). El shade empaqueta les dependències en el JAR.
2. Configura el projecte perquè Maven faci servir Java8 (un altre dels problemes amb els que m'he trobat)

Requirements
------------------

Cal tenir Ruby instal·lat perquè he desenvolupat l'script en Ruby (perquè en volia aprendre i no volia fer servir Python)

Els requeriments només són dues llibreries. Cal instal·lar 'nokogiri' i 'optionparser': 

    $ gem install nokogiri
    $ gem install optionparser

I ja es pot executar.

Funcionament
-----------------
L'únic requeriment és definir on és el main amb *-m* o *--main-path*:

    $ ./mavenmainator.rb -m net.xaviersala.App

Per defecte cerca un arxiu 'pom.xml' en el directori on som, i genera un arxiu anomenat *'new_pom.xm'* que estarà configurat per Java8 i tindrà maven-jar-plugin

### Ajuda
Es pot obtenir ajuda amb el paràmetre -h:

    $ ./mavenmainator.rb -h
    Usage: mavenmainator.rb [options]
        -m, --mainpath PATH              required main
        -i, --input POM                  Source host, default pom.xml
        -o, --output POM                 Source port, default new_pom.xml
        -s, --shade                      Configure maven-shade-plugin to package in a uber-jar
        -h, --help                       Prints this help

### maven-jar-plugin

Per defecte configura *maven-jar-plugin*. La única cosa que cal és definir en quina classe hi ha el 'main':

    $ ./mavenmainator.rb -m net.xaviersala.App

### maven-shade-plugin

Si es vol que el fitxer generat també tingui les dependències s'ha de configurar el "shade". S'ha d'afegir el paràmetre *-s* o *--shade* i en quin fitxer hi ha el main:

    $ ./mavenmainator.rb -m net.xaviersala.App -s

### Definir el fitxer d'entrada i sortida
Per defecte l'script cerca el fitxer 'pom.xml' del directori on estem, però es pot definir un altre nom amb *-i* o *--input*

Una cosa semblant passa amb el fitxer de sortida. Per defecte crea un arxiu anomenat 'new_pom.xml' però és pot definir un altre nom amb *-o* o *--output*: 

    $ ./mavenmainator.rb -m net.xaviersala.App -i pim.xml -o pam.xml
