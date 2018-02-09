module ActiveAdminParanoia
  # Default Authorization permission for ActiveAdminParanoia
  module Authorization
    ARCHIVE = :do_archive
    RESTORE = :restore
    PERMANENT_DELETE = :permanent_delete
  end

  Auth = Authorization
end
