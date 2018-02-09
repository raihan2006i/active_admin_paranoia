module ActiveAdminParanoia
  module DSL
    def active_admin_paranoia
      archived_at_column = @resource.paranoia_column
      not_archived_value = @resource.paranoia_sentinel_value

      do_archive = proc do |ids, resource_class, controller|
        resource_class.where(id: ids).destroy_all
        options = { notice: I18n.t('active_admin_paranoia.batch_actions.succesfully_archived', count: ids.count, model: resource_class.model_name, plural_model: resource_class.to_s.downcase.pluralize) }
        # For more info, see here: https://github.com/rails/rails/pull/22506
        if Rails::VERSION::MAJOR >= 5
          controller.redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options))
        else
          controller.redirect_to :back, options
        end
      end

      controller do
        def find_resource
          resource_class.with_deleted.where(id: params[:id]).first!
        end
      end

      batch_action :archive, confirm: proc{ I18n.t('active_admin_paranoia.batch_actions.archive_confirmation', plural_model: resource_class.to_s.downcase.pluralize) }, if: proc{ authorized?(ActiveAdminParanoia::Auth::ARCHIVE, resource_class) && params[:scope] != 'archived' } do |ids|
        do_archive.call(ids, resource_class, self)
      end

      batch_action :destroy, if: proc { false } do
      end

      batch_action :restore, confirm: proc{ I18n.t('active_admin_paranoia.batch_actions.restore_confirmation', plural_model: resource_class.to_s.downcase.pluralize) }, if: proc{ authorized?(ActiveAdminParanoia::Auth::RESTORE, resource_class) && params[:scope] == 'archived' } do |ids|
        resource_class.restore(ids, recursive: true)
        options = { notice: I18n.t('active_admin_paranoia.batch_actions.succesfully_restored', count: ids.count, model: resource_class.model_name, plural_model: resource_class.to_s.downcase.pluralize) }
        # For more info, see here: https://github.com/rails/rails/pull/22506
        if Rails::VERSION::MAJOR >= 5
          redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options))
        else
          redirect_to :back, options
        end
      end

      action_item :archive, only: :show, if: proc { !resource.send(archived_at_column) } do
        link_to(I18n.t('active_admin_paranoia.archive_model', model: resource_class.to_s.titleize), "#{resource_path(resource)}/archive", method: :put, data: { confirm: I18n.t('active_admin_paranoia.archive_confirmation') }) if authorized?(ActiveAdminParanoia::Auth::ARCHIVE, resource)
      end

      action_item :restore, only: :show, if: proc { resource.send(archived_at_column) } do
        link_to(I18n.t('active_admin_paranoia.restore_model', model: resource_class.to_s.titleize), "#{resource_path(resource)}/restore", method: :put, data: { confirm: I18n.t('active_admin_paranoia.restore_confirmation') }) if authorized?(ActiveAdminParanoia::Auth::RESTORE, resource)
      end

      member_action :archive, method: :put, confirm: proc{ I18n.t('active_admin_paranoia.archive_confirmation') }, if: proc{ authorized?(ActiveAdminParanoia::Auth::ARCHIVE, resource_class) } do
        do_archive.call([resource.id], resource_class, self)
      end

      member_action :restore, method: :put, confirm: proc{ I18n.t('active_admin_paranoia.restore_confirmation') }, if: proc{ authorized?(ActiveAdminParanoia::Auth::RESTORE, resource_class) } do
        resource.restore(recursive: true)
        options = { notice: I18n.t('active_admin_paranoia.batch_actions.succesfully_restored', count: 1, model: resource_class.model_name, plural_model: resource_class.to_s.downcase.pluralize) }
        # For more info, see here: https://github.com/rails/rails/pull/22506
        if Rails::VERSION::MAJOR >= 5
          redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options))
        else
          redirect_to :back, options
        end
      end

      scope(I18n.t('active_admin_paranoia.non_archived'), default: true) { |scope| scope.where(archived_at_column => not_archived_value) }
      scope(I18n.t('active_admin_paranoia.archived')) { |scope| scope.unscope(:where => archived_at_column).where.not(archived_at_column => not_archived_value) }
    end
  end
end

module ActiveAdmin
  module Views
    class IndexAsTable < ActiveAdmin::Component
      class IndexTableFor < ::ActiveAdmin::Views::TableFor
        alias_method :orig_defaults, :defaults

        def defaults(resource, options = {})
          if resource.respond_to?(:deleted?) && resource.deleted?
            if controller.action_methods.include?('restore') && authorized?(ActiveAdminParanoia::Auth::RESTORE, resource)
              # TODO: find a way to use the correct path helper
              item I18n.t('active_admin_paranoia.restore'), "#{resource_path(resource)}/restore", method: :put, class: "restore_link #{options[:css_class]}",
                data: {confirm: I18n.t('active_admin_paranoia.restore_confirmation')}
            end
          else
            orig_defaults(resource, options)
          end
        end
      end
    end
  end
end
