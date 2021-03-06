module Slodown
  class Formatter
    def initialize(source)
      @current = @source = source.to_s
    end

    # Runs the entire pipeline.
    #
    def complete
      extract_metadata.markdown.autolink.sanitize
    end

    # Convert the current document state from Markdown into HTML.
    #
    def markdown
      @current = Kramdown::Document.new(@current, kramdown_options).to_slodown_html
      self
    end

    # Auto-link URLs through Rinku.
    #
    def autolink
      @current = Rinku.auto_link(@current)
      self
    end

    # Sanitize HTML tags.
    #
    def sanitize
      @current = Sanitize.clean(@current, sanitize_config)
      self
    end

    def extract_metadata
      @metadata = {}

      @current = @current.each_line.drop_while do |line|
        next false if line !~ /^#\+([a-z_]+): (.*)/

        key, value = $1, $2
        @metadata[key.to_sym] = value
      end.join('')

      self
    end

    # Return a hash with the extracted metadata
    #
    def metadata
      @metadata
    end

    def to_s
      @current
    end

  private

    def kramdown_options
      { coderay_css: 'style' }
    end

    def sanitize_config
      {
        elements: %w(
          p br a span sub sup strong em div hr abbr
          ul ol li
          blockquote pre code kbd
          h1 h2 h3 h4 h5 h6
          img object param del
        ),
        attributes: {
          :all     => ['class', 'style', 'title', 'id'],
          'a'      => ['href', 'rel', 'name'],
          'li'     => ['id'],
          'sup'    => ['id'],
          'img'    => ['src', 'title', 'alt', 'width', 'height'],
          'object' => ['width', 'height'],
          'param'  => ['name', 'value'],
          'embed'  => ['allowscriptaccess', 'width', 'height', 'src'],
          'iframe' => ['width', 'height', 'src']
        },
        protocols: {
          'a' => { 'href' => ['ftp', 'http', 'https', 'mailto', '#fn', '#fnref', :relative] },
          'img' => {'src'  => ['http', 'https', :relative]},
          'iframe' => {'src'  => ['http', 'https']},
          'embed' => {'src'  => ['http', 'https']},
          'object' => {'src'  => ['http', 'https']},
          'li' => {'id' => ['fn']},
          'sup' => {'id' => ['fnref']}
        },
        transformers: EmbedTransformer
      }
    end
  end
end
