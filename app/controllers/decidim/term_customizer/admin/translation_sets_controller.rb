# frozen_string_literal: true

module Decidim
  module TermCustomizer
    module Admin
      class TranslationSetsController < TermCustomizer::Admin::ApplicationController
        include TranslatableAttributes

        helper_method :collection, :subject_manifests, :blank_constraint

        def index
          enforce_permission_to :read, :translation_set
          @sets = collection
        end

        def new
          enforce_permission_to :create, :translation_set

          @form = form(TranslationSetForm).from_model(
            TranslationSet.new(constraints: [Constraint.new])
          )
        end

        def create
          enforce_permission_to :create, :translation_set
          @form = form(TranslationSetForm).from_params(
            params,
            current_organization: current_organization
          )

          CreateTranslationSet.call(@form) do
            on(:ok) do |set|
              flash[:notice] = I18n.t("translation_sets.create.success", scope: "decidim.term_customizer.admin")
              redirect_to translation_set_translations_path(set)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("translation_sets.create.error", scope: "decidim.term_customizer.admin")
              render action: "new"
            end
          end
        end

        def edit
          enforce_permission_to :update, :translation_set, translation_set: set
          @form = form(TranslationSetForm).from_model(set)
        end

        def update
          enforce_permission_to :update, :translation_set, translation_set: set
          @form = form(TranslationSetForm).from_params(
            params,
            current_organization: current_organization
          )

          UpdateTranslationSet.call(@form, set) do
            on(:ok) do
              flash[:notice] = I18n.t("translation_sets.update.success", scope: "decidim.term_customizer.admin")
              redirect_to translation_sets_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("translation_sets.update.invalid", scope: "decidim.term_customizer.admin")
              render action: "edit"
            end
          end
        end

        def destroy
          enforce_permission_to :destroy, :translation_set, translation_set: set
          set.destroy!

          flash[:notice] = I18n.t("translation_sets.destroy.success", scope: "decidim.term_customizer.admin")

          redirect_to translation_sets_path
        end

        private

        def sets
          @sets ||= OrganizationTranslationSets.new(current_organization)
        end

        alias collection sets

        def subject_manifests
          @subject_manifests ||= Decidim.participatory_space_manifests.map do |manifest|
            models = manifest.model_class_name.constantize.where(organization: current_organization).map { |p| [translated_attribute(p.title), p.id] }
            next unless models.count.positive?

            manifest
          end.compact
        end

        def set
          @set ||= Decidim::TermCustomizer::TranslationSet.find(params[:id])
        end

        def blank_constraint
          @blank_constraint ||= Admin::TranslationSetConstraintForm.from_model(
            Constraint.new
          )
        end
      end
    end
  end
end
