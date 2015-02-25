module ActiveAdminParanoia
  module DSL
    def active_admin_paranoia
      controller do
        def find_resource
          resource_class.to_s.camelize.constantize.unscoped.where(id: params[:id]).first!
        end

        def action_methods
          if params[:scope] == 'archived'
            %w(index)
          else
            super
          end
        end
      end

      batch_action :destroy, confirm: proc{ I18n.t('active_admin.batch_actions.delete_confirmation', plural_model: resource_class.to_s.downcase.pluralize) }, if: proc{ authorized?(ActiveAdmin::Auth::DESTROY, resource_class) && params[:scope] != 'archived' } do |ids|
        resource_class.to_s.camelize.constantize.where(id: ids).destroy_all
        redirect_to :back, notice: I18n.t('active_admin.batch_actions.succesfully_destroyed', count: ids.count, model: resource_class.to_s.camelize.constantize.model_name, plural_model: resource_class.to_s.downcase.pluralize)
      end

      batch_action :restore, confirm: proc{ I18n.t('active_admin_paranoia.batch_actions.restore_confirmation', plural_model: resource_class.to_s.downcase.pluralize) }, if: proc{ authorized?(ActiveAdminParanoia::Auth::RESTORE, resource_class) && params[:scope] == 'archived' } do |ids|
        resource_class.to_s.camelize.constantize.restore(ids, recursive: true)
        redirect_to :back, notice: I18n.t('active_admin_paranoia.batch_actions.succesfully_restored', count: ids.count, model: resource_class.to_s.camelize.constantize.model_name, plural_model: resource_class.to_s.downcase.pluralize)
      end

      scope(I18n.t('active_admin_paranoia.non_archived'), default: true) { |scope| scope.where(resource_class.to_s.camelize.constantize.paranoia_column => resource_class.to_s.camelize.constantize.paranoia_sentinel_value) }
      scope(I18n.t('active_admin_paranoia.archived')) { |scope| scope.where.not(resource_class.to_s.camelize.constantize.paranoia_column => resource_class.to_s.camelize.constantize.paranoia_sentinel_value) }
    end
  end
end
