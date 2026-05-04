class AddUnreadPinnedToConversations < ActiveRecord::Migration[6.0]
  def change
    # Add timestamp columns for unread and pinned states
    # These columns track when the conversation was last marked unread or pinned
    # NULL means the conversation is not in that state
    add_column :conversations, :unread_at, :datetime
    add_column :conversations, :pinned_at, :datetime

    # Create indexes for efficient filtering on unread/pinned conversations
    add_index :conversations, [:account_id, :unread_at], name: 'index_conversations_on_account_unread'
    add_index :conversations, [:account_id, :pinned_at], name: 'index_conversations_on_account_pinned'
    add_index :conversations, [:inbox_id, :unread_at], name: 'index_conversations_on_inbox_unread'
    add_index :conversations, [:inbox_id, :pinned_at], name: 'index_conversations_on_inbox_pinned'
  end
end
