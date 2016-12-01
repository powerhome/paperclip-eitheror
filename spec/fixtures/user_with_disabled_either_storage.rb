class UserWithDisabledEitherStorage < ActiveRecord::Base
  include Paperclip::Glue

  has_attached_file :avatar, {
    storage: :eitheror,
    either: {
      enabled: false,
      storage: :filesystem,
      path: "spec/primary_storage/:filename",
      url: "/url/primary_storage/:filename",
    },
    or: {
      storage: :filesystem,
      path: "spec/fallback_storage/:filename",
      url: "/url/fallback_storage/:filename",
    },
  }

  do_not_validate_attachment_file_type :avatar
end

UserWithDisabledEitherStorage.table_name = "users"
