module Paperclip
  module Storage
    module Eitheror
      def self.extended(base)
        base.instance_eval do
          base.options[:either][:enabled] = true if base.options[:either][:enabled].nil?
          @either = Attachment.new(base.name, base.instance, base.options.merge(base.options[:either]))
          @or = Attachment.new(base.name, base.instance, base.options.merge(base.options[:or]))

          define_aliases @either, base.options[:either].fetch(:alias, {})
          define_aliases @or, base.options[:or].fetch(:alias, {})
        end
      end

      def sync
        @either.assign @or
        @either.save
      end

      def synced?
        @either.exists?
      end

      def syncable?
        @or.exists?
      end

      def path(style_name = default_style)
        usable_storage.path(style_name)
      end

      def url(style_name = default_style, options = {})
        usable_storage.url(style_name, options)
      end

      def flush_writes
        storage = usable_storage
        storage.instance_variable_set(:@queued_for_write, @queued_for_write)
        storage.flush_writes

        @queued_for_write = {}
      end

      def flush_deletes
        all_storages.each do |storage|
          storage.instance_variable_set(:@queued_for_delete, @queued_for_delete)
          storage.flush_deletes
        end

        @queued_for_delete = []
      end

      def queue_some_for_delete(*styles)
        @queued_for_delete += styles.flatten.uniq.map do |style|
          all_storages.map { |s| s.path(style) if s.exists?(style) }
        end.flatten.compact
      end

      def queue_all_for_delete
        queue_some_for_delete([:original, *styles.keys].uniq)
        super
      end

      def method_missing method, *args
        usable_storage.send(method, *args)
      end

      def either_enabled?
        callable_option(@either, :enabled)
      end

      private

      def callable_option(attachment, key)
        option = attachment.options[key]
        option.respond_to?(:call) ? option.call(attachment) : option
      end

      def all_storages
        [@either, @or]
      end

      def usable_storage
        return @or unless either_enabled?
        return @either if !@or.exists? || @either.exists?
        options[:autosync] && sync ? @either : @or
      end

      def define_aliases target, aliases = {}
        aliases.each do |name, value|
          block = is_callable?(value) ?
            ->(*args) { value.call(@either, @or, self, *args) } :
            ->(*args) { target.send(value, *args) }
          create_method(target, name, &block)
        end
      end

      def is_callable?(o)
        o.respond_to?(:call)
      end

      def create_method(target, name, &block)
        target.class.send(:define_method, name, &block)
      end
    end
  end
end
