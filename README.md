Mainmavenator
==========================
En el temps que porto fent de professor de Java deixo que els alumnes facin servir el IDE que vulguin (Eclipse, IntelliJ IDEA, Netbeans, ...). Això era un problema a l'hora de corregir perquè he de crear projectes nous, cercar les llibreries, etc ... 

Per aconseguir independència de l'IDE (quest motiu els demano que m'entreguin projectes en Maven (http://apache.maven.org)

D'aquesta forma no necessito tenir el mateix IDE que ells i puc executar els programes fàcilment. El problema més gran d'aquest enfoc és que al fer programes curts cal definir la classe que té el main en el POM.XML.

M'he trobat que a pesar de repetir-ho diverses vegades els alumnes sovint no defineixen el 'main' en el pom.xml

A l'hora de corregir això m'obliga a editar el POM i posar-hi la configuració del main

Aquest és un simple script que es limita a:

1. configurar el POM.XML afegint-hi el main de dues formes:
    - Fent servir maven-jar-plugin (per quan no calen llibreries externes)
    - Fent servir maven-shade-plugin (per quan a més hi ha llibreries requerides)
2. Configura el projecte perquè Maven faci servir Java8

Funcionament
-----------------
Cal tenir Ruby instal·lat perquè he desenvolupat l'script en Ruby (perquè en volia aprendre i no volia fer servir Python)

L'únic requeriment és definir on és el main amb *-m* o *--main-path*:

    $ ./mainmavenator.rb -m net.xaviersala.App

Per defecte cerca un arxiu 'pom.xml' en el directori on som, i genera un arxiu anomenat *'new_pom.xm'* que estarà configurat per Java8 i tindrà maven-jar-plugin

### Ajuda
Es pot obtenir ajuda amb el paràmetre -h:

    $ ./mainmavenator.rb -h
    Usage: mainmavenator.rb [options]
        -m, --mainpath PATH              required main
        -i, --input POM                  Source host, default pom.xml
        -o, --output POM                 Source port, default new_pom.xml
        -s, --shade                      Fer servir el plugin shade
        -h, --help                       Prints this help

### maven-jar-plugin

Per defecte configura *maven-jar-plugin*. O sigui que no cal fer res perquè el configuri

    $ ./mainmavenator.rb -m net.xaviersala.App


### maven-shade-plugin

Per configurar shade només cal especificar el paràmetre *-s* o *--shade*. Les dependències han d'estar especificades a part...

    $ ./mainmavenator.rb -m net.xaviersala.App -s

### Definir el fitxer d'entrada i sortida
Per defecte l'script cerca el fitxer 'pom.xml' però es pot definir un altre nom amb *-i* o *--input*

Una cosa semblant passa amb el fitxer de sortida. Per defecte crea 'new_pom.xml' però podem canviar-ho amb *-o* o *--output*: 

    $ ./mainmavenator.rb -m net.xaviersala.App -i pim.xml -o pam.xml
