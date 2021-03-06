# frozen_string_literal: true

require "spec_helper"

describe Decidim::TermCustomizer::Engine do
  before do
    ActiveSupport::Notifications.unsubscribe(
      "start_processing.action_controller"
    )
  end

  it "sets up term customizer i18n backend during initialization" do
    expect(Decidim::TermCustomizer::I18nBackend).to receive(:new).and_call_original

    run_initializer

    expect(I18n.backend).to be_a(I18n::Backend::Chain)
    expect(I18n.backend.backends).to include(Decidim::TermCustomizer::I18nBackend)
  end

  context "when instrumenting the start_processing.action_controller notification" do
    let(:dummy_backend) { double }
    let(:dummy_data) { { headers: dummy_data_headers } }
    let(:dummy_data_headers) { double }
    let(:dummy_organization) { double }
    let(:dummy_space) { double }
    let(:dummy_component) { double }
    let(:dummy_env) do
      {
        "decidim.current_organization" => dummy_organization,
        "decidim.current_participatory_space" => dummy_space,
        "decidim.current_component" => dummy_component
      }
    end

    it "calls the subscribed block set during initialization" do
      expect(Decidim::TermCustomizer::I18nBackend).to receive(:new).and_return(dummy_backend)

      run_initializer

      expect(dummy_data_headers).to receive(:env).and_return(dummy_env)
      expect(Decidim::TermCustomizer::Resolver).to receive(:new).with(
        dummy_organization,
        dummy_space,
        dummy_component
      )
      expect(dummy_backend).to receive(:reload!)

      ActiveSupport::Notifications.instrument(
        "start_processing.action_controller",
        dummy_data
      )
    end
  end

  def run_initializer
    config = described_class.initializers.find do |i|
      i.name == "decidim_term_customizer.setup"
    end
    config.run
  end
end
