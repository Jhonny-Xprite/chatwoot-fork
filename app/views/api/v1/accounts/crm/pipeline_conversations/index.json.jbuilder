json.data do
  json.meta do
    json.current_page @conversations.current_page
    json.total_pages @conversations.total_pages
    json.total_count @conversations.total_count
  end
  json.payload do
    json.array! @conversations do |conversation|
      json.partial! 'api/v1/conversations/partials/conversation', formats: [:json], conversation: conversation
    end
  end
end
