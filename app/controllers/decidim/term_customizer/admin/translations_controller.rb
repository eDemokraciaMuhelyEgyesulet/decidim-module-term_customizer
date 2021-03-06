# frozen_string_literal: true

module Decidim
  module TermCustomizer
    module Admin
      class TranslationsController < TermCustomizer::Admin::ApplicationController
        helper_method :collection, :set, :translations, :translation

        def index
          enforce_permission_to :read, :translation
          @translations = collection
          @directory = TranslationDirectory.new(current_locale)
        end

        def new
          enforce_permission_to :create, :translation

          @form = form(TranslationForm).from_model(Translation.new)
        end

        def create
          enforce_permission_to :create, :translation
          @form = form(TranslationForm).from_params(
            params,
            current_organization: current_organization,
            translation_set: set
          )

          CreateTranslation.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("translations.create.success", scope: "decidim.term_customizer.admin")
              redirect_to translation_set_translations_path(set)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("translations.create.error", scope: "decidim.term_customizer.admin")
              render action: "new"
            end
          end
        end

        def edit
          enforce_permission_to :update, :translation, translation: translation
          @form = form(TranslationForm).from_model(translation)
        end

        def update
          enforce_permission_to :update, :translation, translation: translation
          @form = form(TranslationForm).from_params(
            params,
            current_organization: current_organization,
            translation_set: set
          )

          UpdateTranslation.call(@form, translation) do
            on(:ok) do
              flash[:notice] = I18n.t("translations.update.success", scope: "decidim.term_customizer.admin")
              redirect_to translation_set_translations_path(set)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("translations.update.invalid", scope: "decidim.term_customizer.admin")
              render action: "edit"
            end
          end
        end

        def destroy
          enforce_permission_to :destroy, :translation, translation: translation

          # Destroy all locales of the translation key
          Decidim::TermCustomizer::Translation.where(
            translation_set: set,
            key: translation.key
          ).destroy_all

          flash[:notice] = I18n.t("translations.destroy.success", scope: "decidim.term_customizer.admin")

          redirect_to translation_set_translations_path(set)
        end

        private

        def translation_set
          @translation_set ||= OrganizationTranslationSets.new(
            current_organization
          ).query.find(params[:translation_set_id])
        end

        def translations
          @translations ||= SetTranslations.new(translation_set, current_locale)
        end

        def translation
          @translation ||= Decidim::TermCustomizer::Translation.find(params[:id])
        end

        alias collection translations
        alias set translation_set
      end
    end
  end
end
