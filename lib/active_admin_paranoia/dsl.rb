module ActiveAdminParanoia
  module DSL
    def active_admin_paranoia
      controller do
        def find_resource
          resource_class.to_s.camelize.constantize.with_deleted.where(id: params[:id]).first!
        end
      end

      batch_action :destroy, confirm: proc{ I18n.t('active_admin.batch_actions.delete_confirmation', plural_model: resource_class.to_s.downcase.pluralize) }, if: proc{ authorized?(ActiveAdmin::Auth::DESTROY, resource_class) && params[:scope] != 'archived' } do |ids|
        resource_class.to_s.camelize.constantize.where(id: ids).destroy_all
        options = { notice: I18n.t('active_admin.batch_actions.succesfully_destroyed', count: ids.count, model: resource_class.to_s.camelize.constantize.model_name, plural_model: resource_class.to_s.downcase.pluralize) }
        # For more info, see here: https://github.com/rails/rails/pull/22506
        if Rails::VERSION::MAJOR >= 5
          redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options))
        else
          redirect_to :back, options
        end
      end

      batch_action :restore, confirm: proc{ I18n.t('active_admin_paranoia.batch_actions.restore_confirmation', plural_model: resource_class.to_s.downcase.pluralize) }, if: proc{ authorized?(ActiveAdminParanoia::Auth::RESTORE, resource_class) && params[:scope] == 'archived' } do |ids|
        resource_class.to_s.camelize.constantize.restore(ids, recursive: true)
        options = { notice: I18n.t('active_admin_paranoia.batch_actions.succesfully_restored', count: ids.count, model: resource_class.to_s.camelize.constantize.model_name, plural_model: resource_class.to_s.downcase.pluralize) }
        # For more info, see here: https://github.com/rails/rails/pull/22506
        if Rails::VERSION::MAJOR >= 5
          redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options))
        else
          redirect_to :back, options
        end
      end

      member_action :restore, method: :put, confirm: proc{ I18n.t('active_admin_paranoia.restore_confirmation') }, if: proc{ authorized?(ActiveAdminParanoia::Auth::RESTORE, resource_class) } do
        resource.restore(recursive: true)
        options = { notice: I18n.t('active_admin_paranoia.batch_actions.succesfully_restored', count: 1, model: resource_class.to_s.camelize.constantize.model_name, plural_model: resource_class.to_s.downcase.pluralize) }
        # For more info, see here: https://github.com/rails/rails/pull/22506
        if Rails::VERSION::MAJOR >= 5
          redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options))
        else
          redirect_to :back, options
        end
      end

      scope(I18n.t('active_admin_paranoia.non_archived'), default: true) { |scope| scope.where(resource_class.to_s.camelize.constantize.paranoia_column => resource_class.to_s.camelize.constantize.paranoia_sentinel_value) }
      scope(I18n.t('active_admin_paranoia.archived')) { |scope| scope.unscope(:where => resource_class.to_s.camelize.constantize.paranoia_column).where.not(resource_class.to_s.camelize.constantize.paranoia_column => resource_class.to_s.camelize.constantize.paranoia_sentinel_value) }
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
