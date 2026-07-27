# frozen_string_literal: true

namespace :solid_cache do
  desc "Recreate the Solid Cache SQLite database (use after a SQLite3::CorruptException)"
  task recreate: :environment do
    SolidCacheRecreateDatabase.call
  end
end
