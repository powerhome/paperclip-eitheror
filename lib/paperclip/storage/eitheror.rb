module Paperclip
  module Storage
    module Eitheror
      def self.extended base
        base.instance_eval do
          @either = Attachment.new(base.name, base.instance, base.options.merge(base.options[:either]))
          @or = Attachment.new(base.name, base.instance, base.options.merge(base.options[:or]))
        end
      end

      def path(style_name = default_style)
        usable_storage.path(style_name)
      end

      def flush_writes
        storage = usable_storage
        storage.instance_variable_set(:@queued_for_write, @queued_for_write)
        storage.flush_writes
      end

      def flush_deletes
        storage = usable_storage
        storage.flush_deletes
      end

      private
      def usable_storage

        either_exists = @either.exists?
        or_exists = @or.exists?

        if !(either_exists || or_exists)
          @either
        else
          either_exists ? @either : @or
        end
      end
    end
  end
end
