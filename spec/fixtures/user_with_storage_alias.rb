class UserWithStorageAlias < ActiveRecord::Base
  include Paperclip::Glue

  has_attached_file :avatar, {
    storage: :eitheror,
    either: {
      storage: :filesystem,
      path: "spec/primary_storage/:filename",
      url: "/url/primary_storage/:filename",
      alias: {
        only_on_or: :either_handler,
        either_lambda_alias: ->(either_storage, or_storage, avatar, *args) do
          self.instance_variable_set(:@either_lambda_called_with, [either_storage, or_storage, avatar, *args])
        end
      }
    },
    or: {
      storage: :filesystem,
      path: "spec/fallback_storage/:filename",
      url: "/url/fallback_storage/:filename",
      alias: {
        only_on_either: :or_handler,
        or_lambda_alias: ->(either_storage, or_storage, avatar, *args) do
          self.instance_variable_set(:@or_lambda_called_with, [either_storage, or_storage, avatar, *args])
        end
      }
    },
  }

  do_not_validate_attachment_file_type :avatar
end

UserWithStorageAlias.table_name = "users"
