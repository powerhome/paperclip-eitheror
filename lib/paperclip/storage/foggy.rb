module Paperclip
  module Storage
    module Foggy
      def self.extended(base)
        base.instance_eval do
          @fog = Attachment.new(base.name, base.instance, @options.merge(storage: :fog))
        end
      end

      def path(style_name = default_style)
        Paperclip.io_adapters.for(short_expiring_url(style_name)).path
      end

      def fog_path(style_name = default_style)
        @fog.path(style_name)
      end

      def url(style_name = default_style, options = {})
        short_expiring_url(style_name)
      end

      def short_expiring_url(style_name = default_style)
        @fog.expiring_url(Time.now.to_f + 3600, style_name)
      end

      def method_missing(method, *args)
        @fog.send(method, *args)
      end
    end
  end
end
