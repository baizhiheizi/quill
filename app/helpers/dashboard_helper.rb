# frozen_string_literal: true

module DashboardHelper
  # Shared section list for shared/_dashboard_rail and shared/_dashboard_tabbar
  # (specs/005-dashboard-ux-redesign) — single source of truth for the 5
  # grouped nav destinations so desktop/mobile never diverge (FR-006).
  def dashboard_rail_sections
    [
      { section: :overview, label: t("overview"), path: dashboard_root_path, icon: "i-[tabler--layout-dashboard]" },
      { section: :write, label: t("write"), path: dashboard_write_path, icon: "i-[tabler--article]" },
      { section: :read, label: t("read"), path: dashboard_read_path, icon: "i-[tabler--eyeglass]" },
      { section: :finances, label: t("finances"), path: dashboard_finances_path, icon: "i-[tabler--wallet]" },
      { section: :account, label: t("account"), path: dashboard_account_path, icon: "i-[tabler--settings]" }
    ]
  end
end
