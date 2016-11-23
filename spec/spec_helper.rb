$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "paperclip-eitheror"

require 'active_record'
require 'paperclip'

ActiveRecord::Base.establish_connection(
adapter: "sqlite3", database: ":memory:"
)

ActiveRecord::Schema.suppress_messages do
  ActiveRecord::Schema.define version: 0 do
    create_table :users, force: true do |t|
      t.string  :avatar_file_name
      t.string  :avatar_content_type
    end
  end
end

Paperclip.options[:log] = false
Paperclip.interpolates(:rails_root) do |a, _|
  Dir.tmpdir
end

class User < ActiveRecord::Base
  include Paperclip::Glue

  has_attached_file :avatar, {
    storage: :eitheror,
    either: {
      storage: :filesystem,
      path: "spec/primary_storage/:class/:attachment/:style/:filename",
      url: "/primary_storage/:class/:attachment/:style/:filename"
    },
    or: {
      storage: :filesystem,
      path: "spec/fallback_storage/:class/:attachment/:style/:filename",
      url: "/fallback/:class/:attachment/:style/:filename"
    }
  }

  do_not_validate_attachment_file_type :avatar
end
