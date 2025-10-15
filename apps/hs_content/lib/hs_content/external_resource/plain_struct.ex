defprotocol HSContent.ExternalResource.PlainStruct do
  def from_struct(any_object)

  def from_plain_text(content, format)

  def to_plain_text(external_resource, format)
end
