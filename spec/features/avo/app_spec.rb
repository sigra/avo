require "rails_helper"

RSpec.describe "App", type: :feature do
  describe "custom tool works" do
    it "redirects to the admin page" do
      visit "/admin/dashboard"

      expect(current_path).to eq "/admin/dashboard"

      # Label on the menu builder
      expect(page).to have_text "Fishies"
    end
  end
end
