defprotocol HSContent.ExternalResource.HTML do
  @doc "将 %ExternalResource{} 结构体变为 HTML"
  def to_html(external_object)
end
