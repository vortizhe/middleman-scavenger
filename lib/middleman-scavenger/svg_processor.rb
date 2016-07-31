class SVGProcessor
  require "middleman-core/logger"
  require "nokogiri"

  def initialize(path, prefix)
    @path = path
    @prefix = prefix
    build
  end

  def build
    svgs = Dir["#{@path}/*.svg"].map { |file| get_svg(file) }
    logger.info "== Middleman-Scavenger rebuilding: #{svgs.length} svgs found"
    symbols = svgs.map { |svg| convert_to_symbol(svg) }
    @symbol_string = create_sprite(symbols)
  end

  def to_s
    @symbol_string
  end

  private

  def logger
    ::Middleman::Logger.singleton(1)
  end

  def get_svg(file)
    f = File.open(file)
    doc = Nokogiri::XML(f)
    f.close

    {
      filename: File.basename(file, ".svg"),
      xml: doc
    }
  end

  def convert_to_symbol(svg)
    defs = svg[:xml].css("//defs").blank? ? '' : svg[:xml].at_css("defs").children.remove
    content = svg[:xml].at_css("svg").children
    viewbox_size = svg[:xml].xpath("//@viewBox").first.value
    {
      defs: defs.to_s.strip,
      content: "<symbol viewBox=\"#{viewbox_size}\" id=\"#{@prefix}#{svg[:filename]}\">#{content.to_s.strip}</symbol>"
    }
  end

  def create_sprite(symbols)
    d = []
    s = []
    symbols.each do |symbol|
      d << symbol[:defs]
      s << symbol[:content]
    end
    "\n<defs>#{d.reject(&:empty?).uniq.join("\n")}</defs>\n#{s.join("\n")}"
  end
end
