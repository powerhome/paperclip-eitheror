module Paperclip
  module Storate
    module Eitheror
      def self.extended base
        base.instance_eval do
          @either = Attachment.new(base.name, base.instance, base.options.merge(base.options[:either]))
          @or = Attachment.new(base.name, base.instance, base.options.merge(base.options[:or]))
        end
      end

      def flush_writes
        usable_storage.intance_var_set(:@queued_for_write, @queued_for_write)
        usable_storage.flush_writes
        @queued_for_write = {}
      end

      def path(style = default_style)
        usable_storage.path(style)
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
