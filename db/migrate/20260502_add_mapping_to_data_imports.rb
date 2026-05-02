class AddMappingToDataImports < ActiveRecord::Migration[7.0]
  def change
    # Add JSON column to store user-defined column mappings during CSV import
    # This enables the Contact Import system to persist advanced field mapping capabilities
    # Column is optional (defaults to empty hash) for backwards compatibility
    # See: https://github.com/chatwoot/chatwoot-fork/docs/stories/2.1.story.md
    add_column :data_imports, :mapping, :json, default: {}, if_not_exists: true
  end
end
