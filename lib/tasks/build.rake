# ref: https://github.com/rails/rails/issues/43906#issuecomment-1094380699
# https://github.com/rails/rails/issues/43906#issuecomment-1099992310
task before_assets_precompile: :environment do
  skip_pnpm_install = ActiveModel::Type::Boolean.new.cast(
    ENV.fetch('SKIP_PRECOMPILE_PNPM_INSTALL', false)
  )

  system('pnpm install') || abort('pnpm install failed before assets:precompile') unless skip_pnpm_install

  system('echo "-------------- Bulding SDK for Production --------------"')
  system('pnpm run build:sdk') || abort('pnpm run build:sdk failed before assets:precompile')
  system('echo "-------------- Bulding App for Production --------------"')
end

# every time you execute 'rake assets:precompile'
# run 'before_assets_precompile' first
Rake::Task['assets:precompile'].enhance %w[before_assets_precompile]
