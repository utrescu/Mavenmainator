#!/usr/bin/env ruby
require 'nokogiri'
require 'optionparser'

# Comprova si el XML que se li passa com a paràmetre
# ja té la configuració del main feta.
#
# @param doc [Document] Document XML en format nokogiri
# @return [bool] Si el document té la configuració feta o no
#
def comprovaSiEstaConfigurat(doc)

  configuracio = doc.css("artifactId")
  configuracio.each { |plugin|
    if ["maven-shade-plugin", "maven-jar-plugin"].include? plugin.text
      return true
    end
  }
  return false
end
# Afegeix la configuració del 'plugin' que afegeix les dependències en el JAR.
#
# @param node [Node] Etiqueta en la que s'afegirà la configuració (bàsicament
#   és un node 'plugin')
# @param onEsElMain [String] Camí al main que s'ha de posar en la configuració
# @return [Node] retorna el node amb el 'plugin' afegit
#
def afegirConfiguracioShade(node, onEsElMain)
  nouDoc = Nokogiri::HTML::DocumentFragment.parse ""
  Nokogiri::XML::Builder.with( nouDoc ){  |xml|
    xml.plugin {
      xml.groupId "org.apache.maven.plugins"
      xml.artifactId "maven-shade-plugin"
      xml.version "3.0.0"
      xml.executions {
        xml.execution {
          xml.phase "package"
          xml.goals {
            xml.goal "shade"
          }
          xml.configuration {
            xml.transformers {
              xml.transformer("implementation" => "org.apache.maven.plugins.shade.resource.ManifestResourceTransformer") do
                xml.mainClass onEsElMain
              end
            }
          }
        }
      }
    }
  }
  node.add_child(nouDoc.to_xml)
end

# Afegeix la configuració del 'plugin' que no té dependències.
#
# @param node [Node] Etiqueta en la que s'afegirà la configuració (bàsicament
#   és un node 'plugin')
# @param onEsElMain [String] Camí al main que s'ha de posar en la configuració
# @return [Node] retorna el node amb el 'plugin' afegit
#
def afegirConfiguracioJar(node, onEsElMain)
  nouDoc = Nokogiri::HTML::DocumentFragment.parse ""
  Nokogiri::XML::Builder.with( nouDoc ){  |xml|
    xml.plugin {
      xml.groupId "org.apache.maven.plugins"
      xml.artifactId "maven-jar-plugin"
      xml.configuration {
        xml.archive {
          xml.manifest {
            xml.mainClass onEsElMain
          }
        }
      }
    }
  }
  node.add_child(nouDoc.to_xml)
end

# Afegeix la configuració del 'plugin' a l'etiqueta rebuda.
#
# @param node [Node] Etiqueta en la que s'afegirà la configuració (bàsicament
#   és un node 'plugin')
# @param onEsElMain [String] Camí al main que s'ha de posar en la configuració
# @return [Node] retorna el node amb el 'plugin' afegit
#
def afegirEtiquetaPlugin(node, onEsElMain, shade)

  if shade
    afegirConfiguracioShade(node, onEsElMain)
  else
    afegirConfiguracioJar(node, onEsElMain)
  end

end

# Afegeix la configuració de plugins a l'etiqueta rebuda.
#
#
# @param node [Node] Etiqueta en la que s'afegirà la configuració (bàsicament
#   és un node 'plugins')
# @param main [String] Camí al main que s'ha de posar en la configuració
# # (see #afegirEtiquetaPlugin)
# @return [Node] retorna el node amb el 'plugins' afegit
#
def afegirEtiquetaPlugins(node, main, shade)
  plugins = Nokogiri::XML::Node.new "plugins", @doc
  plugins.add_child(afegirEtiquetaPlugin(plugins, main, shade))
  node.add_child(plugins)
end

# Busca el node 'plugins' en el document rebut.
#
# @param doc [Document] Document o node el el que cercar
# @return [Node] Node 'plugins' o res
#
def obtenirEtiquetaPlugins(doc)
  plugins = doc.at_css("plugins")
end

# Busca el node 'build' en el document rebut.
#
# @param doc [Document] Document o node el el que cercar
# @return [Node] Node 'build' o res
#
def obtenirEtiquetaBuild(doc)
  build = doc.at_css("build")
  unless build
    build = Nokogiri::XML::Node.new "build", @doc
    doc.root.add_child(build)
  end
  return build
end

#
# Afegir la propietat amb el valor 1.8
# @param doc [Node] document en el que cercar
# @return la nova etiqueta amb "1.8" a dins
#
def addCompiler(properties, text, valor)
  versio = nil
  properties.element_children().each { |child|
    if child.name == text
        versio = child
    end
  }
  unless versio
    versio = Nokogiri::XML::Node.new text, properties
    text_node = Nokogiri::XML::Text.new(valor, properties)
    versio.add_child(text_node)
  else
    versio.content = valor
  end
  properties.add_child(versio)
end

#
# Configurar el projecte perquè faci servir Maven 1.8
#
def configuraJava8(doc)
    properties = doc.at_css("properties")
    target = addCompiler(properties, "maven.compiler.target", "1.8")
    target = addCompiler(properties, "maven.compiler.source", "1.8")
end

# 1. Obtenir les dades dels paràmetres
options = {}
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: mavenmainator.rb [options]"

  opts.on('-m', '--mainpath PATH', 'required main') {
    |v| options[:main_path] = v }
  opts.on('-i', '--input POM', 'Source host, default pom.xml') {
    |v| options[:input_pom] = v }
  opts.on('-o', '--output POM', 'Source port, default new_pom.xml') {
    |v| options[:output_pom] = v }
  opts.on('-s', '--shade', 'Configure maven-shade-plugin to package in a uber-jar') {
    |v| options[:shade] = true }
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

# El main és 'required'
unless options[:main_path]
  puts "no main specified"
  exit
end

options[:shade] ||= false
options[:input_pom] ||= "pom.xml"
options[:output_pom] ||= "new_pom.xml"
MAINLOCATION = options[:main_path]
INPOM = options[:input_pom]
OUTPOM = options[:output_pom]
SHADE = options[:shade]

# 2. Processar el fitxer

if !File.file?(INPOM)
  puts "File " + INPOM + " doesn't exists"
  exit(1)
end

@doc = File.open(INPOM) {|f| Nokogiri::XML(f, &:noblanks)}
# doc = Nokogiri::XML(File.open("shows.xml"))
# @doc.remove_namespaces!

configuraJava8(@doc)

if !comprovaSiEstaConfigurat(@doc)
  pluginsActual = obtenirEtiquetaPlugins(@doc)
  if pluginsActual.nil?
    # Plugins no hi és per tant es localitza o crea 'build'
    build = obtenirEtiquetaBuild(@doc)
    afegirEtiquetaPlugins(build, MAINLOCATION, SHADE)
  else
    # l'etiqueta 'plugins' hi és però falta la configuració
    afegirEtiquetaPlugin(pluginsActual, MAINLOCATION, SHADE)
  end

  # 3. Emmagatzemar el resultat
  File.open(OUTPOM, 'w') { |f| f.print(@doc.to_xml(indent:2, indent_text:" ")) }

else
  puts "Already configured"
end